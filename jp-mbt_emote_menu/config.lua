MBT = MBT or {}

-------------------------------------------------------------------------------
-- [ セクション1: グローバル設定 ] --
-------------------------------------------------------------------------------

-- 言語: 'ja'(日本語), 'en', 'it', 'es', 'fr', 'de', 'pt'
-- locales/*.lua から読み込まれます。新言語は同フォルダに追加してください。
MBT.Language = 'ja'
MBT.Debug = false -- コンソールにデバッグログを出力

-- rpemotes リソース名の自動検出
-- 'rpemotes-reborn' (公式), 'rpemotes' (旧版), 'rp-emotes' (古いフォーク)
-- nil で自動検出。手動指定する場合は文字列で。
MBT.RpemotesResource = nil

-------------------------------------------------------------------------------
-- [ セクション2: メニュー設定 ] --
-------------------------------------------------------------------------------

MBT.Menu = {
    Keybind            = 'F4',         -- メニュー開閉キー (rpemotes 既定と同じ)
    Command            = 'mbt_emotes', -- チャットコマンド (/mbt_emotes)
    Layout             = 'cinematic',  -- レイアウト: 'default' または 'cinematic'
    Position           = 'right',      -- パネル位置: 'left' または 'right'
    CloseOnPlay        = true,         -- エモート再生時にメニュー自動クローズ
    RememberState      = true,         -- スクロール位置・タブ・フィルタを記憶 (ESC/X でリセット)
    Watermark          = true,         -- 'MBT' ウォーターマーク表示

    -- rpemotes ネイティブメニューを無効化し、F4 で MBT メニューを開く
    OverrideNativeMenu = true,
}

-------------------------------------------------------------------------------
-- [ セクション3: 機能 ] --
-------------------------------------------------------------------------------

MBT.Features = {
    Favorites    = true, -- お気に入りシステム (KVP 保存)
    RecentEmotes = true, -- 最近使ったエモートを記録
    MaxRecent    = 12,   -- 最近エモートの最大保持数
    QuickBind    = true, -- ドラッグでキー割り当て
    SharedPopup  = true, -- 共有エモート招待のポップアップ表示
    PreviewPed   = true, -- ホバー時のペッドプレビュー
    EmoteWheel   = true, -- エモートホイール (ホールドピーク式)

    AdultEmotes    = false, -- 18禁エモート (AdultAnimation) を表示
    AbusableEmotes = false, -- 悪用可能なエモート (移動エクスプロイト系) を表示
}

-- エモートホイール
MBT.EmoteWheel = {
    Key       = 'K', -- ホールド開始キー
    Slots     = 8,   -- スロット数 (最大8)
    RemoveKey = 'X', -- ホイール表示中、現スロットのエモートを削除するキー
}

-------------------------------------------------------------------------------
-- [ セクション4: カテゴリ ] --
-------------------------------------------------------------------------------

-- カテゴリの表示順・表示/非表示を設定
-- icon は Lucide アイコン名 (React UI で使用)
-- label は NUI 表示名 (Lucide 側で locale を使う実装の場合は無視されます)
MBT.Categories = {
    { type = 'Emotes',       label = 'エモート',  icon = 'smile',          visible = true },
    { type = 'PropEmotes',   label = '小道具',    icon = 'package',        visible = true },
    { type = 'Dances',       label = 'ダンス',    icon = 'music',          visible = true },
    { type = 'Shared',       label = '共有',      icon = 'users',          visible = true },
    { type = 'Expressions',  label = '表情',      icon = 'drama',          visible = true },
    { type = 'Walks',        label = '歩き方',    icon = 'footprints',     visible = true },
    { type = 'AnimalEmotes', label = '動物',      icon = 'dog',            visible = true },
    { type = 'Emojis',       label = '絵文字',    icon = 'message-circle', visible = true },
}

-------------------------------------------------------------------------------
-- [ セクション5: テーマ ] --
-------------------------------------------------------------------------------

-- テーマカラー (16進、# なし)。nil でデフォルト適用。
MBT.Theme = {
    Accent     = '00fb8a', -- アクセント (緑)
    Background = '0C0E14', -- 背景
    Card       = '141720', -- カード/パネル背景
    Text       = 'E8E8EE', -- 主テキスト
    SubText    = '6B7280', -- 副テキスト
    Border     = '1A1D26', -- ボーダー
}

-------------------------------------------------------------------------------
-- [ セクション6: MBT エコシステム連携 ] --
-------------------------------------------------------------------------------

MBT.Ecosystem = {
    MetaClothes   = false, -- mbt_meta_clothes v2 を導入済みなら true
    WearableProps = false, -- mbt_wearable_props を導入済みなら true
}

-------------------------------------------------------------------------------
-- [ セクション7: ジョブ権限 ] --
-------------------------------------------------------------------------------

-- 特定ジョブのみ使えるエモートを設定。権限のないプレイヤーには鍵アイコン付きでグレーアウト表示。
-- 形式: ['emoteName'] = { 'job1', 'job2', ... }

MBT.JobPermissions = {
    Enabled = true, -- ジョブ権限システム全体のオン/オフ

    -- フレームワーク検出: 'auto' は ESX → QBox → QBCore → standalone の順で試行
    -- 明示指定: 'esx', 'qbox', 'qbcore', 'standalone'
    -- ※ ESX と QBCore を同時起動する混成サーバーでは明示指定推奨
    Framework = 'auto',

    Emotes = {
        -- 例:
        -- ['handcuff'] = { 'police', 'sheriff' },
        -- ['mechanic'] = { 'mechanic', 'bennys' },
        -- ['medic']    = { 'ambulance', 'doctor' },
    },
}

-------------------------------------------------------------------------------
-- [ セクション8: 通知 ] --
-------------------------------------------------------------------------------

MBT.Notification = function(data)
    -- ox_lib (推奨)
    -- exports.ox_lib:notify({
    --     title = data.title or 'MBT エモート',
    --     description = data.description,
    --     type = data.type or 'info',
    --     duration = data.duration or 4000
    -- })

    -- GTA ネイティブ
    -- BeginTextCommandThefeedPost('STRING')
    -- AddTextComponentSubstringPlayerName(data.description or data.title or '通知')
    -- EndTextCommandThefeedPostTicker(false, true)

    -- ESX
    -- ESX.ShowNotification(data.description or data.text)

    -- QBCore
    -- QBCore.Functions.Notify(data.description or data.text, 'primary')

    -- QBox (qbx_core)
    -- exports.qbx_core:Notify(data.description or data.text, 'info', data.duration or 4000)
end
