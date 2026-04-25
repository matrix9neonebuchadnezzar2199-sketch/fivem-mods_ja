Config = {}

Config.Command = '110'                    -- 通報コマンド
Config.Cooldown = 30                      -- 同一プレイヤーの通報クールダウン（秒）
Config.BlipDuration = 60                  -- マップ上の赤点滅の表示時間（秒）※運営が自由に変更可能
Config.BlipFlashInterval = 500            -- 点滅間隔（ミリ秒）
Config.BlipSprite = 161                   -- ブリップのスプライト（161 = 丸点）
Config.BlipColor = 1                      -- ブリップの色（1 = 赤）
Config.BlipScale = 1.0                    -- ブリップのサイズ
Config.NotificationDuration = 8000        -- NUI通知の表示時間（ミリ秒）

-- 警察判定設定
Config.PoliceJobNames = {                 -- ESX/QBCoreで判定するジョブ名リスト
    'police',
    'sheriff',
    'lspd',
    'bcso',
}
Config.AcePermission = 'jp-110.police'    -- ACE Permission名（フレームワーク未使用時）

-- NUI表示テキスト
Config.NotificationTitle = '110番入電'
Config.NotificationBody = '通報あり'
