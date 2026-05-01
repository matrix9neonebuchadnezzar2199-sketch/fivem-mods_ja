--- NUI → サーバー（方式B: 即時 cb、結果は message イベント）

RegisterNUICallback('openBook', function(_, cb)
    TriggerServerEvent('jp-tcgbook:server:openBook')
    cb({ ok = true })
end)

RegisterNUICallback('closeBook', function(_, cb)
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
