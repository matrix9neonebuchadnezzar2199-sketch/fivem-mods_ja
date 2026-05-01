--- NUI → サーバー（方式B: 即時 cb、結果は message イベント）

RegisterNUICallback('openBook', function(_, cb)
    TriggerServerEvent('jp-tcgbook:server:openBook')
    cb({ ok = true })
end)

RegisterNUICallback('closeBook', function(_, cb)
    if TcgBattleWireLogEnabled() then
        print('[jp-tcgbook][wire] NUI->server closeBook (server:battleVirtualLeave)')
    end
    TriggerServerEvent('jp-tcgbook:server:battleVirtualLeave')
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('selectDeck', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:selectDeck', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('addCardToDeck', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:addCardToDeck', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('removeDeckCard', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:removeDeckCard', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('createDeck', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:createDeck', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('duplicateDeck', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:duplicateDeck', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('deleteDeck', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:deleteDeck', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('renameDeck', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:renameDeck', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('setActiveDeck', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:setActiveDeck', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('battleSetWaiting', function(data, cb)
    if TcgBattleWireLogEnabled() then
        local w = (data or {}).waiting
        print(('[jp-tcgbook][wire] NUI->server battleSetWaiting waiting=%s'):format(tostring(w)))
    end
    TriggerServerEvent('jp-tcgbook:server:battleSetWaiting', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('battleCallById', function(data, cb)
    if TcgBattleWireLogEnabled() then
        local tid = tonumber((data or {}).target_server_id)
        print(('[jp-tcgbook][wire] NUI->server battleCallById target_server_id=%s'):format(tostring(tid)))
    end
    TriggerServerEvent('jp-tcgbook:server:battleCallById', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('battleVirtualLeave', function(_, cb)
    if TcgBattleWireLogEnabled() then
        print('[jp-tcgbook][wire] NUI->server battleVirtualLeave')
    end
    TriggerServerEvent('jp-tcgbook:server:battleVirtualLeave')
    cb({ ok = true })
end)

RegisterNUICallback('battleSoloVirtualWireTest', function(_, cb)
    if TcgBattleWireLogEnabled() then
        print('[jp-tcgbook][wire] NUI->server battleSoloVirtualWireTest')
    end
    TriggerServerEvent('jp-tcgbook:server:battleSoloVirtualWireTest')
    cb({ ok = true })
end)

RegisterNUICallback('battleDebugLookupId', function(data, cb)
    if TcgBattleWireLogEnabled() then
        local tid = tonumber((data or {}).target_server_id)
        print(('[jp-tcgbook][wire] NUI->server battleDebugLookupId target_server_id=%s'):format(tostring(tid)))
    end
    TriggerServerEvent('jp-tcgbook:server:battleDebugLookupId', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('battleDebugStartCpu', function(_, cb)
    if TcgBattleWireLogEnabled() then
        print('[jp-tcgbook][wire] NUI->server battleDebugStartCpu')
    end
    TriggerServerEvent('jp-tcgbook:server:battleDebugStartCpu')
    cb({ ok = true })
end)

RegisterNUICallback('battleDebugPlace', function(data, cb)
    if TcgBattleWireLogEnabled() then
        local d = data or {}
        print(('[jp-tcgbook][wire] NUI->server battleDebugPlace cell=%s hand=%s'):format(
            tostring(d.cell_index),
            tostring(d.hand_index)))
    end
    TriggerServerEvent('jp-tcgbook:server:battleDebugPlace', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('battleDebugLeave', function(_, cb)
    if TcgBattleWireLogEnabled() then
        print('[jp-tcgbook][wire] NUI->server battleDebugLeave')
    end
    TriggerServerEvent('jp-tcgbook:server:battleDebugLeave')
    cb({ ok = true })
end)

RegisterNUICallback('battlePvpPlace', function(data, cb)
    if TcgBattleWireLogEnabled() then
        local d = data or {}
        print(('[jp-tcgbook][wire] NUI->server battlePvpPlace session=%s turn_no=%s cell=%s hand=%s'):format(
            tostring(d.session_id),
            tostring(d.turn_no),
            tostring(d.cell_index),
            tostring(d.hand_index)))
    end
    TriggerServerEvent('jp-tcgbook:server:battlePvpPlace', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('battlePvpLeave', function(_, cb)
    if TcgBattleWireLogEnabled() then
        print('[jp-tcgbook][wire] NUI->server battlePvpLeave')
    end
    TriggerServerEvent('jp-tcgbook:server:battlePvpLeave')
    cb({ ok = true })
end)

RegisterNUICallback('battlePvpRequestState', function(data, cb)
    if TcgBattleWireLogEnabled() then
        local d = data or {}
        print(('[jp-tcgbook][wire] NUI->server battlePvpRequestState session=%s'):format(tostring(d.session_id)))
    end
    TriggerServerEvent('jp-tcgbook:server:battlePvpRequestState', data or {})
    cb({ ok = true })
end)

--- /bookadmin（別 HTML）

RegisterNUICallback('adminBootstrap', function(_, cb)
    TriggerServerEvent('jp-tcgbook:server:adminBootstrap')
    cb({ ok = true })
end)

RegisterNUICallback('adminClose', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
    SendNUIMessage({
        action = 'jp-tcgbook:navigate',
        target = 'book',
        resource = GetCurrentResourceName(),
    })
end)

RegisterNUICallback('adminCheckCardId', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:adminCheckCardId', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('adminImpact', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:adminImpact', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('adminSaveCard', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:adminSaveCard', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('adminDeleteCard', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:adminDeleteCard', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('adminListAudit', function(data, cb)
    TriggerServerEvent('jp-tcgbook:server:adminListAudit', data or {})
    cb({ ok = true })
end)

RegisterNUICallback('adminSuggestNo', function(_, cb)
    TriggerServerEvent('jp-tcgbook:server:adminSuggestNo')
    cb({ ok = true })
end)
