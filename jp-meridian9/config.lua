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
    -- INSTRUCTION-020 v3 / INSTRUCTION-021: サイト・ナイン = Cayo Perico 住宅街エリア
    -- TransferIn 時に spawnPoints からランダム選出（チームが分散しすぎないよう近隣 5 ヶ所）。
    spawnPoints = {
        vector4(5016.281, -5723.576, 17.680, 260.05),
        vector4(5082.916, -5735.612, 21.036,   8.07),
        vector4(5068.562, -5776.124, 16.317, 241.29),
        vector4(5025.901, -5804.289, 17.478, 110.83),
        vector4(4961.023, -5789.379, 26.266, 159.78),
    },
    -- spawnPoints が未指定の場合のフォールバック（旧互換）。
    spawnPoint = vector4(5016.281, -5723.576, 17.680, 260.05),
    returnPoint = vector4(425.0, -979.3, 30.5, 270.0), -- 帰還: ヴェガ事務所の前
    -- TransferIn 後の追加スリープ（クライアント側の島ロード待ち）。
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
-- INSTRUCTION-020 v3: Cayo Perico 内の暫定座標。実機で精査して確定する想定。
-- 各地点でランダムにアイテムが配置される。重みはレアリティ別の出現割合。
Config.LootSpawns = {
    -- メインビーチ
    { coords = vector3(4523.0, -4974.0, 4.5),  weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    { coords = vector3(4490.0, -5050.0, 3.8),  weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    -- 港（西側ドック）
    { coords = vector3(4520.0, -5160.0, 11.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(4470.0, -5180.0, 4.5),  weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    -- 北側ジャングル
    { coords = vector3(4700.0, -5000.0, 30.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(4760.0, -5150.0, 27.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    -- メインコンパウンド門
    { coords = vector3(4760.0, -5500.0, 19.0), weight = { common = 50, uncommon = 35, rare = 12, legendary = 3 } },
    { coords = vector3(4860.0, -5560.0, 22.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    -- El Rubio 邸宅前（高レア集中）
    { coords = vector3(4985.0, -5765.0, 35.0), weight = { common = 40, uncommon = 35, rare = 18, legendary = 7 } },
    -- ビーチサイドバー（パーティ会場）
    { coords = vector3(4500.0, -4500.0, 4.0),  weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    -- コミュニケーションタワー（高レア寄り）
    { coords = vector3(4750.0, -5300.0, 35.0), weight = { common = 40, uncommon = 35, rare = 18, legendary = 7 } },
    -- 滑走路
    { coords = vector3(5160.0, -5810.0, 17.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(5050.0, -5650.0, 15.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    -- ジャングル深部
    { coords = vector3(4900.0, -5200.0, 28.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(4830.0, -5100.0, 24.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
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
-- INSTRUCTION-020 v3 / INSTRUCTION-021 確定運用:
--   Cayo Perico は client/main.lua のリソース起動時に SetIslandEnabled(true) で
--   **常時 ON 固定**（動的 OFF が GTA V ストリーミングエンジン上で LS メモリリーク
--   を引き起こすため不可）。bucket 0 のプレイヤーにも海上に Cayo Perico が見える。
--   任務 bucket での分離は **演出（天気・時間・タイムサイクル・街灯）のみ**。
--   地形は共通だが、ゲート転送以外で島へ物理アクセスは不可（海上独立島）。
-- 演出は熱帯ホラー（雷雨・夜・青みフィルター）。
Config.SiteNine = {
    -- 演出
    weather = 'THUNDER',                -- 雷雨（熱帯ホラー）
    timeHour = 22,                      -- 夜 10 時
    timeMinute = 0,
    timeFreeze = true,                  -- 時間進行停止
    timecycleModifier = 'phone_cam11',  -- 青み・コントラスト寄り（不気味）
    timecycleStrength = 0.85,
    blackout = false,                   -- Cayo Perico は元から街灯少ない、不要
    -- INSTRUCTION-020 v3: 島切替
    -- 'cayoperico' | 'northYankton' | 'none'
    island = 'cayoperico',
    -- 北ヤンクトン用パラメータ（island = 'northYankton' のときのみ有効）
    graveStyle = 'dug',                 -- 'covered' / 'dug' / 'funeral'
    traffic = false,                    -- 島内 AI 交通
    iplLoadWaitMs = 1500,               -- IPL/Island ロード待ち（地形コリジョン安定化）
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
-- INSTRUCTION-020 v3: Cayo Perico 内の脱出 5 ヶ所。実機で確定した座標。
Config.ExtractPoints = {
    { coords = vector3(5043.146, -5112.065,  6.164), label = '監視塔',     radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(4884.140, -5283.067,  8.432), label = 'ヘリポート', radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(4892.726, -4919.016,  3.368), label = 'テント',     radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(4429.605, -4463.830,  4.782), label = '飛行場',     radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(5168.241, -4613.965,  2.864), label = '配電施設',   radius = 4.0, blipSprite = 488, blipColor = 5 },
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
