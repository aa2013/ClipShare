// GENERATED CODE - DO NOT MODIFY BY HAND.
// 修改 src/ 内 Lua 源文件后运行 dart run tools/generate_lua_templates.dart。

/// 内置 Lua 模板，来源：custom_modules.lua。
//language=lua
const String luaCustomModules = r'''
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
''';


/// 内置 Lua 模板，来源：module_sandbox_wrapper.lua。
//language=lua
const String luaModuleSandboxWrapper = r'''
local wrapper = function()
  local function to_string(...)
  local result = {}
  for _, v in ipairs({...}) do
    result[#result + 1] = tostring(v)
  end
  return table.concat(result, ", ")
end
local log = {
  debug = function(...) __log({{isTest}}, 'debug', '{{funcName}}', to_string(...)) end,
  warn = function(...) __log({{isTest}}, 'warn', '{{funcName}}', to_string(...)) end,
  info = function(...) __log({{isTest}}, 'info', '{{funcName}}', to_string(...)) end,
  error = function(...) __log({{isTest}}, 'error', '{{funcName}}', to_string(...)) end,
}
local scope = {
  assert = assert,
  error = error,
  pcall = pcall,
  xpcall = xpcall,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
  ipairs = ipairs,
  pairs = pairs,
  next = next,
  select = select,
  math = math,
  table = table,
  string = string,
  coroutine = coroutine,
  unpack = table.unpack or unpack,
  utf8 = utf8,
  os = {
    clock = os.clock,
    date = os.date,
    time = os.time,
    difftime = os.difftime,
  },
  _VERSION = _VERSION,
  log = log,
  print = log.debug,
  warn = log.warn,
}
for name, module in pairs(__customModules) do
  scope[name] = module
end

  local env = setmetatable({}, {
      __index = scope,
      __newindex = sandboxGlobalAccessError
  })
  local chunk, err = load([[{{code}}]], "sandbox", "t", env)
  if not chunk then
      return err
  end

  __customModules['{{moduleName}}'] = table_readonly(chunk())
  log.debug('loaded module: ' .. '{{moduleName}}')
  return 'OK'
end
print(wrapper())
''';


/// 内置 Lua 模板，来源：module_compile_wrapper.lua。
//language=lua
const String luaModuleCompileWrapper = r'''
local function to_string(...)
  local result = {}
  for _, v in ipairs({...}) do
    result[#result + 1] = tostring(v)
  end
  return table.concat(result, ", ")
end
local log = {
  debug = function(...) __log({{isTest}}, 'debug', '{{funcName}}', to_string(...)) end,
  warn = function(...) __log({{isTest}}, 'warn', '{{funcName}}', to_string(...)) end,
  info = function(...) __log({{isTest}}, 'info', '{{funcName}}', to_string(...)) end,
  error = function(...) __log({{isTest}}, 'error', '{{funcName}}', to_string(...)) end,
}
local scope = {
  assert = assert,
  error = error,
  pcall = pcall,
  xpcall = xpcall,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
  ipairs = ipairs,
  pairs = pairs,
  next = next,
  select = select,
  math = math,
  table = table,
  string = string,
  coroutine = coroutine,
  unpack = table.unpack or unpack,
  utf8 = utf8,
  os = {
    clock = os.clock,
    date = os.date,
    time = os.time,
    difftime = os.difftime,
  },
  _VERSION = _VERSION,
  log = log,
  print = log.debug,
  warn = log.warn,
}
for name, module in pairs(__customModules) do
  scope[name] = module
end

local env = setmetatable({}, {
    __index = scope,
    __newindex = sandboxGlobalAccessError
})
local chunk, err = load([[{{code}}]], "sandbox", "t", env)
if not chunk then
    return err
end
local ok,result = pcall(chunk)
if not ok then
  return result
end
if type(result) ~= "table" then
  return '{{ReturnValueTypeErrorMsg}}'
end
local struct = table_struct_to_string(result)
return 'table:' .. json.encode(struct)
''';

