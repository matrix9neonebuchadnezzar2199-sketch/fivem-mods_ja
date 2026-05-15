-- ============================================================
-- MERIDIAN-9 セッション管理
-- ============================================================
-- 役割:
--   - セッション（仮想空間インスタンス）の作成・破棄
--   - ルーティングバケットのプール管理
--   - プレイヤーのバケット間移動
--   - セッション状態の追跡（メモリのみ・再起動で消失）
--
-- 設計参考（ソース非利用・思想のみ）: JaredScar/Multiverse-World-Manager (MIT)
-- 記載: docs/CREDITS.md
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Session = {}

local sessions = {}
local bucketPool = {}
local memberToSession = {}

---@return integer
local function missionBucketEnd()
    local m = Config.Mission
    if m.bucketEnd then
        return m.bucketEnd
    end
    return m.bucketMax or 999
end

local function InitBucketPool()
    bucketPool = {}
    local last = missionBucketEnd()
    for i = Config.Mission.bucketStart, last do
        bucketPool[#bucketPool + 1] = i
    end
    MRD9.Log('Bucket pool initialized: %d slots', #bucketPool)
end

---@return integer|nil
local function AcquireBucket()
    if #bucketPool == 0 then
        return nil
    end
    return table.remove(bucketPool, 1)
end

---@param bucket integer|nil
local function ReleaseBucket(bucket)
    if not bucket or type(bucket) ~= 'number' then
        return
    end
    bucketPool[#bucketPool + 1] = bucket
end

---@param src integer
---@param bucket integer
local function setPlayerBucket(src, bucket)
    -- CFX サーバーでは通常 integer で問題ない。環境によっては string が必要な場合がある。
    SetPlayerRoutingBucket(src, bucket)
end

---@class Mrd9SessionCreateParams
---@field leader integer
---@field members integer[]
---@field missionType string|nil
---@field difficulty string|nil

---@param params Mrd9SessionCreateParams|nil
---@return string|nil, string|nil
function MRD9.Session.Create(params)
    if not params or not params.leader or not params.members then
        return nil, 'invalid_params'
    end

    local activeCount = 0
    for _ in pairs(sessions) do
        activeCount = activeCount + 1
    end
    if activeCount >= (Config.Mission.maxConcurrentSessions or 20) then
        return nil, 'too_many_sessions'
    end

    for _, src in ipairs(params.members) do
        if type(src) ~= 'number' or src <= 0 then
            return nil, 'invalid_member'
        end
        local identifier = MRD9.GetIdentifier(src)
        if not identifier or not MRD9.Contract.IsContracted(identifier) then
            return nil, 'member_not_contracted'
        end
        if memberToSession[src] then
            return nil, 'member_already_in_session'
        end
    end

    local bucket = AcquireBucket()
    if not bucket then
        return nil, 'no_bucket_available'
    end

    local sessionId = MRD9.GenerateSessionId()
    local now = GetGameTimer()
    local limitMs = (Config.Mission.timeLimitSeconds or 1200) * 1000

    ---@type table
    local session = {
        id = sessionId,
        bucket = bucket,
        leader = params.leader,
        members = {},
        state = 'CREATED',
        startedAt = now,
        endsAt = now + limitMs,
        mission = {
            type = params.missionType or 'SAMPLE_RECOVERY',
            difficulty = params.difficulty or 'NORMAL',
        },
        inventory = {},
        aliveCount = #params.members,
        zombieState = { currentWave = 0, totalKilled = 0 },
    }

    for _, src in ipairs(params.members) do
        session.members[#session.members + 1] = src
        memberToSession[src] = sessionId
        session.inventory[src] = {}
    end

    sessions[sessionId] = session

    MRD9.Log('Session created: id=%s bucket=%d members=%d', sessionId, bucket, #session.members)
    return sessionId, nil
end

---@param sessionId string|nil
---@return boolean, string|nil
function MRD9.Session.TransferIn(sessionId)
    if not sessionId then
        return false, 'session_not_found'
    end
    local s = sessions[sessionId]
    if not s then
        return false, 'session_not_found'
    end

    s.state = 'TRANSITIONING'

    local sp = Config.Mission.spawnPoint
    if not sp then
        return false, 'no_spawn_point'
    end

    for _, src in ipairs(s.members) do
        setPlayerBucket(src, s.bucket)

        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            SetEntityCoords(ped, sp.x, sp.y, sp.z, false, false, false, false)
            SetEntityHeading(ped, sp.w)
        end

        TriggerClientEvent('jp-meridian9:onMissionStart', src, {
            sessionId = sessionId,
            spawnPoint = sp,
            timeLimitSeconds = Config.Mission.timeLimitSeconds or 1200,
        })
    end

    s.state = 'IN_MISSION'
    MRD9.Log('Session transferred in: id=%s', sessionId)

    if MRD9.Arena and MRD9.Arena.Start then
        MRD9.Arena.Start(sessionId)
    end

    if MRD9.Loot and MRD9.Loot.Spawn then
        MRD9.Loot.Spawn(sessionId)
    end

    return true, nil
end

---@param src integer
---@param reason string|nil
---@return boolean
function MRD9.Session.RemovePlayer(src, reason)
    if type(src) ~= 'number' or src <= 0 then
        return false
    end

    local sessionId = memberToSession[src]
    if not sessionId then
        return false
    end

    local s = sessions[sessionId]
    if not s then
        memberToSession[src] = nil
        return false
    end

    setPlayerBucket(src, 0)

    if reason ~= 'disconnect' then
        local rp = Config.Mission.returnPoint
        if rp then
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                SetEntityCoords(ped, rp.x, rp.y, rp.z, false, false, false, false)
                SetEntityHeading(ped, rp.w)
            end
        end
    end

    if reason == 'died' or reason == 'disconnect' then
        s.inventory[src] = {}
    end

    for i, m in ipairs(s.members) do
        if m == src then
            table.remove(s.members, i)
            break
        end
    end

    memberToSession[src] = nil
    s.aliveCount = #s.members

    TriggerClientEvent('jp-meridian9:onMissionEnd', src, {
        sessionId = sessionId,
        reason = reason or 'left',
    })

    MRD9.Log('Player removed from session: src=%d session=%s reason=%s', src, sessionId, tostring(reason))

    if #s.members == 0 then
        local destroyReason = (reason == 'extracted') and 'all_extracted' or 'all_lost'
        MRD9.Session.Destroy(sessionId, destroyReason)
    end

    return true
end

---@param sessionId string|nil
---@param reason string|nil
---@return boolean
function MRD9.Session.Destroy(sessionId, reason)
    if not sessionId then
        return false
    end
    local s = sessions[sessionId]
    if not s then
        return false
    end

    s.state = 'ENDING'

    if MRD9.Extract and MRD9.Extract.OnSessionDestroy then
        MRD9.Extract.OnSessionDestroy(sessionId, reason)
    end

    if MRD9.Arena and MRD9.Arena.Cleanup then
        MRD9.Arena.Cleanup(sessionId, reason)
    end

    if MRD9.Loot and MRD9.Loot.Cleanup then
        MRD9.Loot.Cleanup(sessionId)
    end

    local membersCopy = {}
    for _, src in ipairs(s.members) do
        membersCopy[#membersCopy + 1] = src
    end

    for _, src in ipairs(membersCopy) do
        setPlayerBucket(src, 0)
        local rp = Config.Mission.returnPoint
        if rp then
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                SetEntityCoords(ped, rp.x, rp.y, rp.z, false, false, false, false)
                SetEntityHeading(ped, rp.w)
            end
        end
        memberToSession[src] = nil
        TriggerClientEvent('jp-meridian9:onMissionEnd', src, {
            sessionId = sessionId,
            reason = reason or 'unknown',
        })
    end

    ReleaseBucket(s.bucket)

    if MRD9.Party and MRD9.Party.NotifySessionDestroyed then
        MRD9.Party.NotifySessionDestroyed(sessionId)
    end

    sessions[sessionId] = nil
    MRD9.Log('Session destroyed: id=%s reason=%s', sessionId, tostring(reason))
    return true
end

---@param sessionId string|nil
---@return table|nil
function MRD9.Session.Get(sessionId)
    return sessions[sessionId]
end

---@param src integer
---@return table|nil
function MRD9.Session.GetByPlayer(src)
    local sessionId = memberToSession[src]
    if not sessionId then
        return nil
    end
    return sessions[sessionId]
end

---@return table
function MRD9.Session.GetAll()
    return sessions
end

CreateThread(function()
    Wait(5000)
    local interval = (Config.Mission.cleanupIntervalSeconds or 60) * 1000
    while true do
        Wait(interval)
        local now = GetGameTimer()
        for sessionId, s in pairs(sessions) do
            if s.state == 'IN_MISSION' and now >= s.endsAt then
                MRD9.Log('Session timeout: id=%s', sessionId)
                MRD9.Session.Destroy(sessionId, 'timeout')
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if type(src) ~= 'number' or src <= 0 then
        return
    end
    if MRD9.Party and MRD9.Party.HandleDisconnect then
        MRD9.Party.HandleDisconnect(src)
    end
    if memberToSession[src] then
        MRD9.Log('Player dropped during mission: src=%d', src)
        MRD9.Session.RemovePlayer(src, 'disconnect')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    local ids = {}
    for sessionId in pairs(sessions) do
        ids[#ids + 1] = sessionId
    end
    for _, sessionId in ipairs(ids) do
        MRD9.Session.Destroy(sessionId, 'server_shutdown')
    end
end)

CreateThread(function()
    Wait(1000)
    InitBucketPool()
    print('[jp-meridian9] (server) session manager ready')
    print(('[jp-meridian9] (server) Bucket pool initialized: %d slots'):format(#bucketPool))
end)
