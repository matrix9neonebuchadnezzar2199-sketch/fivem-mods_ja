Config = {}

-- ガチャマシン設置座標（複数可）
Config.Machines = {
    { coords = vector3(-1163.60, -1586.33, 4.41), heading = 294.63, label = "ガチャポン" },
    -- 必要に応じて追加
}

-- マシンに近づく距離
Config.InteractDistance = 2.0

-- ワールドに置くマシンpropモデル（存在しない場合はクライアント側で自動フォールバック）
Config.MachineModel = 'prop_weighstation_02'

-- ガチャ1回のコスト（ゲーム内通貨）
Config.Cost = 50

-- クールダウン（秒）
Config.Cooldown = 10

-- 課金: 'auto' 推奨。優先: qbx_core → es_extended → qb-core → ox_inventory(money) → 金なしで無料扱い
-- 強制: 'qbox' | 'qbx' | 'esx' | 'es_extended' | 'qb' | 'qbcore' | 'oxinv' | 'ox_inventory'
Config.Framework = 'auto'

-- ガチャ回数設定
Config.MaxPullCount = 10           -- 指定回数の上限
Config.MultiPullDiscount = false   -- 10連割引（将来用）
Config.MultiPullCost = nil         -- nil = Cost × 回数（割引なしの場合）

-- メニュー設定
Config.MenuTitle = 'ガチャポン'
Config.MenuOptions = {
    { label = '1連ガチャ ($%d)',   count = 1  },
    { label = '10連ガチャ ($%d)',  count = 10 },
    { label = '回数指定ガチャ',     count = 0  },  -- 0 = 入力プロンプト
}

-- レアリティ定義（weight は相対値、合計不問、100になるようにした方が直感的にわかっておすすめです）
Config.Rarities = {
    { id = 'N',   name = 'N',   color = '#aaaaaa', weight = 50, capsule = 'normal', bg = 'normal', cutin = false },
    { id = 'R',   name = 'R',   color = '#4488ff', weight = 25, capsule = 'normal', bg = 'rare',   cutin = false },
    { id = 'SR',  name = 'SR',  color = '#ffaa00', weight = 10, capsule = 'gold',   bg = 'sr',     cutin = true  },
    { id = 'SSR', name = 'SSR', color = '#ff4444', weight = 4,  capsule = 'gold',   bg = 'ssr',    cutin = true  },
    { id = 'UR',  name = 'UR',  color = '#ff00ff', weight = 10,  capsule = 'rainbow', bg = 'ur',    cutin = true  },
}

-- 排出アイテム定義（運営者向け）
-- レアリティごとにここへ追加/削除するだけで排出候補を調整できます。
-- 例: Config.ItemsByRarity.SSR に1件追加すると SSR 抽選候補が1件増えます。
Config.ItemsByRarity = {
    N = {
        { name = "銅のメダル", image = "" },
        { name = "石ころ", image = "" },
        { name = "木の枝", image = "" },
        { name = "古びたコイン", image = "" },
        { name = "ガラス玉", image = "" },
    },
    R = {
        { name = "銀のメダル", image = "" },
        { name = "青い宝石", image = "" },
        { name = "鉄の指輪", image = "" },
        { name = "星の砂", image = "" },
    },
    SR = {
        { name = "金のメダル", image = "" },
        { name = "ルビーの首飾り", image = "" },
        { name = "古代のコンパス", image = "" },
    },
    SSR = {
        { name = "ドラゴンの鱗", image = "" },
        { name = "伝説の懐中時計", image = "" },
    },
    UR = {
        { name = "世界樹の雫", image = "" },
    },
}

