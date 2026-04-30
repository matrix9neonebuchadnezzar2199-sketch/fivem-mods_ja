-- 台占有・スピン・ジャックポット・ログ

local occupied = {} -- [machineId] = source
local playerMachine = {} -- [source] = machineId
local pendingSpin = {} -- [source] = true
--- フリースピン状態 [source] = { remaining, totalWin, lineBet, promote, streakCount, bigConsumed, effectMode }
local bonusState = {}
--- ボーナス終了後のクールタイム（通常スピン回数）— 残り > 0 の間は miss_tease のみ
local cooldownState = {}

--- 管理プレビューモード（所持金変動なし・演出のみ）— `JpSlotPreviewMode` は server/admin.lua で定義
---@param src number
---@return boolean
local function isPreviewMode(src)
    local pm = rawget(_G, 'JpSlotPreviewMode')
    return type(pm) == 'table' and pm[src] == true
end

local KVP_JACKPOT = 'jp-slot:jackpot:pool'
local KVP_BONUS = 'jp-slot:bonus:'

--- アクティブ演出プリセットから Config.Master を上書き（未設定時は config_shared 既定）
function applyMasterFromActivePreset()
    Config.Master = Config.Master or {}
    local cid, pname = JpSlotParseActivePresetRef()
    if not cid or not pname then
        return
    end
    local raw = GetResourceKvpString(JpSlotPresetBodyKvpKey(cid, pname))
    if not raw or raw == '' then
        return
    end
    local ok, preset = pcall(json.decode, raw)
    if not ok or type(preset) ~= 'table' or type(preset.master) ~= 'table' then
        return
    end
    local m = preset.master
    Config.Master.Normal = Config.Master.Normal or {}
    Config.Master.BonusPromote = Config.Master.BonusPromote or {}
    Config.Master.Cooldown = Config.Master.Cooldown or {}
    if m.normal then
        if m.normal.win ~= nil then
            Config.Master.Normal.Win = tonumber(m.normal.win) or Config.Master.Normal.Win
        end
        if m.normal.bonus ~= nil then
            Config.Master.Normal.Bonus = tonumber(m.normal.bonus) or Config.Master.Normal.Bonus
        end
        if m.normal.miss_tease ~= nil then
            Config.Master.Normal.MissTease = tonumber(m.normal.miss_tease) or Config.Master.Normal.MissTease
        end
    end
    if m.bonus_promote then
        local bp = m.bonus_promote
        if bp.streak ~= nil then
            Config.Master.BonusPromote.Streak = tonumber(bp.streak) or Config.Master.BonusPromote.Streak
        end
        if bp.big ~= nil then
            Config.Master.BonusPromote.Big = tonumber(bp.big) or Config.Master.BonusPromote.Big
        end
        if bp.max_streak ~= nil then
            Config.Master.BonusPromote.MaxStreak = tonumber(bp.max_streak) or Config.Master.BonusPromote.MaxStreak
        end
        if bp.big_multiplier ~= nil then
            Config.Master.BonusPromote.BigMultiplier = tonumber(bp.big_multiplier) or Config.Master.BonusPromote.BigMultiplier
        end
    end
    if m.cooldown and m.cooldown.spins ~= nil then
        Config.Master.Cooldown.Spins = tonumber(m.cooldown.spins) or Config.Master.Cooldown.Spins
    end
end

ApplyJpSlotMasterFromPreset = applyMasterFromActivePreset

--- 演出プリセットから effectBlocks を取得（クライアント演出連鎖用）
---@param sceneKey string
---@return table|nil
local function getEffectBlocksForScene(sceneKey)
    if not sceneKey or sceneKey == '' then
        return nil
    end
    local cid, pname = JpSlotParseActivePresetRef()
    if not cid or not pname then
        return nil
    end
    local raw = GetResourceKvpString(JpSlotPresetBodyKvpKey(cid, pname))
    if not raw or raw == '' then
        return nil
    end
    local ok, preset = pcall(json.decode, raw)
    if not ok or type(preset) ~= 'table' then
        return nil
    end
    local eff = preset.effects and preset.effects[sceneKey]
    if type(eff) ~= 'table' then
        return nil
    end
    return eff
