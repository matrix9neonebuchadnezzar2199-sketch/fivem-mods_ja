Config = {}

-- 表示言語（locales のキーと一致）
Config.Locale = 'ja'

--[[ Discord Incoming Webhook の完全な URL（https://discord.com/api/webhooks/...）
     配布時はダミーのまま。運営環境では実 URL に差し替えること。
     実トークンはリポに含めない（例: PolaPaint/ウェブフックキー.txt は .gitignore 済み）。 ]]
Config.DiscordWebhook = 'https://discord.com/api/webhooks/000000000000000000/REPLACE_ME'

--[[ ox_inventory の items.lua で定義するアイテム名（キーと一致させる） ]]
Config.Items = {
    camera = 'polaroid_camera', -- 撮影用（消費しない想定 consume=0）
    photo = 'polaroid_photo', -- 撮影済み写真（metadata.url に画像 URL）
}

-- 撮影・保存 JPEG の品質（0.0〜1.0、screenshot-basic / Canvas 双方で使用）
Config.JpegQuality = 0.85

-- 画像の最大幅（px）。これを超える場合は NUI で縮小してからサーバーへ送る（負荷軽減）
Config.MaxImageWidth = 2560

-- 撮影の連打防止（秒）
Config.CaptureCooldownSec = 4

-- 編集保存の連打防止（秒）
Config.EditSaveCooldownSec = 3

--[[ サーバーが受け付ける Base64 文字列の最大長（data: プレフィックス除く）
     大きすぎるペイロードは拒否（イベントサイズ・Discord 制限対策） ]]
Config.MaxBase64PayloadLength = 4500000

-- サーバー・クライアントのデバッグログ
Config.Debug = false
