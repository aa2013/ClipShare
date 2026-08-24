import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:clipshare/core/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/dao/rule_dao.dart';
import 'package:clipshare/core/database/dao/script_module_dao.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/database/tables/rule.dart';
import 'package:clipshare/core/database/tables/script_module.dart';
import 'package:clipshare/core/device/local_device_info.dart';
import 'package:clipshare/core/extensions/rule_extension.dart';
import 'package:clipshare/core/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/notify/notify_provider.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/crypto.dart';
import 'package:clipshare/core/utils/snowflake.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/enums/rule/rule_content_type.dart';
import 'package:clipshare/shared/enums/rule/rule_script_language.dart';
import 'package:clipshare/shared/enums/rule/rule_trigger.dart';
import 'package:clipshare/shared/enums/rule/white_black_mode.dart';
import 'package:clipshare/shared/enums/support_platform.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/extensions/target_platform_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/models/rule/rule_apply_result.dart';
import 'package:clipshare/shared/models/rule/rule_exec_params.dart';
import 'package:clipshare/shared/models/rule/rule_exec_result.dart';
import 'package:clipshare/shared/models/rule/rule_item.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_embed_lua/lua_bindings.dart';
import 'package:flutter_embed_lua/lua_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'lua/global_function.dart';
import 'lua/modules.dart';
import 'lua/sandbox.dart';
import 'lua/template.dart';
import 'models/rule_state.dart';
import 'models/white_black_rule.dart';

part 'dart_function_bridge.dart';

part 'rules_provider.g.dart';

@Riverpod(keepAlive: true)
class RulesExecutorNotifier extends _$RulesExecutorNotifier {
  static const String tag = 'RulesExecutorNotifier';
  static final List<String> _testOutputs = [];

  RuleDao get _ruleDao => ref.read(appDbProvider).requireValue.ruleDao;

  ScriptModuleDao get _scriptModuleDao => ref.read(appDbProvider).requireValue.scriptModuleDao;

  OperationRecordDao get _opRecordDao => ref.read(appDbProvider).requireValue.operationRecordDao;

  Snowflake get _idGenerator => ref.read(idProvider);

  LocalDeviceInfo get _localDevInfo => ref.read(localDeviceInfoProvider).requireValue;

  //规则是否已迁移到1.5.0
  final LuaRuntime _lua = LuaRuntime();
  final _loadedLuaFun = <String, int>{};

  List<RuleItem> _rules = [];
  List<ScriptModule> _scriptModules = [];
  RuleItem? _selectedRuleItem;
  ScriptModule? _selectedLuaModuleItem;
  bool _activeItemChanged = false;

  bool get enableSmsSync {
    final smsRules = _rules.where((e) => e.trigger == RuleTrigger.onSms && e.enabled);
    return smsRules.isNotEmpty;
  }

  @override
  Future<RuleState> build() async {
    _refContainer = ref.container;
    await _migrateRules();
    await _initLuaFunc();
    final list = await _ruleDao.getAllRules();
    _rules = list.map((e) => e.toModel()).toList();
    _scriptModules = await _scriptModuleDao.getAllModules();
    _loadAllScriptModules();
    // todo move to ui
    // ensureSmsSyncReady(showDialog: true);
    _loadAllLuaUserFn();
    return RuleState(
      rules: _rules,
      scriptModules: _scriptModules,
      selectedRuleItem: _selectedRuleItem,
      selectedLuaModuleItem: _selectedLuaModuleItem,
    );
  }

  //region 初始化 lua

