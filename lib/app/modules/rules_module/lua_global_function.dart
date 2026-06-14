part of 'rules_controller.dart';

typedef LuaFunction = Int32 Function(Pointer<lua_State>);

///只支持基础的类型
typedef LuaValue = Object?;

/// 主 Lua state。Dart C 回调里的 L 可能是 coroutine 的 lua_State，
/// 异步完成后要用主 state 重新进入 Lua，再由 task.lua 恢复等待中的协程。
late final Pointer<lua_State> _mainState;
final _luaCallbacks = <String, Completer<String>>{};
final _baseDioOptions = BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
);
const _luaGlobalTag = "luaGlobalFunction";
Dio _luaHttpDio = Dio(_baseDioOptions);

//region Lua 回调

///校验是否支持转为 lua 类型
void _validateLuaValue(LuaValue value) {
  if (value == null ||
      value is String ||
      value is int ||
      value is double ||
      value is bool) {
    return;
  }
  throw UnsupportedError(
    'Unsupported Lua callback argument: ${value.runtimeType}',
  );
}

///校验是否支持转为 lua 类型
void _validateLuaArgs(List<LuaValue> args) {
  for (final arg in args) {
    _validateLuaValue(arg);
  }
}

///注册 lua 回调方法引用，以供后续调用
int _registerLuaCallbackRef(Pointer<lua_State> L, int index) {
  final lua = LuaRuntime.lua;
  lua.lua_pushvalue(L, index);
  return lua.luaL_ref(L, LUA_REGISTRYINDEX);
}

///调用 lua 回调方法，并传入参数
void _callLuaCallbackRef(int callbackRef, List<LuaValue> args) {
  //校验类型
  _validateLuaArgs(args);
  final lua = LuaRuntime.lua;
  final L = _mainState;

  lua.lua_rawgeti(L, LUA_REGISTRYINDEX, callbackRef);

  for (final arg in args) {
    _pushValue2LuaCallback(L, arg);
  }

  final result = lua.lua_pcallk(L, args.length, 0, 0, 0, nullptr);

  if (result != LUA_OK) {
    final errorPtr = lua.lua_tolstring(L, -1, nullptr);
    final error = errorPtr.address == 0
        ? 'unknown lua error'
        : errorPtr.cast<Utf8>().toDartString();
    logger.error(_luaGlobalTag, 'Lua callback error: $error');
    lua.lua_settop(L, -2);
  }
  // 清理引用
  _cleanupLuaCallback(L, callbackRef);
}

///将参数入栈
int _raiseLuaCallbackError(
  Pointer<lua_State> L,
  Object error, [
  StackTrace? stack,
]) {
  logger.error(_luaGlobalTag, 'Lua native callback error: $error', stack);
  final errorPtr = error.toString().toNativeUtf8();
  LuaRuntime.lua.lua_pushstring(L, errorPtr.cast());
  calloc.free(errorPtr);
  return LuaRuntime.lua.lua_error(L);
}

void _pushValue2LuaCallback(Pointer<lua_State> L, LuaValue value) {
  final lua = LuaRuntime.lua;

  if (value == null) {
    lua.lua_pushnil(L);
  } else if (value is String) {
    final ptr = value.toNativeUtf8();
    lua.lua_pushstring(L, ptr.cast());
    calloc.free(ptr);
  } else if (value is int) {
    lua.lua_pushinteger(L, value);
  } else if (value is double) {
    lua.lua_pushnumber(L, value);
  } else if (value is bool) {
    lua.lua_pushboolean(L, value ? 1 : 0);
  } else {
    final ptr = value.toString().toNativeUtf8();
    lua.lua_pushstring(L, ptr.cast());
    calloc.free(ptr);
  }
}

/// 清理lua回调引用
void _cleanupLuaCallback(Pointer<lua_State> L, int callbackRef) {
  if (callbackRef != LUA_NOREF && callbackRef != LUA_REFNIL) {
    LuaRuntime.lua.luaL_unref(L, LUA_REGISTRYINDEX, callbackRef);
  }
}

//endregion

//region Lua 栈值读取

String _readLuaString(Pointer<lua_State> L, int index) {
  final lua = LuaRuntime.lua;

  if (lua.lua_type(L, index) != LUA_TSTRING) {
    throw ArgumentError('Expected string at argument $index');
  }

  final ptr = lua.lua_tolstring(L, index, nullptr);
  if (ptr.address == 0) {
    throw ArgumentError('Expected string at argument $index');
  }

  return ptr.cast<Utf8>().toDartString();
}

int _readLuaInt(Pointer<lua_State> L, int index) {
  final lua = LuaRuntime.lua;

  if (lua.lua_type(L, index) != LUA_TNUMBER) {
    throw ArgumentError('Expected number at argument $index');
  }

  return lua.lua_tointegerx(L, index, nullptr);
}

double _readLuaDouble(Pointer<lua_State> L, int index) {
  final lua = LuaRuntime.lua;

  if (lua.lua_type(L, index) != LUA_TNUMBER) {
    throw ArgumentError('Expected number at argument $index');
  }

  return lua.lua_tonumberx(L, index, nullptr);
}

bool _readLuaBool(Pointer<lua_State> L, int index) {
  final lua = LuaRuntime.lua;

  if (lua.lua_type(L, index) != LUA_TBOOLEAN) {
    throw ArgumentError('Expected boolean at argument $index');
  }

  return lua.lua_toboolean(L, index) != 0;
}

