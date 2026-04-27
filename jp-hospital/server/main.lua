-- jp-hospital サーバー: カルテ正解の二重検証、報酬、シフト日報
local function dbg(msg)
    if Config.Debug then
        print(('[jp-hospital] %s'):format(tostring(msg)))
    end
end

---@return table|nil
local function findMedicineById(medId)
    for _, m in ipairs(Config.Medicines or {}) do
        if m.id == medId then
            return m
        end
    end
    return nil
end

-- 多集合として ID 配列 2 つを比較（出現回数一致）
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

-- [src] 勤務中の集計
local Shifts = {}
-- [src] 現在のカルテ正解＋トークン
local KarteSession = {}
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

-- 前回と同じ出題を避けつつ 1 枚選ぶ
---@return integer
local function pickKarteIndex(lastI, list)
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
local function buildKartePayloadForClient(src, shift, kIndex)
    local t = (shift and shift.kartesKey) and Config[shift.kartesKey] or nil
    if not t then
        return nil
    end
    local karte = t[kIndex]
    if not karte then
        return nil
    end
    local answerIds = karte.answers
    local answerMeds = {}
    for _, aid in ipairs(answerIds) do
        local m = findMedicineById(aid)
        if m then
            answerMeds[#answerMeds + 1] = m
        end
    end

    local used = {}
    for _, aid in ipairs(answerIds) do
        used[aid] = true
    end

    local pool = {}
    for _, m in ipairs(Config.Medicines) do
        if m and m.id and not used[m.id] then
            pool[#pool + 1] = m
        end
    end
    shuffleInPlace(pool)

    local nDecoy = math.floor(tonumber(shift.decoyCount) or (Config.DecoyCount) or 20)
    local decoys = {}
    for d = 1, math.min(nDecoy, #pool) do
        decoys[#decoys + 1] = pool[d]
    end

    local right = {}
    for _, m in ipairs(answerMeds) do
        right[#right + 1] = m
    end
    for _, m in ipairs(decoys) do
        right[#right + 1] = m
    end
    shuffleInPlace(right)

    local sessionId = newSessionId()
    KarteSession[src] = {
        id = sessionId,
        answerIds = answerIds, -- 参照用（検証はコピーと比較で）
        t = os.time(),
        karteIdx = kIndex,
    }

    shift.lastKarteIdx = kIndex

    return {
        sessionId = sessionId,
        symptom = karte.symptom,
        diagnosis = karte.diagnosis,
        requiredMeds = answerMeds, -- 左: 正解箇条書き
        rightListMeds = right, -- 右: シャッフル済み
        answerCount = #answerIds,
        combo = shift.combo,
        maxCombo = shift.maxCombo,
        karteCount = shift.karteCount,
        totalReward = shift.totalReward,
        karteNo = shift.karteCount + 1,
    }
end

RegisterNetEvent('jp-hospital:requestKarte', function()
    local src = source
    if not src or src < 1 then
        return
    end
    if not getQbxPlayer(src) then
        dbg('requestKarte: プレイヤーなし ' .. tostring(src))
        return
    end
    local sh = Shifts[src]
    if not sh or type(sh.kartesKey) ~= 'string' or sh.kartesKey == '' then
        return
    end
    local list = Config[sh.kartesKey]
    if not list or #list < 1 then
        dbg('requestKarte: 出題0件 ' .. tostring(sh.kartesKey))
        return
    end
    local idx = pickKarteIndex(sh.lastKarteIdx, list)
    local data = buildKartePayloadForClient(src, sh, idx)
    if not data then
        return
    end
    TriggerClientEvent('jp-hospital:receiveKarte', src, data)
end)

RegisterNetEvent('jp-hospital:karteComplete', function(payload)
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
    local sess = KarteSession[src]
    if not sess or sess.id ~= clientSession then
        dbg('karteComplete: セッション不一致')
        TriggerClientEvent('jp-hospital:verifyFail', src, { reason = 'session' })
        return
    end
    if (os.time() - (sess.t or 0)) > (tonumber(Config.SessionTtlSec) or 600) then
        KarteSession[src] = nil
        TriggerClientEvent('jp-hospital:verifyFail', src, { reason = 'timeout' })
        return
    end
    if not idMultisetsEqual(selected, sess.answerIds) then
        if Config.ComboResetOnFail and Shifts[src] then
            Shifts[src].combo = 0
        end
        TriggerClientEvent('jp-hospital:verifyResult', src, { ok = false, combo = Shifts[src] and Shifts[src].combo or 0, totalReward = Shifts[src] and Shifts[src].totalReward or 0 })
        return
    end
    -- 正解（勤務シフト必須）
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
            p.Functions.AddMoney('cash', pay, tostring(Config.MoneyReason or 'jp-hospital'))
        end)
    else
        dbg('karteComplete: AddMoney 失敗 (qbx なし等)')
    end
    KarteSession[src] = nil
    TriggerClientEvent('jp-hospital:verifyResult', src, {
        ok = true,
        reward = pay,
        combo = sh.combo,
        maxCombo = sh.maxCombo,
        totalReward = sh.totalReward,
    })
    dbg(('[jp-hospital] %d 本日報 %d$ combo=%d base=%d'):format(src, pay, sh.combo, base))
end)

RegisterNetEvent('jp-hospital:startShift', function(diffId)
    local src = source
    if not getQbxPlayer(src) then
        dbg('startShift: プレイヤー取得不可（QBX 未接続等） ' .. tostring(src))
        TriggerClientEvent('jp-hospital:shiftStartFailed', src, { reason = 'noplayer' })
        return
    end
    KarteSession[src] = nil
    local dconf = findDifficultyConfig(type(diffId) == 'string' and diffId or 'easy')
    if not dconf or type(dconf.kartesKey) ~= 'string' or dconf.kartesKey == '' then
        dbg('startShift: 難易度定義が無い')
        TriggerClientEvent('jp-hospital:shiftStartFailed', src, { reason = 'noconfig' })
        return
    end
    local t = Config[dconf.kartesKey]
    if not t or #t < 1 then
        dbg('startShift: カルテ0件 ' .. dconf.kartesKey)
        TriggerClientEvent('jp-hospital:shiftStartFailed', src, { reason = 'nokarte' })
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
    TriggerClientEvent('jp-hospital:shiftStarted', src, {
        id = dconf.id,
        label = dconf.label or dconf.id,
    })
end)

RegisterNetEvent('jp-hospital:endShift', function()
    local src = source
    local sh = Shifts[src]
    KarteSession[src] = nil
    if not sh then
        TriggerClientEvent('jp-hospital:dayReport', src, {
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
    TriggerClientEvent('jp-hospital:dayReport', src, report)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Shifts[src] then
        Shifts[src] = nil
    end
    if KarteSession[src] then
        KarteSession[src] = nil
    end
end)
