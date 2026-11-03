local function expect(condition, message)
  if not condition then error(message, 2) end
end

local registeredEvents = {}
local registeredExports = {}
local clientEvents = {}

function exports(name, callback)
  registeredExports[name] = callback
end

function TriggerClientEvent(name, target, ...)
  clientEvents[#clientEvents + 1] = { name = name, target = target, args = { ... } }
end

function RegisterNetEvent(name, callback)
  registeredEvents[name] = callback
end

dofile('shared/config.lua')
dofile('server/main.lua')

expect(registeredEvents['mz_menu:server:debug'] == nil, 'development debug event remains registered')
expect(MZMenuConfig.Debug == nil, 'obsolete server debug gate remains configured')
expect(MZMenuConfig.ServerDebug == nil, 'obsolete server debug policy remains configured')

expect(type(registeredExports.Notify) == 'function', 'product Notify export was affected')
local notifyOk = registeredExports.Notify(25, 'product behavior')
expect(notifyOk == true, 'product Notify export no longer succeeds')
expect(#clientEvents == 1, 'product Notify export did not emit exactly one event')
expect(clientEvents[1].name == 'mz_menu:client:notify' and clientEvents[1].target == 25,
  'product Notify export behavior changed')

print('mz_menu server debug security harness: PASS event=removed product_exports=preserved')
