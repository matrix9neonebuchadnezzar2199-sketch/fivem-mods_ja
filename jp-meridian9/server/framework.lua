-- ============================================================
-- MERIDIAN-9 フレームワーク自動検出
-- ============================================================
-- ESX / QBCore / Qbox を自動検出し、共通インターフェースを提供。
-- いずれも見つからない場合は Standalone モードで動作する。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Framework = {
    name = 'standalone',
    obj = nil,
}

CreateThread(function()
    Wait(100)

    if GetResourceState('es_extended') == 'started' then
        MRD9.Framework.name = 'esx'
        MRD9.Framework.obj = exports['es_extended']:getSharedObject()
        -- 完了判定用の常時ログ（Config.Debug 非依存）。将来 MRD9.Log へ統一する場合は削除候補。
        print('[jp-meridian9] Framework detected: ESX')
        MRD9.Log('Framework detected: ESX')
        return
    end

    if GetResourceState('qb-core') == 'started' then
        MRD9.Framework.name = 'qbcore'
        MRD9.Framework.obj = exports['qb-core']:GetCoreObject()
        -- 完了判定用の常時ログ（Config.Debug 非依存）。将来 MRD9.Log へ統一する場合は削除候補。
        print('[jp-meridian9] Framework detected: QBCore')
        MRD9.Log('Framework detected: QBCore')
        return
    end

    if GetResourceState('qbx_core') == 'started' then
        MRD9.Framework.name = 'qbox'
        MRD9.Framework.obj = exports.qbx_core
        -- 完了判定用の常時ログ（Config.Debug 非依存）。将来 MRD9.Log へ統一する場合は削除候補。
        print('[jp-meridian9] Framework detected: Qbox')
        MRD9.Log('Framework detected: Qbox')
        return
    end

    -- 完了判定用の常時ログ（Config.Debug 非依存）。将来 MRD9.Log へ統一する場合は削除候補。
    print('[jp-meridian9] Framework detected: Standalone (no framework)')
    MRD9.Log('Framework detected: Standalone (no framework)')
end)

---@param src integer
---@param amount integer
---@param paymentType string|nil
function MRD9.PayPlayer(src, amount, paymentType)
    if type(src) ~= 'number' or src <= 0 then
        return
    end
    if type(amount) ~= 'number' or amount < 0 or amount ~= math.floor(amount) then
        return
    end

    paymentType = paymentType or (Config and Config.Reward and Config.Reward.paymentType) or 'cash'
    local fw = MRD9.Framework.name

    if fw == 'esx' then
        local xPlayer = MRD9.Framework.obj.GetPlayerFromId(src)
        if not xPlayer then
            return
        end
        if paymentType == 'bank' then
            xPlayer.addAccountMoney('bank', amount)
        elseif paymentType == 'custom' then
            if Config and Config.Reward and Config.Reward.standaloneMoneyEvent then
                TriggerEvent(Config.Reward.standaloneMoneyEvent, src, amount)
            end
        else
            xPlayer.addMoney(amount)
        end
        return
    end

    if fw == 'qbcore' then
        local Player = MRD9.Framework.obj.Functions.GetPlayer(src)
        if not Player then
            return
        end
        local acct = paymentType == 'bank' and 'bank' or 'cash'
        if paymentType == 'custom' then
            if Config and Config.Reward and Config.Reward.standaloneMoneyEvent then
                TriggerEvent(Config.Reward.standaloneMoneyEvent, src, amount)
            end
            return
        end
        Player.Functions.AddMoney(acct, amount, 'jp-meridian9 reward')
        return
    end

    if fw == 'qbox' then
        local Player = exports.qbx_core:GetPlayer(src)
        if not Player then
            return
        end
        local acct = paymentType == 'bank' and 'bank' or 'cash'
        if paymentType == 'custom' then
            if Config and Config.Reward and Config.Reward.standaloneMoneyEvent then
                TriggerEvent(Config.Reward.standaloneMoneyEvent, src, amount)
            end
            return
        end
        Player.Functions.AddMoney(acct, amount, 'jp-meridian9 reward')
        return
    end

    if Config and Config.Reward and Config.Reward.standaloneMoneyEvent then
        TriggerEvent(Config.Reward.standaloneMoneyEvent, src, amount)
    else
        MRD9.Log('[WARN] Standalone mode but no money handler configured.')
    end
    TriggerClientEvent('jp-meridian9:notify', src, ('報酬: $%d（手動で付与してください）'):format(amount))
end

