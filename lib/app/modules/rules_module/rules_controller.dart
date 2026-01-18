import 'dart:ffi';
import 'dart:io';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:ffi/ffi.dart';

import 'package:clipshare/app/data/enums/rule/rule_category.dart';
import 'package:clipshare/app/data/enums/rule/rule_content_type.dart';
import 'package:clipshare/app/data/enums/rule/rule_script_language.dart';
import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/support_platform.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/data/models/rule/rule_regex_content.dart';
import 'package:clipshare/app/data/models/rule/rule_script_content.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter_embed_lua/lua_bindings.dart';
import 'package:flutter_embed_lua/lua_runtime.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class RulesController extends GetxController {
  static const String tag = "RulesController";

  // final MultiSplitViewController splitViewController = MultiSplitViewController();
  final rules = <RuleItem>[].obs;
  final selectedItem = Rx<RuleItem?>(null);
  final LuaRuntime _lua = LuaRuntime();
  final _loadedLuaFun = <String, String>{};

  //region 初始化 lua
  static int _log(Pointer<lua_State> L) {
    final bindings = LuaRuntime.lua;

    final levelPtr = bindings.lua_tolstring(L, 1, nullptr);
    final level = levelPtr.cast<Utf8>().toDartString();
    final tagNamePtr = bindings.lua_tolstring(L, 2, nullptr);
    final tagName = tagNamePtr.cast<Utf8>().toDartString();
    final msgPtr = bindings.lua_tolstring(L, 3, nullptr);
    final msg = msgPtr.cast<Utf8>().toDartString();
    var logFunc = Log.debug;
    if (level == "info") {
      logFunc = Log.info;
    } else if (level == "warn") {
      logFunc = Log.warn;
    } else if (level == "error") {
      logFunc = Log.error;
    }
    logFunc('Lua', '$tagName | $msg');
    return 0;
  }

  void _initLuaFunc() {
    var dkJsonPath = 'assets/lua/dkjson.lua';
    var result = '';
    if (Platform.isAndroid) {
      dkJsonPath = p.join(Constants.androidPrivateDataPath, 'lua', 'dkjson.lua');
    }
    result = _lua.run('''
      json = assert(loadfile("$dkJsonPath"))()
      print(json)
      ''');
    Log.debug(tag, "init dkJson: $result");
    result = _lua.run(Constants.globalLuaFun);
    Log.debug(tag, "init global lua fun: $result");
    final logFunPtr = Pointer.fromFunction<Int32 Function(Pointer<lua_State>)>(
      _log,
      0,
    );
    _lua.registerFunction("__log", logFunPtr);
  }

  (bool success, String hash, String? error) _loadLuaUserFun(String funName, String code) {
    final funHash = code.toMd5();
    final sandboxWrapper =
        """
        local wrapper = function() 
          local not_allow_func = function()
            return error("not allow operation in sandbox", 2)
          end
          local log = {
            debug = function(...) __log('debug','$funName', table.concat({...}, ", ")) end,
            warn = function(...) __log('warn','$funName', table.concat({...}, ", ")) end,
            info = function(...) __log('info','$funName', table.concat({...}, ", ")) end,
            error = function(...) __log('error','$funName', table.concat({...}, ", ")) end,
          }
          local safe_os = {}
          for k, v in pairs(os) do
            safe_os[k] = v
          end
          safe_os.exit = not_allow_func
          safe_os.execute = not_allow_func
          
          local forbidden_keys = {
              "__userscripts_map", "_G", "_ENV",
              "load", "loadstring", "dofile", "package",
              "debug", "getmetatable", "setmetatable",
              "rawget", "rawset", "rawequal", 
              'run_user_sandbox_method'
          }
          
          local scope = {
            log = log,
            print = log.debug,
            os = safe_os,
            json = json,
          }
          
          for _, k in ipairs(forbidden_keys) do
            scope[k] = not_allow_func
          end
          
          local env = setmetatable(scope, {
              __index = _G,
              __newindex = function(_, k)
                  error("global '" .. k .. "' is readonly", 2)
              end
          })
      
          local chunk, err = load([[$code]], "sandbox", "t", env)
          if not chunk then
              return err
          end
      
          __userscripts_map['$funHash']= function(...)
              return chunk(...)
          end
          log.debug('loaded fun: '..'$funName: $funHash')
          return 'OK'
        end
        print(wrapper())
    """;
    final msg = _lua.run(sandboxWrapper);
    final result = msg == 'OK';
    return (result, funHash, result ? null : msg);
  }

  void _loadAllLuaUserFun() {
    for (var rule in rules) {
      if (!rule.isUseScript) {
        continue;
      }
      final (result, hash, error) = _loadLuaUserFun(rule.name, rule.script.content);
      if (result) {
        _loadedLuaFun[hash] = rule.id;
      } else {
        Log.warn(tag, 'load user lua function failed! name = ${rule.name}, script = ${rule.script.content}');
      }
    }
  }

  void _removeLuaUserFun(String hash) {
    _lua.run("remove_user_sandbox_method('$hash')");
  }

  //endregion

  @override
  void onInit() {
    _initLuaFunc();
    super.onInit();

    rules.add(
      RuleItem(
        id: "666",
        version: 0,
        name: "测试规则${rules.length + 1}",
        category: RuleCategory.tag,
        platforms: {SupportPlatForm.windows, SupportPlatForm.android},
        sources: {},
        trigger: RuleTrigger.onCopy,
        type: RuleContentType.script,
        regex: RuleRegexContent(
          mainRegex: r"\d+",
          allowExtractData: false,
          extractRegex: '',
          allowAddTag: false,
          tags: {},
          preventSync: false,
          isFinal: false,
        ),
        script: RuleScriptContent(
          language: RuleScriptLanguage.lua,
          content: """
          print(json.encode({a=1,b=2}))
          """,
        ),
        allowSync: true,
        enabled: true,
      ),
    );
    _loadAllLuaUserFun();
    // splitViewController.areas = [
    //   Area(size: 250),
    //   Area(flex: 1),
    // ];
  }

  void saveRules() {}

  RuleExecResult run(RuleItem rule) {
    if (rule.isUseScript) {
      var content = "-- temp\n${rule.script.content}";
      final (compileSuccess, hash, errorMsg) = _loadLuaUserFun("${rule.name}-temp", content);
      if (compileSuccess) {
        final result = _lua.run("return run_user_sandbox_method('$hash')");
        _removeLuaUserFun(hash);
        Log.debug(tag, 'run result: $result');
      } else {
        Log.error(tag, 'compile failed: $errorMsg');
      }
    } else {}
    return RuleExecResult.success();
  }
}
