local MyDrone = nil

---@param v any
---@return vector3|nil
local function asVec3(v)
    if not v then
        return nil
    end
    local x, y, z = v.x, v.y, v.z
    if x and y and z then
        return vector3(tonumber(x) or 0.0, tonumber(y) or 0.0, tonumber(z) or 0.0)
    end
    return nil
end

---@param targetPed integer
---@return vector3
local function getTargetAnchor(targetPed)
    local veh = GetVehiclePedIsIn(targetPed, false)
    if veh ~= 0 then
        return GetEntityCoords(veh)
    end
    return GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
end

---@param drone integer
---@param targetPed integer
local function updateDronePosition(drone, targetPed)
    local interior = GetInteriorFromEntity(targetPed)
    local offsetZ = (interior ~= 0) and Config.DroneIndoorZ or Config.DroneOffsetZ

    local targetPos = getTargetAnchor(targetPed)
    local desired = vector3(targetPos.x, targetPos.y, targetPos.z + offsetZ)
    local current = GetEntityCoords(drone)
    local newPos = current + (desired - current) * Config.LerpFactor

    SetEntityCoordsNoOffset(drone, newPos.x, newPos.y, newPos.z, false, false, false)

    local dx = targetPos.x - newPos.x
    local dy = targetPos.y - newPos.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(drone, heading)
end

---@param drone integer
---@param opts { skipExpireReport: boolean|nil }
local function normalSelfDestruct(drone, opts)
    opts = opts or {}
    if not DoesEntityExist(drone) then
        if MyDrone and MyDrone.sentinelId and not opts.skipExpireReport then
            TriggerServerEvent('jp-sentinel:server:reportExpired', { sentinelId = MyDrone.sentinelId })
        end
        MyDrone = nil
        return
    end

    local cfg = Config.SelfDestruct
    local startPos = GetEntityCoords(drone)
    local t0 = GetGameTimer()
    while GetGameTimer() - t0 < cfg.RiseDuration do
        if not DoesEntityExist(drone) then
            MyDrone = nil
            return
        end
        local t = (GetGameTimer() - t0) / cfg.RiseDuration
        local z = startPos.z + (cfg.RiseHeight * t)
        SetEntityCoordsNoOffset(drone, startPos.x, startPos.y, z, false, false, false)
        Wait(0)
    end

    Wait(cfg.HoverTime)

    local final = GetEntityCoords(drone)
    if opts.skipExpireReport then
        TriggerServerEvent('jp-sentinel:server:relayFxFromPolice', {
            fxType = 'destruct',
            coords = { x = final.x, y = final.y, z = final.z },
        })
    elseif MyDrone and MyDrone.sentinelId then
        TriggerServerEvent('jp-sentinel:server:broadcastFx', {
            sentinelId = MyDrone.sentinelId,
            fxType = 'destruct',
            coords = { x = final.x, y = final.y, z = final.z },
        })
    end

    Wait(300)
    if DoesEntityExist(drone) then
        DeleteEntity(drone)
    end

    if MyDrone and MyDrone.sentinelId and not opts.skipExpireReport then
        TriggerServerEvent('jp-sentinel:server:reportExpired', { sentinelId = MyDrone.sentinelId })
    end
    MyDrone = nil
end

---@param drone integer
local function shotDownDestruct(drone)
    local pos
    if DoesEntityExist(drone) then
        pos = GetEntityCoords(drone)
    elseif MyDrone then
        pos = MyDrone.lastCoords or GetEntityCoords(PlayerPedId())
    else
        pos = GetEntityCoords(PlayerPedId())
    end

    if MyDrone and MyDrone.sentinelId then
        TriggerServerEvent('jp-sentinel:server:broadcastFx', {
            sentinelId = MyDrone.sentinelId,
            fxType = 'shotdown',
            coords = { x = pos.x, y = pos.y, z = pos.z },
        })
    end

    Wait(200)
    if DoesEntityExist(drone) then
        DeleteEntity(drone)
    end

    if MyDrone and MyDrone.sentinelId then
        TriggerServerEvent('jp-sentinel:server:reportShotDown', {
            sentinelId = MyDrone.sentinelId,
            lostCoords = { x = pos.x, y = pos.y, z = pos.z },
        })
    end
    MyDrone = nil
end

---@param drone integer
---@param reason string
local function lostAndDestruct(drone, reason)
    local msg
    if reason == 'speed' then
        msg = Config.Lang('target_lost_speed')
    elseif reason == 'entity' then
        msg = Config.Lang('target_lost_entity')
    else
        msg = Config.Lang('target_lost_indoor')
    end
    TriggerEvent('jp-sentinel:client:notifyLocal', msg, 'info')

    local pos = DoesEntityExist(drone) and GetEntityCoords(drone) or GetEntityCoords(PlayerPedId())
    if MyDrone and MyDrone.sentinelId then
        TriggerServerEvent('jp-sentinel:server:reportLost', {
            sentinelId = MyDrone.sentinelId,
            reason = reason,
            lastCoords = { x = pos.x, y = pos.y, z = pos.z },
        })
    end

    normalSelfDestruct(drone, { skipExpireReport = true })
end

