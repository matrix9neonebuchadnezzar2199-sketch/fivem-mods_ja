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
        print(('[PolaPaint] %s'):format(msg))
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

---@param url string
---@return boolean
local function isDiscordAttachmentUrl(url)
    if type(url) ~= 'string' or not url:match('^https://') then return false end
    if url:match('^https://cdn%.discordapp%.com/attachments/') then return true end
    if url:match('^https://media%.discordapp%.net/attachments/') then return true end
    return false
end

-- Base64 decode（標準アルファベット）
---@param data string
---@return string?
local function base64_decode(data)
    if type(data) ~= 'string' then return nil end
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = data:gsub('%s+', ''):gsub('[^' .. b .. '=]', '')
    local ok, result = pcall(function()
        return (data:gsub('.', function(x)
            if x == '=' then return '' end
            local f = (b:find(x, 1, true) or 1) - 1
            local r = ''
            for i = 6, 1, -1 do
                local bit = f % (2 ^ i) - f % (2 ^ (i - 1))
                r = r .. (bit > 0 and '1' or '0')
            end
            return r
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if #x ~= 8 then return '' end
            local c = 0
            for i = 1, 8 do
                if x:sub(i, i) == '1' then
                    c = c + (2 ^ (8 - i))
                end
            end
            return string.char(c % 256)
        end))
    end)
    if not ok or type(result) ~= 'string' or result == '' then return nil end
    return result
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
    local boundary = '----PolaPaintBoundary' .. tostring(math.random(100000000, 999999999))
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
    TriggerClientEvent('PolaPaint:client:notify', src, L(key))
end

RegisterNetEvent('PolaPaint:server:requestCapture', function()
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
    TriggerClientEvent('PolaPaint:client:doCapture', src)
end)

---@param b64Payload string|nil
RegisterNetEvent('PolaPaint:server:submitCapture', function(b64Payload)
    local src = source
    if type(b64Payload) ~= 'string' then return end
    b64Payload = b64Payload:gsub('^%s+', ''):gsub('%s+$', '')
    local maxLen = Config.MaxBase64PayloadLength or 4500000
    if #b64Payload > maxLen then
        notify(src, 'notify_payload_too_large')
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
            notify(src, err == 'webhook' and 'notify_webhook_not_configured' or 'notify_capture_fail')
            return
        end
        local meta = {
            url = url,
            label = L('meta_photo_label'),
        }
        local ok = ox:AddItem(src, photo, 1, meta)
        if not ok then
            notify(src, 'notify_capture_fail')
            return
        end
        notify(src, 'notify_capture_ok')
    end)
end)

---@param slot number|nil
---@param b64Payload string|nil
RegisterNetEvent('PolaPaint:server:submitEdited', function(slot, b64Payload)
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
            notify(src, err == 'webhook' and 'notify_webhook_not_configured' or 'notify_upload_http_error')
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
