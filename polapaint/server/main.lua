---@diagnostic disable: undefined-global

local ox = exports.ox_inventory

---@return string
local function L(key)
    local pack = Locales[Config.Locale or 'ja']
    if type(pack) == 'table' and pack[key] then
        return pack[key]
    end
    return key
end

---@param msg string
local function dbg(msg)
    if Config.Debug then
        print(('[polapaint] %s'):format(msg))
    end
end

local lastCapture = {}
local lastEdit = {}

---@param src number
---@param kind 'capture'|'edit'
---@param sec number
---@return boolean
local function checkCooldown(src, kind, sec)
    local t = os.time()
    local tab = kind == 'capture' and lastCapture or lastEdit
    local prev = tab[src]
    if prev and (t - prev) < sec then
        return false
    end
    tab[src] = t
    return true
end

---@param url string
---@return boolean
local function isPlaceholderWebhook(url)
    if type(url) ~= 'string' then return true end
    if url:find('REPLACE_ME', 1, true) then return true end
    if url:find('000000000000000000', 1, true) then return true end
    return false
end

---@param url string
---@return boolean
local function isDiscordWebhookUrl(url)
    return type(url) == 'string'
        and url:match('^https://discord%.com/api/webhooks/%d+/.+') ~= nil
end

---@param label string|nil
---@return string|nil
local function normalizePhotoLabel(label)
    local maxLen = Config.MaxPhotoNameLength or 40
    if type(label) ~= 'string' then return nil end
    label = label:gsub('^%s+', ''):gsub('%s+$', '')
    local len = utf8.len(label)
    if not len or len < 1 or len > maxLen then
        return nil
    end
    return label
end

local function isDiscordAttachmentUrl(url)
    if type(url) ~= 'string' or not url:match('^https://') then return false end
    if url:match('^https://cdn%.discordapp%.com/attachments/') then return true end
    if url:match('^https://media%.discordapp%.net/attachments/') then return true end
    if url:match('^https://cdn%.discord%.com/attachments/') then return true end
    return false
end

