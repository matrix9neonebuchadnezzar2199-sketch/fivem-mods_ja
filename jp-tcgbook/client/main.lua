--- jp-tcgbook クライアントエントリ

local function hasBookAdminAce()
    local ace = Config.BookAdminAce or 'command.tcg_book_admin'
    return IsPlayerAceAllowed(PlayerId(), ace)
end

RegisterCommand('bookadmin', function()
    if not hasBookAdminAce() then
        TriggerEvent('chat:addMessage', {
            args = { '[tcg]', '管理者権限がありません（ACE: ' .. (Config.BookAdminAce or 'command.tcg_book_admin') .. '）' },
        })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'jp-tcgbook:navigate',
        target = 'admin',
        resource = GetCurrentResourceName(),
    })
end, false)

RegisterNetEvent('jp-tcgbook:client:adminData', function(msg)
    SendNUIMessage({ action = 'adminData', payload = msg })
end)

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
