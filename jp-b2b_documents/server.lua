local paperCooldowns = {}

-- 初回起動時にテーブルを自動作成（手動で phpMyAdmin / HeidiSQL から流さなくてよい）
CreateThread(function()
    Wait(250)
    local p = promise.new()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `b2b_documents` (
            `id` VARCHAR(60) NOT NULL,
            `content` LONGTEXT NOT NULL,
            `title` VARCHAR(255) NOT NULL DEFAULT 'ドキュメント',
            `locked` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function()
        p:resolve(true)
    end)
    Citizen.Await(p)
    print('[jp-b2b_documents] データベース: b2b_documents テーブルを確認しました（無ければ作成済み）')
end)

local function awaitInvReady()
    local deadline = GetGameTimer() + 12000
    while not INV.name do
        Wait(25)
        if GetGameTimer() > deadline then
            print('[jp-b2b_documents] 警告: インベントリ検出がタイムアウトしました')
            return false
        end
    end
    return true
end

local function awaitDocExecute(query, params)
    local p = promise.new()
    exports.oxmysql:execute(query, params, function()
        p:resolve(true)
    end)
    return Citizen.Await(p)
end

AddEventHandler('playerDropped', function()
    paperCooldowns[source] = nil
end)

RegisterNetEvent('b2b_documents:server:requestPaper', function()
    local src = source
    if not awaitInvReady() then return end

    local now = os.time()
    if paperCooldowns[src] and (now - paperCooldowns[src]) < Config.PaperCooldown then
        FW.Notify(src, T('cooldown'), 'error')
        return
    end

    if INV.CanCarry(src, Config.Items.blank, 1) then
        paperCooldowns[src] = now
        local ok = INV.TryStackBlankPaperOx(src) or select(1, INV.AddItem(src, Config.Items.blank, 1, nil))
        if ok then
            FW.Notify(src, T('paper_taken'), 'success')
        else
            FW.Notify(src, T('pockets_full'), 'error')
        end
    else
        FW.Notify(src, T('pockets_full'), 'error')
    end
end)

lib.callback.register('b2b_documents:handleAction', function(source, data, ctx)
    ctx = ctx or {}
    if not awaitInvReady() then return false end

    if data.itemName and not INV.PlayerHasItemName(source, data.itemName) then
        return false
    end

    local itemName = data.itemName or ctx.itemName
    local item, slotNum = INV.FindPaperOrDocument(source, ctx.slot)

    local metadata = {}
    if INV.name == 'esx_inventory' then
        if itemName == Config.Items.document then
            metadata = INV.GetMetadata(source, nil, ctx.instanceId)
        else
            metadata = {}
        end
    else
        if not item then return false end
        slotNum = item.slot or slotNum
        metadata = item.metadata or item.info or {}
    end

    if not metadata.docId or metadata.docId == "nil" then
        metadata.docId = "DOC_" .. os.time() .. "_" .. math.random(100, 999)
    end

    if data.action == 'save' or data.action == 'lock' then
        local content = data.content
        if type(content) ~= 'string' then
            print(('[jp-b2b_documents] handleAction: content が string ではないため保存しません (%s)'):format(type(content)))
            return false
        end
        local shouldLock = (data.action == 'lock' or metadata.locked)
        local okDb = awaitDocExecute(
            'INSERT INTO b2b_documents (id, content, title, locked) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE content = VALUES(content), title = VALUES(title), locked = VALUES(locked)',
            { metadata.docId, content, data.title or T('ui_untitled'), shouldLock and 1 or 0 }
        )
        if not okDb then return false end

        local newMeta = {
            docId = metadata.docId,
            title = data.title,
            label = data.title,
            locked = shouldLock,
            description = shouldLock and T('ui_signed_locked') or T('ui_editable'),
        }

        local isBlank = false
        if INV.name == 'esx_inventory' then
            isBlank = (itemName == Config.Items.blank)
        else
            isBlank = item and item.name == Config.Items.blank
        end

        if isBlank then
            INV.RemoveItem(source, Config.Items.blank, 1, slotNum, nil)
            local ok, newInstanceId = INV.AddItem(source, Config.Items.document, 1, newMeta)
            return ok, metadata.docId, newInstanceId
        else
            if INV.name == 'esx_inventory' then
                INV.SetMetadata(source, nil, ctx.instanceId, newMeta)
            else
                INV.SetMetadata(source, slotNum, nil, newMeta)
            end
            return true, metadata.docId, ctx.instanceId
        end

    elseif data.action == 'duplicate' then
        if INV.name == 'esx_inventory' then
            if itemName ~= Config.Items.document then return false end
        else
            if not item or item.name ~= Config.Items.document then return false end
        end

        local newDocId = "DOC_" .. os.time() .. "_" .. math.random(100, 999)
        local copyTitle = (data.title or T('ui_untitled')) .. T('ui_copy_suffix')
        local dupContent = data.content
        if type(dupContent) ~= 'string' then
            print(('[jp-b2b_documents] duplicate: content が string ではない (%s)'):format(type(dupContent)))
            return false
        end
        local okDb = awaitDocExecute(
            'INSERT INTO b2b_documents (id, content, title, locked) VALUES (?, ?, ?, ?)',
            { newDocId, dupContent, copyTitle, 0 }
        )
        if not okDb then return false end

        local newMeta = {
            docId = newDocId,
            title = copyTitle,
            label = copyTitle,
            description = T('ui_editable'),
            locked = false,
        }
        local ok, newInstanceId = INV.AddItem(source, Config.Items.document, 1, newMeta)
        return ok, newDocId, newInstanceId
    end

    return false
end)

