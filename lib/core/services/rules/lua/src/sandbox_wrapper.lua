local wrapper = function()
  -- @include luaSandboxEnv
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
