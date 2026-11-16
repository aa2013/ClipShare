local wrapper = function()
  -- @include luaSandboxEnv
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