  Future<void> _initLuaFunc() async {
    final appPaths = await ref.read(appPathsProvider.future);
    final baseDevInfo = _localDevInfo.baseDeviceInfo;
    final appVersion = _localDevInfo.appVersion;

    _mainState = _lua.L;
    final luaLibPath = p.join(appPaths.luaLibDirPath, '?.lua').replaceAll('\\', '/');
    logger.debug(tag, 'LuaLibPath: $luaLibPath');
    var result = _lua.run('''
      package.path = package.path..';'..'$luaLibPath'
      json = require('dkjson')
      task = require('task')
      async = task.async
      await = task.await
      print('success')
      ''');
    if (result.containsIgnoreCase('error')) {
      logger.error(tag, 'init global lib: $result');
    } else {
      logger.debug(tag, 'init global lib: $result');
    }
    final global = luaGlobalFun.replaceAll('{{devId}}', baseDevInfo.id).replaceAll('{{devName}}', baseDevInfo.name).replaceAll('{{versionNumber}}', appVersion.code).replaceAll('{{versionName}}', appVersion.name).replaceAll('{{platformIsAndroid}}', '$isAndroid').replaceAll('{{platformIsLinux}}', '$isLinux').replaceAll('{{platformIsWindows}}', '$isWindows').replaceAll('{{platformIsMacOS}}', '$isMacOS').replaceAll('{{platformIsIOS}}', '$isIOS');

    final onLuaAsyncResult = Pointer.fromFunction<LuaFunction>(_onLuaAsyncResult, 0);
    final logFunPtr = Pointer.fromFunction<LuaFunction>(_log, 0);
    //测试
    final delayPtr = Pointer.fromFunction<LuaFunction>(_delay, 0);
    final notifyFunPtr = Pointer.fromFunction<LuaFunction>(_notify, 0);
    final md5FunPtr = Pointer.fromFunction<LuaFunction>(_calcMd5, 0);
    final sha1FunPtr = Pointer.fromFunction<LuaFunction>(_calcSHA1, 0);
    final sha256FunPtr = Pointer.fromFunction<LuaFunction>(_calcSHA256, 0);
    final base64EncodePtr = Pointer.fromFunction<LuaFunction>(_base64Encode, 0);
    final base64DecodePtr = Pointer.fromFunction<LuaFunction>(_base64Decode, 0);
    final androidToastPtr = Pointer.fromFunction<LuaFunction>(_androidToast, 0);
    final androidSendHistoryChangedBroadcast = Pointer.fromFunction<LuaFunction>(
      _androidSendHistoryChangedBroadcast,
      0,
    );
    final regexMatchPtr = Pointer.fromFunction<LuaFunction>(_regexMatch, 0);
    final regexMatchGroupsPtr = Pointer.fromFunction<LuaFunction>(_regexMatchGroups, 0);
    final httpRequestPtr = Pointer.fromFunction<LuaFunction>(_luaHttpRequest, 0);
    _lua.registerFunction('__onLuaAsyncResult', onLuaAsyncResult);
    _lua.registerFunction('__delay', delayPtr);
    _lua.registerFunction('__log', logFunPtr);
    _lua.registerFunction('__notify', notifyFunPtr);
    _lua.registerFunction('__calcMD5', md5FunPtr);
    _lua.registerFunction('__calcSHA1', sha1FunPtr);
    _lua.registerFunction('__calcSHA256', sha256FunPtr);
    _lua.registerFunction('__base64Encode', base64EncodePtr);
    _lua.registerFunction('__base64Decode', base64DecodePtr);
    _lua.registerFunction('__androidToast', androidToastPtr);
    _lua.registerFunction(
      '__androidSendHistoryChangedBroadcast',
      androidSendHistoryChangedBroadcast,
    );
    _lua.registerFunction('__regexMatch', regexMatchPtr);
    _lua.registerFunction('__regexMatchGroups', regexMatchGroupsPtr);
    _lua.registerFunction('__httpRequest', httpRequestPtr);

    result = _lua.run(global);
    logger.debug(tag, 'init global lua fun: $result');
  }

