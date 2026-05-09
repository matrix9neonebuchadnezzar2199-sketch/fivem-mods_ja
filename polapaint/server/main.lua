---@diagnostic disable: undefined-global

local L = PolaPaintUtil.L
local now = PolaPaintUtil.now

local cooldown        = { capture = {}, edit = {} }
local pendingCapture  = {}
local pendingEdit     = {}

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

---@param body string
---@return boolean ok, string|nil errKey
local function handleUploadCapture(src, body, token, name)
    local s = pendingCapture[src]
    if not s or s.token ~= token or now() > s.expires_ms then
        return false, 'notify_session_expired'
    end
    pendingCapture[src] = nil

    local label = normalizePhotoLabel(name)
    if not label then return false, 'notify_photo_name_invalid' end

    if PolaPaintSvBridge.cameraCount(src) < 1 then return false, 'notify_no_camera' end

    local id, err = PolaPaintStorage.savePhoto(body)
    if not id then
        if err == 'too_large' then return false, 'notify_payload_too_large' end
        return false, 'notify_storage_fail'
    end

    local meta = buildPhotoMeta(id, label)
    local ok, reason = PolaPaintSvBridge.givePhoto(src, meta)
    if not ok then
        local key = 'notify_capture_fail'
        if reason == 'invalid_item' then key = 'notify_capture_item_not_defined'
        elseif reason == 'inventory_full' then key = 'notify_capture_inventory_full'
        elseif reason == 'cannot_carry' or reason == 'cannot_carry_other' then
            key = 'notify_capture_weight_limit'
        end
        return false, key
    end

    markCooldown(src, 'capture')
    PolaPaintWebhook.notify(
        ('%s が写真を撮影: %s'):format(GetPlayerName(src) or '?', label),
        webhookImageUrlForId(id)
    )
    return true, nil
end

---@return boolean ok, string|nil errKey
local function handleUploadEdit(src, body, token, slotStr)
    if not peekCooldown(src, 'edit', Config.EditSaveCooldownSec or 3) then
        return false, 'notify_edit_cooldown'
    end
    local s = pendingEdit[src]
    if not s or s.token ~= token or now() > s.expires_ms then
        return false, 'notify_session_expired'
    end
    local slot = tonumber(slotStr)
    if not slot or slot ~= s.slot then return false, 'notify_slot_invalid' end
    pendingEdit[src] = nil

    local item = PolaPaintSvBridge.getSlot(src, slot)
    if not item or item.name ~= (Config.Items and Config.Items.photo) then
        return false, 'notify_slot_invalid'
    end

    local id, err = PolaPaintStorage.savePhoto(body)
    if not id then
        if err == 'too_large' then return false, 'notify_payload_too_large' end
        return false, 'notify_edit_fail'
    end

    local newMeta = {}
    for k, v in pairs(item.metadata or {}) do newMeta[k] = v end
    newMeta.url = ('polapaint://photo/%s'):format(PolaPaintStorage.publicUrl(id))
    newMeta.ts = os.time()

    local okMeta = PolaPaintSvBridge.setMetadata(src, slot, newMeta)
    if not okMeta then return false, 'notify_edit_fail' end

    markCooldown(src, 'edit')
    PolaPaintWebhook.notify(
        ('%s が写真を編集'):format(GetPlayerName(src) or '?'),
        webhookImageUrlForId(id)
    )
    return true, nil
end

local function parseQuery(path)
    local q = path and path:match('%?(.*)$')
    if not q then return {} end
    local out = {}
    for kv in (q .. '&'):gmatch('([^&]+)&') do
        local k, v = kv:match('^([^=]+)=(.*)$')
        if k then
            v = v or ''
            v = v:gsub('+', ' ')
            v = v:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
            out[k] = v
        end
    end
    return out
end

local function handleRequestCapture(src)
    if not peekCooldown(src, 'capture', Config.CaptureCooldownSec or 4) then
        notify(src, 'notify_capture_cooldown'); return
    end
    if PolaPaintSvBridge.cameraCount(src) < 1 then
        notify(src, 'notify_no_camera'); return
    end
    local token = PolaPaintUtil.token(16)
    pendingCapture[src] = {
        token = token,
        expires_ms = now() + (Config.CaptureSessionTTLSec or 30) * 1000,
    }
    TriggerClientEvent('polapaint:client:doCapture', src, token)
end

RegisterNetEvent('polapaint:server:requestCapture', function()
    handleRequestCapture(source)
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

CreateThread(function()
    PolaPaintStorage.init()

    SetHttpHandler(function(req, res)
        local path = req.path or ''
        local method = (req.method or 'GET'):upper()

        if method == 'GET' then
            local signed = path:match('/photo/([^/%?]+)%.jpg')
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
            res.writeHead(404); res.send('not found'); return
        end

        if method == 'POST' then
            req.setDataHandler(function(body)
                local q = parseQuery(path)
                if path:find('uploadCapture', 1, true) then
                    local token = q.token
                    local name = q.name or ''
                    if not token then res.writeHead(400); res.send('bad'); return end
                    local foundSrc
                    for s, st in pairs(pendingCapture) do
                        if st.token == token then foundSrc = s; break end
                    end
                    if not foundSrc then res.writeHead(403); res.send('expired'); return end
                    local ok, errKey = handleUploadCapture(foundSrc, body, token, name)
                    if not ok then
                        notify(foundSrc, errKey or 'notify_capture_fail')
                        res.writeHead(400); res.send(errKey or 'fail'); return
                    end
                    notify(foundSrc, 'notify_capture_ok')
                    res.writeHead(204); res.send('')
                    return
                end

                if path:find('uploadEdit', 1, true) then
                    local token = q.token
                    local slotStr = q.slot or ''
                    if not token then res.writeHead(400); res.send('bad'); return end
                    local foundSrc
                    for s, st in pairs(pendingEdit) do
                        if st.token == token then foundSrc = s; break end
                    end
                    if not foundSrc then res.writeHead(403); res.send('expired'); return end
                    local ok, errKey = handleUploadEdit(foundSrc, body, token, slotStr)
                    if not ok then
                        notify(foundSrc, errKey or 'notify_edit_fail')
                        res.writeHead(400); res.send(errKey or 'fail'); return
                    end
                    notify(foundSrc, 'notify_edit_saved')
                    res.writeHead(204); res.send('')
                    return
                end

                res.writeHead(404); res.send('not found')
            end)
            return
        end

        res.writeHead(405); res.send('method not allowed')
    end)

    if Config.Debug then print('[polapaint] server initialized (HTTP handler)') end
end)

AddEventHandler('playerDropped', function()
    local s = source
    cooldown.capture[s] = nil
    cooldown.edit[s] = nil
    pendingCapture[s] = nil
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
            handleRequestCapture(src)
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
