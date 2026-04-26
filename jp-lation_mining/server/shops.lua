-- Initialize config(s)
local shared = require 'config.shared'
local server = require 'config.server'

-- Localize export
local mining = exports['jp-lation_mining']

-- Complete a purchase from The Mines shop
-- 処理順・ロジックは IamLation/lation_mining オリジナルに準拠（リソース名・イベント名のみ jp-lation_mining）
--- @param itemId number
--- @param input number
RegisterNetEvent('jp-lation_mining:completepurchase', function(itemId, input)
    if not source or not itemId or not input then return end
    local source = source
    -- メニュー等から来る id が文字列 "5" の場合、items[5] だけ当たり、items["5"] は nil になって弾かれる
    itemId = math.floor(tonumber(itemId) or 0)
    input = math.floor(tonumber(input) or 0)
    if itemId < 1 or input < 1 then return end

    local item = shared.shops.mine.items[itemId]
    if not item then return end

    if item.level then
        -- 「経験」ではなく**採掘（鉱山）レベル**の比較。水・石以外は多く item.level あり。
        local pl = math.max(1, math.floor(tonumber(mining:GetPlayerData(source, 'level')) or 1))
        local need = math.floor(tonumber(item.level) or 0)
        if need < 1 then need = 1 end
        if pl < need then
            TriggerClientEvent('jp-lation_mining:notify', source, locale('notify.shop-need-level', pl, need), 'error')
            return
        end
    end

    local total = math.floor(item.price * input)
    if not total or total < 1 then return end

    local balance = GetPlayerBalance(source, shared.shops.mine.account)
    if not balance or balance < total then
        TriggerClientEvent('jp-lation_mining:notify', source, locale('notify.no-money'), 'error')
        return
    end

    local identifier = GetIdentifier(source)
    if not identifier then return end
    local name = GetName(source)
    if not name then return end

    local coords = shared.shops.location
    local dist = #(vec3(coords.x, coords.y, coords.z) - GetEntityCoords(GetPlayerPed(source))) <= 15
    if not dist then return end

    -- ox + durability 付き: CanCarryItem が偽陰性になり「これ以上持てません」だけ出ることが多い。AddItem の戻りを正とし、通ったら課金
    if Inventory == 'ox_inventory' and item.metadata then
        local a, b = exports.ox_inventory:AddItem(source, item.item, input, item.metadata)
        if a == false then
            local msg = (type(b) == 'string' and b and b ~= '') and b or locale('notify.cant-carry')
            TriggerClientEvent('jp-lation_mining:notify', source, msg, 'error')
            return
        end
        RemoveMoney(source, shared.shops.mine.account, total)
        if server.logs.events.purchased then
            PlayerLog(source, locale('logs.purchased-title'), locale('logs.purchased-message', name, identifier, input, item.item))
        end
        return
    end

    if item.metadata then
        if not CanCarry(source, item.item, input, item.metadata) then
            TriggerClientEvent('jp-lation_mining:notify', source, locale('notify.cant-carry'), 'error')
            return
        end
    else
        if not CanCarry(source, item.item, input) then
            TriggerClientEvent('jp-lation_mining:notify', source, locale('notify.cant-carry'), 'error')
            return
        end
    end

    RemoveMoney(source, shared.shops.mine.account, total)

    if item.metadata then
        AddItem(source, item.item, input, item.metadata)
    else
        AddItem(source, item.item, input)
    end

    if server.logs.events.purchased then
        PlayerLog(source, locale('logs.purchased-title'), locale('logs.purchased-message', name, identifier, input, item.item))
    end
end)

-- Complete a sale from The Mines pawn
--- @param itemId number
--- @param input number
RegisterNetEvent('jp-lation_mining:completesale', function(itemId, input)
    if not source or not itemId or not input then return end

    local item = shared.shops.pawn.items[itemId]
    if not item then return end

    local total = math.floor(item.price * input)
    if not total or total < 1 then return end

    local hasItem = GetItemCount(source, item.item) >= input
    if not hasItem then
        TriggerClientEvent('jp-lation_mining:notify', source, locale('notify.no-item'), 'error')
        return
    end

    local coords = shared.shops.location
    local dist = #(vec3(coords.x, coords.y, coords.z) - GetEntityCoords(GetPlayerPed(source))) <= 15
    if not dist then return end

    local identifier = GetIdentifier(source)
    if not identifier then return end
    local name = GetName(source)
    if not name then return end

    RemoveItem(source, item.item, input)
    AddMoney(source, shared.shops.pawn.account, total)

    mining:AddPlayerData(source, 'earned', total)

    if server.logs.events.pawned then
        PlayerLog(source, locale('logs.pawned-title'), locale('logs.pawned-message', name, identifier, input, item.item))
    end
end)
