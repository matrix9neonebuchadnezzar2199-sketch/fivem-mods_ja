-- 最速・外部スクリプトより先に実行。色コードなし: txAdmin によっては ^2 が出ない
print('jp-taxijob: client/bootstrap.lua LOADED [1/3]')
print('[jp-taxijob] この行が F8 にも出なければ resources に jp-taxijob が無い or ensure されていない')

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
    pcall(function()
        PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end)
    notifTitle('jp-taxijob', 'PING OK（クライアントは動作中）')
    print('^2[jp-taxijob]^7 jp_taxijob_ping クライアント直コマンド実行')
end, false)

RegisterKeyMapping('jp_taxijob_ping', 'jp-taxijob: 接続テスト', 'keyboard', 'F7')

RegisterNetEvent('jp-taxijob:client:bootstrapFromServer')
AddEventHandler('jp-taxijob:client:bootstrapFromServer', function()
    pcall(function()
        PlaySoundFrontend(-1, 'NAV', 'HUD_AMMO_SHOP_SOUNDSET', true)
    end)
    notifTitle('jp-taxijob', 'サーバー→クライアント: /jp_taxijob_ping 届きました')
end)

CreateThread(function()
    Wait(1500)
    local st = GetResourceState and GetResourceState('jp-taxijob') or '?'
    print(('[jp-taxijob] [bootstrap] この resource の状態: %s（started なら正常）'):format(tostring(st)))
end)
