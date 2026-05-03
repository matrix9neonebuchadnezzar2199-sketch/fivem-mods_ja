-- サーバー専用：アイテム使用フックと消費

local Inv = {}

local function getESX()
    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    return ok and obj or nil
end

local function getQBCore()
    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    return ok and obj or nil
end

---@param itemName string
---@param cb fun(source: number)
function Inv.RegisterUsable(itemName, cb)
    local fw = Config.Framework
    if fw == 'esx' then
        local ESX = getESX()
        if ESX then
            ESX.RegisterUsableItem(itemName, function(source)
                cb(source)
            end)
        end
    elseif fw == 'qb' then
        local QBCore = getQBCore()
        if QBCore then
            QBCore.Functions.CreateUseableItem(itemName, function(source, _)
                cb(source)
            end)
        end
    elseif fw == 'qbox' then
        local ok = pcall(function()
            exports.qbx_core:CreateUseableItem(itemName, function(source, _)
                cb(source)
            end)
        end)
        if not ok then
            local QBCore = getQBCore()
            if QBCore then
                QBCore.Functions.CreateUseableItem(itemName, function(source, _)
                    cb(source)
                end)
            end
        end
    end
end

---@param source number
---@param itemName string
---@param count integer
---@return boolean
function Inv.RemoveItem(source, itemName, count)
    count = count or 1
    if GetResourceState('ox_inventory') == 'started' then
        local ok = exports.ox_inventory:RemoveItem(source, itemName, count)
        return ok == true
    end
    local fw = Config.Framework
    if fw == 'esx' then
        local ESX = getESX()
        local xPlayer = ESX and ESX.GetPlayerFromId(source)
        if not xPlayer then
            return false
        end
        xPlayer.removeInventoryItem(itemName, count)
        return true
    elseif fw == 'qb' or fw == 'qbox' then
        local QBCore = getQBCore()
        local player = QBCore and QBCore.Functions.GetPlayer(source)
        if not player then
            return false
        end
        return player.Functions.RemoveItem(itemName, count)
    end
    return false
end

Config._JpSentinel.InventoryBridge = Inv
