-- ============================================================
-- jp-meridian9 / server/result.lua
-- ============================================================
-- 任務リザルト: 脱出時査定・付与・ログ。死亡/切断の記録。クライアントは NUI（`result:show`）。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Result = MRD9.Result or {}

---@return string
local function creditItemId()
    local c = Config.Currencies and Config.Currencies.mrd9_credit
    if type(c) == 'table' and type(c.id) == 'string' and c.id ~= '' then
        return c.id
    end
    return 'mrd9_credit'
end

---@return integer
local function creditUnitValue()
    return math.max(1, math.floor(tonumber(Config.Result and Config.Result.creditUnitValue) or 1000))
end

---@param session table|nil
---@return string|nil
local function resolveMissionId(session)
    if not session then
        return nil
    end
    if session.contractId then
        return tostring(session.contractId)
    end
    if session.mission and session.mission.type then
        return tostring(session.mission.type)
    end
    return nil
end

---@param row table|nil
local function writeResultLog(row)
    if not row then
        return
    end
    local ok, err = pcall(function()
        MySQL.insert.await(
            [[INSERT INTO mrd9_result_logs
                (player_identifier, session_id, mission_id, result,
                 items_subtotal, fiction_bounty, extraction_bonus, total,
                 credit_count, item_count, fiction_item_count,
                 payout_mode, fail_reason)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
            {
                row.identifier or 'unknown',
                row.sessionId or '',
                row.missionId,
                row.result or 'unknown',
                row.itemsSubtotal or 0,
                row.fictionBounty or 0,
                row.extractionBonus or 0,
                row.total or 0,
                row.creditCount or 0,
                row.itemCount or 0,
                row.fictionItemCount or 0,
                row.payoutMode or 'unknown',
                row.failReason,
            }
        )
    end)
    if not ok then
        print(('[jp-meridian9] mrd9_result_logs insert failed: %s'):format(tostring(err)))
    end
end

---@param src integer
---@param payload table
local function triggerResultNui(src, payload)
    if type(src) ~= 'number' or src <= 0 or type(payload) ~= 'table' then
        return
    end
    TriggerClientEvent('jp-meridian9:client:result:show', src, payload)
end

---@param def table|nil
---@return integer
local function baseValueFor(def)
    if not def then
        return 0
    end
    if def.value and tonumber(def.value) then
        return math.floor(tonumber(def.value))
    end
    local t = (Config.Result and Config.Result.baseValueByTier) or {}
    local r = type(def.rarity) == 'string' and def.rarity or 'common'
    return math.floor(tonumber(t[r]) or 0)
end

---@param fictionTag string|nil
---@return integer
local function fictionBountyFor(fictionTag)
    if type(fictionTag) ~= 'string' or fictionTag == '' then
        return 0
    end
    local map = (Config.Result and Config.Result.fictionBounty) or {}
    return math.floor(tonumber(map[fictionTag]) or 0)
end

---@param session table
---@param src integer
---@return table entries, integer itemsSubtotal, integer fictionBounty, integer itemCount, integer fictionItemCount
local function buildItemEntries(session, src)
    local entries = {}
    local itemsSubtotal, fictionBounty = 0, 0
    local itemCount, fictionItemCount = 0, 0
    session.inventory = session.inventory or {}
    local invSrc = session.inventory[src] or {}
    local flat = MRD9.FlattenMissionInventory(invSrc)
    for itemId, count in pairs(flat) do
        count = math.floor(tonumber(count) or 0)
        if count > 0 then
            local def = MRD9.Loot and MRD9.Loot.FindItemDef and MRD9.Loot.FindItemDef(itemId) or nil
            if def and def.fictionTag then
                local bountyPer = fictionBountyFor(def.fictionTag)
                local bounty = bountyPer * count
                fictionBounty = fictionBounty + bounty
                fictionItemCount = fictionItemCount + count
                entries[#entries + 1] = {
                    itemId = itemId,
                    nameKey = def.nameKey,
                    label = def.name or itemId,
                    count = count,
                    tier = def.rarity or 'common',
                    confiscated = true,
                    bounty = bounty,
                }
            elseif def then
                local unit = baseValueFor(def)
                local sub = unit * count
                itemsSubtotal = itemsSubtotal + sub
                itemCount = itemCount + count
                entries[#entries + 1] = {
                    itemId = itemId,
                    nameKey = def.nameKey,
                    label = def.name or itemId,
                    count = count,
                    tier = def.rarity or 'common',
                    unitValue = unit,
                    subtotal = sub,
                }
            end
        end
    end
    local order = { legendary = 1, rare = 2, uncommon = 3, common = 4 }
    table.sort(entries, function(a, b)
        if a.confiscated ~= b.confiscated then
            return not a.confiscated
        end
        local ra, rb = order[a.tier] or 99, order[b.tier] or 99
        if ra ~= rb then
            return ra < rb
        end
        return (a.itemId or '') < (b.itemId or '')
    end)
    return entries, itemsSubtotal, fictionBounty, itemCount, fictionItemCount
end

---@param total integer
---@param creditCount integer
---@param payoutMode string
---@param directCashout boolean
---@return table|nil
local function buildNuiPayout(total, creditCount, payoutMode, directCashout)
    if not total or total <= 0 then
        return nil
    end
    if directCashout or payoutMode == 'cash_direct' or payoutMode == 'cash_fallback' or payoutMode == 'cash_small' then
        return { mode = 'cash', cashAmount = total }
    end
    if payoutMode == 'credit' and creditCount > 0 then
        return { mode = 'credit', creditCount = creditCount, cashAmount = total }
    end
    return { mode = 'cash', cashAmount = total }
end

---@param session table|nil
---@param total integer
---@param result string
---@return string
function MRD9.Result.PickVegaLine(session, total, result)
    if result == 'died' then
        return 'こちら側にも記録は残る。次の契約者を探すまで、しばらく時間がかかる。'
    elseif result == 'disconnected' then
        return '通信が途切れたか。契約上、君の取り分は無効になる。'
    elseif result == 'timeout' then
        return '時間切れだ。回収物は契約上、当方の取り分となる。今回は——縁がなかったということに。'
    elseif result == 'out_of_zone' then
        return '指定区域から離脱しすぎだ。契約条項違反として処理させてもらう。'
    end
    if total >= 200000 then
        return '…驚いた。これだけのものを持ち帰った者は、片手で数えるほどしかいない。'
    elseif total >= 80000 then
        return 'よく戻ってきた。今回の品は…悪くない。座って一杯どうだ。'
    elseif total >= 20000 then
        return '無事で何よりだ。査定を始めよう。'
    elseif total > 0 then
        return '手ぶらに近いな。次は期待している。'
    else
        return '空手で戻るのは契約違反ではない。だが、報酬も発生しない。'
    end
end

---@param session table
---@param src integer
---@param result string
---@return table
local function buildFailurePayload(session, src, result)
    return {
        result = result,
        vegaLine = MRD9.Result.PickVegaLine(session, 0, result),
        items = {},
        breakdown = {
            itemSubtotal = 0,
            fictionBounty = 0,
            extractionBonus = 0,
            total = 0,
        },
        payout = nil,
    }
end

---@param session table
---@param src integer
---@return boolean, table|nil
function MRD9.Result.Finalize(session, src)
    if not session or type(src) ~= 'number' or src <= 0 then
        return false, nil
    end

    local identifier = (MRD9.GetIdentifier and MRD9.GetIdentifier(src)) or ('src:' .. tostring(src))
    local entries, itemsSubtotal, fictionBounty, itemCount, fictionItemCount =
        buildItemEntries(session, src)

    local extractionBonus = math.floor(tonumber(Config.Result and Config.Result.extractionBonus) or 0)
    local total = math.max(0, itemsSubtotal + fictionBounty + extractionBonus)

    local payoutMode = 'none'
    local creditCount = 0
    local directCashout = (Config.Result and Config.Result.directCashout) == true

    if total > 0 then
        if directCashout then
            MRD9.PayPlayer(src, total)
            payoutMode = 'cash_direct'
        else
            local unitVal = creditUnitValue()
            creditCount = math.floor(total / unitVal)
            local remainder = total - creditCount * unitVal
            if creditCount > 0 then
                local cid = creditItemId()
                local okAdd = false
                if MRD9.Framework and MRD9.Framework.AddItem then
                    okAdd = select(1, MRD9.Framework.AddItem(src, cid, creditCount, nil))
                end
                if okAdd then
                    payoutMode = 'credit'
                    if remainder > 0 then
                        MRD9.PayPlayer(src, remainder)
                    end
                else
                    MRD9.PayPlayer(src, total)
                    payoutMode = 'cash_fallback'
                    creditCount = 0
                end
            else
                MRD9.PayPlayer(src, total)
                payoutMode = 'cash_small'
            end
        end
    end

    session.inventory[src] = { main = {}, safe = {} }

    writeResultLog({
        identifier = identifier,
        sessionId = session.id,
        missionId = resolveMissionId(session),
        result = 'extracted',
        itemsSubtotal = itemsSubtotal,
        fictionBounty = fictionBounty,
        extractionBonus = extractionBonus,
        total = total,
        creditCount = creditCount,
        itemCount = itemCount,
        fictionItemCount = fictionItemCount,
        payoutMode = payoutMode,
    })

    local nuiPayload = {
        result = 'extracted',
        vegaLine = MRD9.Result.PickVegaLine(session, total, 'extracted'),
        items = entries,
        breakdown = {
            itemSubtotal = itemsSubtotal,
            fictionBounty = fictionBounty,
            extractionBonus = extractionBonus,
            total = total,
        },
        payout = buildNuiPayout(total, creditCount, payoutMode, directCashout),
    }
    triggerResultNui(src, nuiPayload)

    return true, { total = total, creditCount = creditCount, payoutMode = payoutMode }
end

---@param session table
---@param src integer
---@param reason string|nil
---@return boolean, string|nil
function MRD9.Result.Discard(session, src, reason)
    if not session or type(src) ~= 'number' or src <= 0 then
        return false, 'invalid_args'
    end

    local identifier = (MRD9.GetIdentifier and MRD9.GetIdentifier(src)) or ('src:' .. tostring(src))
    local invSrc = session.inventory and session.inventory[src] or {}
    local flat = MRD9.FlattenMissionInventory(invSrc)

    local itemCount, fictionItemCount = 0, 0
    for itemId, count in pairs(flat) do
        count = math.floor(tonumber(count) or 0)
        if count > 0 then
            local def = MRD9.Loot and MRD9.Loot.FindItemDef and MRD9.Loot.FindItemDef(itemId) or nil
            if def and def.fictionTag then
                fictionItemCount = fictionItemCount + count
            else
                itemCount = itemCount + count
            end
        end
    end

    local dbResult = 'unknown'
    if reason == 'disconnect' then
        dbResult = 'disconnect'
    elseif reason == 'died' then
        dbResult = 'died'
    elseif reason == 'forced' then
        dbResult = 'forced'
    elseif reason == 'timeout' then
        dbResult = 'timeout'
    elseif reason == 'out_of_zone' then
        dbResult = 'out_of_zone'
    end

    writeResultLog({
        identifier = identifier,
        sessionId = session.id,
        missionId = resolveMissionId(session),
        result = dbResult,
        itemsSubtotal = 0,
        fictionBounty = 0,
        extractionBonus = 0,
        total = 0,
        creditCount = 0,
        itemCount = itemCount,
        fictionItemCount = fictionItemCount,
        payoutMode = 'none',
        failReason = reason,
    })

    local uiResult
    if reason == 'disconnect' or reason == 'forced' then
        uiResult = 'disconnected'
    elseif reason == 'timeout' then
        uiResult = 'timeout'
    elseif reason == 'out_of_zone' then
        uiResult = 'out_of_zone'
    else
        uiResult = 'died'
    end
    if GetPlayerPing(src) > 0 or reason ~= 'disconnect' then
        triggerResultNui(src, buildFailurePayload(session, src, uiResult))
    end

    return true, nil
end

RegisterCommand('m9_cashout', function(source, args)
    local src = source
    if type(src) ~= 'number' or src <= 0 then
        return
    end
    if (Config.Result and Config.Result.directCashout) == true then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '[JANUS]', 'directCashout モードのため小切手換金は無効です。' },
        })
        return
    end
    if GetResourceState('ox_inventory') ~= 'started' then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '[JANUS]', 'ox_inventory 未起動のため換金できません。' },
        })
        return
    end

    local cid = creditItemId()
    local invCount = exports.ox_inventory:GetItemCount(src, cid) or 0
    if invCount <= 0 then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '[JANUS]', '小切手を所持していません。' },
        })
        return
    end

    local want = tonumber(args[1])
    local toCash = want and math.min(math.floor(want), invCount) or invCount
    if toCash <= 0 then
        return
    end

    local unitValue = creditUnitValue()
    local cashAmount = toCash * unitValue

    local removed = exports.ox_inventory:RemoveItem(src, cid, toCash)
    if not removed then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '[JANUS]', '小切手の取り出しに失敗しました。' },
        })
        return
    end

    MRD9.PayPlayer(src, cashAmount)
    TriggerClientEvent('chat:addMessage', src, {
        args = { '[JANUS]', ('小切手 %d 枚を $%d に換金しました。'):format(toCash, cashAmount) },
    })
end, false)
