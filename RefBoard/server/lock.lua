--[[
  editor_locks 単一行ロック + ハートビートタイムアウト（設計書 2.5.1）
]]

local function readRow()
  return MySQL.single.await(
    [[SELECT match_id, holder_license, holder_name, holder_server_id,
             UNIX_TIMESTAMP(last_heartbeat) AS last_hb_unix
      FROM editor_locks WHERE id = 1]]
  )
end

--- editor_locks 未作成（install.sql 未実行）時は oxmysql が例外を投げる。true = 成功。
local function clearRow()
  local ok, err = pcall(function()
    MySQL.update.await(
      [[UPDATE editor_locks SET match_id = NULL, holder_license = NULL, holder_name = NULL,
            holder_server_id = NULL, acquired_at = NULL, last_heartbeat = NULL WHERE id = 1]]
    )
  end)
  if not ok then
    Logger.warn('lock', 'clearRow failed', { err = tostring(err) })
  end
  return ok
end

local function writeRow(matchId, license, name, holderSrc)
  MySQL.update.await(
    [[UPDATE editor_locks SET match_id = ?, holder_license = ?, holder_name = ?, holder_server_id = ?,
          acquired_at = CURRENT_TIMESTAMP, last_heartbeat = CURRENT_TIMESTAMP WHERE id = 1]],
    { matchId, license, name, holderSrc }
  )
end

local function touchHeartbeat(holderSrc)
  MySQL.update.await('UPDATE editor_locks SET last_heartbeat = CURRENT_TIMESTAMP WHERE id = 1 AND holder_server_id = ?', { holderSrc })
end

local function isStale(row)
  if not row or not row.holder_server_id then
    return true
  end
  local lh = tonumber(row.last_hb_unix)
  if not lh then
    return true
  end
  local timeout = Config.LockTimeoutSec or 30
  return (os.time() - lh) > timeout
end

local function broadcastLock(holder)
  TriggerClientEvent('refboard:lock:update', -1, { holder = holder })
end

RegisterNetEvent('refboard:lock:acquire', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:lock:acquire:result', 'net:lock:acquire', function()
  if not RefboardIsEditApproved(src) then
    TriggerClientEvent('refboard:lock:acquire:result', src, MakeError(ErrorCodes.NO_PERMISSION))
    return
  end
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)
  local matchId = payload and payload.matchId or nil
  if matchId ~= nil then
    matchId = tonumber(matchId)
  end

  local okRead, r = pcall(readRow)
  if not okRead then
    Logger.warn('lock', 'acquire readRow failed (run sql/install.sql on oxmysql DB?)', {
      src = src,
      err = tostring(r),
    })
    TriggerClientEvent('refboard:lock:acquire:result', src, MakeError(ErrorCodes.DB_QUERY_FAILED, tostring(r)))
    return
  end
  -- oxmysql は holder_server_id を数値／文字列のどちらでも返し得るため、常に tonumber で比較する
  local heldBy = r and tonumber(r.holder_server_id)
  local srcNum = tonumber(src)
  if heldBy and srcNum and heldBy ~= srcNum and not isStale(r) then
    -- 再接続で server id が変わっても license が同一なら同一審判とみなしロックを奪い返す（幽霊 E1003 防止）
    local reclaim = (license ~= '' and r.holder_license and r.holder_license == license)
    if not reclaim then
      local err = MakeError(ErrorCodes.LOCK_HELD_BY_OTHER, nil, {
        holderLicense = r.holder_license,
        holderServerId = r.holder_server_id,
      })
      err.holder = {
        license = r.holder_license,
        name = r.holder_name,
        serverId = r.holder_server_id,
        since = (r.last_hb_unix or os.time()) * 1000,
      }
      TriggerClientEvent('refboard:lock:acquire:result', src, err)
      return
    end
    Logger.info('net:lock:acquire', 'reclaim_same_license', { oldHolder = heldBy, src = srcNum })
  end

  Logger.info('net:lock:acquire', 'granted', { src = src, matchId = matchId })

  local okWrite, wErr = pcall(function()
    writeRow(matchId, license, name, src)
  end)
  if not okWrite then
    Logger.warn('lock', 'acquire writeRow failed', { src = src, err = tostring(wErr) })
    TriggerClientEvent('refboard:lock:acquire:result', src, MakeError(ErrorCodes.DB_QUERY_FAILED, tostring(wErr)))
    return
  end
  TriggerEvent('refboard:presence:setMode', src, 'edit')
  TriggerClientEvent('refboard:lock:acquire:result', src, { ok = true })
  broadcastLock({
    license = license,
    name = name,
    serverId = src,
    since = os.time() * 1000,
  })
  end)
end)

