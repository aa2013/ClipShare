---@meta
-- 仅供 Lua 编辑器解析；宿主函数、模板参数和包含片段变量不在此执行。

---@type boolean
__TPL_isTest__ = false
---@type number
__TPL_versionNumber__ = 0
---@type boolean
__TPL_platformIsAndroid__ = false
---@type boolean
__TPL_platformIsLinux__ = false
---@type boolean
__TPL_platformIsWindows__ = false
---@type boolean
__TPL_platformIsMacOS__ = false
---@type boolean
__TPL_platformIsIOS__ = false

---@type table
scope = {}
---@type table<string, fun(...: any)>
log = {}
---@type table
params = {}
---@type table<string, any>
__customModules = {}

---@param isTest boolean
---@param level string
---@param name string
---@param message string
function __log(isTest, level, name, message) end

---@param url string
---@param options string
---@param body string|nil
---@param callback fun(result: string)
function __httpRequest(url, options, body, callback) end

---@param taskId string
---@param result string
function __onLuaAsyncResult(taskId, result) end

---@type fun(...: any): any
__notify = nil
---@type fun(...: any): any
__androidToast = nil
---@type fun(...: any): any
__androidSendHistoryChangedBroadcast = nil
---@type fun(...: any): any
__calcMD5 = nil
---@type fun(...: any): any
__calcSHA1 = nil
---@type fun(...: any): any
__calcSHA256 = nil
---@type fun(...: any): any
__base64Encode = nil
---@type fun(...: any): any
__base64Decode = nil
---@type fun(...: any): any
__regexMatch = nil
---@type fun(...: any): any
__regexMatchGroups = nil

---@type fun(callback: function): function
async = nil
---@type fun(value: any): any
await = nil
---@type table
json = {}
---@type table
task = {}
