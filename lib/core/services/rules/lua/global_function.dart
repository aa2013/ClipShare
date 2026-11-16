// GENERATED CODE - DO NOT MODIFY BY HAND.
// 修改 src/ 内 Lua 源文件后运行 dart run tools/generate_lua_templates.dart。

/// 内置 Lua 模板，来源：global_function.lua。
//language=lua
const String luaGlobalFun = r'''
-- 沙箱全局访问异常
function sandboxGlobalAccessError(_, k)
  error("global '" .. k .. "' is readonly, try use 'local " .. k .. "' instead", 2)
end
-- 将 table 转为只读
function table_readonly(t)
  return setmetatable({}, {
          __index = t,
          __newindex = sandboxGlobalAccessError,
          __metatable = false
      })
end

-- 将表结构转为string形式
function table_struct_to_string(tb)
    local result = {}
    for k, v in pairs(tb) do
        local t = type(v)
        if t == "function" then
            result[k] = "[function]"
        elseif t == "table" then
            local innerTable = table_struct_to_string(v)
            result[k] = innerTable
        else
            result[k] = t
        end
    end
    return result
end
-- 用户脚本池
__userscripts_map = {}
-- 自定义模块
__customModules = {
  json = table_readonly({
    encode = function(...)
      return json.encode(...)
    end,
    decode = function(...)
      return json.decode(...)
    end,
  }),
  http = table_readonly({
    getAsync = async(function(url, options)
      local t = task.create()
      options = options or {}
      options.method = 'get'
      __httpRequest(url, json.encode(options), nil, function(result)
        local ok, value = pcall(json.decode, result)
        if ok then
          t.result = value
        else
          t.error = value
        end
        t:done()
      end)
      return await(t)
    end),
    postAsync = async(function(url, options, body)
      local t = task.create()
      options = options or {}
      options.method = 'post'
      local data = nil
      if body then
        -- todo pcall
        data = json.encode(body)
      end
      __httpRequest(url, json.encode(options), data, function(result)
        local ok, value = pcall(json.decode, result)
        if ok then
          t.result = value
        else
          t.error = value
        end
        t:done()
      end)
      return t
    end),
    putAsync = async(function(url, options, body)
      local t = task.create()
      options = options or {}
      options.method = 'put'
      local data = nil
      if body then
        data = json.encode(body)
      end
      __httpRequest(url, json.encode(options), data, function(result)
        local ok, value = pcall(json.decode, result)
        if ok then
          t.result = value
        else
          t.error = value
        end
        t:done()
      end)
      return t
    end),
    deleteAsync = async(function(url, options, body)
      local t = task.create()
      options = options or {}
      options.method = 'delete'
      local data = nil
      if body then
        data = json.encode(body)
      end
      __httpRequest(url, json.encode(options), data, function(result)
        local ok, value = pcall(json.decode, result)
        if ok then
          t.result = value
        else
          t.error = value
        end
        t:done()
      end)
      return t
    end)
  }),
  notify = __notify,
  ContentType = table_readonly({
    sms = 'sms',
    text = 'text',
    image = 'image',
    notification = 'notification',
  }),
  self = table_readonly({
    devId = __devId,
    devName = __devName,
  }),
  app = table_readonly({
    versionName = __versionName,
    versionNumber = __versionNumber,
  }),
  Platform = table_readonly({
    isAndroid = __platformIsAndroid,
    isIOS = __platformIsIOS,
    isWindows = __platformIsWindows,
    isMacOS = __platformIsMacOS,
    isLinux = __platformIsLinux,
  }),
  android = table_readonly({
    toast = __androidToast,
    sendHistoryChangedBroadcast = __androidSendHistoryChangedBroadcast,
  }),
  crypto = table_readonly({
    calcMD5 = __calcMD5,
    calcSHA1 = __calcSHA1,
    calcSHA256 = __calcSHA256,
  }),
  base64 = table_readonly({
    encode = __base64Encode,
    decode = __base64Decode,
  }),
  regex = table_readonly({
     match = __regexMatch,
     matchGroups = __regexMatchGroups,
  }),
  async = async,
  await = await,
  task = table_readonly({
    async = async,
    await = await,
    create = task.create,
  })
}

-- 全局变量
__devId = '{{devId}}'
__devName = '{{devName}}'
__versionNumber = {{versionNumber}}
__versionName = '{{versionName}}'
__platformIsAndroid = {{platformIsAndroid}}
__platformIsLinux = {{platformIsLinux}}
__platformIsWindows = {{platformIsWindows}}
__platformIsMacOS = {{platformIsMacOS}}
__platformIsIOS = {{platformIsIOS}}

function remove_user_sandbox_method(script_hash)
  __userscripts_map[script_hash] = nil
end
function _run_user_sandbox_method(taskId, script_hash, paramsJson)
  if not script_hash then
    script_hash = ''
  end
  local script = __userscripts_map[script_hash]
  if not script then
    error('ERR: not found user script: ' .. script_hash, 0)
  end
  local scriptResult = script(json.decode(paramsJson))
  local returnResult = ''
  if type(scriptResult) == "table" then
    returnResult = json.encode(scriptResult)
  else
    returnResult = tostring(scriptResult)
  end
  __onLuaAsyncResult(taskId, returnResult)
end
function run_user_sandbox_method(taskId, script_hash, paramsJson)
  local awaiter = async(_run_user_sandbox_method)(taskId, script_hash, paramsJson)
  awaiter:onCompleted(function()
    if awaiter.error ~= nil then
      __onLuaAsyncResult(taskId, tostring(awaiter.error))
    end
  end)
  return awaiter
end
print('success')
''';