end

---@param src number
---@return string
local function identifierOf(src)
    if Framework and Framework.getPrimaryIdentifier then
        local id = Framework.getPrimaryIdentifier(src)
        if id and id ~= '' then
            return id
        end
    end
    local ids = GetPlayerIdentifiers(src)
    if ids then
        for i = 1, #ids do
            local id = ids[i]
            if id and string.sub(id, 1, 8) == 'license:' then
                return id
            end
        end
    end
    return tostring(src)
end

---@param src number
local function saveBonus(src)
    local b = bonusState[src]
    local id = identifierOf(src)
    if not id then
        return
    end
    if not b or (b.remaining or 0) <= 0 then
        SetResourceKvp(KVP_BONUS .. id, '')
        return
    end
    SetResourceKvp(KVP_BONUS .. id, json.encode(b))
end

---@param src number
local function loadBonus(src)
    local id = identifierOf(src)
    if not id then
        return
    end
    local raw = GetResourceKvpString(KVP_BONUS .. id)
    if not raw or raw == '' then
        return
    end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == 'table' and (decoded.remaining or 0) > 0 then
        bonusState[src] = decoded
    end
end

--- ジャックポット累積額を取得
---@return number
local function getJackpotAmount()
    local raw = GetResourceKvpString(KVP_JACKPOT)
    if not raw or raw == '' then
        return (Config.Jackpot.seedAmount or 0) + 0.0
    end
    local n = tonumber(raw)
    return n and (n + 0.0) or (Config.Jackpot.seedAmount + 0.0)
end

---@param amount number
local function setJackpotAmount(amount)
    SetResourceKvp(KVP_JACKPOT, tostring(math.floor(amount + 0.5)))
end

--- machineId が存在するか（静的 Config + 動的 KVS）
---@param machineId string|nil
---@return table|nil
local function findMachine(machineId)
    if not machineId then
        return nil
    end
    local list = Config.Machines or {}
    for i = 1, #list do
        if list[i].id == machineId then
            return list[i]
        end
    end
    return DynamicMachines.get(machineId)
end

--- アクティブ演出プリセットに characterId があれば素材解決に優先（台の characterId はフォールバック）
---@param machine table|nil
---@return string
local function jpSlotEffectiveCharacterIdForSeat(machine)
    local def = (Config.Characters and Config.Characters.DefaultId) or 'luna'
    if not machine then
        return def
    end
    local pcid, ppname = JpSlotParseActivePresetRef()
    if pcid and ppname then
        local praw = GetResourceKvpString(JpSlotPresetBodyKvpKey(pcid, ppname))
        if praw and praw ~= '' then
            local ok, preset = pcall(json.decode, praw)
            if ok and type(preset) == 'table' and type(preset.characterId) == 'string' and preset.characterId ~= '' then
                if JpSlotCharacterIdValid(preset.characterId) then
                    return preset.characterId
                end
            end
        end
    end
    return machine.characterId or def
end

local function checkLegacyAssetPaths()
    local res = GetCurrentResourceName()
    -- 旧ルートのみ（html/assets/characters/<id>/ 配下は新方式のため含めない）
    local legacy = {
        'html/assets/cutins/img_01.png',
        'html/assets/back.jpg',
    }
    for _, p in ipairs(legacy) do
        if LoadResourceFile(res, p) then
            print(('[jp-slot][WARN] legacy asset path detected: %s'):format(p))
            print('[jp-slot][WARN] run tools/migrate_assets.ps1 or move assets under html/assets/characters/<id>/')
        end
    end
end

