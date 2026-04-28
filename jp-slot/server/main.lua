-- 台占有・スピン・ジャックポット・ログ

local occupied = {} -- [machineId] = source
local playerMachine = {} -- [source] = machineId
local pendingSpin = {} -- [source] = true
--- フリースピン状態 [source] = { remaining, totalWin, lineBet }
local bonusState = {}

local KVP_JACKPOT = 'jp-slot:jackpot:pool'
local KVP_BONUS = 'jp-slot:bonus:'

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
    clearSeat(source)
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
    local mid = playerMachine[src]
    if not mid or mid ~= machineId then
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

    local bState = bonusState[src]
    local inBonus = bState and bState.remaining and bState.remaining > 0
    local effectiveBet = inBonus and 0 or bet

    if not inBonus then
        if bet < (m.minBet or 1) or bet > (m.maxBet or bet) then
            pendingSpin[src] = nil
            TriggerClientEvent('jp-slot:spinResult', src, { ok = false, reason = 'bet_range' })
            return
        end
        if Framework.getMoney(src, Config.MoneyAccount) < bet then
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
    if effectiveBet > 0 then
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
    local spinResult = RNG.spin(paytableId, opts)
    if Config.DebugSettings and Config.DebugSettings.ForceBonus and pt then
        local sym = (Config.Bonus and Config.Bonus.TriggerSymbol) or 'character'
        spinResult.reels = { sym, sym, sym }
        spinResult.payout = RNG.evaluate(spinResult.reels, pt)
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
    if tier == Config.Jackpot.triggerTier and Config.Jackpot.enabled then
        jackpotExtra = math.floor(poolAfterContrib + 0.5)
        setJackpotAmount(Config.Jackpot.seedAmount + 0.0)
    end
    local totalPay = winFlat + jackpotExtra

    if totalPay > 0 then
        Framework.addMoney(src, Config.MoneyAccount, totalPay)
    end

    local bonusPayload = nil
    if inBonus and bState then
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
            bonusPayload = {
                active = true,
                ended = true,
                totalWin = bState.totalWin,
                multiplier = multBase,
                bonusRetrigger = retrigger,
                retriggerAdd = retrigger and retrAdd or nil,
            }
            bonusState[src] = nil
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
    elseif not inBonus and Config.Bonus and Config.Bonus.Enabled and isBonusTriggerReels(reels) then
        local fs = tonumber(Config.Bonus.FreeSpins) or 8
        local multBase = tonumber(Config.Bonus.MultiplierBase) or 1
        bonusState[src] = {
            remaining = fs,
            totalWin = 0,
            lineBet = bet,
        }
        bonusPayload = {
            active = true,
            started = true,
            remaining = fs,
            totalWin = 0,
            multiplier = multBase,
        }
    end

    local cutin = { kind = 'none' }
    if mult > 0 then
        cutin = pickCutinPayload(tier)
    end

    local spinDur = (Config.Debug and Config.DebugSettings.SpinDuration) or Config.SpinDurationDefault

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
        balance = Framework.getMoney(src, Config.MoneyAccount),
        jackpot = Config.Jackpot.enabled and getJackpotAmount() or 0,
        cutin = cutin,
        spinDuration = spinDur,
        characterId = m.characterId,
        bonus = bonusPayload,
    })
end)

RegisterNetEvent('jp-slot:adminSaveTheme', function(themeData)
    local src = source
    if not IsPlayerAceAllowed(src, Config.AdminAce or 'jp-slot.admin') then
        return
    end
    if Theme.save(themeData) then
        TriggerClientEvent('jp-slot:notify', src, { kind = 'ok', msg = 'theme_saved' })
    end
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
    validatePaytableConsistency()
    local raw = GetResourceKvpString(KVP_JACKPOT)
    if not raw or raw == '' then
        setJackpotAmount(Config.Jackpot.seedAmount + 0.0)
    end
end)
