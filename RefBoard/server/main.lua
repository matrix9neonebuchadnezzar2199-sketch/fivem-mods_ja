RegisterNetEvent('refboard:session:enter', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:session:ack', 'net:session:enter', function()
    local license = GetPlayerIdentifierByType(src, 'license') or ''
    local name = GetPlayerName(src) or ('ID %s'):format(src)
    local mode = (payload and payload.mode == 'edit') and 'edit' or 'view'

    if mode == 'edit' then
      local pw = payload and payload.editPassword
      if not RefboardValidateEditPassword(pw) then
        RefboardSetEditApproved(src, false)
        TriggerClientEvent('refboard:session:ack', src, { ok = false, error = 'bad_password' })
        return
      end
      RefboardSetEditApproved(src, true)
    else
      RefboardSetEditApproved(src, false)
    end

    TriggerEvent('refboard:presence:add', src, license, name, mode)
    TriggerClientEvent('refboard:session:ack', src, { ok = true, mode = mode })
  end)
end)

RegisterNetEvent('refboard:session:leave', function()
  local src = source
  RefboardGuard(src, nil, 'net:session:leave', function()
    RefboardSetEditApproved(src, false)
    TriggerEvent('refboard:presence:remove', src)
    TriggerClientEvent('refboard:session:left', src, { ok = true })
  end)
end)

RegisterNetEvent('refboard:match:checkResume', function()
  local src = source
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:match:checkResume:ack', src, { hasResume = false, match = nil })
    return
  end
  TriggerClientEvent('refboard:match:checkResume:ack', src, { hasResume = false, match = nil })
end)
