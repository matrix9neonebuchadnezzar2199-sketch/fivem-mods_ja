local config = require 'config.shared'
if config.framework:lower() ~= 'qbcore' then return false end

-- QBCore はクライアント側で Core オブジェクトの取得自体は不要（イベントだけ使う）
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    setupBlackmarkets()
    lib.callback.await('matkez_blackmarket:server:checkForOrders', false)
end)
