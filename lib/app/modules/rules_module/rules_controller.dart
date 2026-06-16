import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/rule/rule_apply_result.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_params.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/data/repository/entity/tables/script_module.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/rule.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/target_platform_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_embed_lua/lua_bindings.dart';
import 'package:flutter_embed_lua/lua_runtime.dart';
import 'package:get/get.dart' hide Response;
import 'package:path/path.dart' as p;

part 'lua_global_function.dart';

/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class RulesController extends GetxController with WidgetsBindingObserver {
  static const String tag = "RulesController";
  final appConfig = Get.find<ConfigService>();
  final sourceService = Get.find<ClipboardSourceService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final ruleDao = Get.find<DbService>().ruleDao;
  final scriptModuleDao = Get.find<DbService>().scriptModuleDao;
  final opRecordDao = Get.find<DbService>().opRecordDao;

  final rules = <RuleItem>[].obs;
  final scriptModules = <ScriptModule>[].obs;
  final selectedRuleItem = Rx<RuleItem?>(null);
  final selectedLuaModuleItem = Rx<ScriptModule?>(null);
  final LuaRuntime _lua = LuaRuntime();
  final _loadedLuaFun = <String, int>{};
  final activeItemChanged = false.obs;
  static final List<String> _testOutputs = [];
  bool _requestingSmsPermission = false;

  bool get enableSmsSync {
    final smsRules =
        rules.where((e) => e.trigger == RuleTrigger.onSms && e.enabled);
    return smsRules.isNotEmpty;
  }

  //region 初始化 lua

  void _initLuaFunc() {
    _mainState = _lua.L;
    final luaLibPath = p.join(appConfig.luaLibDirPath, "?.lua").replaceAll("\\", "/");
    logger.debug(tag, "LuaLibPath: $luaLibPath");
    var result = _lua.run('''
      package.path = package.path..';'..'$luaLibPath'
      json = require('dkjson')
      task = require('task')
      async = task.async
      await = task.await
      print('success')
      ''');
    if (result.containsIgnoreCase("error")) {
      logger.error(tag, "init global lib: $result");
    } else {
      logger.debug(tag, "init global lib: $result");
    }
    final global = Constants.luaGlobalFun
        .replaceAll("{{devId}}", appConfig.devInfo.guid)
        .replaceAll("{{devName}}", appConfig.devInfo.name)
        .replaceAll("{{versionNumber}}", appConfig.version.code)
        .replaceAll("{{versionName}}", appConfig.version.name)
        .replaceAll("{{platformIsAndroid}}", "${Platform.isAndroid}")
        .replaceAll("{{platformIsLinux}}", "${Platform.isLinux}")
        .replaceAll("{{platformIsWindows}}", "${Platform.isWindows}")
        .replaceAll("{{platformIsMacOS}}", "${Platform.isMacOS}")
        .replaceAll("{{platformIsIOS}}", "${Platform.isIOS}");

    final onLuaAsyncResult =
        Pointer.fromFunction<LuaFunction>(_onLuaAsyncResult, 0);
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
    final androidSendHistoryChangedBroadcast =
        Pointer.fromFunction<LuaFunction>(
      _androidSendHistoryChangedBroadcast,
      0,
    );
    final regexMatchPtr = Pointer.fromFunction<LuaFunction>(_regexMatch, 0);
    final regexMatchGroupsPtr =
        Pointer.fromFunction<LuaFunction>(_regexMatchGroups, 0);
    final httpRequestPtr =
        Pointer.fromFunction<LuaFunction>(_luaHttpRequest, 0);
    _lua.registerFunction("__onLuaAsyncResult", onLuaAsyncResult);
    _lua.registerFunction("__delay", delayPtr);
    _lua.registerFunction("__log", logFunPtr);
    _lua.registerFunction("__notify", notifyFunPtr);
    _lua.registerFunction("__calcMD5", md5FunPtr);
    _lua.registerFunction("__calcSHA1", sha1FunPtr);
    _lua.registerFunction("__calcSHA256", sha256FunPtr);
    _lua.registerFunction("__base64Encode", base64EncodePtr);
    _lua.registerFunction("__base64Decode", base64DecodePtr);
    _lua.registerFunction("__androidToast", androidToastPtr);
    _lua.registerFunction(
      "__androidSendHistoryChangedBroadcast",
      androidSendHistoryChangedBroadcast,
    );
    _lua.registerFunction("__regexMatch", regexMatchPtr);
    _lua.registerFunction("__regexMatchGroups", regexMatchGroupsPtr);
    _lua.registerFunction("__httpRequest", httpRequestPtr);

    result = _lua.run(global);
    logger.debug(tag, "init global lua fun: $result");
  }

  (bool success, String hash, String? error) loadLuaUserFunc(
    String funcName,
    String code, {
    String? hash,
    bool isTest = false,
  }) {
    final funcHash = hash ?? code.toMd5();
    final sandboxWrapper = Constants.luaSandboxWrapper
        .replaceAll("{{isTest}}", isTest.toString())
        .replaceAll("{{funcName}}", funcName)
        .replaceAll("{{funcHash}}", funcHash)
        .replaceAll("{{code}}", code);
    final msg = _lua.run(sandboxWrapper);
    final result = msg == 'OK';
    return (result, funcHash, result ? null : msg);
  }

  void _loadAllScriptModules() {
    for (var lib in scriptModules) {
      final msg = loadLuaModules(lib);
      logger.debug(tag, "load lib(${lib.moduleName}): $msg");
    }
  }

  void _loadAllLuaUserFn() {
    for (var rule in rules) {
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

  @override
  Future<void> onInit() async {
    WidgetsBinding.instance.addObserver(this);
    _initLuaFunc();
    final list = await ruleDao.getAllRules();
    rules.value = list.map((e) => RuleItem.fromRule(e)).toList();
    scriptModules.value = await scriptModuleDao.getAllModules();
    _selectDefaultDesktopItem();
    _loadAllScriptModules();
    _loadAllLuaUserFn();
    ensureSmsSyncReady(showDialog: true);
    super.onInit();
  }

  void _selectDefaultDesktopItem() {
    if (appConfig.isSmallScreen || selectedRuleItem.value != null || selectedLuaModuleItem.value != null) {
      return;
    }
    // Desktop uses a split view; selecting the first item keeps the detail pane useful on entry.
    if (rules.isNotEmpty) {
      selectedRuleItem.value = rules.first.copy();
      selectedLuaModuleItem.value = null;
      return;
    }
    if (scriptModules.isNotEmpty) {
      selectedLuaModuleItem.value = scriptModules.first.copy();
      selectedRuleItem.value = null;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ensureSmsSyncReady(showDialog: true);
    }
  }

  Future<bool> ensureSmsSyncReady({
    bool requestPermission = false,
    bool showDialog = false,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }
    if (!enableSmsSync) {
      await androidChannelService.stopSmsListen();
      return false;
    }
    if (await PermissionHelper.testAndroidReadSms()) {
      await androidChannelService.startSmsListen();
      return true;
    }
    if (requestPermission || showDialog) {
      return requestAndroidSmsPermission(showDialog: showDialog);
    }
    return false;
  }

  Future<bool> requestAndroidSmsPermission({
    bool showDialog = true,
    String? promptText,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }
    if (await PermissionHelper.testAndroidReadSms()) {
      await ensureSmsSyncReady();
      return true;
    }
    if (_requestingSmsPermission) {
      return false;
    }
    _requestingSmsPermission = true;
    try {
      if (showDialog && Get.context == null) {
        return false;
      }
      if (showDialog) {
        final completer = Completer<bool>();
        void completeRequest(bool value) {
          if (!completer.isCompleted) {
            completer.complete(value);
          }
        }
        final dialog = await Global.showTipsDialog(
          context: Get.context!,
          text: promptText ?? TranslationKey.permissionSettingsSmsDesc.tr,
          showCancel: true,
          okText: TranslationKey.goAuthorize.tr,
          cancelText: TranslationKey.notNow.tr,
          onOk: () => completeRequest(true),
          onCancel: () => completeRequest(false),
        );
        if (dialog == null) {
          return false;
        }
        await dialog.future;
        if (!completer.isCompleted) {
          completeRequest(false);
        }
        if (!await completer.future) {
          return false;
        }
      }
      await PermissionHelper.reqAndroidReadSms();
      final granted = await PermissionHelper.testAndroidReadSms();
      if (granted) {
        await ensureSmsSyncReady();
      }
      return granted;
    } finally {
      _requestingSmsPermission = false;
    }
  }

  Future<bool> requestSmsPermissionIfNeeded({String? promptText}) async {
    if (!Platform.isAndroid) {
      return false;
    }
    if (await PermissionHelper.testAndroidReadSms()) {
      return true;
    }
    return requestAndroidSmsPermission(
      showDialog: true,
      promptText: promptText,
    );
  }

  Future<void> requestAppInfo(String devId) async {
    logger.debug(tag, "requestAppInfo $devId");
    for (var rule in rules) {
      final sources = rule.sources;
      for (var source in sources) {
        final appInfo = sourceService.getAppInfoByAppId(source);
        if (appInfo != null) {
          continue;
        }

        logger.debug(tag, "requestAppInfo: $source");
        await DataSender.sendDataByDevId(
          devId,
          MsgType.reqAppInfo,
          {"appId": source},
        );
      }
    }
  }

  bool isNotExistAppInfo(String appId) {
    for (var rule in rules) {
      final sources = rule.sources;
      for (var source in sources) {
        if (source != appId) {
          continue;
        }
        final appInfo = sourceService.getAppInfoByAppId(source);
        if (appInfo != null) {
          continue;
        }
        return true;
      }
    }
    return false;
  }

  Future<void> saveRules() async {
    final List<RuleItem> updateList = [];
    final List<RuleItem> saveList = [];
    var order = 1;
    final newVersion = DateTime.now().yyyyMMddHHmmss;
    for (var rule in rules) {
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
    await ruleDao.updateRules(updateList.map((e) => e.toRule()).toList());
    await ruleDao.addRules(saveList.map((e) => e.toRule()).toList());
    //同步数据
    for (var updateData in updateList) {
      await opRecordDao.deleteByDataWithCascade(updateData.id.toString());
    }
    for (var saveData in [...saveList, ...updateList]) {
      await opRecordDao.addAndNotify(
        OperationRecord.fromSimple(Module.rule, OpMethod.add, saveData.id),
      );
    }
    //保存成功
    update();
    ensureSmsSyncReady(showDialog: true);
  }

  String loadLuaModules(ScriptModule lib, {bool reloadAllUserFn = false}) {
    final sandboxWrapper = Constants.luaModuleSandboxWrapper
        .replaceAll("{{funcName}}", "loaLuaModule")
        .replaceAll("{{moduleName}}", lib.moduleName)
        .replaceAll("{{code}}", lib.source);
    final msg = _lua.run(sandboxWrapper);
    if (msg == 'OK' && reloadAllUserFn) {
      _loadAllLuaUserFn();
    }
    return msg;
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
      var nContent = map['content']?.toString() ?? "";
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
    final snapshots = rules
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
      //来源配置为空或不再设定的来源内
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
          "apply rule failed! content = $content, rule = ${rule.name}",
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

  Future<RuleExecResult> _apply(
    RuleItem rule,
    RuleExecParams params, {
    String? scriptHash,
  }) async {
    if (rule.isUseScript) {
      final language = rule.script.language;
      if (language != RuleScriptLanguage.lua) {
        return RuleExecResult.error('not support language: $language');
      }
      final paramsJson = jsonEncode(params);
      var hash = scriptHash ?? rule.id.toString();
      var taskId = appConfig.snowflake.nextIdStr();
      final completer = Completer<String>();
      _luaCallbacks[taskId] = completer;
      final result = _lua.run(
        "return run_user_sandbox_method('$taskId', '$hash','$paramsJson')",
      );
      logger.debug(tag, 'run log result: $result');
      if (result.containsIgnoreCase("error") && !completer.isCompleted) {
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
      try {
        final result = jsonDecode(scriptResult);
        return RuleExecResult.success(RuleApplyResult.fromJson(result));
      } catch (err, stack) {
        final msg = "$err\n$stack";
        logger.error(tag, err, stack);
        return RuleExecResult.error(msg);
      }
    } else {
      final regexRule = rule.regex;
      final result = regexRule.apply(params);
      return RuleExecResult.success(result);
    }
  }

  Future<RuleExecResult> test(RuleItem rule, RuleExecParams params) async {
    if (rule.isUseScript) {
      var content = "-- test\n${rule.script.content}";
      final (compileSuccess, hash, errorMsg) = loadLuaUserFunc(
        "${rule.name}-test",
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
        final msg = "$err\n$stack";
        return RuleExecResult.error(msg);
      }
    }
  }

  void addOrUpdateRule(Rule rule) {
    var exists = false;
    final ruleItem = RuleItem.fromRule(rule);
    for (var i = 0; i < rules.length; i++) {
      if (rules[i].id == rule.id) {
        rules[i] = ruleItem;
        exists = true;
        break;
      }
    }
    if (!exists) {
      rules.add(ruleItem);
    }
    rules.sort();
    update();
    loadLuaUserFunc(
      ruleItem.name,
      ruleItem.script.content,
      hash: ruleItem.id.toString(),
    );
    ensureSmsSyncReady(showDialog: true);
  }

  void addOrUpdateRuleLib(ScriptModule lib) {
    var exists = false;
    for (var i = 0; i < scriptModules.length; i++) {
      if (scriptModules[i].moduleName == lib.moduleName) {
        scriptModules[i] = lib;
        exists = true;
        update();
        break;
      }
    }
    if (!exists) {
      scriptModules.add(lib);
    }
    final result = loadLuaModules(lib);
    logger.debug(tag, "load lib(${lib.moduleName}): $result");
  }

  String compileModule(String code) {
    final moduleCompileScript = Constants.luaModuleCompileWrapper.replaceAll(
      r"{{code}}",
      code,
    ).replaceAll(
      r"{{ReturnValueTypeErrorMsg}}",
      TranslationKey.scriptModuleCompileReturnTableRequired.tr,
    );
    return _lua.run(moduleCompileScript);
  }
}
