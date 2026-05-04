-- ══════════════════════════════════════════════════════════════
--  jp-UV-Books 2.0  ·  server.lua
--  Supports: ESX (Legacy), QBCore, QBox (qbx_core)
--  Inventories: ox_inventory, jaksam_inventory, qb/qs/ps/lj-inventory,
--               ESX default (limited)
-- ══════════════════════════════════════════════════════════════

local function _L(key, ...)
    local t = Locales[Config.Locale] or Locales.en
    local s = t[key] or Locales.en[key] or key
    if select('#', ...) > 0 then return string.format(s, ...) end
    return s
end

local MAX_PAGES   = Config.MaxPages or 20
local MAX_CHARS   = Config.MaxCharsPerPage or 600
local ITEM_NAME   = Config.ItemName or 'book'

local Framework = nil
local Inventory = nil
local QBCore    = nil
local ESX       = nil

local function dbg(...)
    if Config.Debug then print('[jp-uv-books]', ...) end
end

CreateThread(function()
    if Config.ForceFramework then
        Framework = Config.ForceFramework
    elseif GetResourceState('qbx_core') == 'started' then
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
    end

    if Framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif Framework == 'esx' then
        if exports['es_extended'] and exports['es_extended'].getSharedObject then
            ESX = exports['es_extended']:getSharedObject()
        else
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        end
    end

    if not Framework then
        print('[jp-uv-books] ^1' .. _L('no_framework') .. '^0')
    else
        print('[jp-uv-books] Framework: ' .. Framework)
    end

    if Config.ForceInventory then
        Inventory = Config.ForceInventory
    elseif GetResourceState('jaksam_inventory') == 'started' then
        Inventory = 'jaksam'
    elseif GetResourceState('ox_inventory') == 'started' then
        Inventory = 'ox'
    elseif GetResourceState('qb-inventory') == 'started'
        or GetResourceState('qs-inventory') == 'started'
        or GetResourceState('ps-inventory') == 'started'
        or GetResourceState('lj-inventory') == 'started' then
        Inventory = 'qb'
    elseif Framework == 'esx' then
        Inventory = 'esx_default'
    else
        Inventory = (Framework == 'qbx') and 'ox' or 'qb'
    end

    print('[jp-uv-books] Inventory: ' .. tostring(Inventory))

    if Inventory == 'esx_default' and Config.WarnEsxDefaultInventory then
        print('[jp-uv-books] ^3' .. _L('esx_default_warn') .. '^0')
    end
end)

local function GetPlayer(src)
    if Framework == 'esx' and ESX then
        return ESX.GetPlayerFromId(src)
    elseif Framework == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif Framework == 'qb' and QBCore then
        return QBCore.Functions.GetPlayer(src)
    end
    return nil
end

local function Notify(src, msg, nType)
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', src, {
            description = msg,
            type        = nType or 'info',
        })
    elseif Framework == 'esx' then
        TriggerClientEvent('esx:showNotification', src, msg)
    elseif Framework == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, msg, nType)
    elseif Framework == 'qbx' then
        exports.qbx_core:Notify(src, msg, nType)
    end
end

local function AddItem(src, item, count, metadata)
    if Inventory == 'ox' then
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    elseif Inventory == 'jaksam' then
        return exports.jaksam_inventory:AddItem(src, item, count, metadata)
    elseif Framework == 'esx' then
        local xPlayer = GetPlayer(src); if not xPlayer then return false end
        xPlayer.addInventoryItem(item, count)
        return true
    else
        local Player = GetPlayer(src); if not Player then return false end
        return Player.Functions.AddItem(item, count, false, metadata)
    end
end

local function RemoveItem(src, item, count, slot)
    if Inventory == 'ox' then
        return exports.ox_inventory:RemoveItem(src, item, count, nil, slot)
    elseif Inventory == 'jaksam' then
        return exports.jaksam_inventory:RemoveItem(src, item, count, nil, slot)
    elseif Framework == 'esx' then
        local xPlayer = GetPlayer(src); if not xPlayer then return false end
        xPlayer.removeInventoryItem(item, count)
        return true
    else
        local Player = GetPlayer(src); if not Player then return false end
        return Player.Functions.RemoveItem(item, count, slot)
    end
end

local function SetMetadata(src, slot, metadata)
    if Inventory == 'ox' then
        exports.ox_inventory:SetMetadata(src, slot, metadata)
        return true
    elseif Inventory == 'jaksam' then
        exports.jaksam_inventory:SetMetadata(src, slot, metadata)
        return true
    elseif Inventory == 'qb' then
        local ok = RemoveItem(src, ITEM_NAME, 1, slot)
        if ok then return AddItem(src, ITEM_NAME, 1, metadata) end
        return false
    else
        return false
    end
end

local ActiveWriters = {}

