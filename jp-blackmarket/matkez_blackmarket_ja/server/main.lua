local shared = require 'config.shared'
local server = require 'config.server'
local playerLevels = {}
local orders = {}
local itemPrices = {}

function log(src, title, description)
    if not server.logging then return end
    if server.logging.logType == 'ox_lib' then
        lib.logger(getCharacterIdentifier(src), 'matkez_blackmarket', description)
    else
        local embed = {{
            title = title,
            description = description,
            footer = {text = os.date('%d.%m.%Y | %X')}
        }}
        PerformHttpRequest(server.logging.webhook, function() end, 'POST', json.encode({ embeds = embed }), {['Content-Type'] = 'application/json'})
    end
end

CreateThread(function()
    local response = MySQL.query.await('SELECT * FROM `blackmarket_levels`')

    for i = 1, #response do
        local v = response[i]
        if v then
            playerLevels[v.identifier] = playerLevels[v.identifier] or {}
            playerLevels[v.identifier][v.blackmarket] = tonumber(v.xp) or 0
        end
    end

    for blackmarket, v in pairs(shared.blackmarkets) do
        itemPrices[blackmarket] = {}

        for _, it in pairs(v.items) do
            local price = math.random(it.minPrice, it.maxPrice)
            itemPrices[blackmarket][it.name] = price
        end
    end
end)

lib.callback.register('matkez_blackmarket:server:getBlackmarketPrices', function(src, blackmarket)
    return itemPrices[blackmarket]
end)

function addPlayerToDb(src, blackmarket)
    if not shared.useLevels then return end
    local identifier = getCharacterIdentifier(src)
    playerLevels[identifier] = playerLevels[identifier] or {}
    if playerLevels[identifier][blackmarket] ~= nil then return end
    playerLevels[identifier][blackmarket] = 0
    MySQL.insert.await('INSERT INTO `blackmarket_levels` (identifier, blackmarket, xp) VALUES (?, ?, ?)', {identifier, blackmarket, 0})
end

function getPlayerLevel(src, blackmarket)
    if not shared.useLevels then return 99999999999, 9999999999 end
    local identifier = getCharacterIdentifier(src)
    playerLevels[identifier] = playerLevels[identifier] or {}
    local playerXp = playerLevels[identifier][blackmarket]
    if playerXp == nil then
        addPlayerToDb(src, blackmarket)
        return 0, 0
    end
    local levels = shared.levels
    local level = 0
    for i = 1, #levels do
        if playerXp < levels[i] then break end
        level = i
    end

    return level, playerXp
end

lib.callback.register('matkez_blackmarket:server:getPlayerLevel', function(src, blackmarket)
    local identifier = getCharacterIdentifier(src)
    playerLevels[identifier] = playerLevels[identifier] or {}
    local xpBlackmarket = shared.globalLevel and 'global' or blackmarket
    if playerLevels[identifier][xpBlackmarket] == nil then
        addPlayerToDb(src, xpBlackmarket)
    end

    local level, xp = getPlayerLevel(src, xpBlackmarket)
    return level, xp
end)

function increasePlayerXp(src, blackmarket, amount)
    if not shared.useLevels then return end
    local identifier = getCharacterIdentifier(src)
    local level, xp = getPlayerLevel(src, blackmarket)
    local levels = shared.levels
    local maxLevel = levels[level + 1] == nil
    local maxXp = levels[level]
    playerLevels[identifier][blackmarket] += amount
    local newXp = playerLevels[identifier][blackmarket]
    if maxLevel then
        if newXp >= maxXp then
            playerLevels[identifier][blackmarket] = maxXp
            newXp = maxXp
        end
    end
    if newXp == xp then return false end
    level, xp = getPlayerLevel(src, blackmarket)
    if levels[level + 1] == nil then
        newXp = levels[level]
        playerLevels[identifier][blackmarket] = newXp
    end

    MySQL.update.await('UPDATE blackmarket_levels SET xp = ? WHERE identifier = ? AND blackmarket = ?', {newXp, identifier, blackmarket})
end