bool _isLuaNil(Pointer<lua_State> L, int index) {
  final lua = LuaRuntime.lua;
  return lua.lua_type(L, index) == LUA_TNIL;
}

//endregion

///lua 执行完成后回调结果
int _onLuaAsyncResult(Pointer<lua_State> L) {
  try {
    final callbackId = _readLuaString(L, 1);
    final result = _readLuaString(L, 2);
    final completer = _luaCallbacks[callbackId];
    if (completer == null) {
      logger.warn(_luaGlobalTag, "not found Lua callbackId");
    } else {
      completer.complete(result);
      _luaCallbacks.remove(callbackId);
    }
    return 0;
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

///test
int _delay(Pointer<lua_State> L) {
  try {
    final seconds = _readLuaInt(L, 1);
    final callbackRef = _registerLuaCallbackRef(L, 2);
    Future.delayed(Duration(seconds: seconds), () {
      _callLuaCallbackRef(callbackRef, ['666']);
    });
    return 0;
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

int _log(Pointer<lua_State> L) {
  try {
    final bindings = LuaRuntime.lua;

    final isTest = bindings.lua_toboolean(L, 1) == 1;
    final levelPtr = bindings.lua_tolstring(L, 2, nullptr);
    final level = levelPtr.cast<Utf8>().toDartString();
    final tagNamePtr = bindings.lua_tolstring(L, 3, nullptr);
    final tagName = tagNamePtr.cast<Utf8>().toDartString();
    final msgPtr = bindings.lua_tolstring(L, 4, nullptr);
    final msg = msgPtr.cast<Utf8>().toDartString();
    var logFunc = logger.debug;
    if (level == "info") {
      logFunc = logger.info;
    } else if (level == "warn") {
      logFunc = logger.warn;
    } else if (level == "error") {
      logFunc = logger.error;
    }
    if (isTest) {
      RulesController._testOutputs.add(
        '[$level] | ${DateTime.now().format()} | [$tagName] | $msg',
      );
    } else {
      logFunc('Lua', '$tagName | $msg');
    }
    return 0;
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

int _notify(Pointer<lua_State> L) {
  try {
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
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

//region 摘要

int _calcMd5(Pointer<lua_State> L) {
  try {
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
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

int _calcSHA1(Pointer<lua_State> L) {
  try {
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
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

int _calcSHA256(Pointer<lua_State> L) {
  try {
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
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

int _base64Encode(Pointer<lua_State> L) {
  try {
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
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

int _base64Decode(Pointer<lua_State> L) {
  try {
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
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

//endregion

//region Android

int _androidSendHistoryChangedBroadcast(Pointer<lua_State> L) {
  try {
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
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

int _androidToast(Pointer<lua_State> L) {
  try {
    final bindings = LuaRuntime.lua;
    final contentPtr = bindings.lua_tolstring(L, 1, nullptr);
    final content = contentPtr.cast<Utf8>().toDartString();
    final androidChannelService = Get.find<AndroidChannelService>();
    androidChannelService.toast(content);
    return 0;
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

//endregion

//region 正则

// 正则匹配
int _regexMatch(Pointer<lua_State> L) {
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
  for (var match in matches) {
    final groupStr = match.group(0);
    if (groupStr == null) {
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
int _regexMatchGroups(Pointer<lua_State> L) {
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

//region HTTP

int _luaHttpRequest(Pointer<lua_State> L) {
  try {
    final url = _readLuaString(L, 1);
    final optionsMap = Map<String, dynamic>.from(
      jsonDecode(_readLuaString(L, 2)),
    );
    Object? data;
    if (!_isLuaNil(L, 3)) {
      data = _readLuaString(L, 3);
    }
    final callbackRef = _registerLuaCallbackRef(L, 4);
    _luaHttpDio
        .request(
      url,
      data: data,
      options: Options(
        method: optionsMap['method'],
        headers: optionsMap['headers'] as Map<String, dynamic>?,
        contentType: optionsMap['contentType'],
      ).copyWith(
        connectTimeout:
            optionsMap["connectTimeout"] ?? _baseDioOptions.connectTimeout,
        sendTimeout: optionsMap["sendTimeout"] ?? _baseDioOptions.sendTimeout,
        receiveTimeout:
            optionsMap["receiveTimeout"] ?? _baseDioOptions.receiveTimeout,
      ),
    )
        .then((response) {
      _callLuaCallbackRef(callbackRef, [
        jsonEncode(_response2Map(response)),
      ]);
    }).catchError((error) {
      logger.error(_luaGlobalTag, error);
      _callLuaCallbackRef.call(callbackRef, [
        jsonEncode(_error2Map(error)),
      ]);
    });
    return 0;
  } catch (err, stack) {
    return _raiseLuaCallbackError(L, err, stack);
  }
}

Map<String, Object?> _response2Map(Response response) {
  return {
    'ok': true,
    'statusCode': response.statusCode,
    'statusMessage': response.statusMessage,
    'headers': response.headers.map.map(
      (key, value) => MapEntry(key, value.join(',')),
    ),
    'body': response.data,
  };
}

Map<String, Object?> _error2Map(Object error) {
  if (error is DioException) {
    return {
      'ok': false,
      'statusCode': error.response?.statusCode,
      'statusMessage': error.response?.statusMessage,
      'message': error.message,
      'body': error.response?.data,
    };
  }

  return {
    'ok': false,
    'message': error.toString(),
  };
}

//endregion
