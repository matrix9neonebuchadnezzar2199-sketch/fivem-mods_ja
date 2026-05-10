PolaPaintSvBridge = {}

local detected = nil

function PolaPaintSvBridge.detect()
    if detected then return detected end
    local cfg = (Config and Config.Framework) or 'auto'
    if cfg == 'ox' or cfg == 'qb' then detected = cfg; return cfg end
    if GetResourceState('ox_inventory') == 'started' then detected = 'ox'
    elseif GetResourceState('qb-inventory') == 'started' then detected = 'qb'
    end
    return detected
end

--- カメラ所持数
function PolaPaintSvBridge.cameraCount(src)
    local fw = PolaPaintSvBridge.detect()
    local cam = Config.Items and Config.Items.camera
    if not cam then return 0 end
    if fw == 'ox' then
        return exports.ox_inventory:Search(src, 'count', cam) or 0
    elseif fw == 'qb' then
        local ok, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if not ok or not QBCore then return 0 end
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return 0 end
        local n = 0
        for _, it in pairs(Player.PlayerData.items or {}) do
            if it and it.name == cam then n = n + (it.amount or 1) end
        end
        return n
    end
    return 0
end

--- 写真アイテム付与
---@return boolean ok, string|nil reason
function PolaPaintSvBridge.givePhoto(src, meta)
    local fw = PolaPaintSvBridge.detect()
    local photo = Config.Items and Config.Items.photo
    if not photo then return false, 'invalid_item' end
    if not fw then return false, 'no_framework' end
    if fw == 'ox' then
        local ok, reason = exports.ox_inventory:AddItem(src, photo, 1, meta)
        if ok then return true, nil end
        if Config.Debug then
            print(('[polapaint] ox_inventory AddItem failed item=%s meta_keys=%s reason=%s'):format(
                photo,
                type(meta) == 'table' and next(meta) and 'ok' or 'empty',
                tostring(reason)))
        end
        if reason == 'inventory_full' then return false, 'inventory_full' end
        if reason == 'cannot_carry' or reason == 'cannot_carry_other' then
            return false, reason
        end
        return false, reason or 'inventory_full'
    elseif fw == 'qb' then
        local ok, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if not ok or not QBCore then return false, 'invalid_item' end
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false, 'invalid_item' end
        local itemOk = Player.Functions.AddItem(photo, 1, false, meta)
        return itemOk, itemOk and nil or 'inventory_full'
    end
    return false, 'invalid_item'
end

---@return table|nil { name=string, metadata=table, slot=number }
function PolaPaintSvBridge.getSlot(src, slot)
    local fw = PolaPaintSvBridge.detect()
    if fw == 'ox' then
        local s = exports.ox_inventory:GetSlot(src, slot)
        if not s then return nil end
        return { name = s.name, metadata = s.metadata or {}, slot = s.slot }
    elseif fw == 'qb' then
        local ok, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if not ok or not QBCore then return nil end
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return nil end
        for _, it in pairs(Player.PlayerData.items or {}) do
            if it and it.slot == slot then
                return { name = it.name, metadata = it.info or {}, slot = it.slot }
            end
        end
    end
    return nil
end

function PolaPaintSvBridge.setMetadata(src, slot, newMeta)
    local fw = PolaPaintSvBridge.detect()
    if fw == 'ox' then
        return exports.ox_inventory:SetMetadata(src, slot, newMeta) ~= false
    elseif fw == 'qb' then
        local ok, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if not ok or not QBCore then return false end
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        local items = Player.PlayerData.items
        for k, it in pairs(items or {}) do
            if it and it.slot == slot then
                items[k].info = newMeta
                Player.Functions.SetPlayerData('items', items)
                return true
            end
        end
    end
    return false
end
