-- require / ox / qbx より先に必ず実行（server/main が落ちてもここは動く）
print('^2[jp-taxijob]^7 [server/1] bootstrap.lua — ここが見えないと jp-taxijob 自体が起動していません')

-- どのスクリプトより先に常駐。チャット用。
RegisterCommand('jp_taxijob_ping', function(source, _args, _raw)
    if source == 0 then
        print('[jp-taxijob] (コンソール) ゲーム内プレイヤーで /jp_taxijob_ping')
        return
    end
    local name = GetPlayerName(source) or '?'
    print(('[jp-taxijob] jp_taxijob_ping from id=%s name=%s'):format(tostring(source), name))
    TriggerClientEvent('jp-taxijob:client:bootstrapFromServer', source)
end, false)

RegisterCommand('jp_taxijob_debug', function(source, _args, _raw)
    if source == 0 then
        return
    end
    print(('[jp-taxijob] jp_taxijob_debug from id=%s'):format(tostring(source)))
    TriggerClientEvent('jp-taxijob:client:debugDepot', source)
end, false)
