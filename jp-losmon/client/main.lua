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
        return (Config and Config.EggSpriteStripFrames) or 1
    end
    if pet.phase == 'dead' or pet.evolutionId == 'grave' then
        return (Config and Config.GraveSpriteStripFrames) or 1
    end
    return (Config and Config.SpriteStripFrames) or 4
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