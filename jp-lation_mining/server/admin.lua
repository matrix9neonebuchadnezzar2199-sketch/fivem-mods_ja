-- 採掘レベル管理コマンド
local server = require 'config.server'

if not server.admin or not server.admin.command then
    return
end

local function aceName()
    return server.admin.ace or ('command.' .. tostring(server.admin.command))
end

--- @param source number
--- @param args string[]
local function onSetLevel(source, args)
    if source > 0 and not IsPlayerAceAllowed(source, aceName()) then
        TriggerClientEvent('jp-lation_mining:notify', source, locale('admin.no-permission'), 'error')
        return
    end
    local tid = args[1] and tonumber(args[1]) or nil
    local newLevel
    if args[2] ~= nil then
        newLevel = tonumber(args[2])
    else
        newLevel = 5
    end
    if not newLevel or newLevel < 1 then
        if source == 0 then
            print('^1[jp-lation_mining] レベルは 1 以上の数値。例: ' .. server.admin.command .. ' 1 5^0')
        else
            TriggerClientEvent('jp-lation_mining:notify', source, locale('admin.setlevel-badlevel'), 'error')
        end
        return
    end
    if not tid or tid < 1 or tid > 128 then
        if source == 0 then
            print('^3[jp-lation_mining] 使い方: ' .. server.admin.command .. ' [プレイヤーサーバーID] [レベル(省略で5)]^0')
        else
            TriggerClientEvent('jp-lation_mining:notify', source, locale('admin.setlevel-usage', server.admin.command), 'error')
        end
        return
    end
    if not GetPlayerName(tid) then
        if source == 0 then
            print('^1[jp-lation_mining] 指定のIDのプレイヤーがいません^0')
        else
            TriggerClientEvent('jp-lation_mining:notify', source, locale('admin.player-offline'), 'error')
        end
        return
    end
    local ok = exports['jp-lation_mining']:SetPlayerMiningLevel(tid, newLevel)
    if not ok then
        if source == 0 then
            print('^1[jp-lation_mining] 設定失敗（identifier 未取得など）。フレームワーク有効化を確認^0')
        else
            TriggerClientEvent('jp-lation_mining:notify', source, locale('admin.setlevel-fail'), 'error')
        end
        return
    end
    if source == 0 then
        print(('^2[jp-lation_mining] 採掘レベル %d → 対象: %s (id %d)^0'):format(newLevel, GetPlayerName(tid) or '?', tid))
    else
        TriggerClientEvent('jp-lation_mining:notify', source, locale('admin.setlevel-ok', GetPlayerName(tid) or '?', tid, newLevel), 'info')
    end
    TriggerClientEvent('jp-lation_mining:notify', tid, locale('admin.setlevel-notify-target', newLevel), 'info')
end

RegisterCommand(server.admin.command, onSetLevel, true)
