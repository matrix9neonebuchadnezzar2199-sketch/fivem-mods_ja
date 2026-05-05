-- it-drugs.sql と同等の DDL を起動時に実行（Config.ManualDatabaseSetup が false のとき）
-- 旧実装は rawExecute のコールバック完了前に DatabaseSetuped が立ち、テーブル未作成で SELECT される競合があったため query.await で同期化
DatabaseSetuped = false

local plantSetupStatement = 'CREATE TABLE IF NOT EXISTS drug_plants (' ..
    'id VARCHAR(11) NOT NULL, PRIMARY KEY(id),' ..
    'owner LONGTEXT DEFAULT NULL,' ..
    'coords LONGTEXT NOT NULL,' ..
    'dimension INT(11) NOT NULL,' ..
    'time INT(255) NOT NULL,' ..
    'type VARCHAR(100) NOT NULL,' ..
    'health DOUBLE NOT NULL DEFAULT 100,' ..
    'fertilizer DOUBLE NOT NULL DEFAULT 0,' ..
    'water DOUBLE NOT NULL DEFAULT 0,' ..
    'growtime INT(11) NOT NULL' ..
    ');'

local processingStatement = 'CREATE TABLE IF NOT EXISTS drug_processing (' ..
    'id VARCHAR(11) NOT NULL, PRIMARY KEY(id),' ..
    'coords LONGTEXT NOT NULL,' ..
    'rotation DOUBLE NOT NULL,' ..
    'dimension INT(11) NOT NULL,' ..
    'owner LONGTEXT NOT NULL,' ..
    'type VARCHAR(100) NOT NULL' ..
    ');'

CreateThread(function()
    if Config.ManualDatabaseSetup then
        print('^3[jp-it-drugs]^7 Config.ManualDatabaseSetup=true のため DB 自動作成をスキップします（事前に it-drugs.sql をインポートしてください）')
        DatabaseSetuped = true
        return
    end

    local maxAttempts = 30
    local succeeded = false
    for attempt = 1, maxAttempts do
        local ok, err = pcall(function()
            MySQL.query.await(plantSetupStatement)
            MySQL.query.await(processingStatement)
        end)
        if ok then
            succeeded = true
            print('^2[jp-it-drugs]^7 データベーステーブルを確認しました (drug_plants, drug_processing)')
            break
        end
        lib.print.error(('[jp-it-drugs] DB テーブル作成に失敗 (%d/%d): %s'):format(attempt, maxAttempts, tostring(err)))
        Wait(1000)
    end

    if not succeeded then
        lib.print.error('^1[jp-it-drugs]^7 繰り返し失敗しました。oxmysql・DB 接続・DDL 権限を確認するか、it-drugs.sql を手動インポートして Config.ManualDatabaseSetup = true にしてください。')
    end

    DatabaseSetuped = true
end)
