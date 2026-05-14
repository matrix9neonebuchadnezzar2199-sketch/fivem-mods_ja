-- ============================================================
-- MERIDIAN-9 契約者管理
-- ============================================================
-- mrd9_contracts テーブルの CRUD を提供。
-- 契約締結・状態確認・サスペンド・契約解除を扱う。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Contract = {}

---@param identifier string|nil
---@return boolean
function MRD9.Contract.IsContracted(identifier)
    if not identifier or identifier == '' then
        return false
    end
    local result = MySQL.scalar.await(
        'SELECT status FROM mrd9_contracts WHERE identifier = ?',
        { identifier }
    )
    return result == 'active'
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
