local config = require 'config.shared'
if config.framework:lower() ~= 'esx' then return false end
local ESX = exports.es_extended:getSharedObject()

RegisterNetEvent('esx:playerLoaded', function (xPlayer, skin)
    setupBlackmarkets()
    lib.callback.await('matkez_blackmarket:server:checkForOrders', false)
end)