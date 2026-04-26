-- フレームワーク: auto 時は qbx / ESX / QBCore / ox(現金アイテム) の優先で検出
local ESX, QBCore = nil, nil
--- 'none' 'esx' 'qb' 'qbx' 'oxinv'（ox_core の口座は未対応のため ox_inv の money のみで代替）
local MoneyMode = 'none'

local function InitFramework()
    if Config.Framework == 'esx' or Config.Framework == 'es_extended' then
        if pcall(function() ESX = exports['es_extended']:getSharedObject() end) and ESX then
            MoneyMode = 'esx'
        end
        return
    end
    if Config.Framework == 'qb' or Config.Framework == 'qbcore' then
        if pcall(function() QBCore = exports['qb-core']:GetCoreObject() end) and QBCore then
            MoneyMode = 'qb'
        end
        return
    end
    if Config.Framework == 'qbox' or Config.Framework == 'qbx' then
        if GetResourceState('qbx_core') == 'started' then
            MoneyMode = 'qbx'
        end
        return
    end
    if Config.Framework == 'oxinv' or Config.Framework == 'ox_inventory' then
        if GetResourceState('ox_inventory') == 'started' then
            MoneyMode = 'oxinv'
        end
        return
    end
    if GetResourceState('qbx_core') == 'started' then
        MoneyMode = 'qbx'
        if Config.Debug then
            print('[jp-gacha] 自動: qbx_core (Qbox)')
        end
        return
    end
    if pcall(function() ESX = exports['es_extended']:getSharedObject() end) and ESX then
        MoneyMode = 'esx'
        if Config.Debug then print('[jp-gacha] 自動: es_extended') end
        return
    end
    if pcall(function() QBCore = exports['qb-core']:GetCoreObject() end) and QBCore then
        MoneyMode = 'qb'
        if Config.Debug then print('[jp-gacha] 自動: qb-core') end
        return
    end
    if GetResourceState('ox_inventory') == 'started' then
        MoneyMode = 'oxinv'
        if Config.Debug then
            print('[jp-gacha] 自動: ox_inventory（money 現金）')
        end
        return
    end
    if Config.Debug then
        print('[jp-gacha] 自動: 金検出なし（無料で回せるモード。Framework を設定するか esx/qb/ox 系を導入してください）')
    end
end

Citizen.CreateThread(function()
    Wait(300) -- 起動順: qbx_core 等の export が揃うまで少し遅延
    InitFramework()
end)

local function TryChargeMoney(source, amount)
    if not amount or amount < 0 then
        return true
    end
    if amount == 0 then
        return true
    end
    if MoneyMode == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then
            return false
        end
        if xPlayer.getMoney and xPlayer.getMoney() >= amount and xPlayer.removeMoney then
            xPlayer.removeMoney(amount)
            return true
        end
        return false
    end
    if (MoneyMode == 'qb' and QBCore) or MoneyMode == 'qbx' then
        local Player
        if MoneyMode == 'qbx' then
            Player = exports.qbx_core:GetPlayer(source)
        else
            Player = QBCore.Functions.GetPlayer(source)
        end
        if not Player or not Player.PlayerData or not Player.PlayerData.money then
            return false
        end
        local cash = Player.PlayerData.money.cash
        if cash == nil then
            cash = 0
        end
        if type(cash) == 'string' then
            cash = tonumber(cash) or 0
        end
        if cash < amount then
            return false
        end
        if not Player.Functions or not Player.Functions.RemoveMoney then
            return false
        end
        local r = Player.Functions.RemoveMoney('cash', amount, 'jp-gacha')
        return r ~= false
    end
    if MoneyMode == 'oxinv' and GetResourceState('ox_inventory') == 'started' then
        local have = exports.ox_inventory:Search(source, 'count', 'money') or 0
        if have < amount then
            return false
        end
        if exports.ox_inventory:RemoveItem(source, 'money', amount) then
            return true
        end
        return false
    end
    -- 従来: フレーム未検出時は通す（本番は Framework / ox 導入推奨）
    return true
