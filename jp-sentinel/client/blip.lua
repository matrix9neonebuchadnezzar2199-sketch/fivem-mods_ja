local JB = Config._JpSentinel.JobBridge

local Blips = {}

---@param data table
local function applyUpdateBlip(data)
    if not JB.IsLocalPolice() then
        return
    end
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then
        return
    end

    local c = data.coords
    local x, y, z = tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0

    local b = Blips[data.sentinelId]
    if not b then
        b = AddBlipForCoord(x, y, z)
        SetBlipSprite(b, Config.Blip.Sprite)
        SetBlipColour(b, Config.Blip.Color)
        SetBlipScale(b, Config.Blip.Scale)
        SetBlipAlpha(b, Config.Blip.Alpha)
        SetBlipAsShortRange(b, Config.Blip.ShortRange)
        Blips[data.sentinelId] = b
    else
        SetBlipCoords(b, x, y, z)
    end

    local mm = math.floor((data.remainSec or 0) / 60)
    local ss = math.floor((data.remainSec or 0) % 60)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(string.format('%s %02d:%02d', Config.Blip.NamePrefix, mm, ss))
    EndTextCommandSetBlipName(b)

    if data.indoor then
        SetBlipFlashes(b, true)
    else
        SetBlipFlashes(b, false)
    end
end

RegisterNetEvent('jp-sentinel:client:updateBlip', function(data)
    applyUpdateBlip(data)
end)

RegisterNetEvent('jp-sentinel:client:trackingEnded', function(data)
    local b = Blips[data.sentinelId]
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
    Blips[data.sentinelId] = nil
end)

RegisterNetEvent('jp-sentinel:client:showLostBlip', function(data)
    if not JB.IsLocalPolice() then
        return
    end
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then
        return
    end
    local c = data.coords
    local x, y, z = tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0
    local b = AddBlipForCoord(x, y, z)
    SetBlipSprite(b, Config.ShotDown.LostBlipSprite)
    SetBlipColour(b, Config.ShotDown.LostBlipColor)
    SetBlipAlpha(b, Config.ShotDown.LostBlipAlpha)
    SetBlipScale(b, 1.2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Lang('lost_blip_name'))
    EndTextCommandSetBlipName(b)

    SetTimeout(Config.ShotDown.LostBlipTime, function()
        if DoesBlipExist(b) then
            RemoveBlip(b)
        end
    end)
end)

RegisterNetEvent('jp-sentinel:client:syncActive', function(list)
    if not JB.IsLocalPolice() then
        return
    end
    if type(list) ~= 'table' then
        return
    end
    for _, row in ipairs(list) do
        local remain = tonumber(row.remainSec) or 0
        if remain > 0 and row.coords then
            applyUpdateBlip({
                sentinelId = row.sentinelId,
                coords = row.coords,
                remainSec = remain,
                indoor = row.indoor or false,
            })
        end
    end
end)
