import 'dart:convert';
import 'dart:ffi';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/models/rule/rule_apply_result.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_params.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/rule.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/target_platform_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:ffi/ffi.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_embed_lua/lua_bindings.dart';
import 'package:flutter_embed_lua/lua_runtime.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class RulesController extends GetxController {
  static const String tag = "RulesController";
  final appConfig = Get.find<ConfigService>();
  final ruleDao = Get.find<DbService>().ruleDao;
  final ruleLibDao = Get.find<DbService>().ruleLibDao;
  final opRecordDao = Get.find<DbService>().opRecordDao;

  // final MultiSplitViewController splitViewController = MultiSplitViewController();
  final rules = <RuleItem>[].obs;
  final ruleLibs = <RuleLib>[].obs;
  final selectedRuleItem = Rx<RuleItem?>(null);
  final selectedLuaLibItem = Rx<RuleLib?>(null);
  final LuaRuntime _lua = LuaRuntime();
  final _loadedLuaFun = <String, int>{};
  final activeItemChanged = false.obs;
  static final List<String> _testOutputs = [];

  //region 初始化 lua
  static int _log(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final isTest = bindings.lua_toboolean(L, 1) == 1;
    final levelPtr = bindings.lua_tolstring(L, 2, nullptr);
    final level = levelPtr.cast<Utf8>().toDartString();
    final tagNamePtr = bindings.lua_tolstring(L, 3, nullptr);
    final tagName = tagNamePtr.cast<Utf8>().toDartString();
    final msgPtr = bindings.lua_tolstring(L, 4, nullptr);
    final msg = msgPtr.cast<Utf8>().toDartString();
    var logFunc = Log.debug;
    if (level == "info") {
      logFunc = Log.info;
    } else if (level == "warn") {
      logFunc = Log.warn;
    } else if (level == "error") {
      logFunc = Log.error;
    }
    if (isTest) {
      _testOutputs.add('[$level] | ${DateTime.now().format()} | [$tagName] | $msg');
    } else {
      logFunc('Lua', '$tagName | $msg');
    }
    return 0;
  }

  void _initLuaFunc() {
    final luaLibPath = p.join(appConfig.luaLibDirPath, "?.lua").replaceAll("\\", "/");
    var result = _lua.run('''
      package.path = package.path..';'..'$luaLibPath'
      json = require('dkjson')
      print(json)
      ''');
    Log.debug(tag, "init dkJson: $result");
    result = _lua.run(Constants.luaGlobalFun);
    Log.debug(tag, "init global lua fun: $result");
    final logFunPtr = Pointer.fromFunction<Int32 Function(Pointer<lua_State>)>(
      _log,
      0,
    );
    _lua.registerFunction("__log", logFunPtr);
  }

  (bool success, String hash, String? error) loadLuaUserFunc(
    String funName,
    String code, {
    String? hash,
    bool isTest = false,
  }) {
    final funHash = hash ?? code.toMd5();
    final sandboxWrapper = Constants.luaSandboxWrapper.replaceAll("{{isTest}}", isTest.toString()).replaceAll("{{funName}}", funName).replaceAll("{{funHash}}", funHash).replaceAll("{{code}}", code);
    final msg = _lua.run(sandboxWrapper);
    final result = msg == 'OK';
    return (result, funHash, result ? null : msg);
  }

  void _loadAllLuaLibs() {
    for (var lib in ruleLibs) {
      final msg = loadLuaLib(lib);
      Log.debug(tag, "load lib(${lib.libName}): $msg");
    }
  }

  void _loadAllLuaUserFn() {
    for (var rule in rules) {
      if (!rule.isUseScript) {
        continue;
      }
      final (result, hash, error) = loadLuaUserFunc(
        rule.name,
        rule.script.content,
        hash: rule.id.toString(),
      );
      if (result) {
        _loadedLuaFun[hash] = rule.id;
      } else {
        Log.warn(
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
    _initLuaFunc();
    final list = await ruleDao.getAllRules();
    rules.value = list.map((e) => RuleItem.fromRule(e)).toList();
    ruleLibs.value = await ruleLibDao.getAllLibs();
    _loadAllLuaLibs();
    _loadAllLuaUserFn();
    super.onInit();
  }

  Future<void> saveRules() async {
    final List<RuleItem> updateList = [];
    final List<RuleItem> saveList = [];
    var order = 1;
    for (var rule in rules) {
      if (rule.isNewData) {
        //未达到保存条件的忽略
        continue;
      }
      final oldOrder = rule.order;
      final newOrder = order;
      if (oldOrder == newOrder) {
        //顺序无变化但是需要保存数据
        if (rule.dirty) {
          updateList.add(rule);
          rule.dirty = false;
        }
        continue;
      }
      //顺序变化需要保存
      rule.dirty = false;
      rule.order = newOrder;
      if (rule.version > 0) {
        //新数据，直接插入
        saveList.add(rule);
      } else {
        //老数据，仅更新
        updateList.add(rule);
      }
      order++;
    }
    await ruleDao.updateRules(updateList.map((e) => e.toRule()).toList());
    await ruleDao.addRules(saveList.map((e) => e.toRule()).toList());
    //同步数据
    for (var updateData in updateList) {
      await opRecordDao.deleteByDataWithCascade(updateData.id.toString());
    }
    for (var saveData in [...saveList, ...updateList]) {
      await opRecordDao.addAndNotify(OperationRecord.fromSimple(Module.rule, OpMethod.add, saveData.id));
    }
    //保存成功
    update();
  }

  String loadLuaLib(RuleLib lib, {bool reloadAllUserFn = false}) {
    final sandboxWrapper = Constants.luaLibSandboxWrapper.replaceAll("{{funName}}", "loaLuaLib").replaceAll("{{libName}}", lib.libName).replaceAll("{{code}}", lib.source);
    final msg = _lua.run(sandboxWrapper);
    if (msg == 'OK' && reloadAllUserFn) {
      _loadAllLuaUserFn();
    }
    return msg;
  }

  RuleExecResult apply(HistoryContentType type, String content, ClipboardSource? source) {
    final currentPlatform = defaultTargetPlatform.toSupportPlatform();
    if (currentPlatform == null) {
      return RuleExecResult.ignore();
    }
    RuleExecParams params;
    if (type == HistoryContentType.notification) {
      final map = jsonDecode(content);
      params = RuleExecParams(
        type: type,
        title: map['title'],
        content: map['content'] ?? "",
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
      if (rule.sources.isNotEmpty && !rule.sources.contains(source?.id)) {
        continue;
      }
      final applyResult = _apply(rule, params);
      if (!applyResult.success) {
        Log.warn(tag, "apply rule failed! content = $content, rule = ${rule.name}");
      } else {
        final result = applyResult.result!;
        params.merge(result);
        if (result.isDropped || result.isFinalRule) {
          return RuleExecResult.success(params.toApplyResult());
        }
      }
    }
    return RuleExecResult.success(params.toApplyResult());
  }

  RuleExecResult _apply(RuleItem rule, RuleExecParams params, {String? scriptHash}) {
    if (rule.isUseScript) {
      final language = rule.script.language;
      if (language != RuleScriptLanguage.lua) {
        return RuleExecResult.error('not support language: $language');
      }
      final paramsJson = jsonEncode(params);
      var hash = scriptHash ?? rule.id.toString();
      final scriptResult = _lua.run("return run_user_sandbox_method('$hash','$paramsJson')");
      Log.debug(tag, 'run result: $scriptResult');
      try {
        final result = jsonDecode(scriptResult);
        return RuleExecResult.success(RuleApplyResult.fromJson(result));
      } catch (err, stack) {
        final msg = "$err\n$stack";
        Log.error(tag, err, stack);
        return RuleExecResult.error(msg);
      }
    } else {
      final regexRule = rule.regex;
      final result = regexRule.apply(params);
      return RuleExecResult.success(result);
    }
  }

  RuleExecResult test(RuleItem rule, RuleExecParams params) {
    if (rule.isUseScript) {
      var content = "-- test\n${rule.script.content}";
      final (compileSuccess, hash, errorMsg) = loadLuaUserFunc(
        "${rule.name}-test",
        content,
        isTest: true,
      );
      if (compileSuccess) {
        final result = _apply(rule, params, scriptHash: hash);
        removeLuaUserFun(hash);
        result.outputs = List.from(_testOutputs);
        _testOutputs.clear();
        return result;
      } else {
        final msg = 'compile failed: $errorMsg';
        Log.error(tag, msg);
        return RuleExecResult.error(msg);
      }
    } else {
      try {
        return _apply(rule, params);
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
        update();
        break;
      }
    }
    if (!exists) {
      rules.add(ruleItem);
    }
    loadLuaUserFunc(
      ruleItem.name,
      ruleItem.script.content,
      hash: ruleItem.id.toString(),
    );
  }

  void addOrUpdateRuleLib(RuleLib lib) {
    var exists = false;
    for (var i = 0; i < ruleLibs.length; i++) {
      if (ruleLibs[i].libName == lib.libName) {
        ruleLibs[i] = lib;
        exists = true;
        update();
        break;
      }
    }
    if (!exists) {
      ruleLibs.add(lib);
    }
    final result = loadLuaLib(lib);
    Log.debug(tag, "load lib(${lib.libName}): $result");
  }
}
