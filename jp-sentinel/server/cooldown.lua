local Memory = {}

local function oxReady()
    return GetResourceState('oxmysql') == 'started'
end

local function persistUpsert(identifier, ts)
    if not oxReady() then
        return
    end
    exports.oxmysql:execute(
        'INSERT INTO jp_sentinel_cooldowns (identifier, last_used_at) VALUES (?, ?) ON DUPLICATE KEY UPDATE last_used_at = ?',
        { identifier, ts, ts }
    )
end

local Cooldown = {}

---@param identifier string
---@return boolean ok
---@return integer remainSec
function Cooldown.Check(identifier)
    if not Config.Cooldown.Enabled then
        return true, 0
    end
    local last = Memory[identifier] or 0
    local elapsed = os.time() - last
    local remain = Config.Cooldown.Seconds - elapsed
    if remain > 0 then
        return false, remain
    end
    return true, 0
end

---@param identifier string
function Cooldown.Stamp(identifier)
    if not Config.Cooldown.Enabled then
        return
    end
    Memory[identifier] = os.time()
    if Config.Cooldown.Persist then
        persistUpsert(identifier, Memory[identifier])
    end
end

if Config.Cooldown.Enabled and Config.Cooldown.Persist then
    CreateThread(function()
        local deadline = GetGameTimer() + 30000
        while GetGameTimer() < deadline do
            if oxReady() then
                exports.oxmysql:query('SELECT identifier, last_used_at FROM jp_sentinel_cooldowns', {}, function(rows)
                    for _, r in ipairs(rows or {}) do
                        Memory[r.identifier] = r.last_used_at
                    end
                end)
                return
            end
            Wait(250)
        end
        print('[jp-sentinel] oxmysql が見つかりません。Config.Cooldown.Persist を false にするか oxmysql を開始してください。')
    end)
end

Config._JpSentinel.Cooldown = Cooldown