---@param src integer
---@return string|nil
function MRD9.GetIdentifier(src)
    if type(src) ~= 'number' or src <= 0 then
        return nil
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return nil
end

-- ============================================================
-- MRD9.Framework.AddItem（ルート等から使用）
-- ox_inventory を最優先。ESX+Qbox 併用時は「アイテムの正は ox_inventory」とする運用前提。
-- 戻り値: ok (boolean), reason (string|nil)。inventory_full は主に ox_inventory で厳密。
-- ============================================================

---@param src integer
---@param itemId string
---@param count integer|nil
---@param metadata table|nil
---@return boolean, string|nil
function MRD9.Framework.AddItem(src, itemId, count, metadata)
    src = tonumber(src)
    count = tonumber(count) or 1
    if not src or src <= 0 then
        return false, 'no_player'
    end
    if type(itemId) ~= 'string' or itemId == '' then
        return false, 'invalid_item'
    end

    if GetResourceState('ox_inventory') == 'started' then
        local ok, ret = pcall(function()
            return exports.ox_inventory:AddItem(src, itemId, count, metadata)
        end)
        if not ok then
            return false, 'ox_inventory_error'
        end
        if ret == false then
            return false, 'inventory_full'
        end
        return true
    end

    local fw = MRD9.Framework.name

    if fw == 'esx' and MRD9.Framework.obj then
        local xPlayer = MRD9.Framework.obj.GetPlayerFromId(src)
        if not xPlayer then
            return false, 'no_player'
        end
        local addOk, err = pcall(function()
            xPlayer.addInventoryItem(itemId, count)
        end)
        if not addOk then
            return false, err and tostring(err) or 'esx_error'
        end
        return true
    end

    if fw == 'qbcore' and MRD9.Framework.obj then
        local Player = MRD9.Framework.obj.Functions.GetPlayer(src)
        if not Player then
            return false, 'no_player'
        end
        local ok, ret = pcall(function()
            return Player.Functions.AddItem(itemId, count, nil, metadata)
        end)
        if not ok then
            return false, 'qb_error'
        end
        if ret == false then
            return false, 'inventory_full'
        end
        return true
    end

    if fw == 'qbox' then
        local okGet, Player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)
        if not okGet or not Player then
            return false, 'no_player'
        end
        local ok, ret = pcall(function()
            return Player.Functions.AddItem(itemId, count, nil, metadata)
        end)
        if not ok then
            return false, 'qbx_error'
        end
        if ret == false then
            return false, 'inventory_full'
        end
        return true
    end

    local ev = Config and Config.Reward and Config.Reward.standaloneItemEvent
    if type(ev) == 'string' and ev ~= '' then
        TriggerClientEvent(ev, src, itemId, count, metadata)
        return true
    end

    return true
end

---@param src integer
---@return string
function MRD9.Framework.GetCharacterName(src)
    if type(src) ~= 'number' or src <= 0 then
        return 'Unknown'
    end
    local fw = MRD9.Framework.name

    if fw == 'esx' and MRD9.Framework.obj then
        local xPlayer = MRD9.Framework.obj.GetPlayerFromId(src)
        if xPlayer then
            if xPlayer.getName then
                local n = xPlayer.getName()
                if type(n) == 'string' and n ~= '' then
                    return n
                end
            end
            if xPlayer.get and type(xPlayer.get) == 'function' then
                local fn = xPlayer.get('firstName')
                local ln = xPlayer.get('lastName')
                if type(fn) == 'string' or type(ln) == 'string' then
                    local n = (tostring(fn or '') .. ' ' .. tostring(ln or '')):gsub('^%s*(.-)%s*$', '%1')
                    if n ~= '' then
                        return n
                    end
                end
            end
        end
    elseif fw == 'qbcore' and MRD9.Framework.obj then
        local Player = MRD9.Framework.obj.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            local c = Player.PlayerData.charinfo
            local n = (tostring(c.firstname or '') .. ' ' .. tostring(c.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
            if n ~= '' then
                return n
            end
        end
    elseif fw == 'qbox' then
        local ok, Player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)
        if ok and Player and Player.PlayerData and Player.PlayerData.charinfo then
            local c = Player.PlayerData.charinfo
            local n = (tostring(c.firstname or '') .. ' ' .. tostring(c.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
            if n ~= '' then
                return n
            end
        end
    end

    local gn = GetPlayerName(src)
    if type(gn) == 'string' and gn ~= '' then
        return gn
    end
    return ('Player %d'):format(src)
end
