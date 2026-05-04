local config = require 'config.shared'
if config.framework:lower() ~= 'qbcore' then return false end

local QBCore = exports['qb-core']:GetCoreObject()

function getCharacterIdentifier(src)
    local p = QBCore.Functions.GetPlayer(src)
    if not p then return nil end
    return p.PlayerData.citizenid
end
