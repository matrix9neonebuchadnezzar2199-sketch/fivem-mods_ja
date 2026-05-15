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
    -- INSTRUCTION-020 v4: サイト・ナイン = LS 内 Sandy Shores 北部廃工場エリア（暫定）
    -- v3 Cayo Perico は GTA V クライアントの内部状態破壊問題で撤回。
    -- 「地続きでアクセス可能」だが RP 上「Meridian-9 隔離区域、許可なき侵入は契約違反」と整合。
    -- 実機精査で座標を確定する想定。
    spawnPoints = {
        vector4(2125.0, 4787.0, 41.0,   0.0),   -- 廃倉庫 1（仮）
        vector4(2100.0, 4775.0, 41.0,  90.0),   -- 廃倉庫 2（仮）
        vector4(2150.0, 4760.0, 41.0, 180.0),   -- 廃倉庫 3（仮）
        vector4(2120.0, 4810.0, 41.0, 270.0),   -- 廃倉庫 4（仮）
        vector4(2080.0, 4795.0, 41.0,  45.0),   -- 廃倉庫 5（仮）
    },
    spawnPoint = vector4(2125.0, 4787.0, 41.0, 0.0),
    returnPoint = vector4(425.0, -979.3, 30.5, 270.0),
    siteNineLoadWaitMs = 1500,
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
-- INSTRUCTION-020 v4: Sandy Shores 北部 廃工場・空港周辺の暫定座標。実機精査で確定。
Config.LootSpawns = {
    { coords = vector3(2125.0, 4787.0, 41.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    { coords = vector3(2100.0, 4775.0, 41.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    { coords = vector3(2150.0, 4760.0, 41.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(2080.0, 4795.0, 41.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    { coords = vector3(2120.0, 4810.0, 41.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(1972.0, 3818.0, 33.4), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    { coords = vector3(2200.0, 4825.0, 41.0), weight = { common = 50, uncommon = 35, rare = 12, legendary = 3 } },
    { coords = vector3(2050.0, 4750.0, 41.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(2557.0, 4671.0, 33.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    { coords = vector3(1715.0, 3273.0, 41.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
}

-- ▼ 脱出ポイント -----------------------------------------------
-- Config.ExtractPoints / Config.Extract は INSTRUCTION-013 のブロック（末尾）で定義する。
-- 暫定座標を運営側で差し替える場合は末尾の Config.ExtractPoints を編集すること。

-- ▼ 報酬・経済 -------------------------------------------------
Config.Reward = {
    paymentType = 'cash',               -- 'cash'（現金）/ 'bank'（口座）/ 'custom'（独自通貨）
    framework = 'auto',                 -- 'auto'/'esx'/'qbcore'/'qbox'/'standalone'
    standaloneMoneyEvent = nil,         -- Standalone時のカスタム支払いイベント名（任意）
}

-- ▼ サイト・ナイン演出 -----------------------------------------
-- 任務中だけクライアント側で適用する。`onMissionEnd` で全解除。
-- INSTRUCTION-020 v4 確定運用:
--   Cayo Perico (v3) / 北ヤンクトン (v2) 採用は撤回。GTA V クライアント内部状態の
--   破壊問題で実用不可だったため。サイト・ナインは LS 内 Sandy Shores 北部の
--   廃工場・隔離区域として運用。MAP 切替系ネイティブは一切呼ばない。
--   bucket と演出（雷雨・夜・青みフィルター・街灯消灯）でサイト・ナイン感を出す。
Config.SiteNine = {
    -- 演出（任務中のみ）
    weather = 'THUNDER',                -- 雷雨
    timeHour = 22,                      -- 夜 10 時
    timeMinute = 0,
    timeFreeze = true,                  -- 時間進行停止
    timecycleModifier = 'phone_cam11',  -- 青み・コントラスト
    timecycleStrength = 0.85,
    blackout = true,                    -- 街灯消灯（LS 内なので有効）
    -- INSTRUCTION-020 v4: 島切替は 'none' で完全無効化
    -- 'cayoperico' / 'northYankton' / 'none'
    -- v3/v2 のコードは残置（将来の MAP MOD 採用余地、現状無効）
    island = 'none',
    graveStyle = 'dug',                 -- 北ヤンクトン用（未使用）
    traffic = false,
    iplLoadWaitMs = 1500,
}

-- ▼ HUD設定 -----------------------------------------------------
-- INSTRUCTION-014: `updateInterval` は後方互換の別名（tickServerMs 未指定時に使用）。
Config.HUD = {
    enabled = true,                     -- false で NUI HUD 全体を無効化
    updateInterval = 500,               -- 旧キー（tickServerMs のフォールバック）
    tickServerMs = 500,                 -- サーバー集約 → クライアント配信周期
    tickClientMs = 250,                 -- クライアント側ローカル補間（タイマー・自分 HP）
    tickRenderMs = 100,                  -- 将来: NUI 内アニメ用（現状未使用）
    showPartyHP = true,                 -- パーティ HP パネル
    showTimer = true,                   -- 残り時間
    showInventory = true,               -- インベントリ（総数 + レアリティ別）
    showWaveBanner = true,              -- ウェーブ帯（中央上）
    inventoryMode = 'byRarity',         -- 'byRarity' | 'items' | 'totalOnly'（014 既定: byRarity）
    waveEventMs = 4500,                 -- m9_hud_event ウェーブ系トースト表示時間（ms）
    uiScale = 2.0,                      -- NUI 文字サイズの倍率（CSS 変数 --m9-scale に渡る）
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

-- ▼ ゾンビアリーナ（INSTRUCTION-011）--------------------------------
-- ウェーブ定義は `waves[1]` から連番。TP-Advanced-Zombies 由来のスポーンは `server/arena/spawn.lua`。
-- INSTRUCTION-021: マスター判断により 3 ウェーブ制は廃止。任務開始から直接サバイバル
-- フェーズへ入る運用に変更（初期位置が塀に囲まれてゾンビが入ってこない問題への対処）。
-- アリーナ実装は将来の特定難易度・ボス戦などで再利用できるよう **コードは残置**。
Config.Arena = {
    enabled = false,                    -- INSTRUCTION-021: 既定で無効。true でアリーナ復活
    countdownSeconds = 5,
    waveIntervalSeconds = 10,
    totalWaves = 3,
    maxConcurrentZombies = 15,
    spawnRadiusMin = 15.0,             -- Cayo Perico 住宅街は建物密集で視界が遮られるため、近めに湧かせる
    spawnRadiusMax = 40.0,
    spawnRetryAttempts = 5,
    zombieModels = { 'u_m_y_zombie_01' },
    bossModels = { 'u_m_y_zombie_01' },
    zombieHealth = 150,
    bossHealth = 600,
    ragdollDurationMs = 5000,           -- 全滅送還後のラグドール（ms）
    knockdownHealth = 1,                -- 送還直後の HP（蘇生 UI 実装時に再検証）
    waves = {
        [1] = { zombieCount = 5, bossCount = 0 },
        [2] = { zombieCount = 8, bossCount = 0 },
        [3] = { zombieCount = 10, bossCount = 1 },
    },
}

-- ▼ ルート取得（INSTRUCTION-012）--------------------------------
-- `Config.LootSpawns` が空でない場合は各要素の `coords` からランダムに座標を選ぶ。
-- 空のときは `Config.Mission.spawnPoint` を中心に `spawnAreaRadius` 内へランダム配置。
-- レアリティ抽選: 各スポーンの `weight` があればそれを使用、なければ `Config.LootRarityWeight`。
Config.LootRarityWeight = {
    common = 70,
    uncommon = 25,
    rare = 4,
    legendary = 1,
}

Config.Loot = {
    enabled = true,
    maxPerSession = 24,
    pickupRadius = 3.0,
    spawnAreaRadius = 50.0,
    minDistanceBetween = 4.0,
    spawnPlacementAttempts = 28,
    cooldownMs = 500,
    defaultPropModel = 'prop_paper_bag_01',
}

-- ▼ 脱出（INSTRUCTION-013）------------------------------------------
-- Config.ExtractPoints の各点で「[E] 脱出開始」→ progressCircle（既定 5 秒）。
-- 進行中の被ダメージ・移動・発砲・エリア離脱でキャンセル。成功で個別離脱。
Config.Extract = {
    enabled = true,
    durationMs = 5000,
    cooldownMs = 1500,
    cancelOnDamage = true,
    showBlipsDuringMission = true,
    textUiPosition = 'right-center',
}

-- ▼ 脱出ポイント上書き ---------------------------------------------
-- INSTRUCTION-020 v4: Sandy Shores 北部 周辺の脱出 5 ヶ所（暫定）。実機精査で確定。
Config.ExtractPoints = {
    { coords = vector3(2125.0, 4787.0, 41.0), label = '北側ゲート',     radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(1715.0, 3273.0, 41.0), label = '南側救援所',     radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(2557.0, 4671.0, 33.0), label = '東側ヘリパッド', radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(1972.0, 3818.0, 33.4), label = '中央広場',       radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(2050.0, 4825.0, 41.0), label = '配電施設',       radius = 4.0, blipSprite = 488, blipColor = 5 },
}

-- ▼ オープンワールド・サバイバル（INSTRUCTION-021）------------------
-- Config.Arena.enabled=false（既定）時は TransferIn 直後にこのフェーズが開始。
-- Arena 有効時は 3 ウェーブクリア後に開始。
-- 各メンバー周辺 radiusMin〜radiusMax m にゾンビが intervalMs ごとに count 体スポーン。
-- 「探索しながらゾンビ処理」の持続的脅威でサバイバル感を演出する。
Config.Survival = {
    enabled = true,
    firstSpawnMs = 20 * 1000,           -- 開始から最初のスポーンまで（ゲート演出後すぐ来るよう短め）
    intervalMs = 180 * 1000,            -- 以降のスポーン周期（3 分ごと）
    countPerPlayer = 3,                 -- 1 サイクルで各メンバー周辺に出現する体数
    radiusMin = 30.0,                   -- スポーン半径下限（m）
    radiusMax = 150.0,                  -- スポーン半径上限（m）
    zombieHealth = 100,                 -- 1 体あたり HP
    zombieModels = { 'u_m_y_zombie_01' },
}
