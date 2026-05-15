-- ============================================================
-- MERIDIAN-9 統計・ミッション履歴管理
-- ============================================================
-- mrd9_stats / mrd9_mission_logs テーブルを操作。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Stats = {}

---@param identifier string|nil
---@return table|nil
function MRD9.Stats.Get(identifier)
    if not identifier or identifier == '' then
        return nil
    end
    return MySQL.single.await(
        [[SELECT identifier, total_missions, total_extracts, total_deaths,
                 total_earnings, best_extract_value, fastest_extract_seconds, last_mission_at
          FROM mrd9_stats WHERE identifier = ?]],
        { identifier }
    )
end

---@class Mrd9StatsUpdateParams
---@field extracted boolean|nil
---@field died boolean|nil
---@field earnings integer|nil
---@field extractSeconds integer|nil

---@param identifier string|nil
---@param params Mrd9StatsUpdateParams|nil
---@return boolean
function MRD9.Stats.Update(identifier, params)
    if not identifier or identifier == '' or not params then
        return false
    end

    local sql = [[
        UPDATE mrd9_stats SET
            total_missions = total_missions + 1,
            total_extracts = total_extracts + ?,
            total_deaths = total_deaths + ?,
            total_earnings = total_earnings + ?,
            best_extract_value = GREATEST(best_extract_value, ?),
            fastest_extract_seconds = CASE
                WHEN ? > 0 AND (fastest_extract_seconds IS NULL OR fastest_extract_seconds > ?)
                THEN ? ELSE fastest_extract_seconds END,
            last_mission_at = NOW()
        WHERE identifier = ?
    ]]

    local extractCount = params.extracted and 1 or 0
    local deathCount = params.died and 1 or 0
    local earnings = params.earnings or 0
    local extractSec = params.extractSeconds or 0

    MySQL.update.await(sql, {
        extractCount,
        deathCount,
        earnings,
        earnings,
        extractSec,
        extractSec,
        extractSec,
        identifier,
    })
    return true
end

---@class Mrd9MissionLogParams
---@field sessionId string
---@field startedAt string|nil
---@field endedAt string|nil
---@field outcome string|nil
---@field items table|nil
---@field earnings integer|nil
---@field missionType string|nil
---@field difficulty string|nil

---@param identifier string|nil
---@param params Mrd9MissionLogParams|nil
---@return boolean
function MRD9.Stats.LogMission(identifier, params)
    if not identifier or identifier == '' or not params or not params.sessionId then
        return false
    end
    local itemsJson = nil
    if params.items then
        itemsJson = json.encode(params.items)
    end
    local startedAt = params.startedAt
    if type(startedAt) ~= 'string' or startedAt == '' then
        startedAt = os.date('%Y-%m-%d %H:%M:%S')
    end
    MySQL.insert.await(
        [[INSERT INTO mrd9_mission_logs
            (session_id, identifier, started_at, ended_at, outcome,
             items_recovered_json, earnings, mission_type, difficulty)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            params.sessionId,
            identifier,
            startedAt,
            params.endedAt,
            params.outcome,
            itemsJson,
            params.earnings or 0,
            params.missionType,
            params.difficulty,
        }
    )
    return true
end

---@param limit integer|nil
---@return table
function MRD9.Stats.GetTopEarners(limit)
    limit = limit or 10
    return MySQL.query.await(
        [[SELECT identifier, total_earnings, total_extracts, total_missions
          FROM mrd9_stats
          ORDER BY total_earnings DESC
          LIMIT ?]],
        { limit }
    ) or {}
end

---@param limit integer|nil
---@return table
function MRD9.Stats.GetFastestExtracts(limit)
    limit = limit or 10
    return MySQL.query.await(
        [[SELECT identifier, fastest_extract_seconds, total_extracts
          FROM mrd9_stats
          WHERE fastest_extract_seconds IS NOT NULL
          ORDER BY fastest_extract_seconds ASC
          LIMIT ?]],
        { limit }
    ) or {}
end
