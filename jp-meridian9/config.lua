-- ============================================================
-- MERIDIAN-9 / Project JANUS  設定ファイル
-- ============================================================
-- このファイルでMODの動作を細かく調整できます。
-- 編集後はサーバーの restart jp-meridian9 で反映されます。
-- ============================================================

Config = {}

-- ▼ 基本設定 ----------------------------------------------------
Config.Debug = false                    -- デバッグログを有効化（true で詳細出力）
Config.Locale = 'ja'                    -- 言語コード（現状 'ja' のみ）

-- ▼ ヴェガNPC設定 ----------------------------------------------
Config.NPC = {
    -- 出現位置（暫定: Mission Row 警察署付近。本番は路地裏オフィス等へ差し替え）
    coords = vector4(427.5, -979.3, 30.7, 90.0),
    model = 's_m_m_highsec_01',         -- NPCのモデル
    scenario = 'WORLD_HUMAN_CLIPBOARD', -- 待機モーション
    invincible = true,                  -- 無敵化
    freeze = true,                      -- 移動禁止
    blockEvents = true,                 -- AIイベントブロック
    targetDistance = 2.5,               -- ox_target 有効距離
    blip = {
        enabled = true,                 -- INSTRUCTION-010: 短距離マーカー表示
        sprite = 498,                   -- 書類系アイコン
        color = 4,                      -- 黄
        scale = 0.8,
        shortRange = true,              -- 近距離のみ
        labelKey = 'npc_blip_label',    -- locales のキー（`_()` 参照）
        label = 'Vega & Associates',    -- labelKey 未使用時のフォールバック
    },
}

-- ▼ ゲート位置 -------------------------------------------------
Config.Gate = {
    origin = vector3(0.0, 0.0, 0.0),    -- ロスサントス側ゲート（事務所地下）
    destination = vector3(0.0, 0.0, 0.0), -- サイト・ナイン側スポーン地点
}

-- ▼ パーティ設定（INSTRUCTION-010）-------------------------------
Config.Party = {
    maxMembers = 5,
    minMembers = 1,
    inviteRange = 10.0,                 -- 招待可能距離（m）
    inviteTimeoutSeconds = 30,         -- 招待タイムアウト（秒）
    allowSoloMission = true,            -- ソロでゲート確定を許可
    autoPromoteOnLeaderLeave = true,    -- リーダー離脱時に次メンバーへ自動譲渡
}

-- ▼ ミッション設定 ---------------------------------------------
Config.Mission = {
    timeLimitSeconds = 1200,            -- 制限時間（20分）
    bucketStart = 100,                  -- セッション用バケット番号開始値（プール下限）
    bucketEnd = 999,                    -- バケット番号上限（プール上限）
    maxConcurrentSessions = 20,         -- 同時並行セッション上限
    cleanupIntervalSeconds = 60,      -- タイムアウト監視周期（秒）
    -- 動作確認用の暫定座標（The Apocalypse Project 導入後に差し替え。海上 0,0,0 は避ける）
    spawnPoint = vector4(1972.0, 3818.0, 33.4, 0.0),   -- サイト・ナイン側スポーン（暫定: Sandy Shores 近郊）
    returnPoint = vector4(-75.24, -818.74, 326.18, 0.0), -- 帰還（暫定: Maze Bank 付近）
}

-- ▼ ゾンビ設定 -------------------------------------------------
Config.Zombies = {
    models = {                          -- 使用するペドモデル
        'u_m_y_zombie_01',
    },
    waves = {
        { count = 10, hp = 100, damage = 10, speed = 1.0 },   -- ウェーブ1
        { count = 15, hp = 150, damage = 15, speed = 1.1 },   -- ウェーブ2
        { count = 25, hp = 200, damage = 20, speed = 1.2 },   -- ウェーブ3
    },
}

-- ▼ アイテム設定 -----------------------------------------------
-- レアリティ: common / uncommon / rare / legendary
Config.Items = {
    { id = 'sample_water',     name = '汚染水サンプル',   rarity = 'common',     value = 500 },
    { id = 'plant_fragment',   name = '変質した植物片',   rarity = 'common',     value = 800 },
    { id = 'unknown_metal',    name = '不明金属の破片',   rarity = 'common',     value = 1200 },
    { id = 'biological_tissue',name = '未知の生体組織',   rarity = 'uncommon',   value = 5000 },
    { id = 'damaged_drive',    name = '損傷したドライブ', rarity = 'uncommon',   value = 7500 },
    { id = 'energy_cell',      name = '稼働中エネルギーセル', rarity = 'rare',  value = 25000 },
    { id = 'research_log',     name = '研究ログ',         rarity = 'rare',       value = 30000 },
    { id = 'subject_zero_cell',name = 'Subject-0 細胞片', rarity = 'legendary',  value = 150000 },
}

Config.RarityMultiplier = {
    common = 1.0,
    uncommon = 3.0,
    rare = 10.0,
    legendary = 30.0,
}

-- ▼ アイテム出現地点 -------------------------------------------
Config.LootSpawns = {
    -- サイト・ナイン内の固定座標。各地点でランダムにアイテムが配置される。
    -- { coords = vector3(x, y, z), weight = { common=70, uncommon=25, rare=4, legendary=1 } }
    -- 後で座標と重み付けを調整
}

-- ▼ 脱出ポイント -----------------------------------------------
Config.ExtractPoints = {
    -- { coords = vector3(x, y, z), label = '北側ゲート', radius = 3.0 }
    -- 後で座標を調整
}

-- ▼ 報酬・経済 -------------------------------------------------
Config.Reward = {
    paymentType = 'cash',               -- 'cash'（現金）/ 'bank'（口座）/ 'custom'（独自通貨）
    framework = 'auto',                 -- 'auto'/'esx'/'qbcore'/'qbox'/'standalone'
    standaloneMoneyEvent = nil,         -- Standalone時のカスタム支払いイベント名（任意）
}

-- ▼ サイト・ナイン演出 -----------------------------------------
Config.SiteNine = {
    weather = 'XMAS',                   -- 雪・霧・暗い演出
    timeHour = 3,                       -- 深夜3時固定
    timeFreeze = true,                  -- 時間進行停止
}

-- ▼ HUD設定 -----------------------------------------------------
Config.HUD = {
    updateInterval = 500,               -- HUD更新間隔（ミリ秒）
    showPartyHP = true,                 -- パーティメンバーのHP表示
    showTimer = true,                   -- 残り時間表示
    showInventory = true,               -- 所持アイテム数表示
}

-- ▼ 運営設定 ---------------------------------------------------
Config.Admin = {
    aceName = 'jp-meridian9.admin',     -- 運営向け ACE（server.cfg で付与）
    contractListLimit = 50,           -- /m9_admin_list の表示件数上限
}

-- ▼ コマンド名 -------------------------------------------------
Config.Commands = {
    debugTeleport = 'm9_test_bucket',   -- デバッグ用バケット転送（運営のみ）
    stats = 'm9_stats',                 -- 自分の統計確認
}
