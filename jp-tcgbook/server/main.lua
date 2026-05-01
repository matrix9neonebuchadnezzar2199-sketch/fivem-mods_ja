--- jp-tcgbook サーバーエントリ

--- 識別子が取れないプレイヤーは処理拒否（暫定キーは使わない）
--- @param source number
--- @return string|nil citizenid
function getUidOrReject(source)
    local uid = GetPlayerUid(source)
    if not uid then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '[tcg]', 'プレイヤー識別子を取得できませんでした。' },
        })
        print(('[tcg] WARN: プレイヤー識別子取得失敗 source=%d'):format(source))
        return nil
    end
    return uid
end

CreateThread(function()
    local result = Database.InitializeTables()
    if not result.success then
        print('[tcg] FATAL Database.InitializeTables: ' .. tostring(result.error))
        return
    end

    print('[tcg] テーブル作成完了')
    local n = (result.data and result.data.cardMasterCount) or #TcgCardsMaster
    print(('[tcg] カードマスタ %d 件 UPSERT 完了'):format(n))
end)
