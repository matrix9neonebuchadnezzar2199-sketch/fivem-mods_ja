local ESX, QBCore = nil, nil

Citizen.CreateThread(function()
    if Config.Framework == 'auto' or Config.Framework == 'esx' then
        local success = pcall(function()
            ESX = exports['es_extended']:getSharedObject()
        end)
        if success and ESX then
            if Config.Debug then
                print('[jp-gacha] ESX detected')
            end
            return
        end
    end
    if Config.Framework == 'auto' or Config.Framework == 'qbcore' then
        local success = pcall(function()
            QBCore = exports['qb-core']:GetCoreObject()
        end)
        if success and QBCore then
            if Config.Debug then
                print('[jp-gacha] QBCore detected')
            end
            return
        end
    end
    if Config.Debug then
        print('[jp-gacha] Standalone mode')
    end
end)

local function TryChargeMoney(source, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.getMoney() >= amount then
            xPlayer.removeMoney(amount)
            return true
        end
        return false
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local cash = Player.PlayerData.money['cash'] or 0
            if cash >= amount then
                Player.Functions.RemoveMoney('cash', amount, 'gacha')
                return true
            end
        end
        return false
    else
        return true
    end
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
    local now = os.time()

    -- バリデーション
    if type(count) ~= 'number' or count < 1 or count > Config.MaxPullCount then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'invalid')
        return
    end
    count = math.floor(count)

    -- クールダウン
    if PlayerCooldowns[source] and (now - PlayerCooldowns[source]) < Config.Cooldown then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'cooldown')
        return
    end

    -- 合計コスト計算 & 課金
    local totalCost = Config.Cost * count
    if totalCost > 0 then
        if not TryChargeMoney(source, totalCost) then
            TriggerClientEvent('jp-gacha:drawDenied', source, 'nomoney')
            return
        end
    end

    PlayerCooldowns[source] = now

    -- 複数回抽選
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

    -- クライアントへ送信
    TriggerClientEvent('jp-gacha:multiDrawResult', source, results, count)

    -- ログ & チャット
    local playerName = GetPlayerName(source) or "Unknown"
    for _, r in ipairs(results) do
        print(('[jp-gacha] %s が %s（%s）を引いた'):format(playerName, r.itemName, r.rarityId))
    end

    -- SR以上が含まれていたら全体通知
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
        -- 本人のみ
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
