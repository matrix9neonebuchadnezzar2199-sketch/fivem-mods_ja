-- jp-losmon クライアント: KVS 保存、時間経過シミュ、NUI 制御
local KVP_BLOB = 'losmon_v1'
local nuiHasFocus = false
local nuiShowExpanded = false
local stateCache = nil

---@return number
local function nowSec()
    if GetCloudTimeAsInt then
        return GetCloudTimeAsInt()
    end
    return os.time and os.time() or 0
end

---@return number, number
local function getMiniDefault()
    if Config and Config.MiniPosDefault and Config.MiniPosDefault.x and Config.MiniPosDefault.y then
        return tonumber(Config.MiniPosDefault.x) or 0.12, tonumber(Config.MiniPosDefault.y) or 0.88
    end
    return 0.12, 0.88
end

---@return table
local function readStore()
    local s = GetResourceKvpString and GetResourceKvpString(KVP_BLOB) or (GetResourceKvp and GetResourceKvp(KVP_BLOB) or nil)
    if s and s ~= '' then
        local ok, t = pcall(json.decode, s)
        if ok and t and type(t) == 'table' then
            return t
        end
    end
    local dx, dy = getMiniDefault()
    return { version = 1, lastUpdateAt = nowSec(), pet = nil, zukan = {}, miniPos = { x = dx, y = dy }, noPetMenuDismissed = false }
end

---@param store table
local function writeStore(store)
    store = store or stateCache
    if not store then
        return
    end
    local enc = json.encode(store)
    if SetResourceKvpString then
        SetResourceKvpString(KVP_BLOB, enc)
    elseif SetResourceKvp then
        SetResourceKvp(KVP_BLOB, enc)
    end
end

---@param v number|nil
---@param lo number
---@param hi number
---@return number
local function clamp(v, lo, hi)
    if not v then
        return lo
    end
    v = v + 0.0
    if v < lo then
        return lo
    end
    if v > hi then
        return hi
    end
    return v
end

