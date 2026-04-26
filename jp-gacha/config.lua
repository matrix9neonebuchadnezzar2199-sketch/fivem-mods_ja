-- jp-gacha 全設定。運営者は主にここを編集してください（shared_script により CL/SV 共通）。

Config = {}

-- ガチャマシン設置座標（ワールド上に複数設置可。coords=位置、heading=Y軸回転、label=3D等で使う表示名の参考）
Config.Machines = {
    { coords = vector3(-1205.98, -1560.43, 4.61), heading = 125.0, label = "ガチャポン" },
    -- 必要に応じて { coords = vector3(x,y,z), heading = 0.0, label = "名前" } を追加
}

-- マシンに「近い」と判断する距離（メートル）
Config.InteractDistance = 2.0

-- ガチャ1回あたりのコスト（現金。スタンドアロン時は課金されません）
Config.Cost = 500

-- 連続回転防止のクールダウン（秒）。サーバー・クライアントの両方で制御
Config.Cooldown = 10

-- 経済の取り扱い: 自動 / ESX / QBCore / スタンドアロン
-- ・auto: ESX → 無ければ QBCore → なければ standalone
Config.Framework = 'auto'

-- レアリティ定義（weight は相対的な出現重み。合計は任意でよい）
-- id: 識別子  name: 表示名  color: UI色  weight: 重み
-- capsule: normal|gold|rainbow / bg: 背景画像名の接尾辞 / cutin: SR帯以上で true
Config.Rarities = {
    { id = 'N',   name = 'ノーマル',     color = '#aaaaaa', weight = 60, capsule = 'normal',  bg = 'normal', cutin = false },
    { id = 'R',   name = 'レア',         color = '#4488ff', weight = 25, capsule = 'normal',  bg = 'rare',   cutin = false },
    { id = 'SR',  name = 'スーパーレア', color = '#ffaa00', weight = 10, capsule = 'gold',     bg = 'sr',     cutin = true  },
    { id = 'SSR', name = 'SSレア',       color = '#ff4444', weight = 4,  capsule = 'gold',     bg = 'ssr',    cutin = true  },
    { id = 'UR',  name = 'ウルトラレア', color = '#ff00ff', weight = 1,  capsule = 'rainbow',  bg = 'ur',     cutin = true  },
}

-- 排出コレクションアイテム（rarity は Config.Rarities の id と一致させる。image は将来用 URL 等）
Config.Items = {
    -- N
    { name = "銅のメダル",     rarity = "N",   image = "" },
    { name = "石ころ",         rarity = "N",   image = "" },
    { name = "木の枝",         rarity = "N",   image = "" },
    { name = "古びたコイン",   rarity = "N",   image = "" },
    { name = "ガラス玉",       rarity = "N",   image = "" },
    -- R
    { name = "銀のメダル",     rarity = "R",   image = "" },
    { name = "青い宝石",       rarity = "R",   image = "" },
    { name = "鉄の指輪",       rarity = "R",   image = "" },
    { name = "星の砂",         rarity = "R",   image = "" },
    -- SR
    { name = "金のメダル",     rarity = "SR",  image = "" },
    { name = "ルビーの首飾り", rarity = "SR",  image = "" },
    { name = "古代のコンパス", rarity = "SR",  image = "" },
    -- SSR
    { name = "ドラゴンの鱗",   rarity = "SSR", image = "" },
    { name = "伝説の懐中時計", rarity = "SSR", image = "" },
    -- UR
    { name = "世界樹の雫",     rarity = "UR",  image = "" },
}

-- NUI 演出のタイムライン（ミリ秒）。見た目のテンポ調整用
Config.Timing = {
    capsuleDrop   = 800,   -- カプセル落下アニメ
    crack1Delay   = 1000,  -- 1本目のヒビ
    crack2Delay   = 1500,  -- 2本目のヒビ（SR 以上で使用）
    breakDelay    = 2200,  -- 割れ・フラッシュ等のトリガー
    flashDuration = 300,   -- 白フラッシュ表示
    bgTransition  = 500,   -- 背景切り替えの目安（CSS 側とも兼ね合い）
    cutinDuration = 800,   -- カットイン帯の表示
    resultDelay   = 3500,  -- 結果 UI を出すまでの遅延
    resultDisplay = 3000,  -- 結果表示の想定（README 用。クライアント主タイマーは totalDuration）
    totalDuration = 7000,  -- 演出全体 → このあと NUI フォーカス解除
}

-- マシン位置付近のマップブリップ
Config.Blip = {
    sprite = 272,  -- ブリップスプライトID
    color  = 5,    -- 色ID
    scale  = 0.8,  -- 大きさ
    label  = "ガチャポン",
}

-- 検出状況をコンソールへ（開発時 true）
Config.Debug = false
