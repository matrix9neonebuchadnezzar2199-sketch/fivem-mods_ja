Config = {}

-- 表示言語（locales/ja.lua, en.lua のキー）
Config.Locale = 'ja'

--[[ インベントリフレームワーク
     'ox'  : ox_inventory
     'qb'  : qb-inventory
     'auto': 自動判定（推奨） ]]
Config.Framework = 'auto'

-- アイテム名（items 定義側のキーと一致させる）
Config.Items = {
    camera = 'polaroid_camera',
    photo  = 'polaroid_photo',
}

-- 撮影 / 保存仕様
Config.MaxImageWidth         = 2560     -- 最大幅 (px) ※仕様書要件
Config.JpegQuality           = 0.85
Config.MaxPhotoNameLength    = 40       -- UTF-8 grapheme 単位（Lua 側は utf8.len）
Config.CaptureCooldownSec    = 4
Config.EditSaveCooldownSec   = 3
Config.CaptureSessionTTLSec  = 30       -- 撮影トークン有効秒
Config.EditSessionTTLSec     = 120      -- 編集トークン有効秒

-- ローカルストレージ（リソース配下の data/photos/）
Config.Storage = {
    -- HTTP ハンドラの公開パス（リソース名の後に続く部分）。例: …/polapaint/photo/<signed>.jpg
    httpRoute      = '/photo/',
    -- 保存可能な画像の最大バイト数（multipart 全体ではなく画像本体）
    maxBytes       = 4 * 1024 * 1024,    -- 4 MiB
    -- 自動削除（0 で無効。秒単位で経過した jpg を起動時に掃除）
    retentionSec   = 0,
}

--[[ Discord Webhook（任意・通知のみ）
     設定方法: server.cfg に
       set polapaint_webhook "https://discord.com/api/webhooks/..."
     と書く。空文字列なら通知無効。 ]]
Config.Webhook = {
    enabled    = true,                   -- false で完全無効化
    convarName = 'polapaint_webhook',
    username   = 'polapaint',
    -- 投稿に使用するベースURL（埋め込みで画像表示するため、外部到達可能なURLが必要）
    -- 空ならローカル URL の代わりに「保存しました」テキスト通知のみ
    publicBaseUrl = '',                  -- 例: 'https://photos.example.com/polapaint'
}

-- HTTP 経路の認可（簡易トークン。NUI から画像表示時のみ付与）
Config.HttpToken = {
    enabled      = true,                 -- false で誰でも閲覧可（社内サーバ向け）
    rotateSec    = 3600,                 -- 将来用（現在は起動時に HMAC キー生成）
}

Config.Debug = false
