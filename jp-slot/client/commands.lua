-- 動的設置用クライアント処理・補助コマンド

local function forwardPlaceCoords()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local fwd = GetEntityForwardVector(ped)
    local dp = Config.DynamicPlacement or {}
    local dist = dp.PlaceDistance or 1.5
    local px = c.x + fwd.x * dist
    local py = c.y + fwd.y * dist
    local pz = c.z
    local ok, gz = GetGroundZFor_3dCoord(px + 0.0, py + 0.0, c.z + 50.0)
    if ok then
        pz = gz + (dp.GroundOffset or 0.0)
    else
        pz = c.z + (dp.GroundOffset or 0.0)
    end
    local placeHeading = (h + 180.0) % 360.0
    return {
        coords = { x = px + 0.0, y = py + 0.0, z = pz + 0.0 },
        heading = placeHeading,
        playerCoords = { x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0 },
    }
end

RegisterNetEvent('jp-slot:dyn:requestPlacePos', function(data)
    data = type(data) == 'table' and data or {}
    local pos = forwardPlaceCoords()
    TriggerServerEvent('jp-slot:dyn:placeAt', {
        coords = pos.coords,
        heading = pos.heading,
        propKey = data.propKey,
        charId = data.charId,
        paytableId = data.paytableId,
    })
end)

RegisterNetEvent('jp-slot:dyn:requestRemoveNearest', function()
    local c = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('jp-slot:dyn:removeNearestAt', { x = c.x, y = c.y, z = c.z })
end)

RegisterNetEvent('jp-slot:dyn:requestMove', function()
    local ped = PlayerPedId()
    local pc = GetEntityCoords(ped)
    local pos = forwardPlaceCoords()
    TriggerServerEvent('jp-slot:dyn:applyMove', {
        playerCoords = { x = pc.x, y = pc.y, z = pc.z },
        newCoords = pos.coords,
        newHeading = pos.heading,
    })
end)

RegisterNetEvent('jp-slot:dyn:requestRotate', function(data)
    data = type(data) == 'table' and data or {}
    local c = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('jp-slot:dyn:rotateAt', {
        playerCoords = { x = c.x, y = c.y, z = c.z },
        deg = tonumber(data.deg) or 90.0,
    })
end)

RegisterNetEvent('jp-slot:dyn:requestInfo', function()
    local c = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('jp-slot:dyn:infoAt', { x = c.x, y = c.y, z = c.z })
end)

RegisterCommand('getpos', function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local line = ('coords = vector3(%.2f, %.2f, %.2f), heading = %.2f'):format(c.x, c.y, c.z, h)
    TriggerEvent('chat:addMessage', {
        color = { 255, 210, 74 },
        args = { '[jp-slot]', line },
    })
    SendNUIMessage({
        type = 'clipboard',
        payload = { text = line },
    })
end, false)
