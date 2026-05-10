---@diagnostic disable: undefined-global

local L = PolaPaintUtil.L
local now = PolaPaintUtil.now

local cooldown    = { capture = {}, edit = {} }
local pendingEdit = {}

local function notify(src, key)
    TriggerClientEvent('polapaint:client:notify', src, L(key))
end

local function peekCooldown(src, kind, sec)
    local prev = cooldown[kind][src]
    return not prev or (now() - prev) >= (sec * 1000)
end

local function markCooldown(src, kind)
    cooldown[kind][src] = now()
end

--- data:image/...;base64, を除去（クライアントが素の base64 だけ送る場合もそのまま通す）
local function stripDataUriPayload(s)
    if type(s) ~= 'string' then return '' end
    local raw = s:match('^data:image/[^;]+;base64,(.+)$') or s
    return raw
end

local function normalizePhotoLabel(label)
    local maxLen = Config.MaxPhotoNameLength or 40
    if type(label) ~= 'string' then return nil end
    label = label:gsub('^%s+', ''):gsub('%s+$', '')
    if label == '' then return nil end
    if PolaPaintUtil.hasControl(label) then return nil end
    local len = PolaPaintUtil.utf8len(label)
    if not len or len < 1 or len > maxLen then return nil end
    return label
end

local function buildPhotoMeta(id, label)
    local signed = PolaPaintStorage.publicUrl(id)
    return {
        url   = ('polapaint://photo/%s'):format(signed),
        label = label,
        ts    = os.time(),
    }
end

local function webhookImageUrlForId(id)
    local pub = Config.Webhook and Config.Webhook.publicBaseUrl
    if type(pub) ~= 'string' or pub == '' then return nil end
    local signed = PolaPaintStorage.publicUrl(id)
    pub = pub:gsub('/$', '')
    return ('%s/photo/%s.jpg'):format(pub, signed)
end