-- Base64 decode（RFC 4648・大きな JPEG でもビット列連結方式より高速）
---@param data string
---@return string?
local function base64_decode(data)
    if type(data) ~= 'string' then return nil end
    local alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local map = {}
    for i = 1, #alpha do
        map[alpha:sub(i, i)] = i - 1
    end
    data = data:gsub('%s+', ''):gsub('[^A-Za-z0-9%+/=]', '')
    local len = #data
    if len == 0 or len % 4 ~= 0 then return nil end
    local out = {}
    for pos = 1, len, 4 do
        local c1, c2, c3, c4 = data:sub(pos, pos), data:sub(pos + 1, pos + 1), data:sub(pos + 2, pos + 2), data:sub(pos + 3, pos + 3)
        local v1, v2 = map[c1], map[c2]
        if not v1 or not v2 then return nil end
        if c3 == '=' then
            out[#out + 1] = string.char(v1 * 4 + math.floor(v2 / 16))
        elseif c4 == '=' then
            local v3 = map[c3]
            if not v3 then return nil end
            local n = v1 * 4096 + v2 * 64 + v3
            out[#out + 1] = string.char(math.floor(n / 1024) % 256)
            out[#out + 1] = string.char(math.floor(n / 4) % 256)
        else
            local v3, v4 = map[c3], map[c4]
            if not v3 or not v4 then return nil end
            local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
            out[#out + 1] = string.char(math.floor(n / 65536) % 256)
            out[#out + 1] = string.char(math.floor(n / 256) % 256)
            out[#out + 1] = string.char(n % 256)
        end
    end
    return table.concat(out)
end

---@param err string|nil
---@return string
local function discordErrToNotifyKey(err)
    if err == 'decode' then return 'notify_capture_decode_fail' end
    if err == 'http' then return 'notify_capture_discord_http' end
    if err == 'empty' then return 'notify_capture_discord_empty' end
    if err == 'json' then return 'notify_capture_discord_json' end
    if err == 'attachments' then return 'notify_capture_discord_attachments' end
    if err == 'badurl' then return 'notify_capture_discord_badurl' end
    return 'notify_capture_fail'
end

---@param webhookUrl string
---@return string
local function webhookWithWait(webhookUrl)
    if webhookUrl:find('wait=', 1, true) then
        return webhookUrl
    end
    if webhookUrl:find('?', 1, true) then
        return webhookUrl .. '&wait=true'
    end
    return webhookUrl .. '?wait=true'
end

---@param b64 string
---@param cb fun(url: string?, err: string?)
local function discordUploadJpeg(b64, cb)
    local webhook = webhookWithWait(Config.DiscordWebhook)
    if isPlaceholderWebhook(Config.DiscordWebhook) or not isDiscordWebhookUrl(Config.DiscordWebhook) then
        cb(nil, 'webhook')
        return
    end
    local bin = base64_decode(b64)
    if not bin or #bin < 32 then
        cb(nil, 'decode')
        return
    end
    local b1, b2 = bin:byte(1), bin:byte(2)
    if b1 ~= 0xFF or b2 ~= 0xD8 then
        cb(nil, 'decode')
        return
    end
    local boundary = '----polapaintBoundary' .. tostring(math.random(100000000, 999999999))
    local crlf = '\r\n'
    local head = table.concat({
        '--',
        boundary,
        crlf,
        'Content-Disposition: form-data; name="files[0]"; filename="polapaint.jpg"',
        crlf,
        'Content-Type: image/jpeg',
        crlf,
        crlf,
    })
    local tail = crlf .. '--' .. boundary .. '--' .. crlf
    local body = head .. bin .. tail
    local headers = {
        ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
    }
    PerformHttpRequest(webhook, function(status, response)
        dbg(('webhook status=%s len=%s'):format(tostring(status), response and #response or 0))
        if status ~= 200 and status ~= 204 then
            cb(nil, 'http')
            return
        end
        if type(response) ~= 'string' or response == '' then
            cb(nil, 'empty')
            return
        end
        local ok, decoded = pcall(json.decode, response)
        if not ok or type(decoded) ~= 'table' then
            cb(nil, 'json')
            return
        end
        local atts = decoded.attachments
        if type(atts) ~= 'table' or not atts[1] or type(atts[1].url) ~= 'string' then
            cb(nil, 'attachments')
            return
        end
        local u = atts[1].url
        if not isDiscordAttachmentUrl(u) then
            cb(nil, 'badurl')
            return
        end
        cb(u, nil)
    end, 'POST', body, headers)
end

---@param src number
local function notify(src, key)
    TriggerClientEvent('polapaint:client:notify', src, L(key))
end

RegisterNetEvent('polapaint:server:requestCapture', function()
    local src = source
    if not checkCooldown(src, 'capture', Config.CaptureCooldownSec or 4) then
        notify(src, 'notify_capture_cooldown')
        return
    end
    if isPlaceholderWebhook(Config.DiscordWebhook) or not isDiscordWebhookUrl(Config.DiscordWebhook) then
        notify(src, 'notify_webhook_not_configured')
        return
    end
    local cam = Config.Items and Config.Items.camera
    if type(cam) ~= 'string' then return end
    local n = ox:Search(src, 'count', cam) or 0
    if n < 1 then
        notify(src, 'notify_no_camera')
        return
    end
    TriggerClientEvent('polapaint:client:doCapture', src)
end)

---@param b64Payload string|nil
---@param photoLabel string|nil
RegisterNetEvent('polapaint:server:submitCapture', function(b64Payload, photoLabel)
    local src = source
    if type(b64Payload) ~= 'string' then return end
    b64Payload = b64Payload:gsub('^%s+', ''):gsub('%s+$', '')
    local maxLen = Config.MaxBase64PayloadLength or 4500000
    if #b64Payload > maxLen then
        notify(src, 'notify_payload_too_large')
        return
    end
    local labelOk = normalizePhotoLabel(photoLabel)
    if not labelOk then
        notify(src, 'notify_photo_name_invalid')
        return
    end
    local cam = Config.Items and Config.Items.camera
    local photo = Config.Items and Config.Items.photo
    if type(cam) ~= 'string' or type(photo) ~= 'string' then return end
    if (ox:Search(src, 'count', cam) or 0) < 1 then
        notify(src, 'notify_no_camera')
        return
    end
    discordUploadJpeg(b64Payload, function(url, err)
        if not url then
            dbg('capture upload fail: ' .. tostring(err))
            if err == 'webhook' then
                notify(src, 'notify_webhook_not_configured')
            else
                notify(src, discordErrToNotifyKey(err))
            end
            return
        end
        local meta = {
            url = url,
            label = labelOk,
        }
        local added, addReason = ox:AddItem(src, photo, 1, meta)
        if not added then
            dbg('AddItem failed: ' .. tostring(addReason))
            local key = 'notify_capture_fail'
            if addReason == 'invalid_item' then
                key = 'notify_capture_item_not_defined'
            elseif addReason == 'inventory_full' then
                key = 'notify_capture_inventory_full'
            elseif addReason == 'cannot_carry' or addReason == 'cannot_carry_other' then
                key = 'notify_capture_weight_limit'
            end
            notify(src, key)
            return
        end
        notify(src, 'notify_capture_ok')
    end)
end)

---@param slot number|nil
---@param b64Payload string|nil
RegisterNetEvent('polapaint:server:submitEdited', function(slot, b64Payload)
    local src = source
    slot = tonumber(slot)
    if not slot or type(b64Payload) ~= 'string' then return end
    b64Payload = b64Payload:gsub('^%s+', ''):gsub('%s+$', '')
    if not checkCooldown(src, 'edit', Config.EditSaveCooldownSec or 3) then
        notify(src, 'notify_edit_cooldown')
        return
    end
    local maxLen = Config.MaxBase64PayloadLength or 4500000
    if #b64Payload > maxLen then
        notify(src, 'notify_payload_too_large')
        return
    end
    local photoName = Config.Items and Config.Items.photo
    if type(photoName) ~= 'string' then return end
    local slotData = ox:GetSlot(src, slot)
    if not slotData or slotData.name ~= photoName then
        notify(src, 'notify_slot_invalid')
        return
    end
    local meta = slotData.metadata
    if type(meta) ~= 'table' or type(meta.url) ~= 'string' or meta.url == '' then
        notify(src, 'notify_photo_no_url')
        return
    end
    if not isDiscordAttachmentUrl(meta.url) then
        notify(src, 'notify_edit_fail')
        return
    end
    discordUploadJpeg(b64Payload, function(url, err)
        if not url then
            dbg('edit upload fail: ' .. tostring(err))
            if err == 'webhook' then
                notify(src, 'notify_webhook_not_configured')
            else
                notify(src, discordErrToNotifyKey(err))
            end
            return
        end
        local newMeta = {}
        for k, v in pairs(meta) do
            newMeta[k] = v
        end
        newMeta.url = url
        local setRes = ox:SetMetadata(src, slot, newMeta)
        if setRes == false then
            notify(src, 'notify_edit_fail')
            return
        end
        notify(src, 'notify_edit_saved')
    end)
end)
