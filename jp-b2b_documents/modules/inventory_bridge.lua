-- インベントリ抽象化: ox_inventory / qb-inventory / ESX 標準インベントリ

INV = INV or {}
INV.name = INV.name or nil


local function awaitExecute(query, params)
    local p = promise.new()
    exports.oxmysql:execute(query, params or {}, function()
        p:resolve(true)
    end)
    return Citizen.Await(p)
end

local function ensureLinksTable()
    awaitExecute([[
        CREATE TABLE IF NOT EXISTS `b2b_documents_links` (
            `link_id`    VARCHAR(60) NOT NULL,
            `owner`      VARCHAR(100) NOT NULL,
            `doc_id`     VARCHAR(60) NOT NULL,
            `title`      VARCHAR(255) DEFAULT 'ドキュメント',
            `locked`     TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`link_id`),
            INDEX `idx_owner` (`owner`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end

CreateThread(function()
    local deadline = GetGameTimer() + 15000
    while not FW.name do
        Wait(50)
        if GetGameTimer() > deadline then
            FW.name = 'standalone'
            break
        end
    end

    if Config.Inventory == "auto" then
        if GetResourceState('ox_inventory') == 'started' then
            INV.name = 'ox_inventory'
        elseif GetResourceState('qb-inventory') == 'started' then
            INV.name = 'qb-inventory'
        elseif FW.name == 'esx' then
            INV.name = 'esx_inventory'
        else
            INV.name = 'esx_inventory'
        end
    else
        INV.name = Config.Inventory
    end

    print(('[jp-b2b_documents] Inventory: %s'):format(INV.name))

    if INV.name == 'esx_inventory' then
        ensureLinksTable()
    end
end)

function INV.GetOwnerId(src)
    if FW.name == 'esx' then
        local xPlayer = FW.GetPlayer(src)
        return xPlayer and xPlayer.identifier or nil
    elseif FW.name == 'qbcore' or FW.name == 'qbox' then
        local player = FW.GetPlayer(src)
        return player and player.PlayerData and player.PlayerData.citizenid or nil
    end
    return tostring(src)
end

function INV.CanCarry(src, item, count)
    count = count or 1
    if INV.name == 'ox_inventory' then
        return exports.ox_inventory:CanCarryItem(src, item, count)
    elseif INV.name == 'qb-inventory' then
        local ok, res = pcall(function()
            return exports['qb-inventory']:CanAddItem(src, item, count)
        end)
        return ok and res or false
    elseif INV.name == 'esx_inventory' then
        local xPlayer = FW.GetPlayer(src)
        if not xPlayer then return false end
        local invItem = xPlayer.getInventoryItem(item)
        if not invItem then return true end
        if invItem.limit and invItem.limit ~= -1 then
            return (invItem.count + count) <= invItem.limit
        end
        return true
    end
    return false
end

function INV.AddItem(src, item, count, metadata)
    count = count or 1

    if INV.name == 'ox_inventory' then
        -- 空の {} を渡すと「メタあり」とみなされ、stack=true でも既存スロットと合流しないことがある（nil に正規化）
        local meta = metadata
        if type(meta) == 'table' and next(meta) == nil then
            meta = nil
        end
        local ok = exports.ox_inventory:AddItem(src, item, count, meta)
        return ok and true or false, nil

    elseif INV.name == 'qb-inventory' then
        local qbMeta = metadata or {}
        local ok, res = pcall(function()
            return exports['qb-inventory']:AddItem(src, item, count, false, qbMeta, 'jp-b2b_documents:add')
        end)
        if ok and res and FW.name == 'qbcore' and FW.object then
            local sharedItem = FW.object.Shared.Items[item]
            if sharedItem then
                TriggerClientEvent('qb-inventory:client:ItemBox', src, sharedItem, 'add', count)
            end
        end
        return ok and res and true or false, nil

    elseif INV.name == 'esx_inventory' then
        local xPlayer = FW.GetPlayer(src)
        if not xPlayer then return false, nil end

        xPlayer.addInventoryItem(item, count)

        if item == Config.Items.document then
            local owner = INV.GetOwnerId(src)
            local linkId = ('LNK_%s_%d_%d'):format(owner or 'na', os.time(), math.random(1000, 9999))
            awaitExecute(
                'INSERT INTO b2b_documents_links (link_id, owner, doc_id, title, locked) VALUES (?, ?, ?, ?, ?)',
                { linkId, owner, metadata.docId or 'nil', metadata.title or T('ui_untitled'), metadata.locked and 1 or 0 }
            )
            return true, linkId
        end
        return true, nil
    end
    return false, nil
end

function INV.RemoveItem(src, item, count, slot, instanceId)
    count = count or 1
    if INV.name == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(src, item, count, nil, slot) and true or false
    elseif INV.name == 'qb-inventory' then
        local ok, res = pcall(function()
            return exports['qb-inventory']:RemoveItem(src, item, count, slot, 'jp-b2b_documents:remove')
        end)
        return ok and res and true or false
    elseif INV.name == 'esx_inventory' then
        local xPlayer = FW.GetPlayer(src)
        if not xPlayer then return false end
        xPlayer.removeInventoryItem(item, count)
        if instanceId and item == Config.Items.document then
            awaitExecute('DELETE FROM b2b_documents_links WHERE link_id = ?', { instanceId })
        end
        return true
    end
    return false
end

function INV.GetSlot(src, slot)
    if not slot then return nil end
    if INV.name == 'ox_inventory' then
        return exports.ox_inventory:GetSlot(src, slot)
    elseif INV.name == 'qb-inventory' then
        local ok, item = pcall(function()
            return exports['qb-inventory']:GetItemBySlot(src, slot)
        end)
        return ok and item or nil
    end
    return nil
end

function INV.FindPaperOrDocument(src, slot)
    local slotNum = tonumber(slot)
    if INV.name == 'ox_inventory' or INV.name == 'qb-inventory' then
        local direct = INV.GetSlot(src, slotNum)
        if direct and (direct.name == Config.Items.blank or direct.name == Config.Items.document) then
            return direct, slotNum
        end
        if INV.name == 'ox_inventory' then
            local slots = exports.ox_inventory:Search(src, 'slots', Config.Items.blank)
            if slots and slots[1] then return slots[1], slots[1].slot end
            slots = exports.ox_inventory:Search(src, 'slots', Config.Items.document)
            if slots and slots[1] then return slots[1], slots[1].slot end
        else
            local ok, item = pcall(function()
                return exports['qb-inventory']:GetItemByName(src, Config.Items.blank)
            end)
            if ok and item then return item, item.slot end
            ok, item = pcall(function()
                return exports['qb-inventory']:GetItemByName(src, Config.Items.document)
            end)
            if ok and item then return item, item.slot end
        end
    end
    return nil, nil
end

function INV.GetMetadata(src, slot, instanceId)
    if INV.name == 'ox_inventory' then
        local item = exports.ox_inventory:GetSlot(src, tonumber(slot))
        if item and item.metadata then return item.metadata end
        return {}
    elseif INV.name == 'qb-inventory' then
        local item = INV.GetSlot(src, slot)
        if item and item.info then return item.info end
        return {}
    elseif INV.name == 'esx_inventory' then
        if not instanceId then return {} end
        local p = promise.new()
        exports.oxmysql:query('SELECT doc_id, title, locked FROM b2b_documents_links WHERE link_id = ? LIMIT 1',
            { instanceId }, function(rows)
                if rows and rows[1] then
                    p:resolve({
                        docId = rows[1].doc_id,
                        title = rows[1].title,
                        locked = rows[1].locked == 1,
                    })
                else
                    p:resolve({})
                end
            end)
        return Citizen.Await(p)
    end
    return {}
end

function INV.SetMetadata(src, slot, instanceId, metadata)
    if INV.name == 'ox_inventory' then
        return exports.ox_inventory:SetMetadata(src, tonumber(slot), metadata)
    elseif INV.name == 'qb-inventory' then
        local it = INV.GetSlot(src, tonumber(slot))
        local nm = (it and it.name) or Config.Items.document
        local ok = pcall(function()
            exports['qb-inventory']:SetItemData(src, nm, 'info', metadata, tonumber(slot))
        end)
        return ok
    elseif INV.name == 'esx_inventory' then
        if not instanceId then return false end
        awaitExecute(
            'UPDATE b2b_documents_links SET title = ?, locked = ?, doc_id = ? WHERE link_id = ?',
            {
                metadata.title or T('ui_untitled'),
                metadata.locked and 1 or 0,
                metadata.docId or 'nil',
                instanceId,
            }
        )
        return true
    end
    return false
end

function INV.PlayerHasItemName(src, itemName)
    if not itemName then return false end
    if INV.name == 'ox_inventory' then
        local n = exports.ox_inventory:Search(src, 'count', itemName)
        return (tonumber(n) or 0) > 0
    elseif INV.name == 'qb-inventory' then
        local ok, item = pcall(function()
            return exports['qb-inventory']:GetItemByName(src, itemName)
        end)
        return ok and item and (item.amount or item.count or 0) > 0
    elseif INV.name == 'esx_inventory' then
        local xPlayer = FW.GetPlayer(src)
        if not xPlayer then return false end
        local invItem = xPlayer.getInventoryItem(itemName)
        return invItem and invItem.count > 0
    end
    return false
end
