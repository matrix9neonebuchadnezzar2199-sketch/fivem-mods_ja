--- 仮想対戦ロビー（マッチングなし・相手のサーバーIDで呼び出し）
--- 待受側が「招待待機」を ON にし、呼び出し側がその番号を入力して接続する。

local waiting = {} --- [src] = true
local sessionPeer = {} --- [src] = 相手の src（双方向）
--- 1人検証: 実プレイヤー2人目なしで virtualBattleMatched のみ返す（sessionPeer は使わない）
local soloVirtualLobby = {} --- [src] = true

--- @param src number
--- @param payload { error: string }
local function pushLobbyErr(src, payload)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battleLobbyError src=%d %s'):format(
            src, tostring(payload and payload.error)))
    end
    TriggerClientEvent('jp-tcgbook:client:battleLobbyError', src, payload)
end

--- @param src number
--- @return number|nil
function BattleLobbyGetPeer(src)
    return sessionPeer[src]
end

--- @param src number
--- @return boolean
function BattleLobbySoloWireTestActive(src)
    return soloVirtualLobby[src] == true
end

--- @param src number
--- @return boolean
local function inSession(src)
    return sessionPeer[src] ~= nil
end

--- PvP 終了時など：ピア紐付けのみ解消（イベントは送らない）
--- @param a number
--- @param b number
function BattleLobbyClearPeerPairSilent(a, b)
    if not a or not b then
        return
    end
    sessionPeer[a] = nil
    sessionPeer[b] = nil
    waiting[a] = nil
    waiting[b] = nil
end

--- 双方のセッションと待受を解消し、相手に終了を通知
--- @param src number
--- @param reason string|nil
local function clearSessionFor(src, reason)
    local peer = sessionPeer[src]
    if not peer then
        waiting[src] = nil
        return
    end
    sessionPeer[src] = nil
    sessionPeer[peer] = nil
    waiting[src] = nil
    waiting[peer] = nil
    local payload = {}
    if reason then
        payload.reason = reason
    end
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client virtualBattleEnded src=%d peer=%d'):format(src, peer))
        print(('[jp-tcgbook][wire] server->client virtualBattleEnded src=%d peer=%d'):format(peer, src))
    end
    TriggerClientEvent('jp-tcgbook:client:virtualBattleEnded', src, payload)
    TriggerClientEvent('jp-tcgbook:client:virtualBattleEnded', peer, payload)
end

RegisterNetEvent('jp-tcgbook:server:battleSetWaiting', function(data)
    local src = source
    if TcgBattleWireLogEnabled() then
        local w = (data or {}).waiting
        print(('[jp-tcgbook][wire] server recv battleSetWaiting src=%d waiting=%s'):format(src, tostring(w)))
    end
    if not getUidOrReject(src) then
        return
    end
    if soloVirtualLobby[src] then
        pushLobbyErr(src, {
            error = 'ソロ検証接続中は待受を切り替えられません（先に「切断する」）',
        })
        return
    end
    if BattleDebugInGame and BattleDebugInGame(src) then
        pushLobbyErr(src, {
            error = 'デバッグ対戦中は仮想ロビーを操作できません（先に終了）',
        })
        return
    end
    if BattlePvpInGame and BattlePvpInGame(src) then
        pushLobbyErr(src, {
            error = '対戦中は待受を切り替えられません（先に対戦終了）',
        })
        return
    end
    if inSession(src) then
        pushLobbyErr(src, {
            error = '仮想対戦中は待受を切り替えられません（先に切断）',
        })
        return
    end
    data = data or {}
    if data.waiting == true then
        waiting[src] = true
    else
        waiting[src] = nil
    end
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battleWaitingAck src=%d waiting=%s'):format(
            src, tostring(waiting[src] == true)))
    end
    TriggerClientEvent('jp-tcgbook:client:battleWaitingAck', src, {
        waiting = waiting[src] == true,
    })
end)

