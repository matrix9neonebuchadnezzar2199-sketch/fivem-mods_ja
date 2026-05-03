ClientBridge = ClientBridge or {}

--- @param message string
--- @param typ string|nil
function ClientBridge.Notify(message, typ)
  typ = typ or 'info'
  if Framework == 'esx' then
    TriggerEvent('esx:showNotification', message)
    return
  end
  if Framework == 'qbcore' or Framework == 'qbox' then
    local mapped = typ == 'error' and 'error' or 'primary'
    TriggerEvent('QBCore:Notify', message, mapped)
    return
  end
  BeginTextCommandThefeedPost('STRING')
  AddTextComponentSubstringPlayerName(message)
  EndTextCommandThefeedPostTicker(false, false)
end
