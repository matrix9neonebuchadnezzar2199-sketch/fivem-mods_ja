-- ============================================================
-- jp-meridian9 / server/arena/arena.lua
-- ============================================================
-- ゾンビアリーナ状態（メモリのみ）。MRD9.Session と連携。
-- ============================================================

MRD9.Arena = MRD9.Arena or {}

local arenaStates = {}

---@param t table
---@return integer
local function countKeys(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

---@param sessionId string|nil
---@return table|nil
function MRD9.Arena.Get(sessionId)
    if not sessionId then
        return nil
    end
    return arenaStates[sessionId]
end

---@param sessionId string
---@param src integer
---@param data table
function MRD9.Arena.OnClientZombieSpawned(src, data)
    local sessionId = data.sessionId
    if type(sessionId) ~= 'string' or type(data.netId) ~= 'number' then
        return
    end
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return
    end
    local allowed = false
    for _, m in ipairs(session.members) do
        if m == src then
            allowed = true
            break
        end
    end
    if not allowed then
        return
    end

    local st = arenaStates[sessionId]
    if not st or st.state == 'failed' or st.state == 'cleared' then
        return
    end

    local netId = data.netId
    if st.zombies[netId] then
        return
    end

    st.zombies[netId] = {
        health = tonumber(data.health) or 150,
        isBoss = data.isBoss == true,
        spawnedAt = os.time(),
    }
    st.spawnedThisWave = (st.spawnedThisWave or 0) + 1
    MRD9.Log('Arena zombie registered session=%s netId=%d spawnedWave=%d/%d', sessionId, netId, st.spawnedThisWave, st.expectedThisWave or 0)
end

---@param sessionId string
---@param netId integer
local function onZombieKilledInternal(sessionId, netId, killerSrc)
    local st = arenaStates[sessionId]
    if not st or not st.zombies or not st.zombies[netId] then
        return
    end
    if not st.killToken then
        st.killToken = {}
    end
    if st.killToken[netId] then
        return
    end
    st.killToken[netId] = true

    st.zombies[netId] = nil
    st.killCount = (st.killCount or 0) + 1

    local expected = st.expectedThisWave or 0
    local spawned = st.spawnedThisWave or 0
    if spawned >= expected and countKeys(st.zombies) == 0 then
        MRD9.Arena._onWaveCleared(sessionId)
    end
end

RegisterNetEvent('jp-meridian9:server:zombieKilled', function(data)
    local src = source
    if type(src) ~= 'number' or src <= 0 or type(data) ~= 'table' then
        return
    end
    local sessionId = data.sessionId
    local netId = data.netId
    if type(sessionId) ~= 'string' or type(netId) ~= 'number' then
        return
    end
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return
    end
    local allowed = false
    for _, m in ipairs(session.members) do
        if m == src then
            allowed = true
            break
        end
    end
    if not allowed then
        return
    end
    onZombieKilledInternal(sessionId, netId, src)
end)

---@param sessionId string
function MRD9.Arena._onWaveCleared(sessionId)
    local st = arenaStates[sessionId]
    local session = MRD9.Session.Get(sessionId)
    if not st or not session then
        return
    end

    st.spawnedThisWave = 0
    st.expectedThisWave = 0
    st.killToken = {}
    st.zombies = {}

    local totalWaves = st.totalWaves or (Config.Arena and Config.Arena.totalWaves) or 3
    if st.currentWave >= totalWaves then
        st.state = 'cleared'
        for _, m in ipairs(session.members) do
            TriggerClientEvent('jp-meridian9:client:arenaCleanupZombies', m, { sessionId = sessionId, reason = 'cleared' })
        end
        for _, m in ipairs(session.members) do
            TriggerClientEvent('jp-meridian9:client:missionSuccess', m, {})
        end
        arenaStates[sessionId] = nil
        MRD9.Log('Arena mission success session=%s', sessionId)
        -- INSTRUCTION-021: 3 ウェーブクリア → 自由探索＋持続的ゾンビ脅威フェーズへ移行
        if MRD9.Survival and MRD9.Survival.Start then
            MRD9.Survival.Start(sessionId)
        end
        return
    end

    st.state = 'wave_interval'
    local sec = (Config.Arena and Config.Arena.waveIntervalSeconds) or 10
    for _, m in ipairs(session.members) do
        TriggerClientEvent('jp-meridian9:client:waveCleared', m, {
            waveNumber = st.currentWave,
            nextWaveInSeconds = sec,
        })
    end

    local nextWave = st.currentWave + 1
    CreateThread(function()
        Wait(sec * 1000)
        MRD9.Arena._beginWaveInternal(sessionId, nextWave)
    end)
end

---@param sessionId string
---@param waveNumber integer
function MRD9.Arena._beginWaveInternal(sessionId, waveNumber)
    local st = arenaStates[sessionId]
    local session = MRD9.Session.Get(sessionId)
    if not st or not session then
        return
    end

    local cfgWave = MRD9.Arena.Wave.GetConfig(waveNumber)
    if not cfgWave then
        MRD9.Log('Arena: no wave config %d', waveNumber)
        return
    end

    local zc = tonumber(cfgWave.zombieCount) or 0
    local bc = tonumber(cfgWave.bossCount) or 0
    local maxZ = (Config.Arena and Config.Arena.maxConcurrentZombies) or 15

    st.currentWave = waveNumber
    st.state = 'wave_active'
    st.zombies = {}
    st.spawnedThisWave = 0
    st.expectedThisWave = zc + bc
    st.killToken = {}

    for _, m in ipairs(session.members) do
        TriggerClientEvent('jp-meridian9:client:waveStart', m, {
            waveNumber = waveNumber,
            totalWaves = st.totalWaves or 3,
            zombieCount = zc + bc,
        })
    end

    CreateThread(function()
        local sid = sessionId
        for _ = 1, zc do
            local stRef = arenaStates[sid]
            if not stRef or stRef.state ~= 'wave_active' then
                return
            end
            while countKeys(stRef.zombies) >= maxZ do
                Wait(400)
                stRef = arenaStates[sid]
                if not stRef or stRef.state ~= 'wave_active' then
                    return
                end
            end
            MRD9.Arena.Spawn.RequestZombie(sid, false)
            Wait(400)
        end
        for _ = 1, bc do
            local stRef = arenaStates[sid]
            if not stRef or stRef.state ~= 'wave_active' then
                return
            end
            while countKeys(stRef.zombies) >= maxZ do
                Wait(400)
                stRef = arenaStates[sid]
                if not stRef or stRef.state ~= 'wave_active' then
                    return
                end
            end
            MRD9.Arena.Spawn.RequestZombie(sid, true)
            Wait(400)
        end
    end)
end

---@param sessionId string|nil
function MRD9.Arena.Start(sessionId)
    if not sessionId or not Config.Arena or Config.Arena.enabled == false then
        return
    end
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return
    end

    local totalWaves = Config.Arena.totalWaves or 3
    arenaStates[sessionId] = {
        sessionId = sessionId,
        state = 'countdown',
        currentWave = 0,
        zombies = {},
        spawnedThisWave = 0,
        expectedThisWave = 0,
        killCount = 0,
        downed = {},
        killToken = {},
        totalWaves = totalWaves,
        startedAt = os.time(),
    }

    local sec = Config.Arena.countdownSeconds or 5
    for _, m in ipairs(session.members) do
        TriggerClientEvent('jp-meridian9:client:arenaCountdown', m, { seconds = sec })
    end

    CreateThread(function()
        Wait(sec * 1000)
        MRD9.Arena._beginWaveInternal(sessionId, 1)
    end)

    MRD9.Log('Arena countdown started session=%s', sessionId)
end

---@param sessionId string|nil
---@param reason string|nil
function MRD9.Arena.Cleanup(sessionId, reason)
    if not sessionId then
        return
    end
    local session = MRD9.Session.Get(sessionId)
    if session then
        for _, m in ipairs(session.members) do
            TriggerClientEvent('jp-meridian9:client:arenaCleanupZombies', m, { sessionId = sessionId, reason = reason or 'cleanup' })
        end
    end
    arenaStates[sessionId] = nil
    MRD9.Log('Arena cleanup session=%s reason=%s', sessionId, tostring(reason))
end

---@param sessionId string|nil
---@return table
function MRD9.Arena.GetHudSnapshot(sessionId)
    local totalWaves = (Config.Arena and Config.Arena.totalWaves) or 3
    if not sessionId then
        return { active = false, wave = 0, totalWaves = totalWaves, zombiesAlive = 0 }
    end
    local st = arenaStates[sessionId]
    if not st then
        return { active = false, wave = 0, totalWaves = totalWaves, zombiesAlive = 0 }
    end
    local zombiesAlive = countKeys(st.zombies or {})
    local state = st.state or ''
    local active = state ~= 'failed'
        and (state == 'countdown' or state == 'wave_active' or state == 'wave_interval' or state == 'cleared')
    if Config.Arena and Config.Arena.enabled == false then
        active = false
    end
    return {
        active = active,
        wave = st.currentWave or 0,
        totalWaves = st.totalWaves or totalWaves,
        zombiesAlive = zombiesAlive,
    }
end

---@param sessionId string
---@param src integer
function MRD9.Arena.OnPlayerDowned(sessionId, src)
    local st = arenaStates[sessionId]
    local session = MRD9.Session.Get(sessionId)
    if not st or not session or st.state == 'failed' or st.state == 'cleared' then
        return
    end

    st.downed[src] = true

    local allDown = true
    for _, m in ipairs(session.members) do
        if not st.downed[m] then
            allDown = false
            break
        end
    end

    if allDown then
        st.state = 'failed'
        for _, m in ipairs(session.members) do
            TriggerClientEvent('jp-meridian9:client:arenaMissionFailed', m, { sessionId = sessionId })
        end
        MRD9.Session.Destroy(sessionId, 'arena_wiped')
    end
end

---@param sessionId string
function MRD9.Arena.ForceCompleteWave(sessionId)
    local st = arenaStates[sessionId]
    if not st then
        return
    end
    st.zombies = {}
    st.spawnedThisWave = st.expectedThisWave or 0
    MRD9.Arena._onWaveCleared(sessionId)
end

---@param sessionId string
function MRD9.Arena.ForceKillAllZombies(sessionId)
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return
    end
    for _, m in ipairs(session.members) do
        TriggerClientEvent('jp-meridian9:client:arenaCleanupZombies', m, { sessionId = sessionId, reason = 'admin_kill' })
    end
    local st = arenaStates[sessionId]
    if st then
        st.zombies = {}
        st.spawnedThisWave = st.expectedThisWave or 0
    end
end

RegisterNetEvent('jp-meridian9:server:playerDowned', function()
    local src = source
    if type(src) ~= 'number' or src <= 0 then
        return
    end
    local session = MRD9.Session.GetByPlayer(src)
    if not session then
        return
    end
    MRD9.Arena.OnPlayerDowned(session.id, src)
end)

if Config.Debug then
    RegisterCommand('m9_arena_start', function(source)
        if source == 0 then
            return
        end
        local s = MRD9.Session.GetByPlayer(source)
        if not s then
            TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', 'セッション未所属' } })
            return
        end
        MRD9.Arena.Start(s.id)
        TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', 'Arena.Start: ' .. tostring(s.id) } })
    end, false)

    RegisterCommand('m9_arena_status', function(source)
        if source == 0 then
            return
        end
        local s = MRD9.Session.GetByPlayer(source)
        if not s then
            TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', 'セッション未所属' } })
            return
        end
        local st = MRD9.Arena.Get(s.id)
        if not st then
            TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', 'アリーナ状態なし' } })
            return
        end
        TriggerClientEvent(
            'chat:addMessage',
            source,
            { args = { '[MRD9]', ('arena state=%s wave=%d zombies=%d'):format(tostring(st.state), st.currentWave or 0, countKeys(st.zombies or {})) } }
        )
    end, false)

    RegisterCommand('m9_arena_skip_wave', function(source)
        if source == 0 then
            return
        end
        local ace = Config.Admin and Config.Admin.aceName or 'jp-meridian9.admin'
        if not IsPlayerAceAllowed(source, ace) then
            return
        end
        local s = MRD9.Session.GetByPlayer(source)
        if not s then
            return
        end
        MRD9.Arena.ForceCompleteWave(s.id)
    end, false)

    RegisterCommand('m9_arena_kill_all', function(source)
        if source == 0 then
            return
        end
        local ace = Config.Admin and Config.Admin.aceName or 'jp-meridian9.admin'
        if not IsPlayerAceAllowed(source, ace) then
            return
        end
        local s = MRD9.Session.GetByPlayer(source)
        if not s then
            return
        end
        MRD9.Arena.ForceKillAllZombies(s.id)
    end, false)
end