RegisterNetEvent('jp-tcgbook:server:battleCallById', function(data)
    local src = source
    if TcgBattleWireLogEnabled() then
        local tid0 = tonumber((data or {}).target_server_id)
        print(('[jp-tcgbook][wire] server recv battleCallById src=%d target=%s'):format(src, tostring(tid0)))
    end
    if not getUidOrReject(src) then
        return
    end
    if soloVirtualLobby[src] then
        pushLobbyErr(src, {
            error = 'ソロ検証接続中は呼び出せません（先に「切断する」）',
        })
        return
    end
    if BattleDebugInGame and BattleDebugInGame(src) then
        pushLobbyErr(src, {
            error = 'デバッグ対戦中は呼び出せません（先に終了）',
        })
        return
    end
    if BattlePvpInGame and BattlePvpInGame(src) then
        pushLobbyErr(src, {
            error = '対戦中です（先に対戦終了）',
        })
        return
    end
    if inSession(src) then
        pushLobbyErr(src, {
            error = '既に仮想対戦中です',
        })
        return
    end
    data = data or {}
    local tid = tonumber(data.target_server_id)
    if not tid or tid < 1 or math.floor(tid) ~= tid then
        pushLobbyErr(src, {
            error = '相手の番号（サーバーID・整数）を入力してください',
        })
        return
    end
    if tid == src then
        pushLobbyErr(src, {
            error = '自分の番号は指定できません',
        })
        return
    end
    if GetPlayerName(tid) == nil then
        pushLobbyErr(src, {
            error = 'その番号のプレイヤーはオンラインではありません',
        })
        return
    end
    if not GetPlayerUid(tid) or GetPlayerUid(tid) == '' then
        pushLobbyErr(src, {
            error = '相手の識別子を取得できません',
        })
        return
    end
    if inSession(tid) then
        pushLobbyErr(src, {
            error = '相手は既に別の仮想対戦中です',
        })
        return
    end
    if waiting[tid] ~= true then
        pushLobbyErr(src, {
            error = '相手は招待待機中ではありません（先に対戦タブで待受をON）',
        })
        return
    end

    waiting[src] = nil
    waiting[tid] = nil
    soloVirtualLobby[src] = nil
    soloVirtualLobby[tid] = nil
    sessionPeer[src] = tid
    sessionPeer[tid] = src

    local okPvP, errPvP = BattlePvpStart(tid, src)
    if not okPvP then
        sessionPeer[src] = nil
        sessionPeer[tid] = nil
        pushLobbyErr(src, {
            error = errPvP or '対戦開始に失敗しました',
        })
        pushLobbyErr(tid, {
            error = errPvP or '対戦開始に失敗しました',
        })
        return
    end

    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client virtualBattleMatched src=%d peer=%d caller=true'):format(src, tid))
        print(('[jp-tcgbook][wire] server->client virtualBattleMatched src=%d peer=%d caller=false'):format(tid, src))
    end
    TriggerClientEvent('jp-tcgbook:client:virtualBattleMatched', src, {
        peer_server_id = tid,
        is_caller = true,
        is_pvp = true,
    })
    TriggerClientEvent('jp-tcgbook:client:virtualBattleMatched', tid, {
        peer_server_id = src,
        is_caller = false,
        is_pvp = true,
    })
end)

--- 友達クライアントなしで仮想ロビーの往復だけ試す（Config.DebugCommands のみ）
RegisterNetEvent('jp-tcgbook:server:battleSoloVirtualWireTest', function()
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battleSoloVirtualWireTest src=%d'):format(src))
    end
    if Config.DebugCommands ~= true then
        return
    end
    if not getUidOrReject(src) then
        return
    end
    if BattleDebugInGame and BattleDebugInGame(src) then
        pushLobbyErr(src, {
            error = 'デバッグ対戦中は使えません（先に終了）',
        })
        return
    end
    if inSession(src) then
        pushLobbyErr(src, {
            error = '既に仮想対戦中です（先に切断）',
        })
        return
    end
    if soloVirtualLobby[src] then
        pushLobbyErr(src, {
            error = '既にソロ検証接続中です',
        })
        return
    end

    soloVirtualLobby[src] = true
    waiting[src] = nil

    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] (solo) no second client; emitting single virtualBattleMatched src=%d'):format(src))
        print(('[jp-tcgbook][wire] server->client virtualBattleMatched src=%d solo_wire_test=true'):format(src))
    end
    TriggerClientEvent('jp-tcgbook:client:virtualBattleMatched', src, {
        peer_server_id = nil,
        is_caller = true,
        solo_wire_test = true,
        peer_label = 'ソロ検証（2人目のクライアントなし）',
    })
end)

RegisterNetEvent('jp-tcgbook:server:battleVirtualLeave', function()
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battleVirtualLeave src=%d'):format(src))
    end
    if not getUidOrReject(src) then
        return
    end
    if soloVirtualLobby[src] then
        soloVirtualLobby[src] = nil
        waiting[src] = nil
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire] server->client virtualBattleEnded src=%d reason=solo_wire_test'):format(src))
        end
        TriggerClientEvent('jp-tcgbook:client:virtualBattleEnded', src, {
            reason = 'solo_wire_test',
        })
    end
    if BattleDebugInGame and BattleDebugInGame(src) then
        BattleDebugLeave(src)
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire] server->client battleDebugEnded src=%d (leave while debug)'):format(src))
        end
        TriggerClientEvent('jp-tcgbook:client:battleDebugEnded', src, {})
    end
    if BattlePvpInGame and BattlePvpInGame(src) then
        BattlePvpLeave(src, 'peer_left')
    end
    clearSessionFor(src, 'peer_left')
end)

AddEventHandler('playerDropped', function()
    local src = source
    if BattleDebugLeave then
        BattleDebugLeave(src)
    end
    soloVirtualLobby[src] = nil
    waiting[src] = nil
    if BattlePvpInGame and BattlePvpInGame(src) then
        BattlePvpLeave(src, 'peer_disconnect')
    end
    local peer = sessionPeer[src]
    if peer then
        sessionPeer[src] = nil
        sessionPeer[peer] = nil
        waiting[peer] = nil
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire] server->client virtualBattleEnded src=%d reason=peer_disconnect'):format(peer))
        end
        TriggerClientEvent('jp-tcgbook:client:virtualBattleEnded', peer, {
            reason = 'peer_disconnect',
        })
    end
end)
