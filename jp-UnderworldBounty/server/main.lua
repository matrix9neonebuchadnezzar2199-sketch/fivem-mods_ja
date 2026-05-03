math.randomseed(os.time())

AddEventHandler('onResourceStart', function(resName)
  if resName ~= RESOURCE then
    return
  end
  print(('^2%s^0'):format(_L('loaded_console', VERSION, Framework)))
end)

AddEventHandler('onResourceStop', function(resName)
  if resName ~= RESOURCE then
    return
  end
  for _, sid in ipairs(GetPlayers()) do
    local src = tonumber(sid)
    TriggerClientEvent(UbEvent('client:forceCleanup'), src)
  end
end)

RegisterCommand('ub_test', function(src)
  if src == 0 then
    print(('Framework=%s VERSION=%s'):format(Framework, VERSION))
    return
  end
  local d = Bridge.GetPlayerData(src)
  if not d then
    Bridge.Notify(src, 'UB: no player data', 'error')
    return
  end
  Bridge.Notify(src, _L('ub_test_header'), 'info')
  Bridge.Notify(src, _L('ub_test_name', d.name), 'info')
  Bridge.Notify(src, _L('ub_test_money', tostring(d.money)), 'info')
  Bridge.Notify(src, _L('ub_test_job', d.job), 'info')
  Bridge.Notify(src, _L('ub_test_cops', tostring(Bridge.GetCopCount())), 'info')
end, false)

RegisterCommand('ub_cancel', function(src)
  if src == 0 then
    return
  end
  UbCancelHeist(src)
end, false)
