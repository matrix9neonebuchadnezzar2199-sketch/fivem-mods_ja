--[[
  試合時計（matches.clock_*）。編集ロック保持者のみ更新可。
  経過 ms は event.lua / score.lua と同じ RefboardMatchTimeMsFromRow 定義。
]]

local function assertEditorLock(src, matchId)
  local r = MySQL.single.await(
    'SELECT match_id, holder_server_id FROM editor_locks WHERE id = 1'
  )
  if not r or tonumber(r.holder_server_id) ~= tonumber(src) then
    return false
  end
  local mid = r.match_id and tonumber(r.match_id)
  if not mid or mid ~= tonumber(matchId) then
    return false
  end
  return true
end


local function readClockRow(matchId)
  return MySQL.single.await(
    [[SELECT clock_running, clock_started_at, clock_accumulated_ms
      FROM matches WHERE id = ?]],
    { matchId }
  )
end

local function ackClock(src, matchId)
  local row = readClockRow(matchId)
  if not row then
    TriggerClientEvent('refboard:match:clock:ack', src, { ok = false, error = 'no_match', matchId = matchId })
    return
  end
  TriggerClientEvent('refboard:match:clock:ack', src, {
    ok = true,
    matchId = matchId,
    clock_running = tonumber(row.clock_running) or 0,
    clock_started_at = row.clock_started_at,
    clock_accumulated_ms = tonumber(row.clock_accumulated_ms) or 0,
  })
end

RegisterNetEvent('refboard:match:clock', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:match:clock:ack', 'net:match:clock', function()
    if not RefboardRequireEdit(src) then
      TriggerClientEvent('refboard:match:clock:ack', src, { ok = false, error = 'no_permission' })
      return
    end
    if type(payload) ~= 'table' or not payload.matchId then
      TriggerClientEvent('refboard:match:clock:ack', src, { ok = false, error = 'bad_payload' })
      return
    end
    local matchId = tonumber(payload.matchId)
    local action = payload.action
    if not matchId or type(action) ~= 'string' then
      TriggerClientEvent('refboard:match:clock:ack', src, { ok = false, error = 'bad_payload', matchId = matchId })
      return
    end
    if not assertEditorLock(src, matchId) then
      TriggerClientEvent('refboard:match:clock:ack', src, { ok = false, error = 'no_lock', matchId = matchId })
      return
    end

    local m = MySQL.single.await(
      'SELECT id, status, clock_running, clock_started_at, clock_accumulated_ms FROM matches WHERE id = ?',
      { matchId }
    )
    if not m or m.status ~= 'draft' then
      TriggerClientEvent('refboard:match:clock:ack', src, { ok = false, error = 'bad_status', matchId = matchId })
      return
    end

    if action == 'start' then
      if tonumber(m.clock_running) == 1 then
        ackClock(src, matchId)
        return
      end
      local nowMs = os.time() * 1000
      MySQL.update.await(
        'UPDATE matches SET clock_running = 1, clock_started_at = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
        { nowMs, matchId }
      )
    elseif action == 'stop' then
      if tonumber(m.clock_running) ~= 1 then
        ackClock(src, matchId)
        return
      end
      local elapsed = math.floor(RefboardMatchTimeMsFromRow(m))
      MySQL.update.await(
        [[UPDATE matches SET clock_running = 0, clock_started_at = NULL,
            clock_accumulated_ms = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?]],
        { elapsed, matchId }
      )
    elseif action == 'clear' then
      MySQL.update.await(
        [[UPDATE matches SET clock_running = 0, clock_started_at = NULL, clock_accumulated_ms = 0,
            updated_at = CURRENT_TIMESTAMP WHERE id = ?]],
        { matchId }
      )
    elseif action == 'adjust' then
      local delta = tonumber(payload.deltaRemainingMs) or 0
      local cur = math.floor(RefboardMatchTimeMsFromRow(m))
      local newElapsed = math.max(0, cur - delta)
      if tonumber(m.clock_running) == 1 then
        local nowMs = os.time() * 1000
        MySQL.update.await(
          [[UPDATE matches SET clock_accumulated_ms = ?, clock_started_at = ?,
              updated_at = CURRENT_TIMESTAMP WHERE id = ?]],
          { newElapsed, nowMs, matchId }
        )
      else
        MySQL.update.await(
          'UPDATE matches SET clock_accumulated_ms = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          { newElapsed, matchId }
        )
      end
    else
      TriggerClientEvent('refboard:match:clock:ack', src, { ok = false, error = 'bad_action', matchId = matchId })
      return
    end

    ackClock(src, matchId)
    TriggerEvent('refboard:internal:broadcastState', matchId)
  end)
end)
