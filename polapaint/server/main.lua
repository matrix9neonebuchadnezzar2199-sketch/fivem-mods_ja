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

--- req.path にクエリが無く req.url 側だけにあるランタイムへの対応
local function getQueryString(req)
    local q
    if type(req.path) == 'string' then
        q = req.path:match('%?(.*)$')
    end
    if (not q or q == '') and type(req.url) == 'string' then
        q = req.url:match('%?(.*)$')
    end
    return q
end

local function parseQueryParams(queryStr)
    if not queryStr or queryStr == '' then return {} end
    local out = {}
    for kv in (queryStr .. '&'):gmatch('([^&]+)&') do
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

local function parseQueryFromReq(req)
    return parseQueryParams(getQueryString(req))
end

--- HTTP ヘッダ取得（大文字小文字・キー表記ゆれ対応）
local function hdrGet(hdr, name)
    if type(hdr) ~= 'table' or type(name) ~= 'string' then return nil end
    local nl = name:lower()
    for k, v in pairs(hdr) do
        if type(k) == 'string' and k:lower() == nl then return v end
    end
    return nil
end

--- application/x-www-form-urlencoded 風のパーセント復号（ヘッダの名前用）
local function decodeUriComponent(s)
    if type(s) ~= 'string' then return s end
    s = s:gsub('+', ' ')
    s = s:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

local function mergePolapaintHeadersIntoQuery(q, hdr)
    q = q or {}
    if type(hdr) ~= 'table' then return q end
    if not q.token or q.token == '' then
        local t = hdrGet(hdr, 'X-Polapaint-Token')
        if type(t) == 'string' and t ~= '' then q.token = t end
    end
    if not q.name or q.name == '' then
        local n = hdrGet(hdr, 'X-Polapaint-Name')
        if type(n) == 'string' and n ~= '' then q.name = decodeUriComponent(n) end
    end
    if not q.slot or q.slot == '' then
        local s = hdrGet(hdr, 'X-Polapaint-Slot')
        if type(s) == 'string' and s ~= '' then q.slot = s end
    end
    return q
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
                    ['Access-Control-Allow-Headers']   =
                        'Content-Type, X-Polapaint-Token, X-Polapaint-Name, X-Polapaint-Slot',
                })
                res.send('')
                return
            end
            res.writeHead(404); res.send('')
            return
        end

        if method == 'POST' then
            print('[polapaint] DEBUG: POST received path=' .. tostring(rawPath))
            local q = mergePolapaintHeadersIntoQuery(parseQueryFromReq(req), req.headers or {})
            local hdr = req.headers or {}
            local maxBytes = (Config.Storage and Config.Storage.maxBytes) or (4 * 1024 * 1024)
            local hardCap = maxBytes * 2

            local expectedBody = tonumber(hdr['Content-Length'] or hdr['content-length'])
            print('[polapaint] DEBUG: expectedBody=' .. tostring(expectedBody))
            if expectedBody and expectedBody > hardCap then
                res.writeHead(413); res.send('payload too large'); return
            end

            local parts = {}
            local dispatched = false
            local lastChunkAt = 0
            local quietMs = 250
            local quietThresholdMs = 240

            local function partsTotalLen()
                local t = 0
                for i = 1, #parts do t = t + #parts[i] end
                return t
            end

            local function refuseTooLarge()
                if dispatched then return true end
                dispatched = true
                res.writeHead(413); res.send('payload too large')
                return true
            end

            local function dispatchUploadPost(body)
                print('[polapaint] DEBUG: dispatchUploadPost called, dispatched=' ..
                    tostring(dispatched) .. ' body_type=' .. type(body) ..
                    ' body_len=' .. tostring(type(body) == 'string' and #body or '--'))
                if dispatched then return end
                dispatched = true
                if type(body) ~= 'string' then body = '' end

                if pathForMatch:find('uploadCapture', 1, true) then
                    local token = q.token
                    local name = q.name or ''
                    if Config.Debug then
                        print(('[polapaint] capture upload received: bytes=%d token=%s'):format(
                            #body, tostring(token)))
                    end
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

                if pathForMatch:find('uploadEdit', 1, true) then
                    local token = q.token
                    local slotStr = q.slot or ''
                    if Config.Debug then
                        print(('[polapaint] edit upload received: bytes=%d'):format(#body))
                    end
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
            end

            req.setDataHandler(function(chunk)
                print('[polapaint] DEBUG: chunk received, type=' .. type(chunk) ..
                    ' len=' .. tostring(type(chunk) == 'string' and #chunk or 'n/a'))
                if type(chunk) == 'string' and #chunk > 0 then
                    parts[#parts + 1] = chunk
                    if partsTotalLen() > hardCap then
                        refuseTooLarge()
                        return
                    end
                end

                local body = table.concat(parts)
                print('[polapaint] DEBUG: body so far=' .. #body .. ' / expected=' .. tostring(expectedBody))

                if expectedBody and expectedBody > 0 then
                    if #body < expectedBody then return end
                    if #body > expectedBody then
                        body = body:sub(1, expectedBody)
                    end
                    dispatchUploadPost(body)
                    return
                end

                lastChunkAt = now()
                SetTimeout(quietMs, function()
                    if dispatched then return end
                    if now() - lastChunkAt < quietThresholdMs then return end
                    dispatchUploadPost(table.concat(parts))
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