---@param t table|nil
local function zukanListify(t)
    if type(t) == 'table' and #t > 0 then
        return t
    end
    if type(t) == 'table' and next(t) == nil then
        return {}
    end
    -- set 風: { a=true }
    if type(t) == 'table' then
        local a = {}
        for k, v in pairs(t) do
            if v then
                a[#a + 1] = type(k) == 'string' and k or tostring(v)
            end
        end
        return a
    end
    return {}
end

---@param zukan table
---@param id string|nil
local function zukanAdd(zukan, id)
    if not id or id == 'egg' then
        return
    end
    if type(zukan) ~= 'table' then
        return
    end
    for i = 1, #zukan do
        if zukan[i] == id then
            return
        end
    end
    zukan[#zukan + 1] = id
end

---@param p table|nil
local function hasPet(p)
    return p and type(p) == 'table' and p.name and p.phase
end

---@param p table|nil
local function isAlive(p)
    if not hasPet(p) then
        return false
    end
    return p.phase ~= 'dead'
end

---@param pet table
---@param minutes integer
---@return boolean
local function applyStatDecay(pet, minutes)
    if minutes < 1 or not pet or not pet.stats or pet.phase == 'dead' or pet.phase == 'egg' then
        return false
    end
    local d = (Config.StatDecayRate or 0) * minutes
    local s = pet.stats
    s.hunger = clamp((s.hunger or 0) - d, 0, 100)
    s.mood = clamp((s.mood or 0) - d, 0, 100)
    s.stamina = clamp((s.stamina or 0) - d, 0, 100)
    s.clean = clamp((s.clean or 0) - d, 0, 100)
    return true
end

---@return table
local function createNewEggPet()
    local t = nowSec()
    return {
        line = 'default',
        phase = 'egg',
        evolutionId = 'egg',
        name = (Config and Config.DefaultPetName) or 'ぼく',
        bornAt = t,
        phaseStartAt = t,
        stats = { hunger = 80, mood = 60, stamina = 30, clean = 50 },
        careCount = 0,
        lastAction = { feed = 0, play = 0, sleep = 0, clean = 0 },
        -- 歩行・乗車の累積 m と EXP（KVS 保存。レベルは合計 EXP から算出）
        expTotal = 0,
        statWalkM = 0,
        statDriveM = 0,
    }
end

---@param pet table
---@param n number
---@return boolean|nil
local function tryEnterSick(pet, n)
    if not pet or pet.phase == 'egg' or pet.phase == 'sick' or pet.phase == 'dead' or pet.phase == nil then
        return false
    end
    if (pet.stats and (pet.stats.hunger or 0)) <= (Config.SickThreshold or 10) then
        pet.phaseBeforeSick = pet.phase
        pet.phase = 'sick'
        pet.sickAt = n
        return true
    end
    return false
end

---@param pet table
---@param n number
---@return boolean|nil
local function tryDeath(pet, n)
    if not pet or pet.phase ~= 'sick' or not pet.sickAt then
        return false
    end
    if (n - pet.sickAt) >= (Config.DeathTime or 14400) then
        pet.phase = 'dead'
        pet.evolutionId = 'grave'
        return true
    end
    return false
end

---@param store table
---@param n number
local function advancePhases(store, n)
    local pet = store.pet
    if not hasPet(pet) or not isAlive(pet) or pet.phase == 'sick' then
        return
    end
    while true do
        if pet.phase == 'dead' or pet.phase == 'sick' or pet.phase == 'adult' then
            break
        end
        if pet.phase == 'egg' then
            local nxt = (pet.phaseStartAt or 0) + (Config.HatchTime or 1800)
            if n < nxt then
                break
            end
            pet.phase = 'baby'
            pet.evolutionId = (math.random(1, 2) == 1) and 'baby_a' or 'baby_b'
            pet.phaseStartAt = nxt
            pet.careCount = 0
            if pet.evolutionId then
                zukanAdd(store.zukan, pet.evolutionId)
            end
        elseif pet.phase == 'baby' then
            local nxt = (pet.phaseStartAt or 0) + (Config.GrowthInterval or 3600)
            if n < nxt then
                break
            end
            local el = pet.phaseStartAt or 0
            local idealB = math.max(1, math.floor((nxt - el) / (Config.IdealCareIntervalSec or 1200)))
            local cRatio = ((pet.careCount or 0) / idealB) * 100.0
            if cRatio >= (Config.ChildToGoodChildThreshold or 50) then
                pet.evolutionId = 'child_a'
                pet.childBranch = 'A'
            else
                pet.evolutionId = 'child_b'
                pet.childBranch = 'B'
            end
            pet.phase = 'child'
            pet.phaseStartAt = nxt
            pet.careCount = 0
            if pet.evolutionId then
                zukanAdd(store.zukan, pet.evolutionId)
            end
        elseif pet.phase == 'child' then
            local nxt = (pet.phaseStartAt or 0) + (Config.GrowthInterval or 3600)
            if n < nxt then
                break
            end
            local rp = Config.AdultRarePercent or 10
            if math.random(1, 100) <= rp then
                pet.evolutionId = 'adult_d'
            else
                local u = math.random(1, 3)
                pet.evolutionId = (u == 1) and 'adult_a' or (u == 2) and 'adult_b' or 'adult_c'
            end
            pet.phase = 'adult'
            pet.phaseStartAt = nxt
            pet.careCount = 0
            if pet.evolutionId then
                zukanAdd(store.zukan, pet.evolutionId)
            end
            break
        else
            break
        end
    end
end

---@param store table
---@return table
local function ensureStore(store)
    if type(store) ~= 'table' then
        return readStore()
    end
    if type(store.zukan) ~= 'table' then
        store.zukan = {}
    end
    if type(store.miniPos) ~= 'table' or not store.miniPos.x then
        local dx, dy = getMiniDefault()
        store.miniPos = { x = dx, y = dy }
    end
    store.zukan = zukanListify(store.zukan)
    if not store.lastUpdateAt then
        store.lastUpdateAt = nowSec()
    end
    if store.noPetMenuDismissed == nil then
        store.noPetMenuDismissed = false
    end
    if store.pet and type(store.pet.lastAction) ~= 'table' then
        store.pet.lastAction = { feed = 0, play = 0, sleep = 0, clean = 0 }
    end
    if store.pet and type(store.pet.stats) ~= 'table' then
        store.pet.stats = { hunger = 80, mood = 60, stamina = 30, clean = 50 }
    end
    if store.pet and store.pet.line == nil then
        store.pet.line = 'default'
    end
    if store.pet and (store.pet.expTotal == nil or type(store.pet.expTotal) ~= 'number') then
        store.pet.expTotal = 0
    end
    if store.pet and (store.pet.statWalkM == nil or type(store.pet.statWalkM) ~= 'number') then
        store.pet.statWalkM = 0
    end
    if store.pet and (store.pet.statDriveM == nil or type(store.pet.statDriveM) ~= 'number') then
        store.pet.statDriveM = 0
    end
    return store
end

---@param store table
local function syncWorldTime(store)
    local n = nowSec()
    store = ensureStore(store)
    local last = store.lastUpdateAt
    if not last or last < 0 then
        last = n
    end
    if last > n then
        last = n
    end
    local minutes = math.floor((n - last) / 60)
    if minutes > 0 and store.pet then
        applyStatDecay(store.pet, minutes)
    end
    if store.pet and hasPet(store.pet) and isAlive(store.pet) and store.pet.phase ~= 'sick' then
        advancePhases(store, n)
    end
    if store.pet and hasPet(store.pet) and isAlive(store.pet) and store.pet.phase ~= 'sick' and store.pet.phase ~= 'egg' then
        tryEnterSick(store.pet, n)
    end
    if store.pet and store.pet.phase == 'sick' then
        tryDeath(store.pet, n)
    end
    store.lastUpdateAt = n
    stateCache = store
    return store
end

---@param pet table|nil
---@return string|nil
local function petDisplayName(pet)
    if not pet or not pet.evolutionId or pet.evolutionId == 'egg' then
        return '卵'
    end
    if Config.FormNames and Config.FormNames[pet.evolutionId] then
        return Config.FormNames[pet.evolutionId]
    end
    if pet.name then
        return pet.name
    end
    return 'Los-Mon'
end

---@param p table|nil
---@return string
local function getStageLabel(p)
    if not p or not p.phase then
        return ''
    end
    if p.phase == 'egg' then
        return '卵'
    end
    if p.phase == 'baby' then
        return '幼体'
    end
    if p.phase == 'child' then
        if p.childBranch == 'A' then
            return '成長期（良）'
        end
        if p.childBranch == 'B' then
            return '成長期（悪）'
        end
        return '成長期'
    end
    if p.phase == 'adult' then
        return '成熟期'
    end
    if p.phase == 'sick' then
        return '病気'
    end
    if p.phase == 'dead' then
        return '旅立ち'
    end
    return ''
end

---@param pet table|nil
---@return table|nil
local function getSpriteSetForPet(pet)
    if not pet or not pet.phase then
        return nil
    end
    -- 常に { mode, set } 形式にして NUI setSprite 側と図鑑/タイトルと一貫させる
    if pet.phase == 'sick' and Config.Sprites and Config.Sprites.sick then
        return { mode = 'id', set = Config.Sprites.sick }
    end
    if pet.phase == 'dead' or pet.evolutionId == 'grave' then
        if Config.Sprites and Config.Sprites.grave then
            return { mode = 'id', set = Config.Sprites.grave }
        end
    end
    if pet.phase == 'egg' and Config.Sprites.egg and Config.Sprites.egg_crack then
        return { egg = Config.Sprites.egg, crack = Config.Sprites.egg_crack, mode = 'egg' }
    end
    if pet.evolutionId and Config.Sprites[pet.evolutionId] then
        return { mode = 'id', set = Config.Sprites[pet.evolutionId] }
    end
    if Config.Sprites.egg and pet.phase == 'egg' then
        return { egg = Config.Sprites.egg, crack = Config.Sprites.egg_crack, mode = 'egg' }
    end
    if Config.Sprites and Config.Sprites.baby_a then
        return { mode = 'id', set = Config.Sprites.baby_a }
    end
    return nil
end

---@param st table|nil
---@param a string|nil
---@return number
local function cooldownLeft(st, a)
    if not a or not st or not st.lastAction or not st.lastAction[a] then
        return 0
    end
    local cd = 0
    if a == 'feed' then
        cd = Config.FeedCooldown or 30
    elseif a == 'play' then
        cd = Config.PlayCooldown or 60
    elseif a == 'sleep' then
        cd = Config.SleepCooldown or 120
    else
        cd = Config.CleanCooldown or 60
    end
    local t = (st.lastAction[a] or 0) + cd
    return math.max(0, t - nowSec())
end

---@param pet table|nil
---@return number
local function spriteStripFramesForPet(pet)
    if not pet or not hasPet(pet) then
        return (Config and Config.SpriteStripFrames) or 4
    end
    if pet.phase == 'egg' then
        return (Config and Config.EggSpriteStripFrames) or 4
    end
    if pet.phase == 'dead' or pet.evolutionId == 'grave' then
        return (Config and Config.GraveSpriteStripFrames) or 1
    end
    return (Config and Config.SpriteStripFrames) or 4
end

---@return number
local function expBaseValue()
    local b = (Config and Config.ExpBasePer100) and tonumber(Config.ExpBasePer100) or 100.0
    if b < 0.1 then
        b = 100.0
    end
    return b
end

---@param L number
---@return number
local function expMinForLevel(L)
    L = math.max(1, math.floor((tonumber(L) or 1) + 0.5))
    local b = expBaseValue()
    return b * (L - 1) * L / 2.0
end

---@param e number|nil
---@return number
local function levelFromTotalExp(e)
    e = math.max(0.0, (e or 0) + 0.0)
    local maxLv = (Config and Config.LevelMax) or 999
    if e <= 0 then
        return 1
    end
    local b = expBaseValue()
    local inner = 1.0 + 8.0 * e / b
    if inner < 0.0 then
        inner = 0.0
    end
    local Ld = (1.0 + math.sqrt(inner)) / 2.0
    local L = math.floor(Ld + 0.0)
    if L < 1 then
        L = 1
    end
    if L > maxLv then
        L = maxLv
    end
    return L
end

---@param pet table|nil
---@return table
local function buildLevelFields(pet)
    local maxLv = (Config and Config.LevelMax) or 999
    local mps = (Config and Config.MetersPerStepDisplay) and tonumber(Config.MetersPerStepDisplay) or 0.75
    if mps < 0.1 then
        mps = 0.75
    end
    local e, w, d = 0.0, 0.0, 0.0
    if pet and hasPet(pet) then
        e = (type(pet.expTotal) == 'number' and (pet.expTotal + 0.0)) or 0.0
        w = (type(pet.statWalkM) == 'number' and (pet.statWalkM + 0.0)) or 0.0
        d = (type(pet.statDriveM) == 'number' and (pet.statDriveM + 0.0)) or 0.0
    end
    local L = levelFromTotalExp(e)
    local eMin = expMinForLevel(L)
    local eMax = expMinForLevel(L + 1)
    local inLv = e - eMin
    local range = eMax - eMin
    local toN = eMax - e
    if toN < 0.0 then
        toN = 0.0
    end
    local pct = 0.0
    if L >= maxLv then
        pct = 100.0
    elseif range > 0.0001 then
        pct = math.max(0.0, math.min(100.0, 100.0 * inLv / range))
    else
        pct = 0.0
    end
    return {
        level = L,
        levelMax = maxLv,
        expTotal = e,
        expInLevel = inLv,
        expToNext = toN,
        expLevelMin = eMin,
        expLevelMax = eMax,
        expLevelPct = pct,
        walkMeters = w,
        driveMeters = d,
        stepCount = math.max(0, math.floor(w / mps + 0.0)),
    }
end

---@param a any
---@param b any
---@return number
local function vec3dist(a, b)
    if not a or not b or type(a) ~= 'table' or type(b) ~= 'table' then
        return 0.0
    end
    local ax, ay, az = a.x, a.y, a.z
    local bx, by, bz = b.x, b.y, b.z
    if not ax or not ay or not az or not bx or not by or not bz then
        return 0.0
    end
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@param pet table
---@param amount number
---@return number|nil, number|nil
local function addExpToPet(pet, amount)
    if not pet or not isAlive(pet) or not (amount and amount > 0.0) then
        return nil, nil
    end
    local oldL = levelFromTotalExp(pet.expTotal)
    local add = (amount or 0.0) + 0.0
    pet.expTotal = ((pet.expTotal or 0) + add) + 0.0
    if pet.expTotal < 0.0 then
        pet.expTotal = 0.0
    end
    local newL = levelFromTotalExp(pet.expTotal)
    if newL > oldL then
        SendNUIMessage({ type = 'levelUp', level = newL, from = oldL })
    end
    return oldL, newL
end

---@param st table|nil
local function nuiStatePayload(st, expanded)
    local s = st or readStore()
    s = ensureStore(syncWorldTime(ensureStore(s)))
    stateCache = s
    local pet = s.pet
    local n = nowSec()
    local hLeft = 0
    if pet and hasPet(pet) and pet.phase == 'egg' then
        hLeft = math.max(0, (pet.phaseStartAt or 0) + (Config.HatchTime or 1800) - n)
    end
    local nPhaseLeft = 0
    if pet and hasPet(pet) and isAlive(pet) and (pet.phase == 'baby' or pet.phase == 'child') then
        nPhaseLeft = math.max(0, (pet.phaseStartAt or 0) + (Config.GrowthInterval or 3600) - n)
    end
    local zukanMap = {}
    if Config and Config.ZukanIds and Config.Sprites then
        for _, zid in ipairs(Config.ZukanIds) do
            if Config.Sprites[zid] and (Config.Sprites[zid].idle) then
                zukanMap[zid] = Config.Sprites[zid].idle
            end
        end
    end
    local al = false
    if pet and hasPet(pet) and isAlive(pet) and pet.phase ~= 'egg' and pet.phase ~= 'dead' then
        al = true
    end
    local lvf = buildLevelFields(pet)
    local nameMax = (Config and Config.PetNameMaxLength) or 12
    if nameMax < 1 then
        nameMax = 12
    end
    return {
        type = 'state',
        expanded = expanded or false,
        showEgg = false,
        eggList = nil,
        eggShowCrackSec = (Config and Config.EggShowCrackSec) or 30,
        pet = pet,
        zukan = s.zukan,
        zukanIds = Config.ZukanIds,
        zukanMap = zukanMap,
        miniPos = s.miniPos,
        miniPosDefault = (function()
            local dx, dy = getMiniDefault()
            return { x = dx, y = dy }
        end)(),
        charName = pet and (pet.name or 'ぼく') or 'ぼく',
        petNameMaxLength = nameMax,
        level = lvf.level,
        levelMax = lvf.levelMax,
        expTotal = lvf.expTotal,
        expInLevel = lvf.expInLevel,
        expToNext = lvf.expToNext,
        expLevelMin = lvf.expLevelMin,
        expLevelMax = lvf.expLevelMax,
        expLevelPct = lvf.expLevelPct,
        walkMeters = lvf.walkMeters,
        driveMeters = lvf.driveMeters,
        stepCount = lvf.stepCount,
        evName = petDisplayName(pet),
        stageLabel = getStageLabel(pet),
        elapseSec = pet and n - (pet.bornAt or n) or 0,
        config = {
            hatchTime = Config.HatchTime,
            growth = Config.GrowthInterval,
            sickT = Config.SickThreshold,
            statDecay = Config.StatDecayRate,
            tickerNearHatch = Config.TickerNearHatchMaxSec or 90,
            tickerNearPhase = Config.TickerNearPhaseMaxSec or 600,
            spriteStripFrames = spriteStripFramesForPet(pet),
        },
        sprite = getSpriteSetForPet(pet),
        nextPhaseInSec = nPhaseLeft,
        hatchLeftSec = hLeft,
        deathLeftSec = (pet and pet.phase == 'sick' and pet.sickAt) and math.max(0, (pet.sickAt + (Config.DeathTime or 14400)) - n) or 0,
        cooldowns = {
            feed = al and cooldownLeft(pet, 'feed') or 0,
            play = (al and (pet and pet.phase) ~= 'sick') and cooldownLeft(pet, 'play') or 0,
            sleep = (al and (pet and pet.phase) ~= 'sick') and cooldownLeft(pet, 'sleep') or 0,
            clean = al and cooldownLeft(pet, 'clean') or 0,
        },
        resName = (GetCurrentResourceName and GetCurrentResourceName() or 'jp-losmon'),
    }
end

---@param s table|nil
---@param ex boolean|nil
---@param es boolean|nil
local function pushNui(s, ex)
    if s ~= nil then
        stateCache = ensureStore(s)
    end
    SendNUIMessage(nuiStatePayload(stateCache, ex))
end

---@param focus boolean
local function setNuiFocus(focus)
    nuiHasFocus = focus
    if SetNuiFocus then
        if focus then
            SetNuiFocus(true, true)
        else
            SetNuiFocus(false, false)
        end
    end
end

local function saveAuto()
    if stateCache then
        writeStore(stateCache)
    end
end

RegisterNUICallback('closeExpanded', function(_, cb)
    nuiShowExpanded = false
    setNuiFocus(false)
    if stateCache then
        stateCache = ensureStore(syncWorldTime(stateCache))
    end
    pushNui(stateCache, false)
    if cb then
        cb('ok')
    end
end)

-- ミニ表示の位置: 拡大表示（SetNuiFocus あり）中のドラッグのみ。普段はマウス非表示のため NUI から setMiniPos は呼ばれない
RegisterNUICallback('setMiniPos', function(data, cb)
    if not nuiShowExpanded then
        if cb then
            cb('ok')
        end
        return
    end
    if stateCache and data and data.x and data.y then
        stateCache = ensureStore(stateCache)
        local dx, dy = getMiniDefault()
        stateCache.miniPos = { x = tonumber(data.x) or dx, y = tonumber(data.y) or dy }
        writeStore(stateCache)
    end
    if cb then
        cb('ok')
    end
end)

---@param s string|nil
---@param maxC number
---@return string
local function clampPetNameString(s, maxC)
    local dname = (Config and Config.DefaultPetName) or 'ぼく'
    if not s or type(s) ~= 'string' then
        return dname
    end
    s = s:gsub('[\r\n\t%z]', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then
        return dname
    end
    local mc = (type(maxC) == 'number' and maxC > 0) and maxC or 12
    if utf8 and utf8.len and utf8.offset then
        if utf8.len(s) > mc then
            local cut = utf8.offset(s, mc + 1)
            if cut and cut > 1 then
                s = s:sub(1, cut - 1)
            else
                s = dname
            end
        end
    else
        if #s > mc then
            s = s:sub(1, mc)
        end
    end
    s = s:gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then
        return dname
    end
    return s
end

-- NUI: 通称（名前）の変更
RegisterNUICallback('setPetName', function(data, cb)
    if not stateCache or not hasPet(stateCache.pet) then
        if cb then
            cb('ok')
        end
        return
    end
    stateCache = ensureStore(stateCache)
    local raw = data and tostring(data.name or data.text or '') or ''
    local maxL = (Config and Config.PetNameMaxLength) or 12
    stateCache.pet.name = clampPetNameString(raw, maxL)
    writeStore(stateCache)
    pushNui(stateCache, nuiShowExpanded)
    if cb then
        cb('ok')
    end
end)

--- ミニ常駐を `Config.MiniPosDefault` へ戻し KVS 保存
RegisterNUICallback('resetMiniPos', function(_, cb)
    if not stateCache or not hasPet(stateCache.pet) or not isAlive(stateCache.pet) then
        if cb then
            cb('ok')
        end
        return
    end
    stateCache = ensureStore(stateCache)
    local dx, dy = getMiniDefault()
    stateCache.miniPos = { x = dx, y = dy }
    writeStore(stateCache)
    pushNui(stateCache, nuiShowExpanded)
    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('action', function(data, cb)
    if not stateCache or not hasPet(stateCache.pet) then
        if cb then
            cb('ok')
        end
        return
    end
    stateCache = ensureStore(syncWorldTime(stateCache))
    local pet = stateCache.pet
    local a = data and (data.name or data.action) or nil
    local n = nowSec()
    if not a then
        if cb then
            cb('ok')
        end
        return
    end
    if pet.phase == 'dead' or pet.phase == 'egg' then
        if cb then
            cb('ok')
        end
        return
    end
    if a ~= 'feed' and a ~= 'clean' and (pet.phase == 'sick') then
        if cb then
            cb('ok')
        end
        return
    end
    if cooldownLeft(pet, a) > 0 then
        if cb then
            cb('ok')
        end
        return
    end
    if not pet.lastAction then
        pet.lastAction = { feed = 0, play = 0, sleep = 0, clean = 0 }
    end
    if a == 'feed' then
        pet.stats.hunger = clamp((pet.stats.hunger or 0) + 18, 0, 100)
        pet.stats.mood = clamp((pet.stats.mood or 0) + 5, 0, 100)
        pet.stats.clean = clamp((pet.stats.clean or 0) - 4, 0, 100)
        pet.lastAction.feed = n
        pet.careCount = (pet.careCount or 0) + 1
        if pet.phase == 'sick' and (pet.stats.hunger or 0) > (Config.SickThreshold or 10) and pet.phaseBeforeSick then
            pet.phase = pet.phaseBeforeSick
            pet.sickAt = nil
            pet.phaseBeforeSick = nil
        end
    elseif a == 'play' and pet.phase ~= 'sick' then
        pet.stats.mood = clamp((pet.stats.mood or 0) + 15, 0, 100)
        pet.stats.stamina = clamp((pet.stats.stamina or 0) - 10, 0, 100)
        pet.stats.clean = clamp((pet.stats.clean or 0) - 5, 0, 100)
        pet.careCount = (pet.careCount or 0) + 1
        pet.lastAction.play = n
    elseif a == 'sleep' and pet.phase ~= 'sick' then
        pet.stats.stamina = clamp((pet.stats.stamina or 0) + 20, 0, 100)
        pet.stats.mood = clamp((pet.stats.mood or 0) + 2, 0, 100)
        pet.careCount = (pet.careCount or 0) + 1
        pet.lastAction.sleep = n
    elseif a == 'clean' then
        pet.stats.clean = clamp((pet.stats.clean or 0) + 20, 0, 100)
        pet.careCount = (pet.careCount or 0) + 1
        pet.lastAction.clean = n
    else
    end
    stateCache = ensureStore(syncWorldTime(stateCache))
    writeStore(stateCache)
    SendNUIMessage({ type = 'playAction', name = a, pet = stateCache.pet, sprite = getSpriteSetForPet(stateCache.pet) })
    pushNui(stateCache, nuiShowExpanded)
    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('zukan', function(data, cb)
    local o = data and (data.open == true)
    SendNUIMessage({ type = 'zukan', open = o, zukan = (stateCache and zukanListify(stateCache.zukan)) or {} })
    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('travel', function(data, cb)
    if data and (data.yes or data.confirmed) and stateCache then
        stateCache = ensureStore(stateCache)
        stateCache.pet = createNewEggPet()
        stateCache = ensureStore(syncWorldTime(stateCache))
        stateCache.noPetMenuDismissed = true
        writeStore(stateCache)
        nuiShowExpanded = true
        setNuiFocus(true)
        pushNui(stateCache, true)
    end
    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('newPetAfterDead', function(_, cb)
    if not stateCache then
        if cb then
            cb('ok')
        end
        return
    end
    stateCache = ensureStore(stateCache)
    stateCache.pet = createNewEggPet()
    stateCache = ensureStore(syncWorldTime(stateCache))
    stateCache.noPetMenuDismissed = true
    writeStore(stateCache)
    nuiShowExpanded = true
    setNuiFocus(true)
    pushNui(stateCache, true)
    if cb then
        cb('ok')
    end
end)

RegisterCommand((Config and Config.Command) or 'losmon', function()
    stateCache = readStore()
    stateCache = ensureStore(syncWorldTime(ensureStore(stateCache)))
    if not hasPet(stateCache.pet) then
        stateCache.pet = createNewEggPet()
        stateCache = ensureStore(syncWorldTime(stateCache))
        stateCache.noPetMenuDismissed = true
        writeStore(stateCache)
        nuiShowExpanded = true
        setNuiFocus(true)
        pushNui(stateCache, true)
        return
    end
    nuiShowExpanded = not nuiShowExpanded
    setNuiFocus(nuiShowExpanded)
    pushNui(stateCache, nuiShowExpanded)
end, false)

-- 歩行距離・乗車中の走行距離に応じて EXP を加算（KVS 保存。生存中のペットのみ）
CreateThread(function()
    local lastC = nil
    while true do
        Wait(1000)
        if not stateCache or not hasPet(stateCache.pet) or not isAlive(stateCache.pet) then
            lastC = nil
        else
            stateCache = ensureStore(stateCache)
            local p = stateCache.pet
            local ped = PlayerPedId()
            if not ped or ped < 1 or (IsEntityDead and IsEntityDead(ped)) then
                lastC = nil
            else
                local c = GetEntityCoords(ped, false)
                if not lastC then
                    lastC = c
                else
                    local d = vec3dist(lastC, c)
                    local cap = (type(Config) == 'table' and (Config.ExpMaxDistancePerTick or 45.0)) or 45.0
                    if d > cap then
                        d = cap
                    end
                    lastC = c
                    if d > 0.0005 then
                        local wExp = 0.0
                        if IsPedInAnyVehicle(ped, false) then
                            p.statDriveM = (p.statDriveM or 0) + d
                            wExp = d * (tonumber(Config.ExpPerMeterInVehicle) or 0) + 0.0
                        elseif IsPedOnFoot(ped) then
                            p.statWalkM = (p.statWalkM or 0) + d
                            wExp = d * (tonumber(Config.ExpPerMeterOnFoot) or 0) + 0.0
                        end
                        if wExp > 0.0 then
                            addExpToPet(p, wExp)
                            stateCache = ensureStore(syncWorldTime(stateCache))
                            writeStore(stateCache)
                            pushNui(stateCache, nuiShowExpanded)
                        end
                    end
                end
            end
        end
    end
end)

AddEventHandler('onClientResourceStart', function(name)
    if not GetCurrentResourceName or name ~= GetCurrentResourceName() then
        return
    end
    stateCache = readStore()
    stateCache = ensureStore(syncWorldTime(ensureStore(stateCache)))
    if not hasPet(stateCache.pet) then
        stateCache.pet = createNewEggPet()
        stateCache = ensureStore(syncWorldTime(stateCache))
        stateCache.noPetMenuDismissed = true
        writeStore(stateCache)
    end
    nuiShowExpanded = false
    setNuiFocus(false)
    pushNui(stateCache, false)
end)

CreateThread(function()
    while true do
        Wait(60000)
        saveAuto()
    end
end)