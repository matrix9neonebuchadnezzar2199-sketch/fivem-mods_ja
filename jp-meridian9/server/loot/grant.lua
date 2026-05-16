-- ============================================================
-- jp-meridian9 / server/loot/grant.lua
-- ============================================================
-- MRD9.Loot.RollAndGrant: 案A pessimistic lock。実インベントリ即時付与は行わず、
-- session.inventory[src].main の論理在庫のみ加算（脱出時 MRD9.Result.Finalize で付与）。
--
-- session.inventory は任務 HUD / 脱出 snapshot 用の論理在庫（案S2: main / safe）。
--
-- lastPickupMs は pickup ハンドラで RollAndGrant 直前に更新する。
-- ロック失敗でもクールダウンは進む（失敗連打 DoS 抑止 > 即リトライ）。
--
-- 監査ログは案X（全分岐 DB）。将来ノイズ削減なら Config.Loot.auditLogDenied で
-- granted 以外をスキップする余地あり（現状は未実装・フラグ用コメントのみ）。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Loot = MRD9.Loot or {}

local function nowMs()
    return GetGameTimer()
end

local function lockTimeoutMs()
    return (Config and Config.Loot and tonumber(Config.Loot.pickupLockMs)) or 3000
end

-- 将来: if Config.Loot.auditLogDenied and row.result ~= 'granted' then return end
local function writeLog(row)
    if not row then
        return
    end
    MySQL.insert.await(
        [[INSERT INTO mrd9_loot_logs
            (player_identifier, session_id, mission_id, loot_id, tier, item_id, count,
             coords_x, coords_y, coords_z, result, fail_reason)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            row.identifier or 'unknown',
            row.sessionId or '',
            row.missionId,
            row.lootId or '',
            row.tier or 'common',
            row.itemId or '',
            row.count or 1,
            row.x,
            row.y,
            row.z,
            row.result or 'failed_other',
            row.failReason,
        }
    )
end

---@param session table|nil
---@return string|nil
local function resolveMissionId(session)
    if not session then
        return nil
    end
    if session.contractId then
        return tostring(session.contractId)
    end
    if session.mission and session.mission.type then
        return tostring(session.mission.type)
    end
    return nil
end

---@param slot table|nil
---@return boolean
local function isLocked(slot)
    if not slot or not slot.lockedBy then
        return false
    end
    if (nowMs() - (slot.lockedAt or 0)) > lockTimeoutMs() then
        slot.lockedBy = nil
        slot.lockedAt = nil
        return false
    end
    return true
end

---@param src integer
---@param session table|nil
---@param lootId string
---@param result string
---@param failReason string|nil
function MRD9.Loot.LogFailure(src, session, lootId, result, failReason)
    local slot = (session and session.loot and session.loot[lootId]) or {}
    local coords = slot.coords or vector3(0.0, 0.0, 0.0)
    local identifier = (MRD9.GetIdentifier and MRD9.GetIdentifier(src)) or ('src:' .. tostring(src))
    writeLog({
        identifier = identifier,
        sessionId = session and session.id or '',
        missionId = resolveMissionId(session),
        lootId = lootId or '',
        tier = slot.tier or 'common',
        itemId = slot.itemId or '',
        count = 1,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        result = result or 'failed_other',
        failReason = failReason,
    })
end

---@param src integer
---@param session table
---@param lootId string
---@return table
function MRD9.Loot.RollAndGrant(src, session, lootId)
    if not session or type(session.loot) ~= 'table' then
        return { ok = false, reason = 'no_session' }
    end

    local slot = session.loot[lootId]
    if not slot then
        MRD9.Loot.LogFailure(src, session, lootId, 'failed_other', 'no_slot')
        return { ok = false, reason = 'no_slot' }
    end
    if slot.picked then
        MRD9.Loot.LogFailure(src, session, lootId, 'failed_other', 'already_picked')
        return { ok = false, reason = 'already_picked' }
    end

    if isLocked(slot) and slot.lockedBy ~= src then
        MRD9.Loot.LogFailure(src, session, lootId, 'failed_locked', 'locked_by_other')
        return { ok = false, reason = 'locked' }
    end
    slot.lockedBy = src
    slot.lockedAt = nowMs()

    local itemId = slot.itemId
    local tier = slot.tier or 'common'
    local count = 1
    local coords = slot.coords or vector3(0.0, 0.0, 0.0)
    local identifier = (MRD9.GetIdentifier and MRD9.GetIdentifier(src)) or ('src:' .. tostring(src))

    slot.picked = true
    slot.lockedBy = nil
    slot.lockedAt = nil

    session.inventory = session.inventory or {}
    session.inventory[src] = session.inventory[src] or { main = {}, safe = {} }
    session.inventory[src].main = session.inventory[src].main or {}
    session.inventory[src].main[itemId] = (session.inventory[src].main[itemId] or 0) + count

    for _, m in ipairs(session.members or {}) do
        TriggerClientEvent('jp-meridian9:client:lootRemoved', m, { lootId = lootId })
    end

    writeLog({
        identifier = identifier,
        sessionId = session.id,
        missionId = resolveMissionId(session),
        lootId = lootId,
        tier = tier,
        itemId = itemId,
        count = count,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        result = 'granted',
        failReason = nil,
    })

    if MRD9.HUD and MRD9.HUD.NotifyPickup then
        MRD9.HUD.NotifyPickup(src, itemId)
    end

    return {
        ok = true,
        itemId = itemId,
        tier = tier,
        count = session.inventory[src].main[itemId],
    }
end