  (bool success, String hash, String? error) loadLuaUserFunc(
    String funcName,
    String code, {
    String? hash,
    bool isTest = false,
  }) {
    final funcHash = hash ?? code.toMd5();
    final sandboxWrapper = luaSandboxWrapper.replaceAll('{{isTest}}', isTest.toString()).replaceAll('{{funcName}}', funcName).replaceAll('{{funcHash}}', funcHash).replaceAll('{{code}}', code);
    final msg = _lua.run(sandboxWrapper);
    final result = msg == 'OK';
    return (result, funcHash, result ? null : msg);
  }

  void _loadAllScriptModules() {
    for (var lib in _scriptModules) {
      final msg = loadLuaModules(lib);
      logger.debug(tag, 'load lib(${lib.moduleName}): $msg');
    }
  }

  void _loadAllLuaUserFn() {
    for (var rule in _rules) {
      if (!rule.isUseScript) {
        continue;
      }
      final (result, hash, _) = loadLuaUserFunc(
        rule.name,
        rule.script.content,
        hash: rule.id.toString(),
      );
      if (result) {
        _loadedLuaFun[hash] = rule.id;
      } else {
        logger.warn(
          tag,
          'load user lua function failed! name = ${rule.name}, script = ${rule.script.content}',
        );
      }
    }
  }

  void removeLuaUserFun(String hash) {
    _lua.run("remove_user_sandbox_method('$hash')");
  }

  //endregion

  bool isNotExistAppInfo(String appId) {
    // 来源已登记（来源库或本机已安装应用）时不视为缺失
    final sourceState = ref.read(clipboardSourceProvider).value;
    for (var rule in _rules) {
      final sources = rule.sources;
      for (var source in sources) {
        if (source != appId) {
          continue;
        }
        if (sourceState?.getAppInfoByAppId(source) != null) {
          continue;
        }
        return true;
      }
    }
    return false;
  }

  String loadLuaModules(ScriptModule lib, {bool reloadAllUserFn = false}) {
    final sandboxWrapper = luaModuleSandboxWrapper.replaceAll('{{funcName}}', 'loaLuaModule').replaceAll('{{moduleName}}', lib.moduleName).replaceAll('{{code}}', lib.source);
    final msg = _lua.run(sandboxWrapper);
    if (msg == 'OK' && reloadAllUserFn) {
      _loadAllLuaUserFn();
    }
    return msg;
  }

  void _updateState() {
    state = AsyncData<RuleState>(
      RuleState(
        rules: _rules,
        scriptModules: _scriptModules,
        selectedRuleItem: _selectedRuleItem,
        selectedLuaModuleItem: _selectedLuaModuleItem,
        activeItemChanged: _activeItemChanged,
      ),
    );
  }

  //region modify rules

  void addOrUpdateRule(Rule rule) {
    var exists = false;
    final ruleItem = rule.toModel();
    for (var i = 0; i < _rules.length; i++) {
      if (_rules[i].id == rule.id) {
        _rules[i] = ruleItem;
        exists = true;
        break;
      }
    }
    if (!exists) {
      _rules.add(ruleItem);
    }
    _rules.sort();
    _updateState();
    loadLuaUserFunc(
      ruleItem.name,
      ruleItem.script.content,
      hash: ruleItem.id.toString(),
    );
    //todo move to ui
    // ensureSmsSyncReady(showDialog: true);
  }

  void addOrUpdateRuleLib(ScriptModule lib) {
    var exists = false;
    for (var i = 0; i < _scriptModules.length; i++) {
      if (_scriptModules[i].moduleName == lib.moduleName) {
        _scriptModules[i] = lib;
        exists = true;
        _updateState();
        break;
      }
    }
    if (!exists) {
      _scriptModules.add(lib);
    }
    final result = loadLuaModules(lib);
    logger.debug(tag, 'load lib(${lib.moduleName}): $result');
  }