RegisterNetEvent('polapaint:server:uploadCapture', function(name, b64)
    local src = source
    if type(name) ~= 'string' or type(b64) ~= 'string' then return end

    if Config.Debug then
        print(('[polapaint] uploadCapture from src=%d, name=%s, b64_len=%d'):format(
            src, name, #b64))
    end

    if not peekCooldown(src, 'capture', Config.CaptureCooldownSec or 4) then
        notify(src, 'notify_capture_cooldown'); return
    end

    local label = normalizePhotoLabel(name)
    if not label then notify(src, 'notify_photo_name_invalid'); return end

    if PolaPaintSvBridge.cameraCount(src) < 1 then
        notify(src, 'notify_no_camera'); return
    end

    local maxBytes = (Config.Storage and Config.Storage.maxBytes) or (4 * 1024 * 1024)
    if #b64 > math.floor(maxBytes * 1.4) + 65536 then
        notify(src, 'notify_payload_too_large'); return
    end

    local bin = PolaPaintUtil.b64decode(stripDataUriPayload(b64))
    if not bin then
        notify(src, 'notify_storage_fail')
        if Config.Debug then print('[polapaint] b64decode failed') end
        return
    end

    local id, err = PolaPaintStorage.savePhoto(bin)
    if not id then
        if err == 'too_large' then notify(src, 'notify_payload_too_large')
        else notify(src, 'notify_storage_fail') end
        if Config.Debug then print('[polapaint] savePhoto failed: ' .. tostring(err)) end
        return
    end

    local meta = buildPhotoMeta(id, label)
    local ok, reason = PolaPaintSvBridge.givePhoto(src, meta)
    if not ok then
        if Config.Debug then
            print(('[polapaint] givePhoto failed reason=%s fw=%s Config.Items.photo=%s'):format(
                tostring(reason),
                tostring(PolaPaintSvBridge.detect()),
                tostring(Config.Items and Config.Items.photo)))
        end
        local key = 'notify_capture_fail'
        if reason == 'invalid_item' then key = 'notify_capture_item_not_defined'
        elseif reason == 'no_framework' then key = 'notify_inventory_framework_missing'
        elseif reason == 'inventory_full' then key = 'notify_capture_inventory_full'
        elseif reason == 'cannot_carry' or reason == 'cannot_carry_other' then
            key = 'notify_capture_weight_limit'
        end
        notify(src, key); return
    end

    markCooldown(src, 'capture')
    notify(src, 'notify_capture_ok')
    if Config.Debug then print(('[polapaint] capture saved: id=%s'):format(id)) end

    PolaPaintWebhook.notify(
        ('%s が写真を撮影: %s'):format(GetPlayerName(src) or '?', label),
        webhookImageUrlForId(id)
    )
end)

RegisterNetEvent('polapaint:server:requestEdit', function(slot)
    local src = source
    slot = tonumber(slot)
    if not slot then return end

    local item = PolaPaintSvBridge.getSlot(src, slot)
    if not item or item.name ~= (Config.Items and Config.Items.photo) then
        notify(src, 'notify_slot_invalid'); return
    end
    local meta = item.metadata or {}
    if type(meta.url) ~= 'string' or meta.url == '' then
        notify(src, 'notify_photo_no_url'); return
    end

    local token = PolaPaintUtil.token(16)
    pendingEdit[src] = {
        token = token,
        slot = slot,
        expires_ms = now() + (Config.EditSessionTTLSec or 120) * 1000,
    }
    TriggerClientEvent('polapaint:client:openPaint', src, {
        imageUrl  = meta.url,
        slot      = slot,
        editToken = token,
    })
end)

RegisterNetEvent('polapaint:server:uploadEdit', function(token, slot, b64)
    local src = source
    if type(token) ~= 'string' or type(b64) ~= 'string' then return end
    slot = tonumber(slot)
    if not slot then return end

    if Config.Debug then
        print(('[polapaint] uploadEdit from src=%d, slot=%d, b64_len=%d'):format(
            src, slot, #b64))
    end

    if not peekCooldown(src, 'edit', Config.EditSaveCooldownSec or 3) then
        notify(src, 'notify_edit_cooldown'); return
    end

    local s = pendingEdit[src]
    if not s or s.token ~= token or now() > s.expires_ms then
        notify(src, 'notify_session_expired'); return
    end
    if slot ~= s.slot then notify(src, 'notify_slot_invalid'); return end
    pendingEdit[src] = nil

    local item = PolaPaintSvBridge.getSlot(src, slot)
    if not item or item.name ~= (Config.Items and Config.Items.photo) then
        notify(src, 'notify_slot_invalid'); return
    end

    local maxBytes = (Config.Storage and Config.Storage.maxBytes) or (4 * 1024 * 1024)
    if #b64 > math.floor(maxBytes * 1.4) + 65536 then
        notify(src, 'notify_payload_too_large'); return
    end

    local bin = PolaPaintUtil.b64decode(stripDataUriPayload(b64))
    if not bin then notify(src, 'notify_storage_fail'); return end

    local id, err = PolaPaintStorage.savePhoto(bin)
    if not id then
        if err == 'too_large' then notify(src, 'notify_payload_too_large')
        else notify(src, 'notify_edit_fail') end
        return
    end

    local newMeta = {}
    for k, v in pairs(item.metadata or {}) do newMeta[k] = v end
    newMeta.url = ('polapaint://photo/%s'):format(PolaPaintStorage.publicUrl(id))
    newMeta.ts = os.time()

    if not PolaPaintSvBridge.setMetadata(src, slot, newMeta) then
        notify(src, 'notify_edit_fail'); return
    end

    markCooldown(src, 'edit')
    notify(src, 'notify_edit_saved')
    if Config.Debug then print(('[polapaint] edit saved: id=%s'):format(id)) end

    PolaPaintWebhook.notify(
        ('%s が写真を編集'):format(GetPlayerName(src) or '?'),
        webhookImageUrlForId(id)
    )
end)

local function pathWithoutQuery(p)
    if type(p) ~= 'string' then return '' end
    return (p:match('^([^%?]+)') or p)
end

CreateThread(function()
    PolaPaintStorage.init()

    SetHttpHandler(function(req, res)
        local rawPath = req.path or ''
        local path = pathWithoutQuery(rawPath)
        local method = (req.method or 'GET'):upper()

        if method == 'GET' then
            local signed = path:match('/photo/([^/]+)%.jpg$')
            if signed then
                local id = PolaPaintStorage.verifySignedId(signed)
                if not id then res.writeHead(403); res.send('forbidden'); return end
                local bin = PolaPaintStorage.loadPhoto(id)
                if not bin then res.writeHead(404); res.send('not found'); return end
                res.writeHead(200, {
                    ['Content-Type']  = 'image/jpeg',
                    ['Cache-Control'] = 'public, max-age=86400',
                })
                res.send(bin)
                return
            end
        end

        res.writeHead(404); res.send('not found')
    end)

    if Config.Debug then print('[polapaint] server initialized (GET-only handler)') end
end)

AddEventHandler('playerDropped', function()
    local s = source
    cooldown.capture[s] = nil
    cooldown.edit[s] = nil
    pendingEdit[s] = nil
end)

CreateThread(function()
    Wait(500)
    if PolaPaintSvBridge.detect() ~= 'qb' then return end
    local ok, QBCore = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if not ok or not QBCore then return end

    local cam = Config.Items and Config.Items.camera
    local pho = Config.Items and Config.Items.photo
    if cam then
        QBCore.Functions.CreateUseableItem(cam, function(src)
            TriggerClientEvent('polapaint:client:qbUseCamera', src)
        end)
    end
    if pho then
        QBCore.Functions.CreateUseableItem(pho, function(src, item)
            local slot = item and item.slot
            if type(slot) ~= 'number' then return end
            TriggerClientEvent('polapaint:client:qbUsePhoto', src, slot)
        end)
    end
end)