-- 旧形式（互換維持用）。新規運用は ItemsByRarity のみ編集してください。
Config.Items = {
    { name = "銅のメダル", rarity = "N", image = "" },
    { name = "石ころ", rarity = "N", image = "" },
    { name = "木の枝", rarity = "N", image = "" },
    { name = "古びたコイン", rarity = "N", image = "" },
    { name = "ガラス玉", rarity = "N", image = "" },
    { name = "銀のメダル", rarity = "R", image = "" },
    { name = "青い宝石", rarity = "R", image = "" },
    { name = "鉄の指輪", rarity = "R", image = "" },
    { name = "星の砂", rarity = "R", image = "" },
    { name = "金のメダル", rarity = "SR", image = "" },
    { name = "ルビーの首飾り", rarity = "SR", image = "" },
    { name = "古代のコンパス", rarity = "SR", image = "" },
    { name = "ドラゴンの鱗", rarity = "SSR", image = "" },
    { name = "伝説の懐中時計", rarity = "SSR", image = "" },
    { name = "世界樹の雫", rarity = "UR", image = "" },
}

-- NUI演出タイミング（v2: 1連用。10連は個別カプセル間隔で制御）
Config.Timing = {
    capsuleDrop      = 800,
    crack1Delay      = 1000,
    crack2Delay      = 1500,
    breakDelay       = 2200,
    flashDuration    = 300,
    bgTransition     = 500,
    cutinDuration    = 800,
    resultDelay      = 3500,
    resultDisplay    = 3000,
    totalDuration    = 7000,
    -- 10連用追加
    multiCapsuleInterval = 1200,  -- カプセル間の開封間隔（ms）
    multiResultDisplay   = 5000,  -- 10連結果一覧の表示時間（ms）
}

-- 表示スケール
Config.UIScale = 4.0  -- 1.0 = デフォルト。大きいほどNUI拡大（NUI内 --scale として使用）

-- マップBlip
Config.Blip = {
    sprite = 272,
    color  = 5,
    scale  = 0.8,
    label  = "ガチャポン"
}

-- デバッグ
Config.Debug = false

-- 管理画面（/ コマンド。ACE で制限するなら requireAdminAce を true にし、add_ace で AdminAce を許可）
-- command.<AdminCommand> でも通す
Config.AdminCommand = 'gachaadmin' -- 緊急: ACE command.<AdminCommand> 必須。マシンから入る用パスは KVS（初回は下記）
-- マシンEキー→管理画面: KVS 保存のパスワードと照合。初期値 KVS 未設定時は本値を採用（サーバー起動で KVS に反映）
Config.AdminPassword = 'admin'
Config.RequireAdminAce = false -- 旧: save 周り。現行は j-gacha2 のセッション方式と併用
Config.AdminAce = 'jp-gacha2.admin'

-- ox_inventory: 景品用スタッシュID（未登録ならサーバー起動時に RegisterStash する）
Config.StashName = 'gacha_prizes'
Config.StashLabel = 'ガチャ景品保管'
Config.StashSlots = 100
Config.StashMaxWeight = 2000000
-- スタッシュが空のとき、Config.ItemsByRarity へフォールバックする（false 推奨: 景品は全てスタッシュ軸）
Config.FallbackToConfigIfStashEmpty = false
-- 景品一覧をスタッシュ在庫のみにする（false の場合は旧 Config 枠も併用）
Config.CatalogStashOnly = true

-- ガチャUIテーマ（NUI で色変数に使う。ネオン/クラシック/ゴールド）
Config.Themes = {
    neon = { bg = '#1a0030', accent = '#ff00ff', text = '#ffffff' },
    classic = { bg = '#2d1810', accent = '#ffd700', text = '#ffffff' },
    gold = { bg = '#1a1a00', accent = '#ffaa00', text = '#ffffff' },
}

-- 管理UI・レア度表示用（4段: レジェンダリー〜コモン）。N は抽選上は R とまとめて扱う
Config.RarityDisplayNames = {
    { id = 'UR',  label = 'レジェンダリー', icon = '👑', color = '#ff4444' },
    { id = 'SSR', label = 'エピック',       icon = '💎', color = '#9944ff' },
    { id = 'SR',  label = 'レア',           icon = '⭐', color = '#4488ff' },
    { id = 'R',   label = 'コモン',         icon = '📦', color = '#888888' },
}
