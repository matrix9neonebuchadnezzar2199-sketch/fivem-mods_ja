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
