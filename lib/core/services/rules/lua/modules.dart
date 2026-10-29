
import 'sandbox.dart';

const String luaCustomModules = """
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
""";

const String luaModuleSandboxWrapper = """
local wrapper = function() 
  $luaSandboxEnv
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
""";

const String luaModuleCompileWrapper = """
$luaSandboxEnv
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
""";
