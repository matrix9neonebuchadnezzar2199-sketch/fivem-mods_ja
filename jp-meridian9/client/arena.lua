-- ============================================================
-- jp-meridian9 / client/arena.lua
-- ============================================================
-- ゾンビアリーナ: リーダー側スポーン、撃破報告、送還後ノックダウン連携。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Arena = MRD9.Arena or {}
MRD9.ArenaClient = MRD9.ArenaClient or { zombies = {}, downSent = false, monitor = false }

local State = MRD9.ArenaClient

local function modelFromName(name)
    if type(name) ~= 'string' or name == '' then
        return 0
    end
    return joaat(name)
end

local function deleteZombieEntity(ent)
    if ent and ent ~= 0 and DoesEntityExist(ent) then
        if not NetworkHasControlOfEntity(ent) then
            NetworkRequestControlOfEntity(ent)
            local t = GetGameTimer()
            while not NetworkHasControlOfEntity(ent) and GetGameTimer() - t < 1500 do
                Wait(0)
            end
        end
        SetEntityAsMissionEntity(ent, true, true)
        DeleteEntity(ent)
    end
end

RegisterNetEvent('jp-meridian9:client:arenaCountdown', function(data)
    local sec = type(data) == 'table' and tonumber(data.seconds) or 5
    lib.notify({ type = 'inform', description = _('arena_countdown', sec) })
    if MRD9.HUD and MRD9.HUD.PushEvent then
        MRD9.HUD.PushEvent('countdown', { seconds = sec })
    end
end)

RegisterNetEvent('jp-meridian9:client:waveStart', function(data)
    if type(data) ~= 'table' then
        return
    end
    lib.notify({
        type = 'inform',
        description = _('arena_wave_start', data.waveNumber or 0, data.totalWaves or 0, data.zombieCount or 0),
    })
    if MRD9.HUD and MRD9.HUD.PushEvent then
        MRD9.HUD.PushEvent('wave_start', {
            wave = data.waveNumber or 0,
            total = data.totalWaves or 0,
            alive = data.zombieCount or 0,
        })
    end
end)

RegisterNetEvent('jp-meridian9:client:waveCleared', function(data)
    if type(data) ~= 'table' then
        return
    end
    lib.notify({
        type = 'success',
        description = _('arena_wave_cleared', data.waveNumber or 0, data.nextWaveInSeconds or 0),
    })
    if MRD9.HUD and MRD9.HUD.PushEvent then
        MRD9.HUD.PushEvent('wave_cleared', {
            wave = data.waveNumber or 0,
            label = tostring(data.nextWaveInSeconds or 0),
        })
    end
end)

RegisterNetEvent('jp-meridian9:client:arenaMissionFailed', function()
    lib.notify({ type = 'error', description = _('arena_mission_failed') })
    if MRD9.HUD and MRD9.HUD.PushEvent then
        MRD9.HUD.PushEvent('mission_failed', {})
    end
end)

RegisterNetEvent('jp-meridian9:client:missionSuccess', function()
    lib.notify({ type = 'success', description = _('arena_mission_success') })
    if MRD9.HUD and MRD9.HUD.PushEvent then
        MRD9.HUD.PushEvent('mission_success', {})
    end
end)

RegisterNetEvent('jp-meridian9:client:arenaCleanupZombies', function()
    for netId, ent in pairs(State.zombies) do
        deleteZombieEntity(ent)
        State.zombies[netId] = nil
    end
end)

local function startDeathMonitor(netId, ent, sessionId)
    CreateThread(function()
        local sid = sessionId
        local nid = netId
        local e = ent
        while State.zombies[nid] == e and DoesEntityExist(e) do
            if IsPedDeadOrDying(e, true) then
                local n = NetworkGetNetworkIdFromEntity(e)
                if n and n ~= 0 then
                    TriggerServerEvent('jp-meridian9:server:zombieKilled', { sessionId = sid, netId = nid })
                end
                State.zombies[nid] = nil
                return
            end
            Wait(400)
        end
    end)
end

RegisterNetEvent('jp-meridian9:client:spawnZombie', function(data)
    if type(data) ~= 'table' or type(data.sessionId) ~= 'string' then
        return
    end
    local modelName = data.model or 'u_m_y_zombie_01'
    local model = modelFromName(modelName)
    if model == 0 or not IsModelInCdimage(model) or not IsModelValid(model) then
        return
    end

    RequestModel(model)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(model) do
        if GetGameTimer() > deadline then
            return
        end
        Wait(0)
    end

    local x = tonumber(data.x) or 0.0
    local y = tonumber(data.y) or 0.0
    local z = tonumber(data.z) or 0.0
    local ped = CreatePed(4, model, x, y, z, 0.0, true, true)
    SetModelAsNoLongerNeeded(model)

    if not ped or ped == 0 then
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    local hp = tonumber(data.health) or 150
    SetEntityMaxHealth(ped, hp)
    SetEntityHealth(ped, hp)
    SetPedArmour(ped, 0)
    SetPedRelationshipGroupHash(ped, joaat('HATES_PLAYER'))
    SetBlockingOfNonTemporaryEvents(ped, false)

    local netId = NetworkGetNetworkIdFromEntity(ped)
    if not netId or netId == 0 then
        deleteZombieEntity(ped)
        return
    end

    State.zombies[netId] = ped
    TriggerServerEvent('jp-meridian9:server:zombieSpawned', {
        sessionId = data.sessionId,
        netId = netId,
        health = hp,
        isBoss = data.isBoss == true,
    })

    local playerPed = PlayerPedId()
    if playerPed and playerPed ~= 0 then
        TaskCombatPed(ped, playerPed, 0, 16)
    end

    startDeathMonitor(netId, ped, data.sessionId)
end)

function MRD9.Arena.ClientBeginMission()
    State.downSent = false
    if State.monitor then
        return
    end
    State.monitor = true
    CreateThread(function()
        while MRD9.CurrentSession do
            local ped = PlayerPedId()
            if ped and ped ~= 0 and IsPedDeadOrDying(ped, true) and not State.downSent then
                State.downSent = true
                TriggerServerEvent('jp-meridian9:server:playerDowned')
            end
            Wait(600)
        end
        State.monitor = false
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    for nid, ent in pairs(State.zombies) do
        deleteZombieEntity(ent)
        State.zombies[nid] = nil
    end
end)