lib.callback.register('b2b_documents:getContent', function(source, docId)
    if not docId or docId == "nil" or docId == "" then return "" end

    local p = promise.new()
    exports.oxmysql:query('SELECT content FROM b2b_documents WHERE id = ? LIMIT 1', { docId }, function(result)
        if result and result[1] then
            p:resolve(result[1].content)
        else
            p:resolve("")
        end
    end)
    return Citizen.Await(p)
end)

lib.callback.register('b2b_documents:getFreshMetadata', function(source, ctx)
    ctx = ctx or {}
    if not awaitInvReady() then return {} end
    return INV.GetMetadata(source, ctx.slot, ctx.instanceId) or {}
end)

CreateThread(function()
    local deadline = GetGameTimer() + 15000
    while not FW.name or not INV.name do
        Wait(50)
        if GetGameTimer() > deadline then
            print('[jp-b2b_documents] UsableItem 登録をスキップ: 初期化タイムアウト')
            return
        end
    end

    if INV.name == 'ox_inventory' then
        return
    end

    local function openFromUse(src, item)
        local slot = item and item.slot or nil
        local instanceId = nil

        if INV.name == 'esx_inventory' and item and item.name == Config.Items.document then
            local owner = INV.GetOwnerId(src)
            local p = promise.new()
            exports.oxmysql:query(
                'SELECT link_id FROM b2b_documents_links WHERE owner = ? ORDER BY created_at DESC LIMIT 1',
                { owner },
                function(rows)
                    p:resolve(rows and rows[1] and rows[1].link_id or nil)
                end
            )
            instanceId = Citizen.Await(p)
        end

        TriggerClientEvent('b2b_documents:client:openUI', src, {
            slot = slot,
            instanceId = instanceId,
            itemName = item and item.name or nil,
            metadata = (item and (item.info or item.metadata)) or {},
        })
    end

    FW.RegisterUsableItem(Config.Items.blank, openFromUse)
    FW.RegisterUsableItem(Config.Items.document, openFromUse)
end)

-- ox_inventory: Items.Metadata が白紙に durability 等を付けるとスロット間でメタが一致せずスタックしない。
-- createItem で {} に寄せる（items.lua は stack = true かつ degrade 無し推奨）。
CreateThread(function()
    Wait(4000)
    if GetResourceState('ox_inventory') ~= 'started' then return end
    local reg = exports.ox_inventory and exports.ox_inventory.registerHook
    if not reg then return end
    local ok, err = pcall(function()
        reg('createItem', function(payload)
            local it = payload.item
            local n = (type(it) == 'table' and it.name) or (type(it) == 'string' and it) or nil
            if n ~= Config.Items.blank then return end
            return {}
        end, { itemFilter = { [Config.Items.blank] = true } })
    end)
    if ok then
        print('[jp-b2b_documents] ox_inventory: 白紙 createItem メタを {} に正規化（スタック用フック登録済み）')
    else
        print(('[jp-b2b_documents] ox_inventory createItem フック登録失敗: %s'):format(tostring(err)))
    end
end)
