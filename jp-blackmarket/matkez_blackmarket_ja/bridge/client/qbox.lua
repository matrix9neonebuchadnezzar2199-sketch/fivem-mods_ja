local config = require 'config.shared'
if config.framework:lower() ~= 'qbox' then return false end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    setupBlackmarkets()
    lib.callback.await('matkez_blackmarket:server:checkForOrders', false)
end)