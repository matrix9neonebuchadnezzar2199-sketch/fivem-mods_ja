local ESX, QBCore = nil, nil

-- フレームワーク検出（es_extended / qb-core。無ければ nil のまま）
CreateThread(function()
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

-- 現金の所持確認と支払い
local function TryChargeMoney(source, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.getMoney() >= amount then
            xPlayer.removeMoney(amount)
            return true
        end
        return false
    elseif QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            local cash = player.PlayerData.money['cash'] or 0
            if cash >= amount then
                player.Functions.RemoveMoney('cash', amount, 'gacha')
                return true
            end
        end
        return false
    else
        -- スタンドアロン: 課金不可のため常に true（コスト0運用想定）
        return true
    end
end

-- 重み付き抽選（レアリティ）
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

-- 指定レアリティからアイテムを等確率抽選
local function DrawItem(rarityId)
    local pool = {}
    for _, item in ipairs(Config.Items) do
        if item.rarity == rarityId then
            pool[#pool + 1] = item
        end
    end
    if #pool == 0 then
        return { name = "不明なアイテム", rarity = rarityId, image = "" }
    end
    return pool[math.random(1, #pool)]
end

-- 接続毎の最終成功時刻（os.time 秒）
local playerCooldowns = {}

RegisterNetEvent('jp-gacha:requestDraw', function()
    local source = source
    local now = os.time()

    if playerCooldowns[source] and (now - playerCooldowns[source]) < Config.Cooldown then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'cooldown')
        return
    end

    if Config.Cost > 0 and not TryChargeMoney(source, Config.Cost) then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'nomoney')
        return
    end

    playerCooldowns[source] = now

    local rarity = DrawRarity()
    local item = DrawItem(rarity.id)

    local resultData = {
        rarityId = rarity.id,
        rarityName = rarity.name,
        rarityColor = rarity.color,
        capsule = rarity.capsule,
        bg = rarity.bg,
        cutin = rarity.cutin,
        itemName = item.name,
        itemImage = item.image,
    }

    TriggerClientEvent('jp-gacha:drawResult', source, resultData)

    local playerName = GetPlayerName(source) or "Unknown"
    print(('[jp-gacha] %s が %s（%s）を引いた'):format(playerName, item.name, rarity.id))

    if rarity.id == 'SR' or rarity.id == 'SSR' or rarity.id == 'UR' then
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 215, 0 },
            multiline = false,
            args = {
                "🎰 ガチャ",
                ('%s が【%s】%s を引き当てた！'):format(playerName, rarity.name, item.name),
            },
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = { 200, 200, 200 },
            multiline = false,
            args = {
                "🎰 ガチャ",
                ('%s を手に入れた'):format(item.name),
            },
        })
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerCooldowns[src] = nil
end)
