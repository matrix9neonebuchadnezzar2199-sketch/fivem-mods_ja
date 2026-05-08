local isOpen = false
--- 試合詳細「小窓モード」が有効（NUI から compact_dock_state で同期）
local compactDockActive = false
--- true のときゲームにキー／マウス（歩行）。false のとき NUI 操作
local compactGameInput = false

local function applyCompactNuiFocus()
  if not isOpen then
    return
  end
  if not compactDockActive then
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ type = 'refboard:compact_input_mode', payload = { game = false } })
    return
  end
  if compactGameInput then
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
  else
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
  end
  SendNUIMessage({ type = 'refboard:compact_input_mode', payload = { game = compactGameInput } })
end

local function setOpen(state)
  local wasOpen = isOpen
  isOpen = state
  -- NUI を閉じるときはサーバ側のロック／プレゼンスも必ず外す（F6 閉じ・Close ・ランチャーからの戻りで統一）
  if wasOpen and not state then
    TriggerServerEvent('refboard:lock:release')
    TriggerServerEvent('refboard:session:leave')
  end
  if not state then
    compactDockActive = false
    compactGameInput = false
  end
  SetNuiFocus(state, state)
  SetNuiFocusKeepInput(false)
  SendNUIMessage({ type = 'refboard:setOpen', payload = { open = state } })
  if state and compactDockActive then
    applyCompactNuiFocus()
  end
end

-- リソース起動・再起動時は NUI を必ず閉じた状態に同期（ログイン画面を CEF が覆う事故の防止）
AddEventHandler('onClientResourceStart', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    setOpen(false)
  end
end)

local function toggle()
  if isOpen then
    setOpen(false)
  else
    setOpen(true)
  end
end

RegisterCommand('refboard', function()
  toggle()
end, false)

RegisterKeyMapping('refboard', 'RefBoard を開閉', 'keyboard', Config.OpenKey or 'F6')

RegisterNUICallback('refboard:close', function(_, cb)
  setOpen(false)
  cb({ ok = true })
end)

-- 小窓解除後など、マウスを再び NUI に乗せる（pointer-events 切替後の取りこぼし対策）
RegisterNUICallback('refboard:nui_focus_cursor', function(_, cb)
  if isOpen then
    if compactDockActive and compactGameInput then
      compactGameInput = false
    end
    applyCompactNuiFocus()
  end
  cb({ ok = true })
end)

--- 小窓モードの開始／終了（クライアントのみ）
RegisterNUICallback('compact_dock_state', function(body, cb)
  local compact = type(body) == 'table' and body.compact == true
  compactDockActive = compact
  if not compact then
    compactGameInput = false
  end
  if isOpen then
    applyCompactNuiFocus()
  end
  cb({ ok = true })
end)

--- 小窓中: UI 操作 ⇔ ゲーム（歩行）のフォーカス切替
RegisterNUICallback('compact_toggle_input', function(_, cb)
  if not isOpen or not compactDockActive then
    cb({ ok = false })
    return
  end
  compactGameInput = not compactGameInput
  applyCompactNuiFocus()
  cb({ ok = true })
end)

RegisterCommand('refboard_compact_toggle_input', function()
  if not isOpen or not compactDockActive then
    return
  end
  compactGameInput = not compactGameInput
  applyCompactNuiFocus()
end, false)

RegisterKeyMapping('refboard_compact_toggle_input', 'RefBoard 小窓: UI操作⇔歩行', 'keyboard', 'b')

RegisterNetEvent('refboard:notify', function(payload)
  SendNUIMessage({ type = 'refboard:notify', payload = payload })
end)

RegisterNetEvent('refboard:session:ack', function(payload)
  SendNUIMessage({ type = 'refboard:session:ack', payload = payload })
end)

RegisterNetEvent('refboard:lock:ack', function(payload)
  SendNUIMessage({ type = 'refboard:lock:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:checkResume:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:checkResume:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:list:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:list:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:manage_list:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:manage_list:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:detail:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:detail:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:create:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:create:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:update:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:update:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:delete:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:delete:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:roster:list:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:roster:list:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:roster:add:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:roster:add:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:roster:update:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:roster:update:ack', payload = payload })
end)

RegisterNetEvent('refboard:team:roster:remove:ack', function(payload)
  SendNUIMessage({ type = 'refboard:team:roster:remove:ack', payload = payload })
end)