--- カットイン1種を選ぶ（サーバー権威）
---@param payoutTier string|nil
---@return table
local function pickCutinPayload(payoutTier)
    local key = payoutTier
    if not key or key == '' then
        key = 'win'
    end
    local probs = Config.EffectProbabilities[key]
    if not probs then
        probs = Config.EffectProbabilities.win
    end
    if not probs then
        return { kind = 'none' }
    end
    local order = { 'cutin_image', 'cutin_video', 'none' }
    local weights = {}
    local keys = {}
    for i = 1, #order do
        local k = order[i]
        local w = tonumber(probs[k])
        if w and w > 0 then
            keys[#keys + 1] = k
            weights[#weights + 1] = w
        end
    end
    if #keys == 0 then
        return { kind = 'none' }
    end
    local choice = RNG.pickWeighted(weights, keys)
    if choice == 'none' or not choice then
        return { kind = 'none' }
    end
    local poolName = (choice == 'cutin_image') and 'images' or 'videos'
    local pool = (Config.Cutins[poolName] or {})
    local filtered = {}
    local wts = {}
    for i = 1, #pool do
        local item = pool[i]
        local tiers = item.tiers or {}
        local ok = false
        for t = 1, #tiers do
            if tiers[t] == payoutTier then
                ok = true
                break
            end
        end
        if ok then
            filtered[#filtered + 1] = item
            wts[#wts + 1] = tonumber(item.weight) or 1
        end
    end
    if #filtered == 0 then
        return { kind = 'none' }
    end
    local pick = RNG.pickWeighted(wts, filtered)
    if not pick then
        return { kind = 'none' }
    end
    return {
        kind = choice,
        asset = pick,
    }
end

---@return string|nil
local function transactionLogPath()
    local base = GetResourcePath(GetCurrentResourceName())
    if not base then
        return nil
    end
    local d = os.date('%Y%m%d')
    return base .. '/server/logs/transactions-' .. d .. '.jsonl'
end

--- JSONL 追記（失敗時は無視・日次ファイル）
---@param obj table
local function appendTransactionLog(obj)
    if not Config.TransactionLog then
        return
    end
    local path = transactionLogPath()
    if not path then
        return
    end
    pcall(function()
        local f = io.open(path, 'a')
        if f then
            f:write(json.encode(obj) .. '\n')
            f:close()
        end
    end)
end

---@param source number
local function clearSeat(source)
    saveBonus(source)
    local mid = playerMachine[source]
    if mid then
        occupied[mid] = nil
        playerMachine[source] = nil
    end
    pendingSpin[source] = nil
    bonusState[source] = nil
    cooldownState[source] = nil
end

--- 中段3リールがボーナストリガーか（絵柄の一致数）
---@param reels string[]
---@return boolean
local function isBonusTriggerReels(reels)
    if not Config.Bonus or not Config.Bonus.Enabled then
        return false
    end
    local sym = Config.Bonus.TriggerSymbol or 'character'
    local need = tonumber(Config.Bonus.TriggerCount) or 3
    local n = 0
    for i = 1, #reels do
        if reels[i] == sym then
            n = n + 1
        end
    end
    return n >= need
end

--- 動的台撤去時に着席者を安全に外す（commands から呼ぶ）
---@param machineId string|nil
---@param reason string|nil
function JpSlotForceLeaveOccupant(machineId, reason)
    local occ = occupied[machineId]
    if not occ then
        return
    end
    TriggerClientEvent('jp-slot:forceLeave', occ, { reason = reason or 'machine_removed' })
    clearSeat(occ)
end

AddEventHandler('playerDropped', function()
    local src = source
    if _G.JpSlotPreviewMode then
        _G.JpSlotPreviewMode[src] = nil
    end
    clearSeat(src)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    local plist = GetPlayers()
    for i = 1, #plist do
        local sid = tonumber(plist[i])
        if sid then
            saveBonus(sid)
        end
    end
    if DynamicMachines and DynamicMachines.save then
        DynamicMachines.save()
    end
end)

RegisterNetEvent('jp-slot:requestSeat', function(machineId)
    local src = source
    machineId = type(machineId) == 'string' and machineId or nil
    local m = findMachine(machineId)
    if not m then
        TriggerClientEvent('jp-slot:seatDenied', src, { reason = 'invalid_machine' })
        return
    end
    local occ = occupied[machineId]
    if occ and occ ~= src then
        TriggerClientEvent('jp-slot:seatDenied', src, { reason = 'busy' })
        return
    end
    clearSeat(src)
    occupied[machineId] = src
    playerMachine[src] = machineId
    loadBonus(src)
    local theme = Theme.getActive()
    local jackpot = Config.Jackpot.enabled and getJackpotAmount() or 0
    local paytableId = m.paytableId or 'normal'
    local pt = Config.Paytables and Config.Paytables[paytableId] or {}
    local hypeKey = (Config.Marquee and Config.Marquee.HypeKey) or 'marquee.hype'
    local infoKey = (Config.Marquee and Config.Marquee.InfoKey) or 'marquee.info'
    local cid = jpSlotEffectiveCharacterIdForSeat(m)
    local manifest = JpSlotLoadCharacterManifest(cid)
    TriggerClientEvent('jp-slot:seatGranted', src, {
        machine = m,
        theme = theme,
        jackpot = jackpot,
        balance = Framework.getMoney(src, Config.MoneyAccount),
        spinDuration = (Config.Debug and Config.DebugSettings.SpinDuration) or Config.SpinDurationDefault,
        uiSize = JpSlotGetUISize(),
        marquee = {
            hype = Locales.getList(hypeKey) or {},
            info = Locales.getList(infoKey) or {},
        },
        symbolIds = pt.symbols
            or { 'cherry', 'bell', 'watermelon', 'bar', 'seven', 'wild', 'character' },
        character = manifest,
        characterBasePath = ('characters/%s/'):format(cid),
        characterId = cid,
    })
end)

RegisterNetEvent('jp-slot:leaveSeat', function()
    clearSeat(source)
end)

RegisterNetEvent('jp-slot:spin', function(payload)
    local src = source
    if pendingSpin[src] then
        return
    end
    payload = type(payload) == 'table' and payload or {}
    local machineId = payload.machineId
    local bet = math.floor(tonumber(payload.bet) or 0)
    local embedPreview = payload.embedPreview == true
    local mid = playerMachine[src]

    --- NUI 埋め込みプレビュー：席なしでもプレビューモード中は仮席として指定台でスピン可
    if embedPreview and isPreviewMode(src) then
        machineId = machineId or (Config.Machines[1] and Config.Machines[1].id)
        if not machineId then
            pendingSpin[src] = nil
            TriggerClientEvent('jp-slot:spinResult', src, { ok = false, reason = 'machine' })
            return
        end
        playerMachine[src] = machineId
        mid = machineId
    elseif not mid or mid ~= machineId then
        pendingSpin[src] = nil
        TriggerClientEvent('jp-slot:spinResult', src, { ok = false, reason = 'seat' })
        return
    end
    local m = findMachine(machineId)
    if not m then
        pendingSpin[src] = nil
        TriggerClientEvent('jp-slot:spinResult', src, { ok = false, reason = 'machine' })
        return
    end

    local isPreview = isPreviewMode(src)

    local bState = bonusState[src]
    local inBonus = not isPreview and bState and bState.remaining and bState.remaining > 0
    local effectiveBet = inBonus and 0 or bet

    if not inBonus then
        if bet < (m.minBet or 1) or bet > (m.maxBet or bet) then
            pendingSpin[src] = nil
            TriggerClientEvent('jp-slot:spinResult', src, { ok = false, reason = 'bet_range' })
            return
        end
        if not isPreview and Framework.getMoney(src, Config.MoneyAccount) < bet then
            pendingSpin[src] = nil
            TriggerClientEvent('jp-slot:spinResult', src, { ok = false, reason = 'money' })
            return
        end
    else
        if bet < (m.minBet or 1) or bet > (m.maxBet or bet) then
            pendingSpin[src] = nil
            TriggerClientEvent('jp-slot:spinResult', src, { ok = false, reason = 'bet_range' })
            return
        end
    end

    pendingSpin[src] = true

    local poolAfterContrib = getJackpotAmount()
    if not isPreview and effectiveBet > 0 then
        if not Framework.removeMoney(src, Config.MoneyAccount, effectiveBet) then
            pendingSpin[src] = nil
            TriggerClientEvent('jp-slot:spinResult', src, { ok = false, reason = 'money' })
            return
        end
        if Config.Jackpot.enabled then
            local add = math.floor(effectiveBet * (Config.Jackpot.contributionRate or 0))
            poolAfterContrib = poolAfterContrib + add
            setJackpotAmount(poolAfterContrib)
        end
    end

    local opts = {}
    if Config.Debug and Config.DebugSettings then
        if Config.DebugSettings.ForceJackpot then
            opts.forceJackpot = true
        elseif Config.DebugSettings.ForceWinNext then
            opts.forceWin = true
        end
    end

    local paytableId = m.paytableId or 'normal'
    local pt = Config.Paytables and Config.Paytables[paytableId]
    local spinResult
    local masterScene ---@type string|nil

    if not inBonus then
        local cd = tonumber(cooldownState[src]) or 0
        if not isPreview and cd > 0 then
            cooldownState[src] = cd - 1
            spinResult = RNG.spin(paytableId, { forceLoss = true })
            masterScene = 'miss_tease'
        else
            local M = Config.Master or {}
            local N = M.Normal or {}
            local w = tonumber(N.Win) or 25.0
            local b = tonumber(N.Bonus) or 5.0
            local mt = tonumber(N.MissTease) or 70.0
            local roll = math.random() * 100
            if roll < w then
                if not opts.forceJackpot then
                    opts.forceWin = true
                end
                spinResult = RNG.spin(paytableId, opts)
                masterScene = 'win'
            elseif roll < w + b then
                local BP = M.BonusPromote or {}
                local ps = tonumber(BP.Streak) or 30.0
                local pb = tonumber(BP.Big) or 5.0
                local sub = math.random() * 100
                local promote = nil
                if sub < ps then
                    promote = 'streak'
                elseif sub < ps + pb then
                    promote = 'big'
                end
                local sym = (Config.Bonus and Config.Bonus.TriggerSymbol) or 'character'
                local reels = { sym, sym, sym }
                spinResult = {
                    reels = reels,
                    payout = {
                        multiplier = 0,
                        tier = 'bonus',
                        comboName = 'bonus_entry',
                    },
                    paytableId = paytableId,
                }
                local fs = tonumber(Config.Bonus.FreeSpins) or 8
                bonusState[src] = {
                    remaining = fs,
                    totalWin = 0,
                    lineBet = bet,
                    promote = promote,
                    streakCount = promote == 'streak' and 1 or 0,
                    bigConsumed = false,
                    effectMode = promote == 'big' and 'bonus_big' or (promote == 'streak' and 'bonus_streak' or 'bonus'),
                }
                masterScene = 'bonus'
            else
                spinResult = RNG.spin(paytableId, { forceLoss = true })
                masterScene = 'miss_tease'
            end
        end
        if Config.DebugSettings and Config.DebugSettings.ForceBonus and pt and bonusState[src] == nil then
            local sym = (Config.Bonus and Config.Bonus.TriggerSymbol) or 'character'
            spinResult.reels = { sym, sym, sym }
            spinResult.payout = {
                multiplier = 0,
                tier = 'bonus',
                comboName = 'bonus_entry',
            }
            local fs = tonumber(Config.Bonus.FreeSpins) or 8
            bonusState[src] = {
                remaining = fs,
                totalWin = 0,
                lineBet = bet,
                promote = nil,
                streakCount = 0,
                bigConsumed = false,
                effectMode = 'bonus',
            }
            masterScene = 'bonus'
        end
    else
        spinResult = RNG.spin(paytableId, opts)
        local em = bState and bState.effectMode
        if em == 'bonus_streak' then
            masterScene = 'bonus_streak'
        elseif em == 'bonus_big' then
            masterScene = 'bonus_big'
        else
            masterScene = 'bonus'
        end
    end

    local reels = spinResult.reels or { 'cherry', 'cherry', 'cherry' }
    local payout = spinResult.payout or {}
    local mult = tonumber(payout.multiplier) or 0
    local tier = payout.tier

    local lineBetForWin = bet
    if inBonus and bState.lineBet then
        lineBetForWin = bState.lineBet
    end

    local winFlat = math.floor(lineBetForWin * mult)
    if inBonus and Config.Bonus and Config.Bonus.Enabled then
        winFlat = math.floor(winFlat * (tonumber(Config.Bonus.MultiplierBase) or 1))
    end

    local jackpotExtra = 0
    if not isPreview and tier == Config.Jackpot.triggerTier and Config.Jackpot.enabled then
        jackpotExtra = math.floor(poolAfterContrib + 0.5)
        setJackpotAmount(Config.Jackpot.seedAmount + 0.0)
    end
    local totalPay = winFlat + jackpotExtra

    if not isPreview and totalPay > 0 then
        Framework.addMoney(src, Config.MoneyAccount, totalPay)
    end

    local bonusPayload = nil
    if not isPreview and inBonus and bState then
        bState.remaining = (bState.remaining or 0) - 1
        bState.totalWin = (bState.totalWin or 0) + totalPay
        local retrigger = false
        if Config.Bonus.RetriggerEnable and isBonusTriggerReels(reels) then
            bState.remaining = bState.remaining + (tonumber(Config.Bonus.RetriggerAdd) or 0)
            retrigger = true
        end
        local multBase = tonumber(Config.Bonus.MultiplierBase) or 1
        local retrAdd = tonumber(Config.Bonus.RetriggerAdd) or 0
        if bState.remaining <= 0 then
            local BP = (Config.Master and Config.Master.BonusPromote) or {}
            local maxStr = tonumber(BP.MaxStreak) or 3
            local fs = tonumber(Config.Bonus.FreeSpins) or 8
            local bigM = tonumber(BP.BigMultiplier) or 10
            local promote = bState.promote

            local function endBonusSession()
                bonusPayload = {
                    active = true,
                    ended = true,
                    totalWin = bState.totalWin,
                    multiplier = multBase,
                    bonusRetrigger = retrigger,
                    retriggerAdd = retrigger and retrAdd or nil,
                }
                bonusState[src] = nil
                if not isPreview then
                    cooldownState[src] = tonumber(((Config.Master or {}).Cooldown or {}).Spins) or 5
                end
            end

            if promote == 'streak' and (bState.streakCount or 1) < maxStr then
                bState.streakCount = (bState.streakCount or 1) + 1
                bState.remaining = fs
                bState.promote = 'streak'
                bState.effectMode = 'bonus_streak'
                bonusPayload = {
                    active = true,
                    remaining = bState.remaining,
                    totalWin = bState.totalWin,
                    multiplier = multBase,
                    bonusRetrigger = retrigger,
                    retriggerAdd = retrigger and retrAdd or nil,
                    streakContinue = true,
                }
            elseif promote == 'big' and not bState.bigConsumed then
                bState.bigConsumed = true
                bState.remaining = fs * bigM
                bState.promote = nil
                bState.effectMode = 'bonus_big'
                bonusPayload = {
                    active = true,
                    remaining = bState.remaining,
                    totalWin = bState.totalWin,
                    multiplier = multBase,
                    bonusRetrigger = retrigger,
                    retriggerAdd = retrigger and retrAdd or nil,
                    bigContinue = true,
                }
            else
                endBonusSession()
            end
        else
            bonusPayload = {
                active = true,
                remaining = bState.remaining,
                totalWin = bState.totalWin,
                multiplier = multBase,
                bonusRetrigger = retrigger,
                retriggerAdd = retrigger and retrAdd or nil,
            }
        end
    elseif not isPreview and not inBonus and bonusState[src] and masterScene == 'bonus' then
        local multBase = tonumber(Config.Bonus.MultiplierBase) or 1
        bonusPayload = {
            active = true,
            started = true,
            remaining = bonusState[src].remaining,
            totalWin = 0,
            multiplier = multBase,
        }
    end

    local cutin = { kind = 'none' }
    if mult > 0 then
        cutin = pickCutinPayload(tier)
    end

    local spinDur = (Config.Debug and Config.DebugSettings.SpinDuration) or Config.SpinDurationDefault

    if not isPreview then
        appendTransactionLog({
            t = os.time(),
            src = src,
            machineId = machineId,
            bet = effectiveBet,
            reels = reels,
            multiplier = mult,
            tier = tier,
            paid = totalPay,
            jackpotExtra = jackpotExtra,
            bonus = bonusPayload,
        })
    end

    saveBonus(src)
    pendingSpin[src] = nil

    TriggerClientEvent('jp-slot:spinResult', src, {
        ok = true,
        reels = reels,
        multiplier = mult,
        tier = tier,
        comboName = payout.comboName,
        winAmount = totalPay,
        bet = bet,
        effectiveBet = effectiveBet,
        -- balance は実所持金。埋め込みプレビュー NUI は previewMode 時にこれを使わず表示のみ演算する（html/js/app.js）
        balance = Framework.getMoney(src, Config.MoneyAccount),
        jackpot = Config.Jackpot.enabled and getJackpotAmount() or 0,
        cutin = cutin,
        spinDuration = spinDur,
        characterId = jpSlotEffectiveCharacterIdForSeat(m),
        bonus = bonusPayload,
        previewMode = isPreview or nil,
        effectScene = masterScene,
        effectBlocks = getEffectBlocksForScene(masterScene),
    })
end)

--- Paytables と PaytableDisplay の倍率・コンボが一致しているか（運用ミス検知）
local function validatePaytableConsistency()
    if type(Config.Paytables) ~= 'table' or type(Config.PaytableDisplay) ~= 'table' then
        return
    end
    for ptId, pt in pairs(Config.Paytables) do
        if type(pt) == 'table' and type(pt.payouts) == 'table' then
            local display = Config.PaytableDisplay[ptId]
            local dispList = display and display.payouts
            if type(dispList) ~= 'table' then
                print(('[jp-slot] WARN PaytableDisplay が無いか payouts 空です: %s'):format(tostring(ptId)))
            else
                for _, payout in ipairs(pt.payouts) do
                    local combo = payout.combo
                    local mult = tonumber(payout.multiplier)
                    local found = false
                    for _, disp in ipairs(dispList) do
                        if disp.combo == combo and tonumber(disp.multiplier) == mult then
                            found = true
                            break
                        end
                    end
                    if not found then
                        print(('[jp-slot] WARN PaytableDisplay と不一致: id=%s combo=%s mult=%s'):format(
                            tostring(ptId), tostring(combo), tostring(mult)))
                    end
                end
            end
        end
    end
end

--- 起動時ジャックポット初期化（未設定ならシード）＋配当表整合チェック
CreateThread(function()
    Wait(500)
    checkLegacyAssetPaths()
    JpSlotMigratePresetsV2()
    applyMasterFromActivePreset()
    validatePaytableConsistency()
    local raw = GetResourceKvpString(KVP_JACKPOT)
    if not raw or raw == '' then
        setJackpotAmount(Config.Jackpot.seedAmount + 0.0)
    end
end)