RegisterNetEvent('refboard:lock:release', function()
  local src = source
  RefboardGuard(src, 'refboard:lock:ack', 'net:lock:release', function()
  local okRead, r = pcall(readRow)
  if not okRead then
    Logger.warn('lock', 'release readRow failed', { src = src, err = tostring(r) })
    TriggerClientEvent('refboard:lock:ack', src, { ok = false, error = 'db_error' })
    return
  end
  -- 既に空なら冪等 OK（二重解放・session:leave 先行で消えた直後など）
  if not r or not r.holder_server_id or r.holder_server_id == '' then
    TriggerClientEvent('refboard:lock:ack', src, { ok = true })
    return
  end
  local heldBy = tonumber(r.holder_server_id)
  local srcNum = tonumber(src)
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local sameSrc = heldBy and srcNum and heldBy == srcNum
  local sameLicense = license ~= '' and r.holder_license and r.holder_license == license
  if not sameSrc and sameLicense then
    Logger.info('net:lock:release', 'same_license_release', { src = srcNum, rowHolder = heldBy })
  end
  if not sameSrc and not sameLicense then
    TriggerClientEvent('refboard:lock:ack', src, { ok = false, error = 'not_holder' })
    return
  end
  if not clearRow() then
    TriggerClientEvent('refboard:lock:ack', src, { ok = false, error = 'db_error' })
    return
  end
  TriggerEvent('refboard:presence:setMode', src, 'view')
  TriggerClientEvent('refboard:lock:ack', src, { ok = true })
  broadcastLock(nil)
  end)
end)

RegisterNetEvent('refboard:lock:heartbeat', function()
  local src = source
  local okRead, r = pcall(readRow)
  if okRead and r and tonumber(r.holder_server_id) == tonumber(src) then
    local okHb, hbErr = pcall(function()
      touchHeartbeat(src)
    end)
    if not okHb then
      Logger.warn('lock', 'heartbeat touch failed', { src = src, err = tostring(hbErr) })
    end
  end
end)

AddEventHandler('playerDropped', function()
  local src = source
  local cleared = false
  local ok, r = pcall(readRow)
  if ok and r and tonumber(r.holder_server_id) == tonumber(src) then
    cleared = clearRow()
  else
    if not ok then
      Logger.warn('lock', 'playerDropped readRow failed; trying holder cleanup', { src = src })
    end
    local n
    local okUpd, updErr = pcall(function()
      n = MySQL.update.await(
        [[UPDATE editor_locks SET match_id = NULL, holder_license = NULL, holder_name = NULL,
              holder_server_id = NULL, acquired_at = NULL, last_heartbeat = NULL
         WHERE id = 1 AND holder_server_id = ?]],
        { src }
      )
    end)
    if okUpd then
      cleared = (type(n) == 'number' and n > 0)
    else
      Logger.warn('lock', 'playerDropped fallback update failed', { src = src, err = tostring(updErr) })
    end
  end
  if cleared then
    TriggerEvent('refboard:presence:setMode', src, 'view')
    broadcastLock(nil)
  end
end)

--- session:leave 等から呼ぶ: この src が保持者ならロックを掃除する（NUI が lock_release を送れなかった場合の保険）
function RefboardLockReleaseIfHeldBy(holderSrc)
  if type(holderSrc) ~= 'number' then
    return false
  end
  local ok, r = pcall(readRow)
  if not ok or not r or tonumber(r.holder_server_id) ~= tonumber(holderSrc) then
    return false
  end
  if not clearRow() then
    return false
  end
  TriggerEvent('refboard:presence:setMode', holderSrc, 'view')
  broadcastLock(nil)
  return true
end

--- 試合更新用: 保持者が src かつ editor_locks.match_id が一致、または **NULL のときだけ** payload の試合 ID にバインドする。
--- ランチャーで enterEdit すると lock_acquire が matchId なしになり match_id が NULL のまま → 時計等が no_lock になるのを防ぐ。
--- 既に別試合にロック済みのときは false（奪い合い防止）。
function RefboardAssertEditorLockForMatch(src, matchId)
  matchId = tonumber(matchId)
  local srcNum = tonumber(src)
  if not matchId or not srcNum then
    return false
  end
  local okRead, r = pcall(readRow)
  if not okRead or not r then
    return false
  end
  if tonumber(r.holder_server_id) ~= srcNum then
    return false
  end
  local mid = r.match_id ~= nil and tonumber(r.match_id) or nil
  if mid == matchId then
    return true
  end
  if mid == nil then
    local n
    local okUpd, err = pcall(function()
      n = MySQL.update.await(
        'UPDATE editor_locks SET match_id = ? WHERE id = 1 AND holder_server_id = ?',
        { matchId, srcNum }
      )
    end)
    if not okUpd then
      Logger.warn('lock', 'bind match_id failed', { src = srcNum, matchId = matchId, err = tostring(err) })
      return false
    end
    local affected = tonumber(n) or 0
    if affected < 1 then
      Logger.warn('lock', 'bind match_id affected 0', {
        src = srcNum,
        matchId = matchId,
        rowHolder = r.holder_server_id,
      })
      return false
    end
    return true
  end
  return false
end

AddEventHandler('onResourceStart', function(resName)
  if resName ~= GetCurrentResourceName() then
    return
  end
  -- テーブル未作成でもリソース全体は起動させる（install.sql 後に ensure し直せばロックはリセットされる）
  clearRow()
  broadcastLock(nil)
end)

CreateThread(function()
  while true do
    Wait(5000)
    local ok, r = pcall(readRow)
    if ok and r and r.holder_server_id and isStale(r) then
      local hid = tonumber(r.holder_server_id)
      if clearRow() then
        broadcastLock(nil)
        if hid then
          TriggerEvent('refboard:presence:setMode', hid, 'view')
          TriggerClientEvent('refboard:notify', hid, { type = 'info', key = 'lock_timeout' })
        end
      end
    end
  end
end)