RegisterNetEvent('refboard:data:team_stats:ack', function(payload)
  SendNUIMessage({ type = 'refboard:data:team_stats:ack', payload = payload })
end)

RegisterNetEvent('refboard:data:player_stats:ack', function(payload)
  SendNUIMessage({ type = 'refboard:data:player_stats:ack', payload = payload })
end)

RegisterNetEvent('refboard:data:score_edit_log:ack', function(payload)
  SendNUIMessage({ type = 'refboard:data:score_edit_log:ack', payload = payload })
end)

RegisterNetEvent('refboard:data:match_history:ack', function(payload)
  SendNUIMessage({ type = 'refboard:data:match_history:ack', payload = payload })
end)

RegisterNetEvent('refboard:data:db_meta:ack', function(payload)
  SendNUIMessage({ type = 'refboard:data:db_meta:ack', payload = payload })
end)

RegisterNetEvent('refboard:player:add_from_roster:ack', function(payload)
  SendNUIMessage({ type = 'refboard:player:add_from_roster:ack', payload = payload })
end)

RegisterNetEvent('refboard:event:pk_decided', function(payload)
  SendNUIMessage({ type = 'refboard:event:pk_decided', payload = payload })
end)

RegisterNetEvent('refboard:match:list:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:list:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:create:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:create:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:get:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:get:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:clock:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:clock:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:state', function(payload)
  SendNUIMessage({ type = 'refboard:match:state', payload = payload })
end)

RegisterNetEvent('refboard:match:finished', function(payload)
  SendNUIMessage({ type = 'refboard:match:finished', payload = payload })
end)

RegisterNetEvent('refboard:match:finish:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:finish:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:reopen:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:reopen:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:delete:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:delete:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:set_half:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:set_half:ack', payload = payload })
end)

RegisterNetEvent('refboard:event:substitute:ack', function(payload)
  SendNUIMessage({ type = 'refboard:event:substitute:ack', payload = payload })
end)

RegisterNetEvent('refboard:event:issue_card:ack', function(payload)
  SendNUIMessage({ type = 'refboard:event:issue_card:ack', payload = payload })
end)

RegisterNetEvent('refboard:event:record_penalty:ack', function(payload)
  SendNUIMessage({ type = 'refboard:event:record_penalty:ack', payload = payload })
end)

RegisterNetEvent('refboard:score:goal:ack', function(payload)
  SendNUIMessage({ type = 'refboard:score:goal:ack', payload = payload })
end)

RegisterNetEvent('refboard:score:manual_edit:ack', function(payload)
  SendNUIMessage({ type = 'refboard:score:manual_edit:ack', payload = payload })
end)

RegisterNetEvent('refboard:player:resolve:ack', function(payload)
  SendNUIMessage({ type = 'refboard:player:resolve:ack', payload = payload })
end)

RegisterNetEvent('refboard:player:add:ack', function(payload)
  SendNUIMessage({ type = 'refboard:player:add:ack', payload = payload })
end)

RegisterNetEvent('refboard:player:remove:ack', function(payload)
  SendNUIMessage({ type = 'refboard:player:remove:ack', payload = payload })
end)

RegisterNetEvent('refboard:player:online_list:ack', function(payload)
  SendNUIMessage({ type = 'refboard:player:online_list:ack', payload = payload })
end)

RegisterNetEvent('refboard:lock:acquire:result', function(payload)
  SendNUIMessage({ type = 'refboard:lock:acquire:result', payload = payload })
end)

RegisterNetEvent('refboard:lock:update', function(payload)
  SendNUIMessage({ type = 'refboard:lock:update', payload = payload })
end)

RegisterNetEvent('refboard:autosave:saved', function(payload)
  SendNUIMessage({ type = 'refboard:autosave:saved', payload = payload })
end)

RegisterNetEvent('refboard:presence:update', function(payload)
  SendNUIMessage({ type = 'refboard:presence:update', payload = payload })
end)

RegisterNetEvent('refboard:presence:list:ack', function(payload)
  SendNUIMessage({ type = 'refboard:presence:list:ack', payload = payload })
end)

RegisterNetEvent('refboard:health:check:ack', function(payload)
  SendNUIMessage({ type = 'refboard:health:check:ack', payload = payload })
end)
