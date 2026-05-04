ClientBridge = ClientBridge or {}

local function ub_notify_use_nui()
  local v = Config and Config.NotifyUseNui
  if v == nil then
    return Framework == 'standalone'
  end
  return v == true
end

--- @param message string
--- @param typ string|nil
function ClientBridge.Notify(message, typ)
  typ = typ or 'info'
  if ub_notify_use_nui() then
    SendNUIMessage({
      action = 'notify',
      message = message,
      typ = typ,
    })
    return
  end
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
