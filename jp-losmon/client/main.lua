-- jp-losmon クライアント: KVS 保存、時間経過シミュ、NUI 制御
local KVP_BLOB = 'losmon_v1'
local nuiShowExpanded = false
local stateCache = nil
--- /losmon が一度でも実行されるまで NUI へ state を送らない（起動直後のミニ表示を防ぐ。KVS 非保存）
local losmonActivated = false
-- デバッグ: 強制進化の予約状態
local debugForceEvolve = {
    target = nil,
    triggerAt = nil,
}

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
    if not id then
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

---@type fun(pet: table|nil): boolean
local isLotteryEligible
---@type fun(weights: table): string|nil
local pickByWeight
---@type fun(store: table): string|nil
local advanceAdultLottery
---@type fun(store: table, n: number): string|nil
local applyDebugForceEvolve

---@param store table
---@param n number 現在時刻
---@return number 加算したオンライン秒
local function tickOnline(store, n)
    if not store or not store.pet or not hasPet(store.pet) then
        return 0
    end
    local pet = store.pet
    local last = pet.lastOnlineAt or n
    local delta = n - last
    pet.lastOnlineAt = n
    if delta < 0 then
        return 0
    end
    local threshold = Config.OfflineThresholdSec or 120
    if delta > threshold then
        return 0
    end
    if pet.phase ~= 'dead' and pet.phase ~= 'egg' and pet.stats then
        local d = (Config.StatDecayRate or 0) * (delta / 60.0)
        pet.stats.hunger = clamp((pet.stats.hunger or 0) - d, 0, 100)
        pet.stats.mood = clamp((pet.stats.mood or 0) - d, 0, 100)
        pet.stats.stamina = clamp((pet.stats.stamina or 0) - d, 0, 100)
        pet.stats.clean = clamp((pet.stats.clean or 0) - d, 0, 100)
    end
    if pet.phase == 'egg' or pet.phase == 'baby' or pet.phase == 'child' then
        pet.phaseElapsedSec = (pet.phaseElapsedSec or 0) + delta
    end
    return delta
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
        expTotal = 0,
        statWalkM = 0,
        statDriveM = 0,
        phaseElapsedSec = 0,
        lastOnlineAt = t,
        lastLotteryAt = 0,
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

---@param pet table
---@return boolean
local function tryRecoverFromSick(pet)
    if not pet or pet.phase ~= 'sick' or not pet.phaseBeforeSick then
        return false
    end
    local h = pet.stats and (pet.stats.hunger or 0) or 0
    local c = pet.stats and (pet.stats.clean or 0) or 0
    local hT = Config.SickThreshold or 10
    local cT = Config.SickCleanThreshold or 50
    if h > hT and c >= cT then
        pet.phase = pet.phaseBeforeSick
        pet.sickAt = nil
        pet.phaseBeforeSick = nil
        return true
    end
    return false
end