end

local function DrawRarity()
    local totalWeight = 0
    for _, r in ipairs(Config.Rarities) do
        totalWeight = totalWeight + r.weight
    end
    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, r in ipairs(Config.Rarities) do
        cumulative = cumulative + r.weight
        if roll <= cumulative then
            return r
        end
    end
    return Config.Rarities[1]
end

local function DrawItem(rarityId)
    if type(Config.ItemsByRarity) == 'table' and type(Config.ItemsByRarity[rarityId]) == 'table' then
        local byRarityPool = Config.ItemsByRarity[rarityId]
        if #byRarityPool > 0 then
            local picked = byRarityPool[math.random(#byRarityPool)]
            return {
                name = picked.name or "不明なアイテム",
                rarity = rarityId,
                image = picked.image or ""
            }
        end
    end

    local pool = {}
    for _, item in ipairs(Config.Items) do
        if item.rarity == rarityId then
            table.insert(pool, item)
        end
    end
    if #pool == 0 then
        return { name = "不明なアイテム", rarity = rarityId, image = "" }
    end
    return pool[math.random(#pool)]
end

local PlayerCooldowns = {}

-- 複数回ガチャ対応
RegisterNetEvent('jp-gacha:requestMultiDraw', function(count)
    local source = source
    if type(source) == 'string' then
        source = tonumber(source)
    end
    if not source or source < 1 then
        return
    end
    -- 必ず数値化（Cfx のイベント型ゆらぎ）
    count = math.floor(tonumber(count) or 0)
    if count < 1 or count > Config.MaxPullCount then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'invalid')
        return
    end

    local now = os.time()
    if PlayerCooldowns[source] and (now - PlayerCooldowns[source]) < Config.Cooldown then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'cooldown')
        return
    end

    local totalCost = Config.Cost * count
    if totalCost > 0 and not TryChargeMoney(source, totalCost) then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'nomoney')
        return
    end

    PlayerCooldowns[source] = now

    local results = {}
    for i = 1, count do
        local rarity = DrawRarity()
        local item = DrawItem(rarity.id)
        table.insert(results, {
            index = i,
            rarityId = rarity.id,
            rarityName = rarity.name,
            rarityColor = rarity.color,
            capsule = rarity.capsule,
            bg = rarity.bg,
            cutin = rarity.cutin,
            itemName = item.name,
            itemImage = item.image,
        })
    end

    TriggerClientEvent('jp-gacha:multiDrawResult', source, results, count)

    local playerName = GetPlayerName(source) or "Unknown"
    for _, r in ipairs(results) do
        print(('[jp-gacha] %s が %s（%s）を引いた'):format(playerName, r.itemName, r.rarityId))
    end

    local hasRare = false
    local rareItems = {}
    for _, r in ipairs(results) do
        if r.rarityId == 'SR' or r.rarityId == 'SSR' or r.rarityId == 'UR' then
            hasRare = true
            table.insert(rareItems, ('【%s】%s'):format(r.rarityName, r.itemName))
        end
    end

    if hasRare then
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 215, 0 },
            multiline = false,
            args = {
                "🎰 ガチャ",
                ('%s が %s を引き当てた！'):format(playerName, table.concat(rareItems, '、'))
            }
        })
    else
        local itemNames = {}
        for _, r in ipairs(results) do
            table.insert(itemNames, r.itemName)
        end
        TriggerClientEvent('chat:addMessage', source, {
            color = { 200, 200, 200 },
            multiline = false,
            args = {
                "🎰 ガチャ",
                ('%s を手に入れた'):format(table.concat(itemNames, '、'))
            }
        })
    end
end)

AddEventHandler('playerDropped', function()
    PlayerCooldowns[source] = nil
end)
