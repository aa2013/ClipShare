import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/models/rule/rule_apply_result.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_params.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/data/repository/entity/tables/lua_lib.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/rule.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/target_platform_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/notify_util.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:crypto/crypto.dart';
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
typedef LuaFunction = Int32 Function(Pointer<lua_State>);

class RulesController extends GetxController {
  static const String tag = "RulesController";
  final appConfig = Get.find<ConfigService>();
  final ruleDao = Get.find<DbService>().ruleDao;
  final ruleLibDao = Get.find<DbService>().ruleLibDao;
  final opRecordDao = Get.find<DbService>().opRecordDao;

  final rules = <RuleItem>[].obs;
  final ruleLibs = <RuleLib>[].obs;
  final selectedRuleItem = Rx<RuleItem?>(null);
  final selectedLuaLibItem = Rx<RuleLib?>(null);
  final LuaRuntime _lua = LuaRuntime();
  final _loadedLuaFun = <String, int>{};
  final activeItemChanged = false.obs;
  static final List<String> _testOutputs = [];

  bool get enableSmsSync {
    final smsRules = rules.where((e) => e.trigger == RuleTrigger.onSms && e.enabled);
    return smsRules.isNotEmpty;
  }

  //region 初始化 lua

  //region FFI 注册函数
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
      _testOutputs.add(
        '[$level] | ${DateTime.now().format()} | [$tagName] | $msg',
      );
    } else {
      logFunc('Lua', '$tagName | $msg');
    }
    return 0;
  }

  static int _notify(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final titlePtr = bindings.lua_tolstring(L, 1, nullptr);
    final title = titlePtr.cast<Utf8>().toDartString();
    final contentPtr = bindings.lua_tolstring(L, 2, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    NotifyUtil.notify(
      title: title,
      content: content,
      key: 'lua_content_${content.hashCode}',
    );
    return 0;
  }

  static int _calcMd5(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    final result = CryptoUtil.toMD5(content);
    final resultPtr = result.toNativeUtf8();
    bindings.lua_pushlstring(
      L,
      resultPtr.cast(),
      result.length,
    );
    malloc.free(resultPtr);
    return 1;
  }

  static int _calcSHA1(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    final result = CryptoUtil.toSHA1(content);
    final resultPtr = result.toNativeUtf8();
    bindings.lua_pushlstring(
      L,
      resultPtr.cast(),
      result.length,
    );
    malloc.free(resultPtr);
    return 1;
  }

  static int _calcSHA256(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    final result = CryptoUtil.toSHA256(content);
    final resultPtr = result.toNativeUtf8();
    bindings.lua_pushlstring(
      L,
      resultPtr.cast(),
      result.length,
    );
    malloc.free(resultPtr);
    return 1;
  }

  static int _base64Encode(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    final result = CryptoUtil.base64EncodeStr(content);
    final resultPtr = result.toNativeUtf8();
    bindings.lua_pushlstring(
      L,
      resultPtr.cast(),
      result.length,
    );
    malloc.free(resultPtr);
    return 1;
  }

  static int _base64Decode(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    final result = CryptoUtil.base64DecodeStr(content);
    final resultPtr = result.toNativeUtf8();
    bindings.lua_pushlstring(
      L,
      resultPtr.cast(),
      result.length,
    );
    malloc.free(resultPtr);
    return 1;
  }

  static int _androidNotifyMediaScan(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;
    final pathPtr = bindings.lua_tolstring(L, 1, nullptr);
    final path = pathPtr.cast<Utf8>().toDartString();
    final androidChannelService = Get.find<AndroidChannelService>();
    androidChannelService.notifyMediaScan(path);
    return 0;
  }

  static int _androidSendHistoryChangedBroadcast(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;
    final typePtr = bindings.lua_tolstring(L, 1, nullptr);
    final type = typePtr.cast<Utf8>().toDartString();

    final contentPtr = bindings.lua_tolstring(L, 2, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();

    final fromDevIdPtr = bindings.lua_tolstring(L, 3, nullptr);
    final fromDevId = fromDevIdPtr.cast<Utf8>().toDartString();

    final fromDevNamePtr = bindings.lua_tolstring(L, 4, nullptr);
    final fromDevName = fromDevNamePtr.cast<Utf8>().toDartString();

    final androidChannelService = Get.find<AndroidChannelService>();
    final contentType = HistoryContentType.parse(type);
    if (contentType == HistoryContentType.unknown) {
      return 0;
    }
    androidChannelService.sendHistoryChangedBroadcast(
      contentType,
      content,
      fromDevId,
      fromDevName,
    );
    return 0;
  }

  static int _androidToast(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;
    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    final androidChannelService = Get.find<AndroidChannelService>();
    androidChannelService.toast(content);
    return 0;
  }

  // 正则匹配
  static int _regexMatch(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    final regExpContentPtr = bindings.lua_tolstring(L, 2, nullptr);
    final regExpContent = regExpContentPtr.cast<Utf8>().toDartString();
    final caseSensitive = bindings.lua_toboolean(L, 3) == 1;
    final multiLines = bindings.lua_toboolean(L, 4) == 1;
    final dotAll = bindings.lua_toboolean(L, 5) == 1;

    // 构建正则
    final regExp = RegExp(
      regExpContent,
      caseSensitive: caseSensitive,
      multiLine: multiLines,
      dotAll: dotAll,
    );
    final matches = regExp.allMatches(content);
    bindings.lua_createtable(L, 0, 0);
    int index = 1;
    for(var match in matches){
      final groupStr = match.group(0);
      if(groupStr == null){
        continue;
      }
      final ptr = groupStr.toNativeUtf8();

      bindings.lua_pushinteger(L, index);
      bindings.lua_pushstring(L, ptr.cast());
      bindings.lua_settable(L, -3);

      malloc.free(ptr);
      index++;
    }
    return 1;
  }

  // 正则匹配获得捕获组
  static int _regexMatchGroups(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final regExpPtr = bindings.lua_tolstring(L, 2, nullptr);

    if (contentPtr == nullptr || regExpPtr == nullptr) {
      bindings.lua_createtable(L, 0, 0);
      return 1;
    }

    final content = contentPtr.cast<Utf8>().toDartString();
    final regExpStr = regExpPtr.cast<Utf8>().toDartString();

    final caseSensitive = bindings.lua_toboolean(L, 3) == 1;
    final multiLines = bindings.lua_toboolean(L, 4) == 1;
    final dotAll = bindings.lua_toboolean(L, 5) == 1;

    final regExp = RegExp(
      regExpStr,
      caseSensitive: caseSensitive,
      multiLine: multiLines,
      dotAll: dotAll,
    );

    final matches = regExp.allMatches(content);

    // 创建 result table
    bindings.lua_createtable(L, 0, 0);
    final resultIndex = bindings.lua_gettop(L);

    int matchIndex = 1;

    for (final match in matches) {
      final groupCount = match.groupCount;
      if (groupCount == 0) {
        continue;
      }
      // 子 table（当前 match）
      bindings.lua_createtable(L, 0, 0);

      for (int i = 1; i <= match.groupCount; i++) {
        final groupStr = match.group(i);
        if (groupStr == null) continue;

        final ptr = groupStr.toNativeUtf8();

        bindings.lua_pushinteger(L, i);
        bindings.lua_pushstring(L, ptr.cast());
        bindings.lua_settable(L, -3);

        malloc.free(ptr);
      }

      // result[matchIndex] = 当前 match table
      bindings.lua_pushinteger(L, matchIndex);
      bindings.lua_pushvalue(L, -2); // 复制子 table
      bindings.lua_settable(L, resultIndex);

      // 等价 lua_pop(L, 1)
      bindings.lua_settop(L, -2);

      matchIndex++;
    }

    return 1;
  }

  //endregion

  void _initLuaFunc() {
    final luaLibPath = p
        .join(appConfig.luaLibDirPath, "?.lua")
        .replaceAll("\\", "/");
    var result = _lua.run('''
      package.path = package.path..';'..'$luaLibPath'
      json = require('dkjson')
      print(json)
      ''');
    Log.debug(tag, "init dkJson: $result");
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

    result = _lua.run(global);
    Log.debug(tag, "init global lua fun: $result");
    final logFunPtr = Pointer.fromFunction<LuaFunction>(_log, 0);
    final notifyFunPtr = Pointer.fromFunction<LuaFunction>(_notify, 0);
    final md5FunPtr = Pointer.fromFunction<LuaFunction>(_calcMd5, 0);
    final sha1FunPtr = Pointer.fromFunction<LuaFunction>(_calcSHA1, 0);
    final sha256FunPtr = Pointer.fromFunction<LuaFunction>(_calcSHA256, 0);
    final base64EncodePtr = Pointer.fromFunction<LuaFunction>(_base64Encode, 0);
    final base64DecodePtr = Pointer.fromFunction<LuaFunction>(_base64Decode, 0);
    final androidNotifyMediaScanPtr = Pointer.fromFunction<LuaFunction>(
      _androidNotifyMediaScan,
      0,
    );
    final androidToastPtr = Pointer.fromFunction<LuaFunction>(_androidToast, 0);
    final androidSendHistoryChangedBroadcast = Pointer.fromFunction<LuaFunction>(
      _androidSendHistoryChangedBroadcast,
      0,
    );
    final regexMatchPtr = Pointer.fromFunction<LuaFunction>(_regexMatch, 0);
    final regexMatchGroupsPtr = Pointer.fromFunction<LuaFunction>(_regexMatchGroups, 0);
    _lua.registerFunction("__log", logFunPtr);
    _lua.registerFunction("__notify", notifyFunPtr);
    _lua.registerFunction("__calcMD5", md5FunPtr);
    _lua.registerFunction("__calcSHA1", sha1FunPtr);
    _lua.registerFunction("__calcSHA256", sha256FunPtr);
    _lua.registerFunction("__base64Encode", base64EncodePtr);
    _lua.registerFunction("__base64Decode", base64DecodePtr);
    _lua.registerFunction(
      "__androidNotifyMediaScan",
      androidNotifyMediaScanPtr,
    );
    _lua.registerFunction("__androidToast", androidToastPtr);
    _lua.registerFunction(
      "__androidSendHistoryChangedBroadcast",
      androidSendHistoryChangedBroadcast,
    );
    _lua.registerFunction("__regexMatch", regexMatchPtr);
    _lua.registerFunction("__regexMatchGroups", regexMatchGroupsPtr);
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
      await opRecordDao.addAndNotify(
        OperationRecord.fromSimple(Module.rule, OpMethod.add, saveData.id),
      );
    }
    //保存成功
    update();
  }

  String loadLuaLib(RuleLib lib, {bool reloadAllUserFn = false}) {
    final sandboxWrapper = Constants.luaLibSandboxWrapper
        .replaceAll("{{funcName}}", "loaLuaLib")
        .replaceAll("{{libName}}", lib.libName)
        .replaceAll("{{code}}", lib.source);
    final msg = _lua.run(sandboxWrapper);
    if (msg == 'OK' && reloadAllUserFn) {
      _loadAllLuaUserFn();
    }
    return msg;
  }

  RuleExecResult apply(
    HistoryContentType type,
    String content,
    ClipboardSource? source,
  ) {
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
        Log.warn(
          tag,
          "apply rule failed! content = $content, rule = ${rule.name}",
        );
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

  RuleExecResult _apply(
    RuleItem rule,
    RuleExecParams params, {
    String? scriptHash,
  }) {
    if (rule.isUseScript) {
      final language = rule.script.language;
      if (language != RuleScriptLanguage.lua) {
        return RuleExecResult.error('not support language: $language');
      }
      final paramsJson = jsonEncode(params);
      var hash = scriptHash ?? rule.id.toString();
      final scriptResult = _lua.run(
        "return run_user_sandbox_method('$hash','$paramsJson')",
      );
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
