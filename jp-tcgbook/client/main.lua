--- jp-tcgbook クライアントエントリ

--- @param action string
--- @param msg unknown
local function sendBattleNui(action, msg)
    if TcgBattleWireLogEnabled() then
        local hint = ''
        if type(msg) == 'table' then
            if msg.waiting ~= nil then
                hint = (' waiting=%s'):format(tostring(msg.waiting))
            elseif msg.error ~= nil then
                hint = (' err=%s'):format(tostring(msg.error))
            elseif msg.phase ~= nil then
                hint = (' phase=%s turn=%s'):format(tostring(msg.phase), tostring(msg.turn))
            elseif msg.ok ~= nil then
                hint = (' ok=%s'):format(tostring(msg.ok))
            elseif msg.peer_server_id ~= nil or msg.is_cpu ~= nil or msg.solo_wire_test ~= nil then
                hint = (' peer=%s is_cpu=%s solo=%s'):format(
                    tostring(msg.peer_server_id),
                    tostring(msg.is_cpu),
                    tostring(msg.solo_wire_test))
            elseif msg.session_id ~= nil and msg.turn_no ~= nil then
                hint = (' session=%s turn_no=%s'):format(tostring(msg.session_id), tostring(msg.turn_no))
            elseif msg.mode ~= nil or msg.pvp_session_id ~= nil then
                hint = (' mode=%s seq=%s'):format(tostring(msg.mode), tostring(msg.turn_seq))
            elseif msg.reason ~= nil then
                hint = (' reason=%s'):format(tostring(msg.reason))
            end
        end
        print(('[jp-tcgbook][wire] client->NUI %s%s'):format(action, hint))
    end
    SendNUIMessage({ action = action, payload = msg })
end

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

RegisterNetEvent('jp-tcgbook:client:rankingData', function(msg)
    SendNUIMessage({ action = 'rankingData', payload = msg })
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

RegisterNetEvent('jp-tcgbook:client:battleWaitingAck', function(msg)
    sendBattleNui('battleWaitingAck', msg)
end)

RegisterNetEvent('jp-tcgbook:client:battleLobbyError', function(msg)
    sendBattleNui('battleLobbyError', msg)
end)

RegisterNetEvent('jp-tcgbook:client:virtualBattleMatched', function(msg)
    sendBattleNui('virtualBattleMatched', msg)
end)

RegisterNetEvent('jp-tcgbook:client:virtualBattleEnded', function(msg)
    sendBattleNui('virtualBattleEnded', msg)
end)

RegisterNetEvent('jp-tcgbook:client:battleDebugState', function(msg)
    sendBattleNui('battleDebugState', msg)
end)

RegisterNetEvent('jp-tcgbook:client:battleDebugLookupAck', function(msg)
    sendBattleNui('battleDebugLookupAck', msg)
end)

RegisterNetEvent('jp-tcgbook:client:battleDebugEnded', function(msg)
    sendBattleNui('battleDebugEnded', msg)
end)

RegisterNetEvent('jp-tcgbook:client:battlePvpStarted', function(msg)
    sendBattleNui('battlePvpStarted', msg)
end)

RegisterNetEvent('jp-tcgbook:client:battlePvpError', function(msg)
    sendBattleNui('battlePvpError', msg)
end)

RegisterNetEvent('jp-tcgbook:client:battlePvpState', function(msg)
    sendBattleNui('battlePvpState', msg)
end)

RegisterNetEvent('jp-tcgbook:client:battlePvpEnded', function(msg)
    sendBattleNui('battlePvpEnded', msg)
end)

--- デバッグ: DBリセット等で BOOK を強制クローズ
RegisterNetEvent('jp-tcgbook:client:debugForceCloseBook', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'forceClose' })
end)