RegisterNetEvent('uv-books:server:createBook', function(bookData)
    local src    = source
    local Player = GetPlayer(src)
    if not Player or not bookData or type(bookData.pages) ~= 'table' then return end

    if #bookData.pages > MAX_PAGES then
        print('[jp-uv-books] Exploit: too many pages from ' .. src); return
    end

    local hasContent = false
    for i = 1, MAX_PAGES do
        local page = bookData.pages[i] or bookData.pages[tostring(i)] or ''
        if type(page) ~= 'string' then
            print('[jp-uv-books] Exploit: invalid page type from ' .. src); return
        end
        local len = utf8 and utf8.len(page) or #page
        if len and len > MAX_CHARS then
            print('[jp-uv-books] Exploit: page too long from ' .. src); return
        end
        if page ~= '' then hasContent = true end
    end

    if not hasContent then
        Notify(src, _L('empty_book'), 'error'); return
    end

    local author = (bookData.signed and bookData.signature ~= '') and bookData.signature or _L('ui_unknown_author')
    local genre  = (bookData.genre and bookData.genre ~= '') and bookData.genre or nil

    local title = bookData.title or _L('ui_untitled')
    local desc  = '「' .. title .. '」　' .. _L('ui_reader_by', author)
    if genre then desc = desc .. '　・　' .. genre end

    local writerInfo = ActiveWriters[src]
    if writerInfo and writerInfo.slot then
        RemoveItem(src, ITEM_NAME, 1, writerInfo.slot)
    elseif Inventory == 'esx_default' then
        RemoveItem(src, ITEM_NAME, 1, nil)
    end
    ActiveWriters[src] = nil

    local info = {
        title       = title,
        author      = author,
        content     = bookData.pages,
        images      = bookData.images or {},
        genre       = genre or '',
        font        = bookData.font or '',
        signed      = bookData.signed or false,
        signature   = bookData.signature or '',
        description = desc,
    }

    local success = AddItem(src, ITEM_NAME, 1, info)
    Notify(src,
        success and _L('book_published') or _L('book_publish_failed'),
        success and 'success' or 'error')
end)

RegisterNetEvent('uv-books:server:saveDraft', function(draftData)
    local src = source
    if not GetPlayer(src) or not draftData then return end

    if Inventory == 'esx_default' then
        Notify(src, _L('draft_save_failed') .. ' (ESX default)', 'error')
        ActiveWriters[src] = nil
        return
    end

    local writerInfo = ActiveWriters[src]
    if not writerInfo or not writerInfo.slot then
        Notify(src, _L('draft_save_failed'), 'error'); return
    end

    local draftMeta = {
        draft = {
            title  = draftData.title or '',
            pages  = draftData.pages or {},
            images = draftData.images or {},
            font   = draftData.font or '',
        }
    }

    local success = SetMetadata(src, writerInfo.slot, draftMeta)
    ActiveWriters[src] = nil

    Notify(src,
        success and _L('draft_saved') or _L('draft_save_failed'),
        success and 'success' or 'error')
end)

local function OnBookUsed(src, item)
    local info = (item and item.info) or (item and item.metadata) or {}
    local slot = item and item.slot
    ActiveWriters[src] = { slot = slot }

    if info.content and type(info.content) == 'table' and next(info.content) ~= nil then
        ActiveWriters[src] = nil
        TriggerClientEvent('uv-books:client:readBook', src, info)
    elseif info.draft and type(info.draft) == 'table' then
        TriggerClientEvent('uv-books:client:startWriting', src, info.draft)
    else
        TriggerClientEvent('uv-books:client:startWriting', src)
    end
end

exports(ITEM_NAME, function(event, item, inventory, slot, data)
    if event ~= 'usingItem' then return end
    local src = inventory.id
    local slotData = exports.ox_inventory:GetSlot(src, slot)
    local info = (slotData and slotData.metadata) or {}
    ActiveWriters[src] = { slot = slot }

    if info.content and type(info.content) == 'table' and next(info.content) ~= nil then
        ActiveWriters[src] = nil
        TriggerClientEvent('uv-books:client:readBook', src, info)
    elseif info.draft and type(info.draft) == 'table' then
        TriggerClientEvent('uv-books:client:startWriting', src, info.draft)
    else
        TriggerClientEvent('uv-books:client:startWriting', src)
    end
end)

CreateThread(function()
    local deadline = GetGameTimer() + 15000
    while Framework == nil and GetGameTimer() < deadline do
        Wait(100)
    end
    if Framework == nil then
        print('[jp-uv-books] ^1' .. _L('no_framework') .. ' (init timeout)^0')
        return
    end

    if Inventory == 'jaksam' then
        exports['jaksam_inventory']:registerUsableItem(ITEM_NAME, function(playerId, item)
            OnBookUsed(playerId, item)
        end)
        dbg('Registered useable item via jaksam_inventory')

    elseif Inventory == 'qb' then
        if Framework == 'qb' and QBCore then
            QBCore.Functions.CreateUseableItem(ITEM_NAME, function(source, item)
                OnBookUsed(source, item)
            end)
            dbg('Registered useable item via QBCore')
        elseif Framework == 'qbx' then
            local core = exports['qb-core']:GetCoreObject()
            if core then
                core.Functions.CreateUseableItem(ITEM_NAME, function(source, item)
                    OnBookUsed(source, item)
                end)
                dbg('Registered useable item via QBox bridge')
            end
        elseif Framework == 'esx' and ESX then
            ESX.RegisterUsableItem(ITEM_NAME, function(source)
                OnBookUsed(source, { slot = nil })
            end)
            dbg('Registered useable item via ESX (qb-style inv bridge)')
        end

    elseif Inventory == 'esx_default' and ESX then
        ESX.RegisterUsableItem(ITEM_NAME, function(source)
            OnBookUsed(source, { slot = nil })
        end)
        dbg('Registered useable item via ESX default inventory')

    else
        dbg('Using ox_inventory export for item registration')
    end
end)

AddEventHandler('playerDropped', function()
    ActiveWriters[source] = nil
end)