---@param store table
---@param n number
---@return string|nil 進化した evolutionId
local function advancePhases(store, n)
    local pet = store.pet
    if not hasPet(pet) or not isAlive(pet) or pet.phase == 'sick' then
        return nil
    end
    local evolved = nil
    local guard = 0
    while guard < 8 do
        guard = guard + 1
        if pet.phase == 'dead' or pet.phase == 'sick' or pet.phase == 'adult' then
            break
        end
        local elapsed = pet.phaseElapsedSec or 0
        if pet.phase == 'egg' then
            local need = Config.HatchTime or 1800
            if elapsed < need then
                break
            end
            pet.phase = 'baby'
            pet.evolutionId = 'baby'
            pet.phaseElapsedSec = elapsed - need
            pet.phaseStartAt = n
            pet.careCount = 0
            zukanAdd(store.zukan, 'baby')
            evolved = 'baby'
        elseif pet.phase == 'baby' then
            local need = Config.GrowthInterval or 14400
            if elapsed < need then
                break
            end
            pet.phase = 'child'
            pet.evolutionId = 'child'
            pet.phaseElapsedSec = elapsed - need
            pet.phaseStartAt = n
            pet.careCount = 0
            pet.lastLotteryAt = 0
            zukanAdd(store.zukan, 'child')
            evolved = 'child'
        elseif pet.phase == 'child' then
            break
        else
            break
        end
    end
    return evolved
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
    do
        local zmap = { baby_a = 'baby', baby_b = 'baby', child_a = 'child', child_b = 'child' }
        for i = 1, #store.zukan do
            local zid = store.zukan[i]
            if type(zid) == 'string' and zmap[zid] then
                store.zukan[i] = zmap[zid]
            end
        end
        local seen = {}
        local newZ = {}
        for i = 1, #store.zukan do
            local zid = store.zukan[i]
            if type(zid) == 'string' and not seen[zid] then
                seen[zid] = true
                newZ[#newZ + 1] = zid
            end
        end
        store.zukan = newZ
    end
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
    if store.pet then
        if type(store.pet.phaseElapsedSec) ~= 'number' then
            store.pet.phaseElapsedSec = 0
        end
        if type(store.pet.lastOnlineAt) ~= 'number' then
            store.pet.lastOnlineAt = nowSec()
        end
        if type(store.pet.lastLotteryAt) ~= 'number' then
            store.pet.lastLotteryAt = 0
        end
        if type(store.pet.bornAt) ~= 'number' then
            store.pet.bornAt = store.pet.phaseStartAt or nowSec()
        end
        if type(store.pet.evolutionId) == 'string' then
            if store.pet.evolutionId == 'baby_a' or store.pet.evolutionId == 'baby_b' then
                store.pet.evolutionId = 'baby'
            elseif store.pet.evolutionId == 'child_a' or store.pet.evolutionId == 'child_b' then
                store.pet.evolutionId = 'child'
            elseif store.pet.evolutionId == 'sick' then
                if store.pet.phaseBeforeSick == 'baby' then
                    store.pet.evolutionId = 'baby'
                elseif store.pet.phaseBeforeSick == 'child' then
                    store.pet.evolutionId = 'child'
                elseif store.pet.phaseBeforeSick == 'adult' then
                    store.pet.evolutionId = 'adult_a'
                else
                    store.pet.evolutionId = 'baby'
                end
            end
        end
        if hasPet(store.pet) and store.pet.phase == 'egg' then
            zukanAdd(store.zukan, 'egg')
        end
    end
    return store
end

---@param store table
local function syncWorldTime(store)
    local n = nowSec()
    store = ensureStore(store)

    if store.pet and isAlive(store.pet) then
        tickOnline(store, n)
    end

    local forceEvolved = applyDebugForceEvolve(store, n)

    local evolved = nil
    if not forceEvolved and store.pet and hasPet(store.pet) and isAlive(store.pet) and store.pet.phase ~= 'sick' then
        evolved = advancePhases(store, n)
    end

    if not forceEvolved and store.pet and store.pet.phase == 'child' then
        local lotteryResult = advanceAdultLottery(store)
        if lotteryResult then
            evolved = lotteryResult
        end
    end

    if not forceEvolved then
        if store.pet and hasPet(store.pet) and isAlive(store.pet) and store.pet.phase ~= 'sick' and store.pet.phase ~= 'egg' then
            if tryEnterSick(store.pet, n) then
                zukanAdd(store.zukan, 'sick')
            end
        end
        if store.pet and store.pet.phase == 'sick' then
            if tryDeath(store.pet, n) then
                zukanAdd(store.zukan, 'grave')
            end
        end
    end

    local notify = forceEvolved or evolved
    if notify and losmonActivated then
        SendNUIMessage({
            type = 'evolve',
            evolutionId = notify,
            phase = store.pet and store.pet.phase,
            evName = (Config.FormNames and Config.FormNames[notify]) or notify,
            forced = forceEvolved ~= nil,
        })
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
    -- 病気: 直前形態のスプライト（ドクロは NUI の sick-skull 要素で重ねる）
    if pet.phase == 'sick' then
        local prevId = pet.evolutionId
        if prevId == 'sick' or not prevId or prevId == 'grave' or prevId == 'egg' then
            local pbs = pet.phaseBeforeSick
            if pbs == 'baby' then
                prevId = 'baby'
            elseif pbs == 'child' then
                prevId = 'child'
            elseif pbs == 'adult' then
                prevId = 'adult_a'
            else
                prevId = 'baby'
            end
        end
        if Config.Sprites and Config.Sprites[prevId] then
            return { mode = 'id', set = Config.Sprites[prevId] }
        end
        if Config.Sprites and Config.Sprites.baby then
            return { mode = 'id', set = Config.Sprites.baby }
        end
        return nil
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
    if Config.Sprites and Config.Sprites.baby then
        return { mode = 'id', set = Config.Sprites.baby }
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
    local cd
    if a == 'feed' then
        cd = Config.FeedCooldown or 30
    elseif a == 'play' then
        cd = Config.PlayCooldown or 60
    elseif a == 'sleep' then
        cd = Config.SleepCooldown or 120
    elseif a == 'clean' then
        cd = Config.CleanCooldown or 60
    else
        return 0
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

isLotteryEligible = function(pet)
    if not pet or pet.phase ~= 'child' then
        return false
    end
    if (pet.phaseElapsedSec or 0) < (Config.AdultLotteryMinChildSec or 1800) then
        return false
    end
    local L = levelFromTotalExp(pet.expTotal or 0)
    if L < (Config.AdultLotteryMinLevel or 5) then
        return false
    end
    local mps = (Config.MetersPerStepDisplay and Config.MetersPerStepDisplay > 0.1) and Config.MetersPerStepDisplay or 0.75
    local steps = math.floor((pet.statWalkM or 0) / mps)
    if steps < (Config.AdultLotteryMinSteps or 1000) then
        return false
    end
    return true
end

pickByWeight = function(weights)
    local total = 0
    for _, w in pairs(weights) do
        total = total + (w or 0)
    end
    if total <= 0 then
        return nil
    end
    local r = math.random() * total
    local acc = 0
    for k, w in pairs(weights) do
        acc = acc + (w or 0)
        if r <= acc then
            return k
        end
    end
    return nil
end

advanceAdultLottery = function(store)
    local pet = store.pet
    if not hasPet(pet) or pet.phase ~= 'child' then
        return nil
    end
    if not isLotteryEligible(pet) then
        return nil
    end
    local intervalSec = Config.AdultLotteryIntervalSec or 3600
    local elapsed = pet.phaseElapsedSec or 0
    local last = pet.lastLotteryAt or 0
    if (elapsed - last) < intervalSec then
        return nil
    end
    local chance = Config.AdultLotteryChancePercent or 10
    pet.lastLotteryAt = last + intervalSec
    if math.random(1, 100) > chance then
        return nil
    end
    local form = pickByWeight(Config.AdultFormWeights or { adult_a = 30, adult_b = 30, adult_c = 30, adult_d = 10 })
    if not form then
        form = 'adult_a'
    end
    pet.phase = 'adult'
    pet.evolutionId = form
    pet.phaseStartAt = nowSec()
    pet.phaseElapsedSec = 0
    pet.careCount = 0
    zukanAdd(store.zukan, form)
    return form
end

applyDebugForceEvolve = function(store, n)
    if not Config.DebugForceEvolveEnabled then
        return nil
    end
    if not debugForceEvolve.target or not debugForceEvolve.triggerAt then
        return nil
    end
    if n < debugForceEvolve.triggerAt then
        return nil
    end
    local target = debugForceEvolve.target
    if not store or not hasPet(store.pet) then
        debugForceEvolve.target = nil
        debugForceEvolve.triggerAt = nil
        return nil
    end
    local pet = store.pet
    if target == 'sick' and (pet.phase == 'sick' or pet.phase == 'dead' or pet.phase == 'egg') then
        debugForceEvolve.target = nil
        debugForceEvolve.triggerAt = nil
        return nil
    end
    debugForceEvolve.target = nil
    debugForceEvolve.triggerAt = nil
    if target == 'baby' then
        pet.phase = 'baby'
        pet.evolutionId = 'baby'
        pet.phaseElapsedSec = 0
        pet.phaseStartAt = n
        pet.careCount = 0
        pet.lastLotteryAt = 0
        pet.sickAt = nil
        pet.phaseBeforeSick = nil
    elseif target == 'child' then
        pet.phase = 'child'
        pet.evolutionId = 'child'
        pet.phaseElapsedSec = 0
        pet.phaseStartAt = n
        pet.careCount = 0
        pet.lastLotteryAt = 0
        pet.sickAt = nil
        pet.phaseBeforeSick = nil
    elseif target == 'adult_a' or target == 'adult_b' or target == 'adult_c' or target == 'adult_d' then
        pet.phase = 'adult'
        pet.evolutionId = target
        pet.phaseElapsedSec = 0
        pet.phaseStartAt = n
        pet.careCount = 0
        pet.lastLotteryAt = 0
        pet.sickAt = nil
        pet.phaseBeforeSick = nil
    elseif target == 'sick' then
        pet.phaseBeforeSick = pet.phase
        pet.phase = 'sick'
        pet.sickAt = n
        if pet.stats then
            pet.stats.hunger = math.min(pet.stats.hunger or 0, Config.SickThreshold or 10)
        end
    elseif target == 'grave' then
        pet.phase = 'dead'
        pet.evolutionId = 'grave'
        pet.sickAt = nil
        pet.phaseBeforeSick = nil
    else
        return nil
    end
    zukanAdd(store.zukan, target)
    return target
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
    if not a or not b then
        return 0.0
    end
    -- FiveM: GetEntityCoords は vector3（type は "vector3" 等。table ではない）。旧実装の table 判定で距離が常に0だった
    local function xyz(v)
        if not v or v.x == nil or v.y == nil or v.z == nil then
            return nil, nil, nil
        end
        return v.x + 0.0, v.y + 0.0, v.z + 0.0
    end
    local ax, ay, az = xyz(a)
    local bx, by, bz = xyz(b)
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
    if newL > oldL and losmonActivated then
        SendNUIMessage({ type = 'levelUp', level = newL, from = oldL })
    end
    return oldL, newL
end

---@return table, table
local function buildZukanMap()
    local zukanMap = {}
    local zukanFrames = {}
    if Config and Config.ZukanIds and Config.Sprites then
        for _, zid in ipairs(Config.ZukanIds) do
            if zid == 'sick' then
                zukanMap[zid] = '__SKULL__'
                zukanFrames[zid] = 1
            elseif Config.Sprites[zid] and Config.Sprites[zid].idle then
                zukanMap[zid] = Config.Sprites[zid].idle
                if zid == 'grave' then
                    zukanFrames[zid] = Config.GraveSpriteStripFrames or 1
                elseif zid == 'egg' then
                    zukanFrames[zid] = Config.EggSpriteStripFrames or 4
                else
                    zukanFrames[zid] = Config.SpriteStripFrames or 4
                end
            end
        end
    end
    return zukanMap, zukanFrames
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
        hLeft = math.max(0, (Config.HatchTime or 1800) - (pet.phaseElapsedSec or 0))
    end
    local nPhaseLeft = 0
    if pet and hasPet(pet) and isAlive(pet) and pet.phase == 'baby' then
        nPhaseLeft = math.max(0, (Config.GrowthInterval or 14400) - (pet.phaseElapsedSec or 0))
    end
    local zukanMap, zukanFrames = buildZukanMap()
    local al = false
    if pet and hasPet(pet) and isAlive(pet) and pet.phase ~= 'egg' and pet.phase ~= 'dead' then
        al = true
    end
    local lvf = buildLevelFields(pet)
    local nameMax = (Config and Config.PetNameMaxLength) or 12
    if nameMax < 1 then
        nameMax = 12
    end
    local notSick = pet and pet.phase ~= 'sick'
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
        zukanFrames = zukanFrames,
        formNames = Config.FormNames or {},
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
        adultLottery = (pet and pet.phase == 'child') and {
            eligible = isLotteryEligible(pet),
            intervalSec = Config.AdultLotteryIntervalSec or 3600,
            chancePercent = Config.AdultLotteryChancePercent or 10,
            nextLotteryInSec = math.max(0, ((pet.lastLotteryAt or 0) + (Config.AdultLotteryIntervalSec or 3600)) - (pet.phaseElapsedSec or 0)),
            minLevel = Config.AdultLotteryMinLevel or 5,
            minSteps = Config.AdultLotteryMinSteps or 1000,
            minChildSec = Config.AdultLotteryMinChildSec or 1800,
            currentLevel = levelFromTotalExp(pet.expTotal or 0),
            currentSteps = math.floor((pet.statWalkM or 0) / ((Config.MetersPerStepDisplay and Config.MetersPerStepDisplay > 0.1) and Config.MetersPerStepDisplay or 0.75)),
            currentChildSec = pet.phaseElapsedSec or 0,
        } or nil,
        phaseElapsedSec = pet and pet.phaseElapsedSec or 0,
        debugForceEvolve = (Config.DebugForceEvolveEnabled and debugForceEvolve.target) and {
            target = debugForceEvolve.target,
            evName = (Config.FormNames and Config.FormNames[debugForceEvolve.target]) or debugForceEvolve.target,
            remainSec = math.max(0, (debugForceEvolve.triggerAt or 0) - nowSec()),
        } or nil,
        debugEnabled = Config.DebugForceEvolveEnabled and true or false,
        debugTargets = Config.DebugForceEvolveEnabled and (Config.DebugEvolveTargets) or nil,
        cooldowns = {
            feed = al and cooldownLeft(pet, 'feed') or 0,
            play = (al and notSick) and cooldownLeft(pet, 'play') or 0,
            sleep = (al and notSick) and cooldownLeft(pet, 'sleep') or 0,
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
    if not losmonActivated then
        return
    end
    SendNUIMessage(nuiStatePayload(stateCache, ex))
end

---@param focus boolean
local function setNuiFocus(focus)
    if SetNuiFocus then
        if focus then
            SetNuiFocus(true, true)
        else
            SetNuiFocus(false, false)
        end
    end
end

local function saveAuto()
    if not stateCache then
        return
    end
    -- オフライン化前の最終保存・tickOnline 経由の進行反映用（60秒ごと）
    stateCache = ensureStore(syncWorldTime(ensureStore(stateCache)))
    writeStore(stateCache)
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
        if pet.phase ~= 'sick' then
            pet.careCount = (pet.careCount or 0) + 1
        end
        tryRecoverFromSick(pet)
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
        if pet.phase ~= 'sick' then
            pet.careCount = (pet.careCount or 0) + 1
        end
        pet.lastAction.clean = n
        tryRecoverFromSick(pet)
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
    if stateCache then
        stateCache = ensureStore(syncWorldTime(ensureStore(stateCache)))
    end
    local zm, zf = buildZukanMap()
    local zids = (Config and Config.ZukanIds) or {}
    SendNUIMessage({
        type = 'zukan',
        open = o,
        zukan = (stateCache and zukanListify(stateCache.zukan)) or {},
        zukanMap = zm,
        zukanIds = zids,
        zukanFrames = zf,
        formNames = Config.FormNames or {},
    })
    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('debugForceEvolve', function(data, cb)
    if not Config.DebugForceEvolveEnabled then
        if cb then
            cb('disabled')
        end
        return
    end
    if not stateCache or not hasPet(stateCache.pet) then
        if cb then
            cb('nopet')
        end
        return
    end
    local target = data and tostring(data.target or '') or ''
    if target == '' then
        if cb then
            cb('notarget')
        end
        return
    end
    local allowed = false
    for _, v in ipairs(Config.DebugEvolveTargets or {}) do
        if v == target then
            allowed = true
            break
        end
    end
    if not allowed then
        if cb then
            cb('invalid')
        end
        return
    end
    local pet = stateCache.pet
    if target == 'sick' and (pet.phase == 'sick' or pet.phase == 'dead' or pet.phase == 'egg') then
        SendNUIMessage({
            type = 'debugEvolveRejected',
            target = target,
            reason = 'invalid_phase',
        })
        if cb then
            cb('invalid_phase')
        end
        return
    end
    local delay = Config.DebugForceEvolveDelaySec or 10
    debugForceEvolve.target = target
    debugForceEvolve.triggerAt = nowSec() + delay
    SendNUIMessage({
        type = 'debugEvolveScheduled',
        target = target,
        evName = (Config.FormNames and Config.FormNames[target]) or target,
        delaySec = delay,
    })
    if stateCache then
        stateCache = ensureStore(stateCache)
        pushNui(stateCache, nuiShowExpanded)
    end
    if cb then
        cb('ok')
    end
end)

RegisterNUICallback('debugCancelForceEvolve', function(_, cb)
    debugForceEvolve.target = nil
    debugForceEvolve.triggerAt = nil
    SendNUIMessage({ type = 'debugEvolveCancelled' })
    if stateCache then
        stateCache = ensureStore(stateCache)
        pushNui(stateCache, nuiShowExpanded)
    end
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
    losmonActivated = true
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

-- 2 秒ごと: 孵化・成長の time 通過をクライアント常時に反映（静止中でも卵が孵る）
CreateThread(function()
    while true do
        Wait(2000)
        if not stateCache or not hasPet(stateCache.pet) or not isAlive(stateCache.pet) then
        else
            stateCache = ensureStore(stateCache)
            local was = stateCache.pet.phase
            stateCache = syncWorldTime(stateCache)
            local nowP = stateCache.pet
            if nowP and (was ~= nowP.phase) then
                writeStore(stateCache)
            end
            if nowP and (nowP.phase == 'egg' or nowP.phase == 'baby' or nowP.phase == 'child') then
                pushNui(stateCache, nuiShowExpanded)
            end
        end
    end
end)

-- デバッグ: 強制進化の発火を 0.5 秒粒度で拾う
CreateThread(function()
    while true do
        Wait(500)
        if debugForceEvolve.triggerAt and stateCache and hasPet(stateCache.pet) then
            local n = nowSec()
            if n >= (debugForceEvolve.triggerAt or 0) then
                stateCache = ensureStore(syncWorldTime(stateCache))
                writeStore(stateCache)
                pushNui(stateCache, nuiShowExpanded)
            end
        end
    end
end)

-- デバッグ: 残り秒表示の再送（1 秒）
CreateThread(function()
    while true do
        Wait(1000)
        if
            (Config and Config.DebugForceEvolveEnabled)
            and debugForceEvolve
            and debugForceEvolve.triggerAt
            and stateCache
            and hasPet(stateCache.pet)
        then
            stateCache = ensureStore(stateCache)
            pushNui(stateCache, nuiShowExpanded)
        end
    end
end)

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
end)

CreateThread(function()
    while true do
        Wait(60000)
        saveAuto()
    end
end)