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

local function pathWithoutQuery(p)
    if type(p) ~= 'string' then return '' end
    return (p:match('^([^%?]+)') or p)
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
        local rawPath = req.path or ''
        local pathForMatch = pathWithoutQuery(rawPath)
        local method = (req.method or 'GET'):upper()

        if method == 'GET' then
            local signed = pathForMatch:match('/photo/([^/]+)%.jpg$')
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

        if method == 'OPTIONS' then
            if pathForMatch:find('uploadCapture', 1, true) or pathForMatch:find('uploadEdit', 1, true) then
                res.writeHead(204, {
                    ['Access-Control-Allow-Origin']  = '*',
                    ['Access-Control-Allow-Methods']   = 'POST, OPTIONS',
                    ['Access-Control-Allow-Headers']   = 'Content-Type',
                })
                res.send('')
                return
            end
            res.writeHead(404); res.send('')
            return
        end

        if method == 'POST' then
            local hdr = req.headers or {}
            local maxBytes = (Config.Storage and Config.Storage.maxBytes) or (4 * 1024 * 1024)
            local hardCap = math.floor(maxBytes * 1.4) + 65536
            local parts = {}
            local dispatched = false
            local lastChunkAt = 0

            local function finish(status, text)
                if dispatched then return end
                dispatched = true
                res.writeHead(status)
                res.send(text or '')
            end

            local function dispatchJsonBody(body)
                if dispatched then return end
                if type(body) ~= 'string' then body = '' end

                local okDec, data = pcall(json.decode, body)
                if not okDec or type(data) ~= 'table' then
                    finish(400, 'bad json')
                    return
                end

                local token = data.token
                local image = data.image
                local name = data.name
                local slotStr = tostring(data.slot or '')

                if type(image) ~= 'string' or image == '' then
                    finish(400, 'no image')
                    return
                end

                local bin = PolaPaintUtil.b64decode(image)
                if not bin or #bin > maxBytes then
                    finish(413, 'too large')
                    return
                end

                if pathForMatch:find('uploadCapture', 1, true) then
                    local nameStr = type(name) == 'string' and name or ''
                    if type(token) ~= 'string' or token == '' then
                        finish(400, 'bad')
                        return
                    end
                    local foundSrc
                    for s, st in pairs(pendingCapture) do
                        if st.token == token then foundSrc = s; break end
                    end
                    if not foundSrc then finish(403, 'expired'); return end
                    local ok, errKey = handleUploadCapture(foundSrc, bin, token, nameStr)
                    if not ok then
                        notify(foundSrc, errKey or 'notify_capture_fail')
                        finish(400, errKey or 'fail')
                        return
                    end
                    notify(foundSrc, 'notify_capture_ok')
                    finish(204, '')
                    return
                end

                if pathForMatch:find('uploadEdit', 1, true) then
                    if type(token) ~= 'string' or token == '' then
                        finish(400, 'bad')
                        return
                    end
                    local foundSrc
                    for s, st in pairs(pendingEdit) do
                        if st.token == token then foundSrc = s; break end
                    end
                    if not foundSrc then finish(403, 'expired'); return end
                    local ok, errKey = handleUploadEdit(foundSrc, bin, token, slotStr)
                    if not ok then
                        notify(foundSrc, errKey or 'notify_edit_fail')
                        finish(400, errKey or 'fail')
                        return
                    end
                    notify(foundSrc, 'notify_edit_saved')
                    finish(204, '')
                    return
                end

                finish(404, 'not found')
            end

            req.setDataHandler(function(chunk)
                if dispatched then return end

                if type(chunk) == 'string' and #chunk > 0 then
                    parts[#parts + 1] = chunk
                    local total = 0
                    for i = 1, #parts do total = total + #parts[i] end
                    if total > hardCap then
                        finish(413, 'payload too large')
                        return
                    end
                end

                local body = table.concat(parts)
                local cl = tonumber(hdr['Content-Length'] or hdr['content-length'] or 0)
                if cl and cl > hardCap then
                    finish(413, 'payload too large')
                    return
                end

                if cl and cl > 0 then
                    if #body < cl then return end
                    if #body > cl then
                        body = body:sub(1, cl)
                    end
                    dispatchJsonBody(body)
                    return
                end

                lastChunkAt = now()
                SetTimeout(120, function()
                    if dispatched then return end
                    if now() - lastChunkAt < 100 then return end
                    dispatchJsonBody(table.concat(parts))
                end)
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
