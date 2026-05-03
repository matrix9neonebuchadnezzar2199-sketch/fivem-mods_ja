local JB = {}

local function getESX()
    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    return ok and obj or nil
end

local function getQBCore()
    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    return ok and obj or nil
end

---@param source number|nil サーバーではプレイヤー src、クライアントでは nil
---@return string jobName
function JB.GetJob(source)
    local fw = Config.Framework
    if fw == 'esx' then
        local ESX = getESX()
        if IsDuplicityVersion() then
            local xPlayer = ESX and ESX.GetPlayerFromId(source)
            return (xPlayer and xPlayer.job and xPlayer.job.name) or 'unemployed'
        end
        local pd = ESX and ESX.PlayerData and ESX.PlayerData.job
        return (pd and pd.name) or 'unemployed'
    elseif fw == 'qb' or fw == 'qbox' then
        local QBCore = getQBCore()
        if IsDuplicityVersion() then
            local player = QBCore and QBCore.Functions.GetPlayer(source)
            local j = player and player.PlayerData and player.PlayerData.job
            return (j and j.name) or 'unemployed'
        end
        local pd = QBCore and QBCore.Functions.GetPlayerData()
        local j = pd and pd.job
        return (j and j.name) or 'unemployed'
    end
    return 'standalone'
end

---@param source number|nil
---@return boolean
function JB.IsPolice(source)
    if Config.Framework == 'standalone' then
        if IsDuplicityVersion() then
            return IsPlayerAceAllowed(source --[[@as number]], Config.StandalonePoliceAce)
        end
        return IsPlayerAceAllowed(PlayerId(), Config.StandalonePoliceAce)
    end
    local job = JB.GetJob(source)
    for _, j in ipairs(Config.PoliceJobs) do
        if j == job then
            return true
        end
    end
    return false
end

---@return integer[]
function JB.GetAllPoliceSources()
    local list = {}
    local players = GetPlayers()
    for _, sid in ipairs(players) do
        local src = tonumber(sid)
        if src and JB.IsPolice(src) then
            list[#list + 1] = src
        end
    end
    return list
end

---@return boolean
function JB.IsLocalPolice()
    return JB.IsPolice(nil)
end

Config._JpSentinel.JobBridge = JB