  Future<void> saveRules() async {
    final List<RuleItem> updateList = [];
    final List<RuleItem> saveList = [];
    var order = 1;
    final newVersion = DateTime.now().yyyyMMddHHmmss;
    for (var rule in _rules) {
      if (rule.isNewData) {
        //未达到保存条件的忽略
        continue;
      }
      final oldOrder = rule.order;
      final newOrder = order++;
      if (oldOrder == newOrder) {
        //顺序无变化但是需要保存数据
        if (rule.dirty) {
          updateList.add(rule);
          rule.dirty = false;
        }
        continue;
      }
      //顺序变化需要保存
      final isSavedData = rule.version > 0;
      rule.dirty = false;
      rule.order = newOrder;
      rule.version = rule.version >= newVersion ? rule.version + 1 : newVersion;
      if (isSavedData) {
        //新数据，直接插入
        saveList.add(rule);
      } else {
        //老数据，仅更新
        updateList.add(rule);
      }
    }
    await _ruleDao.updateRules(updateList.map((e) => e.toRule()).toList());
    await _ruleDao.addRules(saveList.map((e) => e.toRule()).toList());
    //同步数据
    for (var updateData in updateList) {
      await _opRecordDao.deleteByDataWithCascade(updateData.id.toString());
    }
    for (var saveData in [...saveList, ...updateList]) {
      await _opRecordDao.addAndNotify(
        newOperationRecord(
          _idGenerator,
          _localDevInfo.baseDeviceInfo,
          Module.rule,
          OpMethod.add,
          saveData.id,
        ),
      );
    }
    //保存成功
    _updateState();
    //todo move to ui
    // ensureSmsSyncReady(showDialog: true);
  }

  /// 保存单条规则（新增或更新）。
  ///
  /// 成功后刷新 Lua 用户函数并同步操作记录；返回是否保存成功，由调用方决定提示。
  Future<bool> saveRule(RuleItem item) async {
    final index = _rules.indexWhere((e) => e.id == item.id);
    if (index < 0) {
      return false;
    }
    item.version = DateTime.now().yyyyMMddHHmmss;
    final newRule = item.toRule();
    try {
      final Future<int> saveFuture;
      if (item.isNewData) {
        item.isNewData = false;
        saveFuture = _ruleDao.addRule(newRule);
      } else {
        saveFuture = _ruleDao.updateRule(newRule);
      }
      final cnt = await saveFuture;
      if (cnt == 0) {
        return false;
      }
      _rules[index] = item;
      _selectedRuleItem = item;
      loadLuaUserFunc(
        item.name,
        item.script.content,
        hash: item.id.toString(),
      );
      //同步数据
      await _opRecordDao.deleteByDataWithCascade(newRule.id.toString());
      await _opRecordDao.addAndNotify(
        newOperationRecord(
          _idGenerator,
          _localDevInfo.baseDeviceInfo,
          Module.rule,
          OpMethod.add,
          newRule.id,
        ),
      );
      _updateState();
      return true;
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return false;
    }
  }

  /// 保存单个脚本模块（新增或更新）。
  ///
  /// 成功后重新加载 Lua 模块并同步操作记录；返回是否保存成功，由调用方决定提示。
  Future<bool> saveScriptModule(ScriptModule module, ScriptModule newValue) async {
    final index = _scriptModules.indexWhere((e) => e.moduleName == module.moduleName);
    if (index < 0) {
      return false;
    }
    newValue = newValue.copyWith(
      version: DateTime.now().yyyyMMddHHmmss,
    );
    try {
      final Future<int> saveFuture;
      if (newValue.isNewData) {
        newValue.isNewData = false;
        saveFuture = _scriptModuleDao.addModule(newValue);
      } else {
        saveFuture = _scriptModuleDao.updateModule(newValue);
      }
      final cnt = await saveFuture;
      if (cnt == 0) {
        return false;
      }
      _scriptModules[index] = newValue;
      _selectedLuaModuleItem = newValue;
      //加载到全局函数
      final result = loadLuaModules(newValue);
      logger.debug(tag, 'load module(${module.moduleName}): $result');
      //同步数据
      await _opRecordDao.deleteByDataWithCascade(module.moduleName);
      await _opRecordDao.addAndNotify(
        newOperationRecord(
          _idGenerator,
          _localDevInfo.baseDeviceInfo,
          Module.scriptModule,
          OpMethod.add,
          module.moduleName,
        ),
      );
      _updateState();
      return true;
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return false;
    }
  }

