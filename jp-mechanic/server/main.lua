-- jp-mechanic: 伝票正解二重検証、報酬、日報
local function dbg(msg)
    if Config.Debug then
        print(('[jp-mechanic] %s'):format(tostring(msg)))
    end
end

---@return table|nil
local function findPartById(pid)
    for _, m in ipairs(Config.Parts or {}) do
        if m.id == pid then
            return m
        end
    end
    return nil
end

local function idMultisetsEqual(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then
        return false
    end
    local c, d = {}, {}
    for _, x in ipairs(a) do
        c[x] = (c[x] or 0) + 1
    end
    for _, x in ipairs(b) do
        d[x] = (d[x] or 0) + 1
    end
    for k, v in pairs(c) do
        if (d[k] or 0) ~= v then
            return false
        end
    end
    for k, v in pairs(d) do
        if (c[k] or 0) ~= v then
            return false
        end
    end
    return true
end

local function shuffleInPlace(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local Shifts = {}
local SlipSession = {}
local usedSession = 0

local function newSessionId()
    usedSession = usedSession + 1
    return (os.time() * 10000) + usedSession
end

---@return table|nil
local function getQbxPlayer(src)
    local ok, p = pcall(function()
        return exports.qbx_core:GetPlayer(src)
    end)
    if ok and p and p.PlayerData then
        return p
    end
    return nil
end

---@return table|nil
local function findDifficultyConfig(diffId)
    if type(diffId) ~= 'string' or diffId == '' then
        diffId = 'easy'
    end
    local dft
    for _, d in ipairs(Config.Difficulties or {}) do
        if d and d.id == 'easy' then
            dft = d
        end
    end
    for _, d in ipairs(Config.Difficulties or {}) do
        if d and d.id == diffId then
            return d
        end
    end
    return dft
end

---@return integer
local function pickSlipIndex(lastI, list)
    local n = #list
    if n < 1 then
        return 1
    end
    if n == 1 then
        return 1
    end
    local i = math.random(n)
    if lastI and i == lastI then
        i = (i % n) + 1
    end
    return i
end

---@return table|nil
local function buildSlipPayloadForClient(src, shift, kIndex)
    local t = (shift and shift.kartesKey) and Config[shift.kartesKey] or nil
    if not t then
        return nil
    end
    local row = t[kIndex]
    if not row then
        return nil
    end
    local answerIds = row.answers
    local listReq = {}
    for _, aid in ipairs(answerIds) do
        local p = findPartById(aid)
        if p then
            listReq[#listReq + 1] = p
        end
    end
    local used = {}
    for _, aid in ipairs(answerIds) do
        used[aid] = true
    end
    local pool = {}
    for _, p in ipairs(Config.Parts) do
        if p and p.id and not used[p.id] then
            pool[#pool + 1] = p
        end
    end
    shuffleInPlace(pool)
    local nDecoy = math.floor(tonumber(shift.decoyCount) or (Config.DecoyCount) or 20)
    local decoys = {}
    for d = 1, math.min(nDecoy, #pool) do
        decoys[#decoys + 1] = pool[d]
    end
    local right = {}
    for _, p in ipairs(listReq) do
        right[#right + 1] = p
    end
    for _, p in ipairs(decoys) do
        right[#right + 1] = p
    end
    shuffleInPlace(right)
    local sessionId = newSessionId()
    SlipSession[src] = {
        id = sessionId,
        answerIds = answerIds,
        t = os.time(),
        karteIdx = kIndex,
    }
    shift.lastKarteIdx = kIndex
    return {
        sessionId = sessionId,
        vehicle = row.vehicle or '—',
        symptom = row.symptom,
        diagnosis = row.diagnosis,
        requiredMeds = listReq,
        rightListMeds = right,
        answerCount = #answerIds,
        combo = shift.combo,
        maxCombo = shift.maxCombo,
        karteCount = shift.karteCount,
        totalReward = shift.totalReward,
        karteNo = shift.karteCount + 1,
    }
end

RegisterNetEvent('jp-mechanic:requestSlip', function()
    local src = source
    if not src or src < 1 then
        return
    end
    if not getQbxPlayer(src) then
        dbg('requestSlip: プレイヤーなし ' .. tostring(src))
        return
    end
    local sh = Shifts[src]
    if not sh or type(sh.kartesKey) ~= 'string' or sh.kartesKey == '' then
        return
    end
    local list = Config[sh.kartesKey]
    if not list or #list < 1 then
        dbg('requestSlip: 出題0件 ' .. tostring(sh.kartesKey))
        return
    end
    local idx = pickSlipIndex(sh.lastKarteIdx, list)
    local data = buildSlipPayloadForClient(src, sh, idx)
    if not data then
        return
    end
    TriggerClientEvent('jp-mechanic:receiveSlip', src, data)
end)

RegisterNetEvent('jp-mechanic:slipComplete', function(payload)
    local src = source
    if not src or src < 1 then
        return
    end
    if type(payload) ~= 'table' then
        return
    end
    local clientSession = tonumber(payload.sessionId)
    local selected = payload.selectedIds
    if not clientSession or type(selected) ~= 'table' then
        return
    end
    local sess = SlipSession[src]
    if not sess or sess.id ~= clientSession then
        TriggerClientEvent('jp-mechanic:verifyFail', src, { reason = 'session' })
        return
    end
    if (os.time() - (sess.t or 0)) > (tonumber(Config.SessionTtlSec) or 600) then
        SlipSession[src] = nil
        TriggerClientEvent('jp-mechanic:verifyFail', src, { reason = 'timeout' })
        return
    end
    if not idMultisetsEqual(selected, sess.answerIds) then
        if Config.ComboResetOnFail and Shifts[src] then
            Shifts[src].combo = 0
        end
        TriggerClientEvent('jp-mechanic:verifyResult', src, { ok = false, combo = Shifts[src] and Shifts[src].combo or 0, totalReward = Shifts[src] and Shifts[src].totalReward or 0 })
        return
    end
    if not Shifts[src] then
        return
    end
    local sh = Shifts[src]
    sh.combo = (sh.combo or 0) + 1
    if sh.combo > (sh.maxCombo or 0) then
        sh.maxCombo = sh.combo
    end
    sh.karteCount = (sh.karteCount or 0) + 1
    local multI = math.min(sh.combo, tonumber(Config.MaxCombo) or 5)
    local mult = (Config.ComboMultiplier[multI]) or 1.0
    local base = math.floor(tonumber(sh.rewardBase) or (Config.RewardPerKarte) or 0)
    local pay = math.floor(base * (mult * 1.0))
    sh.totalReward = (sh.totalReward or 0) + pay
    local p = getQbxPlayer(src)
    if p and p.Functions and p.Functions.AddMoney then
        pcall(function()
            p.Functions.AddMoney('cash', pay, tostring(Config.MoneyReason or 'jp-mechanic'))
        end)
    else
        dbg('slipComplete: AddMoney 失敗')
    end
    SlipSession[src] = nil
    TriggerClientEvent('jp-mechanic:verifyResult', src, {
        ok = true,
        reward = pay,
        combo = sh.combo,
        maxCombo = sh.maxCombo,
        totalReward = sh.totalReward,
    })
end)

RegisterNetEvent('jp-mechanic:startShift', function(diffId)
    local src = source
    if not getQbxPlayer(src) then
        TriggerClientEvent('jp-mechanic:shiftStartFailed', src, { reason = 'noplayer' })
        return
    end
    SlipSession[src] = nil
    local dconf = findDifficultyConfig(type(diffId) == 'string' and diffId or 'easy')
    if not dconf or type(dconf.kartesKey) ~= 'string' or dconf.kartesKey == '' then
        TriggerClientEvent('jp-mechanic:shiftStartFailed', src, { reason = 'noconfig' })
        return
    end
    local t = Config[dconf.kartesKey]
    if not t or #t < 1 then
        TriggerClientEvent('jp-mechanic:shiftStartFailed', src, { reason = 'nokarte' })
        return
    end
    Shifts[src] = {
        startTime = os.time(),
        totalReward = 0,
        karteCount = 0,
        maxCombo = 0,
        combo = 0,
        lastKarteIdx = nil,
        diffId = dconf.id,
        kartesKey = dconf.kartesKey,
        rewardBase = tonumber(dconf.rewardBase) or 300,
        decoyCount = math.floor(tonumber(dconf.decoyCount) or 20),
        timeLimit = tonumber(dconf.timeLimit) or 0,
    }
    TriggerClientEvent('jp-mechanic:shiftStarted', src, { id = dconf.id, label = dconf.label or dconf.id })
end)

RegisterNetEvent('jp-mechanic:endShift', function()
    local src = source
    local sh = Shifts[src]
    SlipSession[src] = nil
    if not sh then
        TriggerClientEvent('jp-mechanic:dayReport', src, {
            startTime = os.time(),
            endTime = os.time(),
            karteCount = 0,
            maxCombo = 0,
            totalReward = 0,
            minutes = 0,
        })
        Shifts[src] = nil
        return
    end
    local t1 = sh.startTime or os.time()
    local t2 = os.time()
    local mins = math.max(0, math.floor((t2 - t1) / 60))
    local report = {
        startTime = t1,
        endTime = t2,
        karteCount = sh.karteCount or 0,
        maxCombo = sh.maxCombo or 0,
        totalReward = sh.totalReward or 0,
        minutes = mins,
    }
    Shifts[src] = nil
    TriggerClientEvent('jp-mechanic:dayReport', src, report)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Shifts[src] then
        Shifts[src] = nil
    end
    if SlipSession[src] then
        SlipSession[src] = nil
    end
end)
