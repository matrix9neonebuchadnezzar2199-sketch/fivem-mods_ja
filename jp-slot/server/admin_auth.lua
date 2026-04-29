-- 管理パネル: パスワード・セッション・ロックアウト（JP-SlotSha2 = vendor/sha2.lua）

AdminAuth = {}

local sessions = {} ---@type table<string, { src: number, identifier: string, expiresAt: number }>
local bootstrapped_console ---@type boolean?

---@return string
local function identifierOf(src)
    if Framework and Framework.getPrimaryIdentifier then
        local id = Framework.getPrimaryIdentifier(src)
        if id and id ~= '' then
            return id
        end
    end
    local ids = GetPlayerIdentifiers(src)
    if ids then
        for i = 1, #ids do
            local id = ids[i]
            if id and string.sub(id, 1, 8) == 'license:' then
                return id
            end
        end
        return ids[1] or ('src:' .. src)
    end
    return 'src:' .. src
end

---@param n integer
---@return string
local function randomHexBytes(n)
    local parts = {}
    for _ = 1, n do
        parts[#parts + 1] = string.format('%02x', math.random(0, 255))
    end
    return table.concat(parts)
end

---@param len integer
---@return string
local function randomPasswordAlphanum(len)
    local chars = {}
    local alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    for i = 1, len do
        local idx = math.random(1, #alphabet)
        chars[#chars + 1] = alphabet:sub(idx, idx)
    end
    return table.concat(chars)
end

---@param password string
---@param salt_bin string
---@param iterations integer
---@return string hex 64 chars
local function deriveHashHex(password, salt_bin, iterations)
    local x = salt_bin .. password
    local it = tonumber(iterations) or 10000
    for _ = 1, it do
        local hx = JpSlotSha2.sha256(x)
        x = JpSlotSha2.hex_to_bin(hx)
    end
    return JpSlotSha2.bin_to_hex(x)
end

---@param src number
---@return string
local function issueToken(src)
    local cfg = Config.AdminAuth or {}
    local ttl = tonumber(cfg.sessionTtl) or 1800
    local id = identifierOf(src)
    local token = randomHexBytes(16)
    sessions[token] = {
        src = src,
        identifier = id,
        expiresAt = os.time() + ttl,
    }
    return token
end

--- ACE で管理者か
---@param src number
---@return boolean
function AdminAuth.hasAce(src)
    if src == 0 then
        return true
    end
    return IsPlayerAceAllowed(src, Config.AdminAce or 'jp-slot.admin')
end

---@param identifier string
local function clearLock(identifier)
    SetResourceKvp('jp-slot:adm:lock:' .. identifier, '')
end

--- ロック状態と残り秒
---@param identifier string
---@return boolean locked
---@return integer remainSec
function AdminAuth.isLocked(identifier)
    local raw = GetResourceKvpString('jp-slot:adm:lock:' .. identifier)
    if not raw or raw == '' then
        return false, 0
    end
    local ok, t = pcall(json.decode, raw)
    if not ok or type(t) ~= 'table' then
        return false, 0
    end
    local until_t = tonumber(t.lockUntil) or 0
    local now = os.time()
    if until_t > now then
        return true, until_t - now
    end
    if until_t > 0 and until_t <= now then
        clearLock(identifier)
    end
    return false, 0
end

---@param identifier string
---@param attempts integer
---@param untilUnix integer
local function saveLock(identifier, attempts, untilUnix)
    SetResourceKvp(
        'jp-slot:adm:lock:' .. identifier,
        json.encode({ attempts = attempts, lockUntil = untilUnix })
    )
end

---@param identifier string
local function registerFailure(identifier)
    local cfg = Config.AdminAuth or {}
    local maxA = tonumber(cfg.maxAttempts) or 5
    local lockSec = tonumber(cfg.lockoutSeconds) or 300
    local raw = GetResourceKvpString('jp-slot:adm:lock:' .. identifier)
    local attempts = 1
    if raw and raw ~= '' then
        local ok, t = pcall(json.decode, raw)
        if ok and type(t) == 'table' then
            attempts = (tonumber(t.attempts) or 0) + 1
        end
    end
    if attempts >= maxA then
        saveLock(identifier, attempts, os.time() + lockSec)
    else
        saveLock(identifier, attempts, 0)
    end
end

--- KVP にハッシュが無い場合に初期パスワード生成（コンソールに1回表示）
function AdminAuth.bootstrap()
    local cfg = Config.AdminAuth or {}
    if not cfg.bootstrapIfMissing then
        return
    end
    local existing = GetResourceKvpString('jp-slot:adm:passhash')
    if existing and existing ~= '' then
        return
    end
    math.randomseed(os.time() + GetGameTimer() % 2147483647)
    local plain = randomPasswordAlphanum(16)
    local salt_bin = ''
    for _ = 1, 16 do
        salt_bin = salt_bin .. string.char(math.random(0, 255))
    end
    local salt_hex = JpSlotSha2.bin_to_hex(salt_bin)
    local iter = 10000
    local hash_hex = deriveHashHex(plain, salt_bin, iter)
    SetResourceKvp('jp-slot:adm:passhash', hash_hex)
    SetResourceKvp('jp-slot:adm:salt', salt_hex)
    SetResourceKvp('jp-slot:adm:iter', tostring(iter))
    if not bootstrapped_console then
        bootstrapped_console = true
        print('^1[jp-slot] ====================================================^7')
        print('^1[jp-slot]  ADMIN PASSWORD (initial) : ' .. plain .. '^7')
        print('^1[jp-slot]  Change it via /jpslotadmin > パスワード変更^7')
        print('^1[jp-slot] ====================================================^7')
    end
end

---@param src number
---@param plainPassword string
---@return string|nil token
---@return string|nil err
---@return integer|nil lockRemainSec
function AdminAuth.verifyPassword(src, plainPassword)
    local cfg = Config.AdminAuth or {}
    if cfg.requireAce and not AdminAuth.hasAce(src) then
        return nil, 'no_ace', nil
    end
    if not cfg.enabled then
        return issueToken(src), nil, nil
    end
    local id = identifierOf(src)
    local locked, remain = AdminAuth.isLocked(id)
    if locked then
        return nil, 'locked', remain
    end
    local stored = GetResourceKvpString('jp-slot:adm:passhash')
    local salt_hex = GetResourceKvpString('jp-slot:adm:salt')
    local iter_raw = GetResourceKvpString('jp-slot:adm:iter')
    if not stored or stored == '' or not salt_hex or salt_hex == '' then
        AdminAuth.bootstrap()
        stored = GetResourceKvpString('jp-slot:adm:passhash')
        salt_hex = GetResourceKvpString('jp-slot:adm:salt')
    end
    local salt_bin = JpSlotSha2.hex_to_bin(salt_hex)
    local iter = tonumber(iter_raw) or 10000
    local guess = deriveHashHex(plainPassword or '', salt_bin, iter)
    if guess ~= stored then
        registerFailure(id)
        return nil, 'wrong', nil
    end
    clearLock(id)
    return issueToken(src), nil, nil
end

---@param src number
---@param token string|nil
---@return boolean ok
---@return string|nil reason
function AdminAuth.verifySession(src, token)
    local cfg = Config.AdminAuth or {}
    if not cfg.enabled then
        if AdminAuth.hasAce(src) then
            return true, nil
        end
        return false, 'no_ace'
    end
    if not token or token == '' then
        return false, 'no_token'
    end
    local s = sessions[token]
    if not s then
        return false, 'invalid'
    end
    local ttl = tonumber(cfg.sessionTtl) or 1800
    if s.expiresAt < os.time() then
        sessions[token] = nil
        return false, 'expired'
    end
    local id = identifierOf(src)
    if s.identifier ~= id then
        return false, 'mismatch'
    end
    s.expiresAt = os.time() + ttl
    return true, nil
end

---@param token string|nil
function AdminAuth.logout(token)
    if token and token ~= '' then
        sessions[token] = nil
    end
end

---@param src number
---@param oldPassword string
---@param newPassword string
---@param token string|nil
---@return boolean ok
---@return string|nil reason
function AdminAuth.changePassword(src, oldPassword, newPassword, token)
    local cfg = Config.AdminAuth or {}
    local minL = tonumber(cfg.minLength) or 8
    if not newPassword or #newPassword < minL then
        return false, 'short'
    end
    if cfg.enabled then
        local ok = AdminAuth.verifySession(src, token)
        if not ok then
            return false, 'unauthorized'
        end
    elseif not AdminAuth.hasAce(src) then
        return false, 'no_ace'
    end
    local stored = GetResourceKvpString('jp-slot:adm:passhash')
    local salt_hex = GetResourceKvpString('jp-slot:adm:salt')
    local iter_raw = GetResourceKvpString('jp-slot:adm:iter')
    local iter = tonumber(iter_raw) or 10000
    if stored and stored ~= '' and salt_hex and salt_hex ~= '' then
        local salt_bin = JpSlotSha2.hex_to_bin(salt_hex)
        local oldHash = deriveHashHex(oldPassword or '', salt_bin, iter)
        if oldHash ~= stored then
            return false, 'wrong_old'
        end
    else
        if not AdminAuth.hasAce(src) then
            return false, 'no_ace'
        end
    end
    math.randomseed(os.time() + GetGameTimer() % 2147483647)
    local salt_bin = ''
    for _ = 1, 16 do
        salt_bin = salt_bin .. string.char(math.random(0, 255))
    end
    local new_salt_hex = JpSlotSha2.bin_to_hex(salt_bin)
    local new_hash = deriveHashHex(newPassword, salt_bin, iter)
    SetResourceKvp('jp-slot:adm:passhash', new_hash)
    SetResourceKvp('jp-slot:adm:salt', new_salt_hex)
    SetResourceKvp('jp-slot:adm:iter', tostring(iter))
    return true, nil
end

--- リソース停止時セッション破棄（メモリのみ）
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then
        return
    end
    sessions = {}
end)

CreateThread(function()
    Wait(100)
    AdminAuth.bootstrap()
end)
