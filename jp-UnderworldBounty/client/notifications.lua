--- @param msg string
--- @param typ string|nil
function UbNotify(msg, typ)
  ClientBridge.Notify(msg, typ)
end

RegisterNetEvent(UbEvent('client:standaloneNotify'), function(message, typ)
  UbNotify(message, typ)
end)