  //endregion

  void updateSelectedRuleItem(RuleItem? selected) {
    _selectedRuleItem = selected;
    _updateState();
  }

  void updateSelectedScriptModule(ScriptModule? selected) {
    _selectedLuaModuleItem = selected;
    _updateState();
  }

  void updateActiveItemChanged(bool changed) {
    _activeItemChanged = changed;
    _updateState();
  }

  String compileModule(String code) {
    final moduleCompileScript = luaModuleCompileWrapper
        .replaceAll(
          r'{{code}}',
          code,
        )
        .replaceAll(
          r'{{ReturnValueTypeErrorMsg}}',
          TranslationKey.scriptModuleCompileReturnTableRequired.tr,
        );
    return _lua.run(moduleCompileScript);
  }

  Future<RuleExecResult> _apply(
    RuleItem rule,
    RuleExecParams params, {
    String? scriptHash,
  }) async {
    try {
      if (rule.isUseScript) {
        final language = rule.script.language;
        if (language != RuleScriptLanguage.lua) {
          return RuleExecResult.error('not support language: $language');
        }
        final paramsJson = jsonEncode(params);
        var hash = scriptHash ?? rule.id.toString();
        var taskId = _idGenerator.nextIdStr();
        final completer = Completer<String>();
        _luaCallbacks[taskId] = completer;
        final result = _lua.run(
          "return run_user_sandbox_method('$taskId', '$hash','$paramsJson')",
        );
        logger.debug(tag, 'run log result: $result');
        if (result.containsIgnoreCase('error') && !completer.isCompleted) {
          _luaCallbacks.remove(taskId);
          completer.complete(result);
        }
        final scriptResult = await completer.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            _luaCallbacks.remove(taskId);
            return 'Lua script execution timed out';
          },
        );
        logger.debug(tag, 'run result: $scriptResult');
        final map = jsonDecode(scriptResult);
        return RuleExecResult.success(RuleApplyResult.fromJson(map));
      } else {
        final regexRule = rule.regex;
        if (regexRule.mainRegex.isNullOrEmpty) {
          return RuleExecResult.ignore();
        }
        final result = regexRule.apply(params);
        return RuleExecResult.success(result);
      }
    } catch (err, stack) {
      final msg = '$err\n$stack';
      logger.error(tag, err, stack);
      return RuleExecResult.error(msg);
    }
  }

  Future<RuleExecResult> apply(
    HistoryContentType type,
    String content,
    ClipboardSource? source,
  ) async {
    final currentPlatform = defaultTargetPlatform.toSupportPlatform();
    if (currentPlatform == null) {
      return RuleExecResult.ignore();
    }
    RuleExecParams params;
    if (type == HistoryContentType.notification) {
      final map = jsonDecode(content);
      var nTitle = map['title'];
      var nContent = map['content']?.toString() ?? '';
      if (nContent.isEmpty) {
        return RuleExecResult.dropped();
      }
      params = RuleExecParams(
        type: type,
        title: nTitle,
        content: nContent,
        source: source,
      );
    } else {
      params = RuleExecParams(
        type: type,
        content: content,
        source: source,
      );
    }
    final snapshots = _rules
        .where((e) {
          return e.trigger.match(type) && e.version > 0;
        })
        .map((e) => e.copy())
        .toList();
    for (var rule in snapshots) {
      if (!rule.enabled) {
        continue;
      }
      if (!rule.platforms.contains(currentPlatform)) {
        continue;
      }
      RuleExecResult? execResult;
      //正则白名单模式
      final isRegexWhiteMode = rule.isUseRegex && rule.regex.mode == WhiteBlackMode.white;
      //来源配置为空或不在设定的来源内
      if (rule.sources.isNotEmpty && !rule.sources.contains(source?.id)) {
        if (isRegexWhiteMode) {
          //白名单丢弃，但需等待所有规则过完后统一判断，若有一个白名单通过则算通过
          execResult = RuleExecResult.success(
            params.toApplyResult(drop: true, isFinal: rule.regex.isFinal),
          );
        } else {
          //其他不在来源范围内的规则忽略
          continue;
        }
      }
      execResult ??= await _apply(rule, params);
      if (!execResult.success) {
        logger.warn(
          tag,
          'apply rule failed! content = $content, rule = ${rule.name}',
        );
      } else {
        final result = execResult.result!;
        params.merge(rule, result);
        //如果当前是规则白名单模式，需要等到最终才知道是否丢弃结果
        if (isRegexWhiteMode) {
          continue;
        } else if (result.isDropped || result.isFinalRule) {
          return RuleExecResult.success(params.toApplyResult());
        }
      }
    }
    return RuleExecResult.success(params.toApplyResult());
  }

  Future<RuleExecResult> test(RuleItem rule, RuleExecParams params) async {
    if (rule.isUseScript) {
      var content = '-- test\n${rule.script.content}';
      final (compileSuccess, hash, errorMsg) = loadLuaUserFunc(
        '${rule.name}-test',
        content,
        isTest: true,
      );
      if (compileSuccess) {
        _testOutputs.clear();
        final result = await _apply(rule, params, scriptHash: hash);
        removeLuaUserFun(hash);
        result.outputs = List.from(_testOutputs);
        _testOutputs.clear();
        return result;
      } else {
        final msg = 'compile failed: $errorMsg';
        logger.error(tag, msg);
        return RuleExecResult.error(msg);
      }
    } else {
      try {
        return await _apply(rule, params);
      } catch (err, stack) {
        final msg = '$err\n$stack';
        return RuleExecResult.error(msg);
      }
    }
  }

  ///迁移 1.5.0 以前的规则到现版本
  Future<void> _migrateRules() async {
    final dbRulesCnt = ((await _ruleDao.count()) ?? 0);
    if (dbRulesCnt != 0) {
      return;
    }
    final cfg = ref.read(appDbProvider).requireValue.configDao;
    var rules = <Rule>[];
    int order = 1;
    final version = DateTime.now().yyyyMMddHHmmss;
    final allPlatforms = (SupportPlatForm.values.map((e) => e.name).toList()..sort()).join(',');

    final enableSmsSync = (await cfg.getConfigByKey(ConfigKey.enableSmsSync, false));
    final tagRulesStr = (await cfg.getConfigByKey<String?>(ConfigKey.tagRules, null));

    //region 老标签规则转换
    try {
      final tagRules = jsonDecode(tagRulesStr ?? defaultTagRules) as Map<String, dynamic>;
      for (var rule in (tagRules['data'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        try {
          final name = rule['name'];
          final regex = rule['rule'];
          final isDefaultTag = name == TranslationKey.defaultLinkTagName.tr;
          rules.add(
            Rule(
              id: isDefaultTag ? 2061101839524896768 : _idGenerator.nextId(),
              name: name,
              platforms: allPlatforms,
              sources: '',
              trigger: RuleTrigger.onCopy.name,
              type: RuleContentType.regex.name,
              regexTags: name,
              regexMain: regex,
              regexAllowExtractData: false,
              regexExtractedContent: '',
              regexAllowAddTag: true,
              regexIsSyncDisabled: false,
              regexIsFinalRule: false,
              version: version,
              order: order++,
              enabled: true,
              regexWhiteBlackMode: WhiteBlackMode.defaultMode.name,
              scriptContent: luaTemplateRule,
              scriptLanguage: RuleScriptLanguage.lua.name,
            ),
          );
        } catch (err, stack) {
          logger.error(tag, err, stack);
        }
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    //endregion

    //region 老短信规则转换
    final smsRulesStr = (await cfg.getConfigByKey<String?>(ConfigKey.smsRules, null));
    try {
      final smsRules = jsonDecode(smsRulesStr ?? defaultSmsRules) as Map<String, dynamic>;
      final allSmsRules = (smsRules['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (var rule in allSmsRules) {
        try {
          final name = rule['name'];
          final regex = rule['rule'];
          rules.add(
            Rule(
              id: _idGenerator.nextId(),
              name: name,
              platforms: SupportPlatForm.android.name,
              sources: '',
              trigger: RuleTrigger.onSms.name,
              type: RuleContentType.regex.name,
              regexMain: regex,
              regexAllowExtractData: false,
              regexExtractedContent: '',
              regexAllowAddTag: false,
              regexTags: '',
              regexIsSyncDisabled: false,
              regexIsFinalRule: false,
              version: version,
              order: order++,
              enabled: enableSmsSync,
              regexWhiteBlackMode: WhiteBlackMode.defaultMode.name,
              scriptContent: luaTemplateRule,
              scriptLanguage: RuleScriptLanguage.lua.name,
            ),
          );
        } catch (err, stack) {
          logger.error(tag, err, stack);
        }
      }
      if (allSmsRules.isEmpty && enableSmsSync) {
        try {
          //若启用但是规则为空则代表所有短信都同步
          rules.add(
            Rule(
              id: _idGenerator.nextId(),
              name: TranslationKey.all.tr,
              platforms: SupportPlatForm.android.name,
              sources: '',
              trigger: RuleTrigger.onSms.name,
              type: RuleContentType.regex.name,
              regexMain: '.+',
              regexAllowExtractData: false,
              regexExtractedContent: '',
              regexAllowAddTag: false,
              regexTags: '',
              regexIsSyncDisabled: false,
              regexIsFinalRule: false,
              version: version,
              order: order++,
              enabled: enableSmsSync,
              regexWhiteBlackMode: WhiteBlackMode.defaultMode.name,
              scriptContent: luaTemplateRule,
              scriptLanguage: RuleScriptLanguage.lua.name,
            ),
          );
        } catch (err, stack) {
          logger.error(tag, err, stack);
        }
      }
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
    //endregion

    //region 老通知规则转换

    //region 老通知规则反序列化
    List<FilterRule> notificationWhiteList = [];
    List<FilterRule> notificationBlackList = [];
    WhiteBlackMode? currentNotificationWhiteBlackMode;
    final notificationBlackWhiteList = await cfg.getConfigByKey(ConfigKey.notificationBlackWhiteList, '');
    try {
      if (notificationBlackWhiteList.isNullOrEmpty) {
        notificationWhiteList = [];
        notificationBlackList = [];
      } else {
        final map = jsonDecode(notificationBlackWhiteList) as Map<String, dynamic>;
        currentNotificationWhiteBlackMode = WhiteBlackMode.values.byName(map['mode'].toString());
        notificationBlackList = (map['blacklist']! as List<dynamic>).map((item) => FilterRule.fromJson(item)).toList();
        notificationWhiteList = (map['whitelist']! as List<dynamic>).map((item) => FilterRule.fromJson(item)).toList();
      }
    } catch (err, stack) {
      debugPrint(err.toString());
      debugPrintStack(stackTrace: stack);
      notificationWhiteList = [];
      notificationBlackList = [];
    }
    //endregion

    var index = 1;

    //region 黑名单通知规则
    for (var rule in notificationBlackList) {
      try {
        var regex = rule.content;
        if (rule.isAllContent) {
          regex = '.+';
        }
        final sources = (rule.appIds.toList()..sort()).join(',');
        rules.add(
          Rule(
            id: _idGenerator.nextId(),
            name: '${TranslationKey.notification.tr}${index++}',
            platforms: SupportPlatForm.android.name,
            trigger: RuleTrigger.onNotification.name,
            type: RuleContentType.regex.name,
            sources: sources,
            regexMain: regex,
            regexAllowExtractData: false,
            regexExtractedContent: '',
            regexAllowAddTag: false,
            regexTags: '',
            regexIsSyncDisabled: false,
            version: version,
            order: order++,
            regexWhiteBlackMode: WhiteBlackMode.black.name,
            regexIsFinalRule: true,
            enabled: currentNotificationWhiteBlackMode == WhiteBlackMode.black && rule.enable,
            scriptContent: luaTemplateRule,
            scriptLanguage: RuleScriptLanguage.lua.name,
          ),
        );
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
    //endregion

    //region 白名单通知规则
    for (var rule in notificationWhiteList) {
      try {
        var regex = rule.content;
        if (rule.isAllContent) {
          regex = '.+';
        }
        final sources = (rule.appIds.toList()..sort()).join(',');
        rules.add(
          Rule(
            id: _idGenerator.nextId(),
            name: '${TranslationKey.notification.tr}${index++}',
            platforms: SupportPlatForm.android.name,
            trigger: RuleTrigger.onNotification.name,
            type: RuleContentType.regex.name,
            sources: sources,
            regexMain: regex,
            regexAllowExtractData: false,
            regexExtractedContent: '',
            regexAllowAddTag: false,
            regexTags: '',
            regexIsSyncDisabled: false,
            regexIsFinalRule: false,
            version: version,
            order: order++,
            regexWhiteBlackMode: WhiteBlackMode.white.name,
            enabled: currentNotificationWhiteBlackMode == WhiteBlackMode.white && rule.enable,
            scriptContent: luaTemplateRule,
            scriptLanguage: RuleScriptLanguage.lua.name,
          ),
        );
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
    //endregion

    //endregion

    //region 老内容规则转换
    //是否黑名单模式

    final isContentBlackMode = (await cfg.getConfigByKey(ConfigKey.enableContentBlackList, false));
    final contentRules = (await cfg.getConfigByKey<List<FilterRule>>(
      ConfigKey.blacklist,
      <FilterRule>[],
      convert: (value) {
        try {
          List<Map<String, dynamic>> jsonList = (jsonDecode(value) as List<dynamic>).cast();
          return jsonList.map((item) => FilterRule.fromJson(item)).toList();
        } catch (err, stack) {
          debugPrint(err.toString());
          debugPrintStack(stackTrace: stack);
          return [];
        }
      },
    ));
    index = 1;
    for (var rule in contentRules) {
      try {
        rules.add(
          Rule(
            id: _idGenerator.nextId(),
            name: '${TranslationKey.content.tr}${index++}',
            platforms: allPlatforms,
            sources: '',
            trigger: RuleTrigger.onCopy.name,
            type: RuleContentType.regex.name,
            regexTags: '',
            regexMain: rule.content,
            regexAllowExtractData: false,
            regexExtractedContent: '',
            regexAllowAddTag: false,
            regexIsSyncDisabled: false,
            regexIsFinalRule: true,
            version: version,
            order: order++,
            enabled: isContentBlackMode,
            regexWhiteBlackMode: WhiteBlackMode.black.name,
            scriptContent: luaTemplateRule,
            scriptLanguage: RuleScriptLanguage.lua.name,
          ),
        );
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }

    //endregion

    if (rules.isNotEmpty) {
      await _ruleDao.addRules(rules);
      for (var newRule in rules) {
        await _opRecordDao.addAndNotify(
          newOperationRecord(
            _idGenerator,
            _localDevInfo.baseDeviceInfo,
            Module.rule,
            OpMethod.add,
            newRule.id,
          ),
        );
      }
    }
  }
}
