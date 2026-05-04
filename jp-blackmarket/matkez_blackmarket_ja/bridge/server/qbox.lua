local config = require 'config.shared'
if config.framework:lower() ~= 'qbox' then return false end

function getCharacterIdentifier(src)
    local p = exports.qbx_core:GetPlayer(src)
    return p.PlayerData.citizenid
end