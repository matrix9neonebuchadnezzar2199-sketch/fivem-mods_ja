local function canRefer(src)
  return IsPlayerAceAllowed(src, Config.RefereePermission)
end

local function requireReferee(src)
  if not canRefer(src) then
    TriggerClientEvent('refboard:notify', src, { type = 'error', key = 'no_permission' })
    return false
  end
  return true
end

local function resetEditorLocks()
  pcall(function()
    MySQL.update.await(
      'UPDATE editor_locks SET match_id = NULL, holder_license = NULL, holder_name = NULL, holder_server_id = NULL, acquired_at = NULL, last_heartbeat = NULL WHERE id = 1'
    )
  end)
end

AddEventHandler('onResourceStart', function(resName)
  if resName ~= GetCurrentResourceName() then
    return
  end
  resetEditorLocks()
end)

AddEventHandler('playerDropped', function()
  -- TODO: Lock.release(source) — lock.lua 実装時に接続
end)

RegisterNetEvent('refboard:session:enter', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:session:ack', src, { ok = true, mode = payload and payload.mode or 'view' })
end)

RegisterNetEvent('refboard:session:leave', function()
  local src = source
  TriggerClientEvent('refboard:session:left', src, { ok = true })
end)

RegisterNetEvent('refboard:lock:acquire', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:lock:ack', src, { ok = true, holder = nil })
end)

RegisterNetEvent('refboard:lock:release', function()
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:lock:ack', src, { ok = true })
end)

RegisterNetEvent('refboard:lock:heartbeat', function()
  local src = source
  if not requireReferee(src) then
    return
  end
end)

RegisterNetEvent('refboard:team:list', function()
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:team:list:ack', src, { teams = {} })
end)

RegisterNetEvent('refboard:match:list', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:match:list:ack', src, { matches = {} })
end)

RegisterNetEvent('refboard:match:get', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:match:get:ack', src, {
    match = nil,
    players = {},
    events = {},
    history = {},
  })
end)

RegisterNetEvent('refboard:match:checkResume', function()
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:match:checkResume:ack', src, { hasResume = false, match = nil })
end)

RegisterNetEvent('refboard:score:goal', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:notify', src, { type = 'info', key = 'stub', detail = 'score:goal' })
end)
