-- 最速・依存なし: qbx/ox より前に実行。ここで反応しなければリソースが ensure されていないか fxmanifest エラー
print('^2[jp-taxijob]^7 [1/3] client/bootstrap.lua 読み込み OK')

--- 古いGTA系ヘルプ。ox / chat 不要
local function notifBody(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    DrawNotification(false, true)
end

local function notifTitle(title, msg)
    -- EndTextCommandThefeedPostMessagetext Tu 形式は長いので簡易に2回
    SetNotificationTextEntry('STRING')
    AddTextComponentSubstringPlayerName(('[ %s ] %s'):format(tostring(title), tostring(msg)))
    DrawNotification(false, true)
end

RegisterCommand('jp_taxijob_ping', function()
    notifTitle('jp-taxijob', 'PING OK（クライアントは動作中）')
    print('^2[jp-taxijob]^7 jp_taxijob_ping コマンド実行')
end, false)

RegisterKeyMapping('jp_taxijob_ping', 'jp-taxijob: 接続テスト', 'keyboard', 'F7')

RegisterNetEvent('jp-taxijob:client:bootstrapFromServer', function()
    notifTitle('jp-taxijob', 'サーバーから受信: クライアント生きてます')
end)

CreateThread(function()
    Wait(1500)
    local st = GetResourceState and GetResourceState('jp-taxijob') or '?'
    print(('[jp-taxijob] [bootstrap] この resource の状態: %s（started なら正常）'):format(tostring(st)))
end)
