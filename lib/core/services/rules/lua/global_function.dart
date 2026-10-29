
import 'modules.dart';

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
