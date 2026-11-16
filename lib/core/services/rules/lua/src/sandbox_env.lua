local function to_string(...)
  local result = {}
  for _, v in ipairs({...}) do
    result[#result + 1] = tostring(v)
  end
  return table.concat(result, ", ")
end
local log = {
  debug = function(...) __log(__TPL_isTest__, 'debug', '{{funcName}}', to_string(...)) end,
  warn = function(...) __log(__TPL_isTest__, 'warn', '{{funcName}}', to_string(...)) end,
  info = function(...) __log(__TPL_isTest__, 'info', '{{funcName}}', to_string(...)) end,
  error = function(...) __log(__TPL_isTest__, 'error', '{{funcName}}', to_string(...)) end,
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
