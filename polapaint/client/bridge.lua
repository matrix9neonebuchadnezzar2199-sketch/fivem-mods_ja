PolaPaintBridge = {}

local detected = nil

---@return 'ox'|'qb'|nil
function PolaPaintBridge.detect()
    if detected then return detected end
    local cfg = (Config and Config.Framework) or 'auto'
    if cfg == 'ox' or cfg == 'qb' then detected = cfg; return cfg end
    if GetResourceState('ox_inventory') == 'started' then detected = 'ox'
    elseif GetResourceState('qb-inventory') == 'started' then detected = 'qb'
    end
    return detected
end

---@param slotId number
---@return table|nil { name=string, metadata=table }
function PolaPaintBridge.getSlotItem(slotId)
    local fw = PolaPaintBridge.detect()
    if fw == 'ox' then
        local inv = exports.ox_inventory:GetPlayerItems()
        return type(inv) == 'table' and inv[slotId] or nil
    elseif fw == 'qb' then
        local ok, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if not ok or not QBCore then return nil end
        local items = QBCore.Functions.GetPlayerData().items
        for _, it in pairs(items or {}) do
            if it and it.slot == slotId then
                return { name = it.name, metadata = it.info or {} }
            end
        end
    end
    return nil
end

---@param item table
function PolaPaintBridge.extractPhotoUrl(item)
    if not item then return nil end
    local m = item.metadata or item.info or {}
    if type(m.url) == 'string' and m.url ~= '' then return m.url end
    return nil
end
