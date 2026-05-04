local config = require 'config.shared'
if config.framework:lower() ~= 'esx' then return false end
local ESX = exports.es_extended:getSharedObject()

function getCharacterIdentifier(src)
    local p = ESX.GetPlayerFromId(src)
    return p.identifier
end