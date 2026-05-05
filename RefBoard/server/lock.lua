--[[
  editor_locks 単一行ロック + ハートビートタイムアウト（設計書 2.5.1）
]]

local function canRefer(src)
  return IsPlayerAceAllowed(src, Config.RefereePermission)
end

local function readRow()
  return MySQL.single.await(
    [[SELECT match_id, holder_license, holder_name, holder_server_id,
             UNIX_TIMESTAMP(last_heartbeat) AS last_hb_unix
      FROM editor_locks WHERE id = 1]]
  )
end

local function clearRow()
  MySQL.update.await(
    [[UPDATE editor_locks SET match_id = NULL, holder_license = NULL, holder_name = NULL,
          holder_server_id = NULL, acquired_at = NULL, last_heartbeat = NULL WHERE id = 1]]
  )
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
  if not canRefer(src) then
    TriggerClientEvent('refboard:lock:acquire:result', src, { ok = false, error = 'no_permission' })
    return
  end
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)
  local matchId = payload and payload.matchId or nil
  if matchId ~= nil then
    matchId = tonumber(matchId)
  end

  local r = readRow()
  local heldBy = r and r.holder_server_id
  if heldBy and heldBy ~= src and not isStale(r) then
    TriggerClientEvent('refboard:lock:acquire:result', src, {
      ok = false,
      error = 'lock_held',
      holder = {
        license = r.holder_license,
        name = r.holder_name,
        serverId = r.holder_server_id,
        since = (r.last_hb_unix or os.time()) * 1000,
      },
    })
    return
  end

  writeRow(matchId, license, name, src)
  TriggerEvent('refboard:presence:setMode', src, 'edit')
  TriggerClientEvent('refboard:lock:acquire:result', src, { ok = true })
  broadcastLock({
    license = license,
    name = name,
    serverId = src,
    since = os.time() * 1000,
  })
end)

RegisterNetEvent('refboard:lock:release', function()
  local src = source
  if not canRefer(src) then
    TriggerClientEvent('refboard:lock:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  local r = readRow()
  if not r or not r.holder_server_id or r.holder_server_id ~= src then
    TriggerClientEvent('refboard:lock:ack', src, { ok = false, error = 'not_holder' })
    return
  end
  clearRow()
  TriggerEvent('refboard:presence:setMode', src, 'view')
  TriggerClientEvent('refboard:lock:ack', src, { ok = true })
  broadcastLock(nil)
end)

RegisterNetEvent('refboard:lock:heartbeat', function()
  local src = source
  if not canRefer(src) then
    return
  end
  local r = readRow()
  if r and r.holder_server_id == src then
    touchHeartbeat(src)
  end
end)

AddEventHandler('playerDropped', function()
  local src = source
  local ok, r = pcall(readRow)
  if ok and r and r.holder_server_id == src then
    clearRow()
    TriggerEvent('refboard:presence:setMode', src, 'view')
    broadcastLock(nil)
  end
end)

CreateThread(function()
  while true do
    Wait(5000)
    local ok, r = pcall(readRow)
    if ok and r and r.holder_server_id and isStale(r) then
      local hid = r.holder_server_id
      clearRow()
      TriggerEvent('refboard:presence:setMode', hid, 'view')
      broadcastLock(nil)
      TriggerClientEvent('refboard:notify', hid, { type = 'info', key = 'lock_timeout' })
    end
  end
end)
