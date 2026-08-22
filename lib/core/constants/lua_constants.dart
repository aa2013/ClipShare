

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

const String luaGlobalFun = """
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
    $luaCustomModules
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
  """;

const String luaTemplateRule = '''
  -- 内容
  local content = params.content
  -- 返回结果
  return {
    -- 通知的标题(仅当类型为通知时有效)
    title = params.title,
    -- 内容/通知的内容
    content = content,
    -- 提取出的内容
    extractedContent = params.extractedContent,
    -- 标签
    tags = params.tags or {},
    -- 是否阻止同步
    isSyncDisabled = params.isSyncDisabled or false,
    -- 是否丢弃
    isDropped = false,
    -- 是否最终规则
    isFinalRule = false,
  }
  ''';

const String luaSandboxEnv = """
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
  """;

const String luaSandboxWrapper =
"""
        local wrapper = function() 
          $luaSandboxEnv      
          local env = setmetatable({}, {
              __index = scope,
              __newindex = sandboxGlobalAccessError
          })
          local func, err = load([[return function(params) {{code}} end]], "sandbox", "t", env)
          if not func then
              return err
          end
      
          __userscripts_map['{{funcHash}}'] = func()
          log.debug('loaded fun: ' .. '{{funcName}}: {{funcHash}}')
          return 'OK'
        end
        print(wrapper())
    """;

const String luaModuleSandboxWrapper =
"""
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

const String luaModuleCompileWrapper =
"""
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
