local PlayerCooldowns = {}
local CachedESX = nil
local CachedQBCore = nil

local function inPoliceJobList(jobName)
    if not jobName then
        return false
    end
    for _, allowed in ipairs(Config.PoliceJobNames) do
        if jobName == allowed then
            return true
        end
    end
    return false
end

local function getESX()
    if CachedESX then
        return CachedESX
    end
    local ok, esx = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if ok and esx then
        CachedESX = esx
        return CachedESX
    end
    return nil
end

local function getQBCore()
    if CachedQBCore then
        return CachedQBCore
    end
    local ok, qb = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok and qb then
        CachedQBCore = qb
        return CachedQBCore
    end
    return nil
end

local function isPolice(source)
    local esx = getESX()
    if esx then
        local xPlayer = esx.GetPlayerFromId(source)
        if xPlayer and xPlayer.job and inPoliceJobList(xPlayer.job.name) then
            return true
        end
    end

    local qb = getQBCore()
    if qb then
        local player = qb.Functions.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.job and inPoliceJobList(player.PlayerData.job.name) then
            return true
        end
    end

    return IsPlayerAceAllowed(source, Config.AcePermission)
end

RegisterNetEvent('jp-110:report110', function()
    local source = source
    local now = os.time()
    local last = PlayerCooldowns[source] or 0
    if now - last < Config.Cooldown then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 200, 200, 50 },
            args = { '110番', 'しばらく待ってから再度通報してください。' }
        })
        return
    end
    PlayerCooldowns[source] = now

    local ped = GetPlayerPed(source)
    if ped <= 0 then
        return
    end
    local coords = GetEntityCoords(ped)

    for _, playerIdStr in ipairs(GetPlayers()) do
        local playerId = tonumber(playerIdStr)
        if playerId and isPolice(playerId) then
            TriggerClientEvent('jp-110:receive110', playerId, {
                x = coords.x,
                y = coords.y,
                z = coords.z
            })
        end
    end

    TriggerClientEvent('chat:addMessage', source, {
        color = { 200, 50, 50 },
        args = { '110番', '通報しました。警察に通知されます。' }
    })
    print(('[jp-110] 110番通報 from player %s'):format(source))
end)

AddEventHandler('playerDropped', function()
    local source = source
    PlayerCooldowns[source] = nil
end)
