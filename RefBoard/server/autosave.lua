--[[
  match_drafts へのデバウンス保存 + 編集者へ refboard:autosave:saved
]]

local debounceGen = {}
local pendingEditor = {}

local function canRefer(src)
  return IsPlayerAceAllowed(src, Config.RefereePermission)
end

local function flush(matchId, stateJson, editorSrc, license, name)
  local ok, err = pcall(function()
    MySQL.update.await(
      [[INSERT INTO match_drafts (match_id, state_json, last_editor_license, last_editor_name)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          state_json = VALUES(state_json),
          last_editor_license = VALUES(last_editor_license),
          last_editor_name = VALUES(last_editor_name),
          updated_at = CURRENT_TIMESTAMP]],
      { matchId, stateJson, license, name }
    )
  end)
  if ok then
    TriggerClientEvent('refboard:autosave:saved', editorSrc, {
      matchId = matchId,
      savedAt = os.time() * 1000,
    })
  else
    TriggerClientEvent('refboard:autosave:saved', editorSrc, {
      matchId = matchId,
      savedAt = os.time() * 1000,
      error = tostring(err),
    })
  end
end

RegisterNetEvent('refboard:autosave:draft', function(payload)
  local src = source
  RefboardGuard(src, nil, 'net:autosave:draft', function()
  if not canRefer(src) then
    return
  end
  if type(payload) ~= 'table' or not payload.matchId then
    return
  end
  local matchId = tonumber(payload.matchId)
  if not matchId then
    return
  end
  local state = payload.state or {}
  local stateJson = json.encode(state)
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)
  pendingEditor[matchId] = { src = src, license = license, name = name }

  debounceGen[matchId] = (debounceGen[matchId] or 0) + 1
  local gen = debounceGen[matchId]
  local debounce = Config.AutosaveDebounceMs or 500

  CreateThread(function()
    Wait(debounce)
    if debounceGen[matchId] ~= gen then
      return
    end
    local ed = pendingEditor[matchId]
    if not ed then
      return
    end
    flush(matchId, stateJson, ed.src, ed.license, ed.name)
  end)
  end)
end)
