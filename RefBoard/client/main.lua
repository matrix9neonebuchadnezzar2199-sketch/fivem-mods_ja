local isOpen = false

local function setOpen(state)
  isOpen = state
  SetNuiFocus(state, state)
  SetNuiFocusKeepInput(false)
  SendNUIMessage({ type = 'refboard:setOpen', payload = { open = state } })
end

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

RegisterNetEvent('refboard:match:list:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:list:ack', payload = payload })
end)

RegisterNetEvent('refboard:match:create:ack', function(payload)
  SendNUIMessage({ type = 'refboard:match:create:ack', payload = payload })
end)

RegisterNetEvent('refboard:lock:acquire:result', function(payload)
  SendNUIMessage({ type = 'refboard:lock:acquire:result', payload = payload })
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
