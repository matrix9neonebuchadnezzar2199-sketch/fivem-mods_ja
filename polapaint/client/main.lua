---@diagnostic disable: undefined-global

local uiOpen = false
local captureBusy = false

---@return string
local function L(key)
    local pack = Locales[Config.Locale or 'ja']
    if type(pack) == 'table' and pack[key] then
        return pack[key]
    end
    return key
end

---@param msg string
local function notify(msg)
    if type(msg) ~= 'string' or msg == '' then return end
    -- ox_lib（ox_inventory と併用されることが多い）があれば確実に表示される
    if GetResourceState('ox_lib') == 'started' then
        local ok = pcall(function()
            exports.ox_lib:notify({
                title = 'polapaint',
                description = msg,
                duration = 7500,
                position = 'top-right',
            })
        end)
        if ok then return end
    end
    -- ネイティブは長文・日本語で出ない環境があるため短くし、KeyboardDisplay を使う
    local short = msg
    if #short > 220 then
        short = short:sub(1, 217) .. '...'
    end
    local okFeed = pcall(function()
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringKeyboardDisplay(short)
        EndTextCommandThefeedPostTicker(false, true)
    end)
    if not okFeed then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(short)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

local function closeUi()
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setMode', mode = 'hidden' })
end

---@param payload table
local function openUi(payload)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(payload)
end

CreateThread(function()
    while true do
        if uiOpen then
            Wait(0)
            if IsControlJustPressed(0, 202) or IsControlJustPressed(0, 322) then
                closeUi()
                Wait(200)
            end
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('polapaint:client:notify', function(msg)
    if type(msg) == 'string' and msg ~= '' then
        notify(msg)
    end
end)

-- NUI からの軽量通知（postNui の fetch 失敗・画像加工失敗など）
RegisterNUICallback('ppNuiAlert', function(data, cb)
    cb('ok')
    if type(data) == 'string' then
        local ok, decoded = pcall(json.decode, data)
        if ok and type(decoded) == 'table' then
            data = decoded
        end
    end
    local key = data and data.key
    if type(key) == 'string' and key ~= '' then
        notify(L(key))
    end
end)

---@param data table|nil
---@param slot table|nil
local function slotPhotoUrl(data, slot)
    local meta = (slot and slot.metadata) or (data and data.metadata) or {}
    local u = meta.url
    if type(u) == 'string' and u ~= '' then
        return u
    end
    return nil
end

---@param slotNum number
---@return table|nil
local function getSlotItem(slotNum)
    local inv = exports.ox_inventory:GetPlayerItems()
    if type(inv) ~= 'table' then return nil end
    return inv[slotNum]
end

---@return boolean
local function isScreenshotBasicReady()
    return GetResourceState('screenshot-basic') == 'started'
end

-- ox_inventory items.lua: client.export = 'polapaint.useCamera'
exports('useCamera', function(_, _)
    if uiOpen or captureBusy then return end
    if not isScreenshotBasicReady() then
        notify(L('notify_screenshot_basic_missing'))
        return
    end
    TriggerServerEvent('polapaint:server:requestCapture')
end)

RegisterNetEvent('polapaint:client:doCapture', function()
    if captureBusy or uiOpen then return end
    if not isScreenshotBasicReady() then
        notify(L('notify_screenshot_basic_missing'))
        return
    end
    captureBusy = true
    notify(L('notify_capture_started'))
    local enc = 'jpg'
    local q = Config.JpegQuality or 0.85
    local ok, err = pcall(function()
        exports['screenshot-basic']:requestScreenshot({
            encoding = enc,
            quality = q,
        }, function(dataUri)
            captureBusy = false
            if type(dataUri) ~= 'string' or dataUri == '' then
                notify(L('notify_capture_fail'))
                return
            end
            uiOpen = true
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'downscaleScreenshot',
                dataUri = dataUri,
                maxWidth = Config.MaxImageWidth or 2560,
                quality = q,
                maxNameLength = Config.MaxPhotoNameLength or 40,
                nameDialog = {
                    title = L('nui_capture_name_title'),
                    placeholder = L('nui_capture_name_placeholder'),
                    confirm = L('nui_capture_confirm'),
                    cancel = L('nui_capture_cancel'),
                },
            })
        end)
    end)
    if not ok then
        captureBusy = false
        if Config.Debug then
            print(('[polapaint] requestScreenshot failed: %s'):format(tostring(err)))
        end
        notify(L('notify_capture_fail'))
    end
end)

-- ox_inventory: client.export = 'polapaint.usePhoto'（編集）
exports('usePhoto', function(data, slot)
    if uiOpen or captureBusy then return end
    local url = slotPhotoUrl(data, slot)
    if not url then
        notify(L('notify_photo_no_url'))
        return
    end
    local sn = slot and slot.slot
    if type(sn) ~= 'number' then return end
    openUi({
        action = 'openPaint',
        imageUrl = url,
        slot = sn,
        quality = Config.JpegQuality or 0.85,
        strings = {
            close = L('nui_close'),
            save = L('nui_save'),
            clear = L('nui_clear'),
            undo = L('nui_undo'),
            penSize = L('nui_pen_size'),
        },
    })
end)

-- ox_inventory items.lua の buttons から: exports['polapaint']:openPhotoViewer(slot)
---@param slotId number inventory スロット番号
exports('openPhotoViewer', function(slotId)
    if uiOpen or captureBusy then return end
    slotId = tonumber(slotId)
    if not slotId then return end
    local item = getSlotItem(slotId)
    if not item then
        notify(L('notify_slot_invalid'))
        return
    end
    local photoName = Config.Items and Config.Items.photo
    if type(photoName) == 'string' and item.name ~= photoName then
        notify(L('notify_slot_invalid'))
        return
    end
    local url = slotPhotoUrl(nil, item)
    if not url then
        notify(L('notify_photo_no_url'))
        return
    end
    local meta = item.metadata or {}
    local cap = type(meta.label) == 'string' and meta.label ~= '' and meta.label or L('nui_viewer_title')
    openUi({
        action = 'openViewer',
        imageUrl = url,
        strings = {
            close = L('nui_close'),
            title = cap,
        },
    })
end)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb('ok')
end)

RegisterNUICallback('captureWithName', function(data, cb)
    cb('ok')
    if type(data) == 'string' then
        local ok, decoded = pcall(json.decode, data)
        if ok and type(decoded) == 'table' then
            data = decoded
        end
    end
    local b64 = data and data.base64
    local name = data and data.name
    if type(name) ~= 'string' then name = '' end
    name = name:gsub('^%s+', ''):gsub('%s+$', '')
    if type(b64) ~= 'string' or b64 == '' then
        closeUi()
        notify(L('notify_capture_fail'))
        return
    end
    closeUi()
    TriggerServerEvent('polapaint:server:submitCapture', b64, name)
end)

RegisterNUICallback('savePaint', function(data, cb)
    cb('ok')
    if type(data) == 'string' then
        local ok, decoded = pcall(json.decode, data)
        if ok and type(decoded) == 'table' then
            data = decoded
        end
    end
    local slot = data and tonumber(data.slot)
    local b64 = data and data.base64
    if not slot or type(b64) ~= 'string' or b64 == '' then
        notify(L('notify_edit_fail'))
        return
    end
    TriggerServerEvent('polapaint:server:submitEdited', slot, b64)
end)
