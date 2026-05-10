---@diagnostic disable: undefined-global

local L = PolaPaintUtil.L
local uiOpen      = false
local captureBusy = false

local function notify(msg)
    if type(msg) ~= 'string' or msg == '' then return end
    print(('^3[polapaint client]^7 %s'):format(msg))
    if GetResourceState('ox_lib') == 'started' then
        pcall(TriggerEvent, 'ox_lib:notify', {
            title = 'polapaint', description = msg,
            duration = 6000, position = 'top-right', type = 'inform',
        })
        return
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg:sub(1, 220))
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('polapaint:client:notify', function(msg) notify(msg) end)

--- polapaint://photo/<signed> → NUI から読み込めるリソース URL
---@param url string
---@return string
local function resolvePhotoUrl(url)
    if type(url) ~= 'string' then return '' end
    local signed = url:match('^polapaint://photo/(.+)$')
    if not signed then return url end
    return ('https://%s/photo/%s.jpg'):format(GetCurrentResourceName(), signed)
end

local function closeUi()
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setMode', mode = 'hidden' })
end

---@param payload table
local function openUi(payload)
    if type(payload) == 'table' and type(payload.imageUrl) == 'string' then
        payload.imageUrl = resolvePhotoUrl(payload.imageUrl)
    end
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(payload)
    SetTimeout(300000, function()
        if uiOpen then closeUi() end
    end)
end

CreateThread(function()
    while true do
        if uiOpen then
            Wait(0)
            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 202) then
                closeUi()
                Wait(200)
            end
        else
            Wait(500)
        end
    end
end)

local function isScreenshotBasicReady()
    return GetResourceState('screenshot-basic') == 'started'
end

--- ox_lib による名前入力（撮影フロー用・NUI fetch 不使用）
---@return string|nil
local function askPhotoName(maxLen)
    if GetResourceState('ox_lib') ~= 'started' then
        notify(L('notify_ox_lib_required'))
        return nil
    end
    local input = lib.inputDialog(L('nui_capture_name_title'), {
        {
            type = 'input',
            label = L('nui_capture_name_title'),
            placeholder = L('nui_capture_name_placeholder'),
            required = true,
            min = 1,
            max = maxLen or 40,
        },
    })
    if not input or not input[1] then return nil end
    local s = tostring(input[1]):gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then return nil end
    return s
end

--- 撮影フロー（exports / qb から）
local function startCaptureFlow()
    print('[polapaint] STEP1 startCaptureFlow entered')
    if uiOpen or captureBusy then notify(L('notify_busy')); return end
    if not isScreenshotBasicReady() then
        notify(L('notify_screenshot_basic_missing')); return
    end
    captureBusy = true
    notify(L('notify_capture_started'))
    print('[polapaint] STEP2 captureBusy=true, calling requestScreenshot')

    local q = Config.JpegQuality or 0.85
    local resolved = false
    SetTimeout(15000, function()
        if not resolved then
            resolved = true
            captureBusy = false
            notify(L('notify_capture_timeout'))
            print('[polapaint] STEP_TIMEOUT screenshot did not return in 15s')
        end
    end)

    local ok, err = pcall(function()
        exports['screenshot-basic']:requestScreenshot({
            encoding = 'jpg',
            quality = q,
        }, function(dataUri)
            print('[polapaint] STEP3 screenshot callback fired, type=' .. type(dataUri) .. ' len=' .. (type(dataUri) == 'string' and #dataUri or 0))
            if resolved then return end
            resolved = true

            if type(dataUri) ~= 'string' or dataUri == '' then
                captureBusy = false
                notify(L('notify_capture_fail'))
                print('[polapaint] STEP3a invalid dataUri')
                return
            end

            print('[polapaint] STEP4 calling askPhotoName')
            local name = askPhotoName(Config.MaxPhotoNameLength or 40)
            print('[polapaint] STEP5 askPhotoName returned: ' .. tostring(name))
            captureBusy = false
            if not name then
                notify(L('notify_capture_cancelled'))
                return
            end

            local b64 = dataUri:match('^data:image/[^;]+;base64,(.+)$') or dataUri
            print('[polapaint] STEP6 firing TriggerServerEvent uploadCapture, b64 len=' .. #b64)
            TriggerServerEvent('polapaint:server:uploadCapture', name, b64)
            print('[polapaint] STEP7 TriggerServerEvent done')
        end)
    end)
    print('[polapaint] STEP2.5 pcall returned ok=' .. tostring(ok) .. ' err=' .. tostring(err))

    if not ok then
        captureBusy = false
        resolved = true
        notify(L('notify_capture_fail'))
    end
end

exports('useCamera', function(_, _)
    startCaptureFlow()
end)

exports('usePhoto', function(data, slot)
    if uiOpen or captureBusy then notify(L('notify_busy')); return end
    local sn = slot and slot.slot
    if type(sn) ~= 'number' then return end
    TriggerServerEvent('polapaint:server:requestEdit', sn)
end)

exports('openPhotoViewer', function(slotId)
    if uiOpen or captureBusy then notify(L('notify_busy')); return end
    slotId = tonumber(slotId)
    if not slotId then return end
    local item = PolaPaintBridge.getSlotItem(slotId)
    if not item then notify(L('notify_slot_invalid')); return end

    local cfgPhoto = Config.Items and Config.Items.photo
    if cfgPhoto and item.name ~= cfgPhoto then
        notify(L('notify_slot_invalid')); return
    end
    local url = PolaPaintBridge.extractPhotoUrl(item)
    if not url then notify(L('notify_photo_no_url')); return end

    local meta = item.metadata or item.info or {}
    local cap = (type(meta.label) == 'string' and meta.label ~= '') and meta.label or L('nui_viewer_title')
    openUi({
        action = 'openViewer',
        imageUrl = url,
        strings = { close = L('nui_close'), title = cap },
    })
end)

RegisterNetEvent('polapaint:client:qbUseCamera', function()
    startCaptureFlow()
end)

RegisterNetEvent('polapaint:client:qbUsePhoto', function(slot)
    if uiOpen or captureBusy then notify(L('notify_busy')); return end
    slot = tonumber(slot)
    if not slot then return end
    TriggerServerEvent('polapaint:server:requestEdit', slot)
end)

RegisterNetEvent('polapaint:client:openPaint', function(payload)
    if uiOpen or captureBusy then return end
    if type(payload) ~= 'table' or type(payload.imageUrl) ~= 'string' then return end
    openUi({
        action    = 'openPaint',
        imageUrl  = payload.imageUrl,
        slot      = payload.slot,
        editToken = payload.editToken,
        quality   = Config.JpegQuality or 0.85,
        strings   = {
            close = L('nui_close'),
            save  = L('nui_save'),
            clear = L('nui_clear'),
            undo  = L('nui_undo'),
            penSize = L('nui_pen_size'),
        },
    })
end)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb({ ok = true })
end)

RegisterNUICallback('savePaint', function(data, cb)
    cb({ ok = true })
    if type(data) ~= 'table' then return end
    local token = data.token
    local slot = data.slot
    local image = data.image
    if type(token) ~= 'string' or token == '' then return end
    if type(image) ~= 'string' or image == '' then return end
    local slotNum = tonumber(slot)
    if not slotNum then return end
    closeUi()
    TriggerServerEvent('polapaint:server:uploadEdit', token, slotNum, image)
end)

RegisterCommand('polapaint_unstuck', function()
    closeUi()
    captureBusy = false
    notify(L('notify_ui_force_closed'))
end, false)
