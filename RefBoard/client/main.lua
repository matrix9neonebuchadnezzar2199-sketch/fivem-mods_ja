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

local function setOpen(open)
  isOpen = open
  if not open then
    compactDockActive = false
    compactGameInput = false
  end
  SetNuiFocus(open, open)
  SetNuiFocusKeepInput(false)
  -- v0.1.0 以降の NUI はトップレベル open も見る。現行 dist は payload.open を参照。
  SendNUIMessage({ type = 'refboard:setOpen', open = open, payload = { open = open } })
  if open and compactDockActive then
    applyCompactNuiFocus()
  end
end

RegisterCommand('refboard', function()
  setOpen(not isOpen)
end, false)

RegisterKeyMapping('refboard', 'RefBoard を開閉', 'keyboard', Config.OpenKey or 'F6')

local function nuiClose(_, cb)
  setOpen(false)
  cb({ ok = true })
end

RegisterNUICallback('close', nuiClose)
RegisterNUICallback('refboard:close', nuiClose)

AddEventHandler('onClientResourceStart', function(res)
  if res ~= GetCurrentResourceName() then
    return
  end
  setOpen(false)
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
