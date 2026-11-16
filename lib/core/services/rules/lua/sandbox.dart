// GENERATED CODE - DO NOT MODIFY BY HAND.
// 修改 src/ 内 Lua 源文件后运行 dart run tools/generate_lua_templates.dart。

/// 内置 Lua 模板，来源：sandbox_env.lua。
//language=lua
const String luaSandboxEnv = r'''
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
''';


/// 内置 Lua 模板，来源：sandbox_wrapper.lua。
//language=lua
const String luaSandboxWrapper = r'''
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
  local func, err = load([[return function(params) {{code}} end]], "sandbox", "t", env)
  if not func then
      return err
  end

  __userscripts_map['{{funcHash}}'] = func()
  log.debug('loaded fun: ' .. '{{funcName}}: {{funcHash}}')
  return 'OK'
end
print(wrapper())
''';