lib.callback.register('matkez_blackmarket:server:order', function(src, blackmarket, cart)
    local b = shared.blackmarkets[blackmarket]
    if not b or not cart then return false end
    local identifier = getCharacterIdentifier(src)
    if orders[identifier] then notify(src, translate('hasOrder'), 'error', 5000) return false end
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(playerCoords.xyz - b.ped.coords.xyz)
    if dist > 10.0 then DropPlayer(src, 'Distance check (matkez_blackmarket)') return false end
    orders[identifier] = true
    local prices = itemPrices[blackmarket]
    local currencyItem = b.currencyItem
    local xpBlackmarket = shared.globalLevel and 'global' or blackmarket
    local playerLevel, playerXp = getPlayerLevel(src, xpBlackmarket)
    local formatted = {}
    local totalPrice = 0
    local xpToAdd = 0
    local toAdd = {}

    for _, v in ipairs(b.items) do
        formatted[v.name] = v
    end

    for _, v in ipairs(cart) do
        local itemData = formatted[v.item]
        if not itemData then
            orders[identifier] = nil
            return false
        end
        if v.amount < 1 then
            orders[identifier] = nil
            return false
        end
        if playerLevel < itemData.minLevel then
            orders[identifier] = nil
            return false
        end
        totalPrice += prices[v.item] * v.amount
        xpToAdd += itemData.givesXp * v.amount
        table.insert(toAdd, {
            item = v.item,
            amount = v.amount
        })
    end

    local money = exports.ox_inventory:Search(src, 'count', currencyItem)
    if money < totalPrice then
        notify(src, translate('noMoney'), 'error', 5000)
        orders[identifier] = nil
        return false
    end
    exports.ox_inventory:RemoveItem(src, currencyItem, totalPrice)
    local randomLocation = shared.pickupLocations[math.random(#shared.pickupLocations)]
    orders[identifier] = {
        items = toAdd,
        pickupLocation = randomLocation.id,
        coords = randomLocation.coords.xyz
    }
    TriggerClientEvent('matkez_blackmarket:client:createRoute', src, randomLocation.coords.xyz)
    notify(src, translate('goPickup'), 'success', 10000)
    increasePlayerXp(src, xpBlackmarket, xpToAdd)
    log(src, 'ORDER', translate('logOrder'):format(identifier, GetPlayerName(src), blackmarket, json.encode(toAdd), totalPrice, currencyItem))
    
    return true
end)

lib.callback.register('matkez_blackmarket:server:pickupItems', function(src, id)
    local identifier = getCharacterIdentifier(src)
    if not orders[identifier] or orders[identifier].pickupLocation ~= id then notify(src, translate('nothingHere'), 'error', 5000) return false end
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist = #(playerCoords.xyz - orders[identifier].coords)
    if dist > 10.0 then orders[identifier] = nil DropPlayer(src, 'Distance check (matkez_blackmarket)') return false end
    local items = orders[identifier].items
    local itemsToDrop = {}
    orders[identifier] = nil
    for _, v in ipairs(items) do
        if exports.ox_inventory:CanCarryItem(src, v.item, v.amount) then
            exports.ox_inventory:AddItem(src, v.item, v.amount)
        else
            table.insert(itemsToDrop, {v.item, v.amount})
        end
    end
    if #itemsToDrop > 0 then
        notify(src, translate('droppedItems'), 'info', 10000)
        exports.ox_inventory:CustomDrop(identifier..math.random(99999, 9999999999), itemsToDrop, playerCoords.xyz)
    end
    log(src, 'PICKUP', translate('logPickup'):format(identifier, GetPlayerName(src), json.encode(items), playerCoords))
    return true
end)

lib.callback.register('matkez_blackmarket:server:checkForOrders', function(src)
    local identifier = getCharacterIdentifier(src)
    if orders[identifier] then
        TriggerClientEvent('matkez_blackmarket:client:createRoute', src, orders[identifier].coords)
    end
    return true
end)

function isAdmin(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, identifier in ipairs(identifiers) do
        if server.admins[identifier] then return true end
    end
    return false
end

function restartPlayerLevel(src, id)
    if not shared.useLevels then return end
    local playerId = getCharacterIdentifier(id)
    if not playerId then return end
    local success = MySQL.update.await('UPDATE blackmarket_levels SET xp = ? WHERE identifier = ?', {0, playerId})
    for k, v in pairs(playerLevels[playerId]) do
        playerLevels[playerId][k] = 0
    end
    if success then
        notify(src, translate('restartSuccess'), 'success', 5000)
    end
end

lib.addCommand(server.levelRestartCommand, {
    help = 'Restart player levels',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
    },
}, function(source, args, raw)
    local isAdmin = isAdmin(source) or false
    if not isAdmin then return end
    restartPlayerLevel(source, args.target)
end)