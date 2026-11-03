local function validTarget(source)
  local src = tonumber(source)
  if not src then
    return nil
  end
  return src
end

local function trigger(target, eventName, ...)
  local src = validTarget(target)
  if not src then
    return false, 'invalid_target'
  end

  TriggerClientEvent(eventName, src, ...)
  return true
end

exports('Notify', function(target, messageOrData, kind, duration, extra)
  return trigger(target, 'mz_menu:client:notify', messageOrData, kind, duration, extra)
end)

exports('OpenContext', function(target, menu)
  return trigger(target, 'mz_menu:client:openContext', menu)
end)

exports('OpenMenu', function(target, menu)
  return trigger(target, 'mz_menu:client:openContext', menu)
end)

exports('AlertDialog', function(target, dataOrTitle, content, options)
  return trigger(target, 'mz_menu:client:alert', dataOrTitle, content, options)
end)

exports('CloseContext', function(target)
  return trigger(target, 'mz_menu:client:close')
end)

exports('CloseMenu', function(target)
  return trigger(target, 'mz_menu:client:close')
end)

exports('HideContext', function(target)
  return trigger(target, 'mz_menu:client:close')
end)
