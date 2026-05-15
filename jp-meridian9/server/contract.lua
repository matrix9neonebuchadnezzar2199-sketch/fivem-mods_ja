-- ============================================================
-- MERIDIAN-9 契約者管理
-- ============================================================
-- mrd9_contracts テーブルの CRUD を提供。
-- 契約締結・状態確認・サスペンド・契約解除を扱う。
--
-- 契約者キャッシュ（INSTRUCTION-008）:
--   - nil … 未ロード
--   - false … DB に行なし
--   - 'active' / 'suspended' / 'terminated' … 最終既知の status
-- Sign / Suspend / Terminate は必ずキャッシュを同期すること。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Contract = {}

---@type table<string, string|false|nil>
local contractCache = {}

---@param identifier string|nil
function MRD9.Contract.LoadCache(identifier)
    if not identifier or identifier == '' then
        return
    end
    local status = MySQL.scalar.await(
        'SELECT status FROM mrd9_contracts WHERE identifier = ?',
        { identifier }
    )
    contractCache[identifier] = status or false
    MRD9.Log('Cache loaded: %s = %s', identifier, tostring(status))
end

---@param identifier string|nil
function MRD9.Contract.UnloadCache(identifier)
    if not identifier or identifier == '' then
        return
    end
    contractCache[identifier] = nil
    MRD9.Log('Cache unloaded: %s', identifier)
end

---@param identifier string|nil
---@return boolean
function MRD9.Contract.IsContracted(identifier)
    if not identifier or identifier == '' then
        return false
    end
    local cached = contractCache[identifier]
    if cached ~= nil then
        return cached == 'active'
    end
    local status = MySQL.scalar.await(
        'SELECT status FROM mrd9_contracts WHERE identifier = ?',
        { identifier }
    )
    contractCache[identifier] = status or false
    return status == 'active'
end

---@param identifier string|nil
---@return boolean
function MRD9.Contract.Sign(identifier)
    if not identifier or identifier == '' then
        return false
    end

    local existing = MySQL.scalar.await(
        'SELECT status FROM mrd9_contracts WHERE identifier = ?',
        { identifier }
    )

    if existing == 'active' then
        MRD9.Log('Contract already active: %s', identifier)
        return false
    end

    if existing then
        MySQL.update.await(
            'UPDATE mrd9_contracts SET status = ?, signed_at = NOW() WHERE identifier = ?',
            { 'active', identifier }
        )
    else
        MySQL.insert.await(
            'INSERT INTO mrd9_contracts (identifier, signed_at, status) VALUES (?, NOW(), ?)',
            { identifier, 'active' }
        )
        MySQL.insert.await(
            'INSERT IGNORE INTO mrd9_stats (identifier) VALUES (?)',
            { identifier }
        )
    end

    contractCache[identifier] = 'active'
    MRD9.Log('Contract signed: %s', identifier)
    return true
end

---@param identifier string|nil
---@param reason string|nil
---@return boolean
function MRD9.Contract.Suspend(identifier, reason)
    if not identifier or identifier == '' then
        return false
    end
    local stamp = os.date('%Y-%m-%d %H:%M')
    local line = ('[suspend] %s: %s\n'):format(stamp, reason or 'no reason')
    MySQL.update.await(
        'UPDATE mrd9_contracts SET status = ?, notes = CONCAT(IFNULL(notes, ""), ?) WHERE identifier = ?',
        { 'suspended', line, identifier }
    )
    contractCache[identifier] = 'suspended'
    return true
end

---@param identifier string|nil
---@param reason string|nil
---@return boolean
function MRD9.Contract.Terminate(identifier, reason)
    if not identifier or identifier == '' then
        return false
    end
    local stamp = os.date('%Y-%m-%d %H:%M')
    local line = ('[terminate] %s: %s\n'):format(stamp, reason or 'no reason')
    MySQL.update.await(
        'UPDATE mrd9_contracts SET status = ?, notes = CONCAT(IFNULL(notes, ""), ?) WHERE identifier = ?',
        { 'terminated', line, identifier }
    )
    contractCache[identifier] = 'terminated'
    return true
end

---@param identifier string|nil
---@return table|nil
function MRD9.Contract.Get(identifier)
    if not identifier or identifier == '' then
        return nil
    end
    return MySQL.single.await(
        'SELECT identifier, signed_at, status, notes FROM mrd9_contracts WHERE identifier = ?',
        { identifier }
    )
end

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(1000)
        if type(src) ~= 'number' or src <= 0 then
            return
        end
        local identifier = MRD9.GetIdentifier(src)
        if identifier then
            MRD9.Contract.LoadCache(identifier)
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if type(src) ~= 'number' or src <= 0 then
        return
    end
    local identifier = MRD9.GetIdentifier(src)
    if identifier then
        MRD9.Contract.UnloadCache(identifier)
    end
end)

CreateThread(function()
    Wait(3000)
    for _, sid in ipairs(GetPlayers()) do
        local pid = tonumber(sid)
        if pid and pid > 0 then
            local identifier = MRD9.GetIdentifier(pid)
            if identifier then
                MRD9.Contract.LoadCache(identifier)
            end
        end
    end
end)