---@param drone integer
---@param targetPed integer
local function startDroneLoop(drone, targetPed)
    MyDrone.entity = drone
    MyDrone.targetPed = targetPed
    MyDrone.startTime = GetGameTimer()
    MyDrone.loopRunning = true
    MyDrone.lastCoords = GetEntityCoords(targetPed)

    CreateThread(function()
        local trackMs = Config.TrackDuration * 1000
        local lastCoordSent = 0

        while MyDrone and MyDrone.loopRunning and DoesEntityExist(drone) do
            if GetGameTimer() - MyDrone.startTime >= trackMs then
                TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('self_destruct'), 'info')
                normalSelfDestruct(drone, {})
                return
            end

            if Config.ShotDown.Enabled then
                if IsEntityDead(drone) or GetEntityHealth(drone) <= 0 then
                    TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('shot_down'), 'info')
                    shotDownDestruct(drone)
                    return
                end
            end

            if not DoesEntityExist(targetPed) then
                lostAndDestruct(drone, 'entity')
                return
            end

            local veh = GetVehiclePedIsIn(targetPed, false)
            if veh ~= 0 then
                local kmh = GetEntitySpeed(veh) * 3.6
                if kmh > Config.LostSpeedKmh then
                    lostAndDestruct(drone, 'speed')
                    return
                end
            end

            updateDronePosition(drone, targetPed)
            MyDrone.lastCoords = GetEntityCoords(targetPed)

            if MyDrone.sentinelId and (GetGameTimer() - lastCoordSent) >= 200 then
                lastCoordSent = GetGameTimer()
                local c = MyDrone.lastCoords
                TriggerServerEvent('jp-sentinel:server:updateCoords', {
                    sentinelId = MyDrone.sentinelId,
                    coords = { x = c.x, y = c.y, z = c.z },
                    indoor = GetInteriorFromEntity(targetPed) ~= 0,
                })
            end

            Wait(0)
        end

        if MyDrone and MyDrone.sentinelId and DoesEntityExist(drone) == false then
            TriggerServerEvent('jp-sentinel:server:reportExpired', { sentinelId = MyDrone.sentinelId })
            MyDrone = nil
        end
    end)
end

---@param targetPed integer
---@param hitCoords vector3
local function spawnDrone(targetPed, hitCoords)
    if MyDrone and MyDrone.loopRunning then
        return
    end

    local model = Config.DronePropHash
    RequestModel(model)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do
        Wait(10)
    end
    if not HasModelLoaded(model) then
        TriggerServerEvent('jp-sentinel:server:reportMiss')
        return
    end

    local pos = GetEntityCoords(targetPed)
    local drone = CreateObject(model, pos.x, pos.y, pos.z + Config.DroneOffsetZ, true, true, false)
    if not DoesEntityExist(drone) then
        SetModelAsNoLongerNeeded(model)
        TriggerServerEvent('jp-sentinel:server:reportMiss')
        return
    end

    SetEntityAsMissionEntity(drone, true, true)
    NetworkRegisterEntityAsNetworked(drone)
    local netId = NetworkGetNetworkIdFromEntity(drone)
    SetNetworkIdExistsOnAllMachines(netId, true)

    if Config.ShotDown.Enabled then
        SetEntityInvincible(drone, false)
        SetEntityCanBeDamaged(drone, true)
        SetEntityMaxHealth(drone, Config.ShotDown.DroneHealth)
        SetEntityHealth(drone, Config.ShotDown.DroneHealth)
    else
        SetEntityInvincible(drone, true)
    end

    SetEntityDynamic(drone, true)

    local dcoords = GetEntityCoords(drone)
    PlayFx('spawn', dcoords)

    MyDrone = {
        sentinelId = nil,
        entity = drone,
        targetPed = targetPed,
        startTime = GetGameTimer(),
        loopRunning = false,
        lastCoords = GetEntityCoords(targetPed),
    }

    local targetNetId = PedToNet(targetPed)
    local targetServerId = nil
    local playerIdx = NetworkGetPlayerIndexFromPed(targetPed)
    if playerIdx ~= -1 and NetworkIsPlayerActive(playerIdx) then
        targetServerId = GetPlayerServerId(playerIdx)
    end

    TriggerServerEvent('jp-sentinel:server:reportHit', {
        targetNetId = targetNetId,
        droneNetId = netId,
        hitCoords = { x = hitCoords.x, y = hitCoords.y, z = hitCoords.z },
        targetServerId = targetServerId,
    })

    startDroneLoop(drone, targetPed)
    SetModelAsNoLongerNeeded(model)
end

AddEventHandler('jp-sentinel:client:spawnDroneLocal', function(targetPed, hitCoords)
    if type(targetPed) ~= 'number' then
        return
    end
    local hc = asVec3(hitCoords)
    if not hc then
        return
    end
    spawnDrone(targetPed, hc)
end)

RegisterNetEvent('jp-sentinel:client:abortDrone', function()
    if MyDrone then
        MyDrone.loopRunning = false
        local ent = MyDrone.entity
        MyDrone = nil
        if ent and DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
    end
end)

RegisterNetEvent('jp-sentinel:client:trackingStarted', function(data)
    if MyDrone then
        MyDrone.sentinelId = data.sentinelId
    end
end)

RegisterNetEvent('jp-sentinel:client:trackingEnded', function(data)
    if MyDrone and MyDrone.sentinelId == data.sentinelId then
        local ent = MyDrone.entity
        MyDrone.loopRunning = false
        MyDrone = nil
        if ent and DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
    end
end)
