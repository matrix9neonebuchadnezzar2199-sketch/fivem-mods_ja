--- jp-tcgbook クライアントエントリ

RegisterCommand('book', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    TriggerServerEvent('jp-tcgbook:server:openBook')
end, false)

RegisterNetEvent('jp-tcgbook:client:bookData', function(result)
    SendNUIMessage({ action = 'bookData', payload = result })
end)

RegisterNetEvent('jp-tcgbook:client:deckSelected', function(result)
    SendNUIMessage({ action = 'deckSelected', payload = result })
end)

RegisterNetEvent('jp-tcgbook:client:deckUpdated', function(result)
    SendNUIMessage({ action = 'deckUpdated', payload = result })
end)

RegisterNetEvent('jp-tcgbook:client:deckListUpdated', function(result)
    SendNUIMessage({ action = 'deckListUpdated', payload = result })
end)

--- デバッグ: DBリセット等で BOOK を強制クローズ
RegisterNetEvent('jp-tcgbook:client:debugForceCloseBook', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'forceClose' })
end)
