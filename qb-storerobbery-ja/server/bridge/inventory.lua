--[[
    インベントリ互換レイヤー（ox_inventory / qb-inventory / qs-inventory）
    qb-storerobbery の報酬・ロックピック削除を複数インベントリに対応させる。
]]
local QBCore = exports['qb-core']:GetCoreObject()

local InventorySystem -- 'ox' | 'qb' | 'qs' | 'none'

-- 初回の AddItemCompat / RemoveItemCompat / Notify* で確定する（CreateThread 一本判定ではない）。
-- そのため ox_inventory の起動が本リソースより遅くても、プレイヤー操作までに通常は started になる。
local function detectInventory()
    if InventorySystem ~= nil then return end
    if GetResourceState('ox_inventory') == 'started' then
        InventorySystem = 'ox'
    elseif GetResourceState('qb-inventory') == 'started' then
        InventorySystem = 'qb'
    elseif GetResourceState('qs-inventory') == 'started' then
        InventorySystem = 'qs'
    else
        InventorySystem = 'none'
        print(('^1[%s] No supported inventory (ox_inventory / qb-inventory / qs-inventory). Item ops will fail.^7'):format(GetCurrentResourceName()))
        return
    end
    print(('^2[%s] Inventory bridge: %s^7'):format(GetCurrentResourceName(), InventorySystem))
end

function AddItemCompat(src, item, count, info, reason)
    detectInventory()
    if InventorySystem == 'none' then return false end

    local meta = info
    if meta == false then meta = nil end
    reason = reason or 'qb-storerobbery:reward'

    if InventorySystem == 'ox' then
        local metaOx = (type(meta) == 'table') and meta or {}
        local success, response = exports.ox_inventory:AddItem(src, item, count, metaOx)
        if not success then
            print(('^1[%s] ox_inventory:AddItem failed | item=%s count=%s | %s (undefined item -> add to ox_inventory/data/items.lua; see optional/ox_inventory_items_snippet.lua)^7'):format(
                GetCurrentResourceName(),
                tostring(item),
                tostring(count),
                tostring(response)
            ))
        end
        return success
    elseif InventorySystem == 'qb' then
        return exports['qb-inventory']:AddItem(src, item, count, false, meta, reason)
    elseif InventorySystem == 'qs' then
        return exports['qs-inventory']:AddItem(src, item, count, nil, meta)
    end
    return false
end

function RemoveItemCompat(src, item, count, reason)
    detectInventory()
    if InventorySystem == 'none' then return false end

    reason = reason or 'qb-storerobbery:remove'

    if InventorySystem == 'ox' then
        return exports.ox_inventory:RemoveItem(src, item, count)
    elseif InventorySystem == 'qb' then
        return exports['qb-inventory']:RemoveItem(src, item, count, false, reason)
    elseif InventorySystem == 'qs' then
        return exports['qs-inventory']:RemoveItem(src, item, count)
    end
    return false
end

-- qb-inventory の ItemBox のみ。ox / qs はインベントリ側の通知に任せる。
function NotifyItemAdded(src, itemName)
    detectInventory()
    if InventorySystem ~= 'qb' then return end
    local item = QBCore.Shared.Items[itemName]
    if item then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, item, 'add')
    end
end

function NotifyItemRemoved(src, itemName)
    detectInventory()
    if InventorySystem ~= 'qb' then return end
    local item = QBCore.Shared.Items[itemName]
    if item then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, item, 'remove')
    end
end
