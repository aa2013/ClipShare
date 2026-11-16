-- @include luaSandboxEnv
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
