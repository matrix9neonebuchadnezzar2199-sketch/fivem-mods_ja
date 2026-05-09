PolaPaintWebhook = {}

local function webhookUrl()
    local cfg = Config.Webhook or {}
    if cfg.enabled == false then return nil end
    local name = cfg.convarName or 'polapaint_webhook'
    local url = GetConvar(name, '')
    if url == '' then return nil end
    if not url:match('^https://discord%.com/api/webhooks/%d+/[^%s]+$') then
        return nil
    end
    return url
end

--- 通知のみ（画像 URL を任意で埋め込み）
---@param msg string
---@param imageUrl string|nil
function PolaPaintWebhook.notify(msg, imageUrl)
    local url = webhookUrl()
    if not url then return end
    local cfg = Config.Webhook or {}
    local payload = {
        username = cfg.username or 'polapaint',
        embeds = { {
            description = msg or '',
            image = imageUrl and { url = imageUrl } or nil,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }
    PerformHttpRequest(url, function(status, _, _)
        if Config.Debug then print(('[polapaint] webhook status=%s'):format(tostring(status))) end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end
