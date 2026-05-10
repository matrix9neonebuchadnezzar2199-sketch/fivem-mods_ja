local QBCore = exports['qb-core']:GetCoreObject()

-- ===================================================================
-- jp-pola サーバー側
-- ===================================================================
-- 原作互換のためイベント名（ps-camera:*）・アイテム名（camera / photo）は変更しない。
-- 機微情報（webhook / Fivemerr トークン）は server.cfg の convar 経由で渡せる。
-- 既存の直書き（SvConfig.webhook 等）も後方互換として有効。
--   server.cfg 例:
--     set jp-pola_webhook "https://discord.com/api/webhooks/..."
--     set jp-pola_fivemerr_token "your-fivemerr-token"
-- ===================================================================

SvConfig = {
    Inv = 'qb',                    -- 'qb' または 'ox'（インベントリシステム）
    webhook = '',                  -- 旧来の直書き互換。空なら convar 'jp-pola_webhook' を読む
    FivemerrApiToken = '',         -- 旧来の直書き互換。空なら convar 'jp-pola_fivemerr_token' を読む
}

-- convar フォールバック（直書きが空のときだけ読む。直書きを優先＝既存運用を壊さない）
local function ResolveWebhook()
    if SvConfig.webhook ~= '' then return SvConfig.webhook end
    return GetConvar('jp-pola_webhook', '')
end

local function ResolveFivemerrToken()
    if SvConfig.FivemerrApiToken ~= '' then return SvConfig.FivemerrApiToken end
    return GetConvar('jp-pola_fivemerr_token', '')
end

local function ConfigInvInvalid()
    print(L('err_invalid_inv', tostring(SvConfig.Inv)))
end

RegisterNetEvent('ps-camera:cheatDetect', function()
    local src = source
    DropPlayer(src, L('drop_cheater'))
end)

RegisterNetEvent('ps-camera:requestWebhook', function(Key)
    local src = source
    local event = ('ps-camera:grabbed%s'):format(Key)

    local webhook = ResolveWebhook()
    if webhook == '' then
        print(L('err_webhook_missing'))
    else
        TriggerClientEvent(event, src, webhook)
    end
end)

RegisterNetEvent('ps-camera:requestFivemerrToken', function(Key)
    local src = source
    local event = ('ps-camera:grabbed%s'):format(Key)

    if Config.UseFivemerr == false then
        return print(L('err_fivemerr_disabled'))
    end

    local token = ResolveFivemerrToken()
    if token == '' then
        return print(L('err_fivemerr_missing'))
    end

    TriggerClientEvent(event, src, token)
end)

RegisterNetEvent('ps-camera:CreatePhoto', function(url)
    local src = source
    if Config and Config.Debug then
        print(('[%s] [DEBUG] CreatePhoto 受信 src=%d url=%s'):format(GetCurrentResourceName(), src, tostring(url):sub(1, 200)))
    end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        if Config and Config.Debug then
            print(('[%s] [DEBUG] CreatePhoto: GetPlayer(%d) が nil（キャラ未ロード？）'):format(GetCurrentResourceName(), src))
        end
        return
    end

    local coords = GetEntityCoords(GetPlayerPed(src))

    TriggerClientEvent('ps-camera:getStreetName', src, url, coords)
end)

RegisterNetEvent('ps-camera:savePhoto', function(url, streetName)
    local src = source
    if Config and Config.Debug then
        print(('[%s] [DEBUG] savePhoto 受信 src=%d streetName=%s url=%s'):format(GetCurrentResourceName(), src, tostring(streetName), tostring(url):sub(1, 200)))
    end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        if Config and Config.Debug then
            print(('[%s] [DEBUG] savePhoto: GetPlayer(%d) が nil'):format(GetCurrentResourceName(), src))
        end
        return
    end

    local location = streetName

    local info = {
        ps_image = url,
        location = location,
    }

    if not (SvConfig.Inv == 'qb' or SvConfig.Inv == 'ox') then
        ConfigInvInvalid()
        return
    end

    if SvConfig.Inv == 'qb' then
        local addOk = player.Functions.AddItem('photo', 1, nil, info)
        if Config and Config.Debug then
            print(('[%s] [DEBUG] AddItem photo 結果=%s（false の場合は qb-core/shared/items.lua の photo 未登録か容量超過）'):format(GetCurrentResourceName(), tostring(addOk)))
        end
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['photo'], 'add')
    elseif SvConfig.Inv == 'ox' then
        local ox_inventory = exports.ox_inventory

        if not ox_inventory:CanCarryItem(src, 'photo', 1) then
            return TriggerClientEvent('QBCore:Notify', src, L('notify_cannot_carry'), 'error')
        end

        ox_inventory:AddItem(src, 'photo', 1, info)
    end
end)


QBCore.Functions.CreateUseableItem('camera', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not (SvConfig.Inv == 'qb' or SvConfig.Inv == 'ox') then
        ConfigInvInvalid()
        return
    end

    if Config.UseFivemerr == false then
        if ResolveWebhook() == '' then
            print(L('err_webhook_missing'))
            return
        end
    else
        if ResolveFivemerrToken() == '' then
            return print(L('err_fivemerr_missing'))
        end
    end

    if SvConfig.Inv == 'qb' then
        if Player.Functions.GetItemByName(item.name) then
            TriggerClientEvent('ps-camera:useCamera', src)
        end
    elseif SvConfig.Inv == 'ox' then
        local ox_inventory = exports.ox_inventory
        if ox_inventory:GetItem(src, item.name, nil, true) > 0 then
            TriggerClientEvent('ps-camera:useCamera', src)
        end
    end
end)

QBCore.Functions.CreateUseableItem('photo', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not (SvConfig.Inv == 'qb' or SvConfig.Inv == 'ox') then
        ConfigInvInvalid()
        return
    end

    if SvConfig.Inv == 'qb' then
        if Player.Functions.GetItemByName(item.name) then
            TriggerClientEvent('ps-camera:usePhoto', src, item.info.ps_image, item.info.location)
        end
    elseif SvConfig.Inv == 'ox' then
        local ox_inventory = exports.ox_inventory
        if ox_inventory:GetItem(src, item.name, nil, true) > 0 then
            TriggerClientEvent('ps-camera:usePhoto', src, item.metadata.ps_image, item.metadata.location)
        end
    end
end)

-- 外部リソースから dslrcamera でカメラを起動するための export
function UseCam(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not (SvConfig.Inv == 'qb' or SvConfig.Inv == 'ox') then
        ConfigInvInvalid()
        return
    end

    if ResolveWebhook() == '' and Config.UseFivemerr == false then
        print(L('err_webhook_missing'))
        return
    end

    if SvConfig.Inv == 'qb' then
        if Player.Functions.GetItemByName('dslrcamera') then
            TriggerClientEvent('ps-camera:useCamera', src)
        else
            TriggerClientEvent('QBCore:Notify', src, L('notify_no_camera'), 'error')
        end
    elseif SvConfig.Inv == 'ox' then
        local ox_inventory = exports.ox_inventory
        if ox_inventory:GetItem(src, 'dslrcamera', nil, true) > 0 then
            TriggerClientEvent('ps-camera:useCamera', src)
        else
            TriggerClientEvent('QBCore:Notify', src, L('notify_no_camera'), 'error')
        end
    end
end

exports('UseCam', UseCam)
