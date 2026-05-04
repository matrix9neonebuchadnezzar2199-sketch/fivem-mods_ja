-- ══════════════════════════════════════════════════════════════
--  jp-UV-Books 2.0  ·  client.lua
-- ══════════════════════════════════════════════════════════════

local function _L(key, ...)
    local t = Locales[Config.Locale] or Locales.en
    local s = t[key] or Locales.en[key] or key
    if select('#', ...) > 0 then return string.format(s, ...) end
    return s
end

local MAX_PAGES = Config.MaxPages or 20
local MAX_CHARS = Config.MaxCharsPerPage or 600
local UI_SCALE = tonumber(Config.UiScale) or 1.0
if UI_SCALE < 0.45 then UI_SCALE = 0.45 elseif UI_SCALE > 1.4 then UI_SCALE = 1.4 end
local isWriting = false

local Framework = nil
local QBCore    = nil
local ESX       = nil

CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
        QBCore = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
        if exports['es_extended'] and exports['es_extended'].getSharedObject then
            ESX = exports['es_extended']:getSharedObject()
        else
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        end
    end
end)

local function Notify(msg, nType)
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ description = msg, type = nType or 'info' })
    elseif Framework == 'qb' and QBCore then
        QBCore.Functions.Notify(msg, nType)
    elseif Framework == 'esx' and ESX then
        ESX.ShowNotification(msg)
    else
        print('[jp-uv-books] ' .. (nType or 'info') .. ': ' .. msg)
    end
end

local function PushLocaleToNui()
    SendNUIMessage({
        action  = 'setLocale',
        locale  = Config.Locale,
        strings = Locales[Config.Locale] or Locales.en,
        config  = {
            maxPages       = MAX_PAGES,
            maxChars       = MAX_CHARS,
            maxTitleChars  = Config.MaxTitleChars  or 30,
            maxAuthorChars = Config.MaxAuthorChars or 20,
            maxGenreChars  = Config.MaxGenreChars  or 30,
            uiScale        = UI_SCALE,
        },
    })
end

RegisterNUICallback('uiReady', function(_, cb)
    PushLocaleToNui()
    cb('ok')
end)

RegisterNetEvent('uv-books:client:startWriting', function(draft)
    if isWriting then return end
    isWriting = true
    SetNuiFocus(true, true)
    PushLocaleToNui()

    local msg = { action = 'openBookWriter' }
    if draft and type(draft) == 'table' then msg.draft = draft end
    SendNUIMessage(msg)

    Citizen.CreateThread(function()
        local ticks = 0
        while isWriting and ticks < 10 do
            Citizen.Wait(500)
            if isWriting then SetNuiFocus(true, true) end
            ticks = ticks + 1
        end
    end)
end)

RegisterNetEvent('uv-books:client:readBook', function(info, page)
    if not info then Notify(_L('book_corrupted'), 'error'); return end
    if isWriting then return end
    isWriting = true
    SetNuiFocus(true, true)
    PushLocaleToNui()
    SendNUIMessage({
        action = 'openBookReader',
        info   = info,
        page   = page or 1,
    })

    Citizen.CreateThread(function()
        local ticks = 0
        while isWriting and ticks < 10 do
            Citizen.Wait(500)
            if isWriting then SetNuiFocus(true, true) end
            ticks = ticks + 1
        end
    end)
end)

local lastEsc = 0
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isWriting then
            local now = GetGameTimer()
            if (now - lastEsc) > 600 then
                if IsControlJustPressed(0, 202) or IsControlJustPressed(0, 322) then
                    lastEsc = now
                    SendNUIMessage({ action = 'escPressed' })
                end
            end
        end
    end
end)

RegisterNUICallback('draftSaved', function(_, cb) cb('ok') end)

RegisterNUICallback('bookPublished', function(data, cb)
    cb('ok')
    if not data then return end
    local pages = {}
    for i = 1, MAX_PAGES do
        local raw = data.pages[i] or data.pages[tostring(i)] or data.pages[i - 1] or ''
        if type(raw) ~= 'string' then raw = '' end
        local len = utf8 and utf8.len(raw) or #raw
        if len and len > MAX_CHARS then
            local cut, cnt = '', 0
            for _, c in utf8.codes(raw) do
                cnt = cnt + 1
                if cnt > MAX_CHARS then break end
                cut = cut .. utf8.char(c)
            end
            raw = cut
        end
        pages[i] = raw
    end

    local bookDraft = {
        title     = type(data.title) == 'string' and data.title or _L('ui_untitled'),
        pages     = pages,
        images    = data.images or {},
        genre     = type(data.genre) == 'string' and data.genre or '',
        font      = type(data.font) == 'string' and data.font or '',
        signed    = data.signed == true,
        signature = type(data.signature) == 'string' and data.signature or '',
    }

    TriggerServerEvent('uv-books:server:createBook', bookDraft)
    isWriting = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

RegisterNUICallback('bookDraftSaved', function(data, cb)
    cb('ok')
    if not data then return end
    local draft = {
        title  = type(data.title) == 'string' and data.title or '',
        pages  = data.pages or {},
        images = data.images or {},
        font   = type(data.font) == 'string' and data.font or '',
    }
    TriggerServerEvent('uv-books:server:saveDraft', draft)
    isWriting = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

RegisterNUICallback('bookClosed', function(_, cb)
    isWriting = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    cb('ok')
end)