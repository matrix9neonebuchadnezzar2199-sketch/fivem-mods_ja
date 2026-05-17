-- ============================================================
-- MERIDIAN-9 / Project JANUS  設定ファイル
-- ============================================================
-- このファイルでMODの動作を細かく調整できます。
-- 編集後はサーバーの restart jp-meridian9 で反映されます。
-- ============================================================

Config = {}

-- ▼ 基本設定 ----------------------------------------------------
Config.Debug = false                    -- デバッグログを有効化（true で詳細出力）
Config.Locale = 'ja'                    -- 'ja' | 'en'（未翻訳キーは日本語へフォールバック）

-- ▼ ヴェガNPC設定 ----------------------------------------------
Config.NPC = {
    -- 出現位置（暫定: Mission Row 警察署付近。本番は路地裏オフィス等へ差し替え）
    coords = vector4(427.5, -979.3, 30.7, 90.0),
    model = 's_m_m_highsec_01',         -- NPCのモデル
    scenario = 'WORLD_HUMAN_CLIPBOARD', -- 待機モーション
    invincible = true,                  -- 無敵化
    freeze = true,                      -- 移動禁止
    blockEvents = true,                 -- AIイベントブロック
    -- INSTRUCTION-022: サーバ側距離検証用。coords 省略時は上記 `coords` の xyz を使用する。
    points = {
        vega = { enabled = true },
    },
    -- INSTRUCTION-022: NPC は E キー＋TextUI。任務受注フロー本体は変更せず呼び出しのみ差し替え。
    interact = {
        mode = 'key',
        key = 38,
        keyLabel = 'E',
        promptDistance = 3.0,
        triggerDistance = 2.0,
        facingDotMin = 0.5,
        cooldownMs = 800,
        hud = {
            style = 'bottom_center',
            text = '[E] 話しかける',
            subText = nil,
            showOutline = true,
            outlineColor = { r = 140, g = 60, b = 220, a = 180 },
        },
        entryEvent = 'mrd9:npc:interact',
    },
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

-- ▼ ポータル演出（INSTRUCTION-022）--------------------------------
-- 紫の渦／靄は**目印のみ**。インタラクション・ox_target は付けない。ON/OFF はサーバが `mrd9:portal:setState` で同期。
Config.Portals = {
    enabled = true,
    lod = {
        maxDrawDistance = 85.0,
    },
    -- 各要素の label はブリップ／ログ用（インタラクション文言ではない）
    points = {
        {
            id = 'vega_gate',
            coords = vector3(426.4, -978.8, 29.65),
            label = '次元境界（演出）',
        },
    },
    haze = {
        enabled = true,
        markerType = 28,
        scale = { x = 1.9, y = 1.9, z = 0.45 },
        rgba = { r = 140, g = 60, b = 220, a = 100 },
        bobHz = 0.35,
        bobAmp = 0.12,
    },
    gate = {
        enabled = false,
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
    cleanupIntervalSeconds = 5,       -- タイムアウト監視周期（秒）。endsAt 到達からこの秒内に Destroy が走る。
    -- INSTRUCTION-020 v5: サイト・ナイン = Cayo Perico 住宅街（v3 案を EnableMpDlcMaps だけ
    -- 封印して復活）。SetIslandEnabled('HeistIsland', true) のみ常時 ON、
    -- EnableMpDlcMaps は呼ばない（ESC マップ崩壊の主犯と判明したため）。
    -- 住宅街 5 ヶ所からランダム選出（チーム分散しすぎ防止）。
    spawnPoints = {
        vector4(5016.281, -5723.576, 17.680, 260.05),
        vector4(5082.916, -5735.612, 21.036,   8.07),
        vector4(5068.562, -5776.124, 16.317, 241.29),
        vector4(5025.901, -5804.289, 17.478, 110.83),
        vector4(4961.023, -5789.379, 26.266, 159.78),
    },
    spawnPoint = vector4(5016.281, -5723.576, 17.680, 260.05),
    returnPoint = vector4(425.0, -979.3, 30.5, 270.0),
    siteNineLoadWaitMs = 1500,
    -- ▼ プレイエリア（境界判定）------------------------------------
    -- 任務エリアの中心と最大半径。範囲外に出ると warn → graceSec 経過で 'out_of_zone' 除外。
    -- center は spawnPoint 系の中心地（Cayo メインビーチ）。半径 1200m は島ほぼ全域＋海岸線少し。
    -- 設定変更時の影響: 値が小さすぎるとプレイヤーが普通に動いただけで除外される。実機で
    --                  ExtractPoints 全 5 ヶ所が範囲内に収まることを必ず確認。
    playArea = {
        enabled = true,
        center = vector3(4790.0, -5170.0, 10.0),  -- Cayo Perico 概略中心
        maxRadius = 1200.0,                       -- メイン区域の半径（m）
        warnSec = 20,                             -- この秒数の間は警告のみ
        graceSec = 30,                            -- warnSec 経過後さらに graceSec 経過で除外
        checkIntervalMs = 2000,                   -- 監視周期（負荷とのトレードオフ）
    },
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
-- 表示名: `nameKey` → `locales/ja.lua` / `locales/en.lua` の `m9_item_*`（和名は ja のみで管理）
-- `name` は英語の正式名（サーバログ・DB・NUI フォールバック用）。画像は `image/item/<id>.png`（ASCII・Linux 互換）
Config.Items = {
    { id = 'field_tool_kit',       nameKey = 'm9_item_field_tool_kit',       name = 'Field Tool Kit',       rarity = 'common',     value = 600 },
    { id = 'ration_pack',         nameKey = 'm9_item_ration_pack',         name = 'Field Ration Pack',   rarity = 'common',     value = 700 },
    { id = 'multitool',           nameKey = 'm9_item_multitool',           name = 'Multitool',           rarity = 'common',     value = 900 },
    { id = 'combat_boots',        nameKey = 'm9_item_combat_boots',        name = 'Combat Boots',        rarity = 'common',     value = 1200 },
    { id = 'welding_torch',       nameKey = 'm9_item_welding_torch',       name = 'Welding Torch',       rarity = 'common',     value = 1500 },
    { id = 'protective_mask',     nameKey = 'm9_item_protective_mask',     name = 'Protective Mask',     rarity = 'common',     value = 1800 },
    { id = 'oxygen_cylinder',     nameKey = 'm9_item_oxygen_cylinder',     name = 'Oxygen Cylinder',     rarity = 'common',     value = 2200 },
    { id = 'motion_sensor',       nameKey = 'm9_item_motion_sensor',       name = 'Motion Sensor',       rarity = 'common',     value = 2500 },
    { id = 'thermal_goggles',     nameKey = 'm9_item_thermal_goggles',     name = 'Thermal Goggles',     rarity = 'uncommon',   value = 4500 },
    { id = 'tactical_gloves',     nameKey = 'm9_item_tactical_gloves',     name = 'Tactical Gloves',     rarity = 'uncommon',   value = 5000 },
    { id = 'comms_unit',          nameKey = 'm9_item_comms_unit',          name = 'Communications Unit', rarity = 'uncommon',   value = 5500 },
    { id = 'repair_drone',        nameKey = 'm9_item_repair_drone',        name = 'Repair Drone',        rarity = 'uncommon',   value = 8000 },
    { id = 'hacking_device',      nameKey = 'm9_item_hacking_device',      name = 'Hacking Device',      rarity = 'uncommon',   value = 9000 },
    { id = 'biometric_scanner',   nameKey = 'm9_item_biometric_scanner',   name = 'Biometric Scanner',   rarity = 'uncommon',   value = 10000 },
    { id = 'radiation_detector',  nameKey = 'm9_item_radiation_detector',  name = 'Radiation Detector',  rarity = 'uncommon',   value = 11000 },
    { id = 'tactical_helmet',     nameKey = 'm9_item_tactical_helmet',     name = 'Tactical Helmet',     rarity = 'uncommon',   value = 12000 },
    { id = 'tactical_vest',        nameKey = 'm9_item_tactical_vest',        name = 'Tactical Vest',       rarity = 'rare',       value = 22000 },
    { id = 'shield_booster',      nameKey = 'm9_item_shield_booster',      name = 'Shield Booster',      rarity = 'rare',       value = 26000 },
    { id = 'energy_cell',         nameKey = 'm9_item_energy_cell',         name = 'Energy Cell',         rarity = 'rare',       value = 28000 },
    { id = 'dimensional_scanner', nameKey = 'm9_item_dimensional_scanner', name = 'Dimensional Scanner', rarity = 'rare',       value = 32000 },
    { id = 'encrypted_keycard',   nameKey = 'm9_item_encrypted_keycard',   name = 'Encrypted Keycard',   rarity = 'rare',       value = 35000 },
    { id = 'radiation_suit',      nameKey = 'm9_item_radiation_suit',      name = 'Radiation Hazard Suit', rarity = 'rare',     value = 38000 },
    { id = 'nanite_repair_paste', nameKey = 'm9_item_nanite_repair_paste', name = 'Nanite Repair Paste', rarity = 'legendary', value = 120000 },
    { id = 'data_chip',           nameKey = 'm9_item_data_chip',           name = 'Data Chip',           rarity = 'legendary', value = 150000, fictionTag = 'subject_zero' },
}

Config.RarityMultiplier = {
    common = 1.0,
    uncommon = 3.0,
    rare = 10.0,
    legendary = 30.0,
}

-- ▼ アイテム出現地点 -------------------------------------------
-- Cayo Perico 陸上の足元のみ。海・崖外の XY は避ける（誤上面／海底 Z になりやすい）。
-- 取得: 陸で立ち `/m9_cayo coords` → 表示の vector4 から xyz を vector3 にして `scripts/_loot_coords_block.txt` へ貼る。
-- 一括反映: `node scripts/gen-lootspawns-snippet.mjs` → `_loot_spawns_body.lua.txt` を生成 → `node scripts/merge-lootspawns-into-config.mjs`（同一 xyz は除去済み）。
-- レア度は weight で調整（省略時は Config.LootRarityWeight）。
Config.LootSpawns = {
    { coords = vector3(3901.219, -4695.216, 4.240) },
    { coords = vector3(3901.675, -4703.375, 4.435) },
    { coords = vector3(4073.811, -4669.852, 3.787) },
    { coords = vector3(4287.560, -4538.662, 4.230) },
    { coords = vector3(4284.973, -4538.506, 4.238) },
    { coords = vector3(4283.575, -4533.207, 4.390) },
    { coords = vector3(4364.406, -4585.269, 4.208) },
    { coords = vector3(4376.744, -4583.226, 4.208) },
    { coords = vector3(4370.268, -4575.670, 4.208) },
    { coords = vector3(4414.136, -4491.559, 4.241) },
    { coords = vector3(4415.885, -4478.236, 4.339) },
    { coords = vector3(4413.239, -4470.053, 4.308) },
    { coords = vector3(4428.106, -4477.537, 4.328) },
    { coords = vector3(4429.758, -4482.386, 4.328) },
    { coords = vector3(4435.780, -4483.800, 4.303) },
    { coords = vector3(4435.150, -4473.560, 4.328) },
    { coords = vector3(4431.154, -4466.813, 6.006) },
    { coords = vector3(4427.646, -4451.593, 7.237) },
    { coords = vector3(4423.627, -4453.536, 7.237) },
    { coords = vector3(4425.759, -4450.123, 7.237) },
    { coords = vector3(4430.767, -4447.902, 7.246) },
    { coords = vector3(4434.353, -4447.438, 7.237) },
    { coords = vector3(4435.062, -4450.559, 7.242) },
    { coords = vector3(4431.062, -4454.760, 4.328) },
    { coords = vector3(4436.269, -4446.143, 4.328) },
    { coords = vector3(4438.301, -4448.857, 4.328) },
    { coords = vector3(4437.420, -4445.293, 4.328) },
    { coords = vector3(4444.051, -4449.483, 4.328) },
    { coords = vector3(4448.420, -4451.037, 4.328) },
    { coords = vector3(4446.535, -4457.874, 4.328) },
    { coords = vector3(4452.242, -4462.484, 5.008) },
    { coords = vector3(4455.544, -4471.161, 4.328) },
    { coords = vector3(4459.918, -4474.498, 7.025) },
    { coords = vector3(4462.047, -4526.648, 4.596) },
    { coords = vector3(4466.970, -4543.905, 4.909) },
    { coords = vector3(4461.792, -4463.823, 4.224) },
    { coords = vector3(4503.416, -4521.729, 4.412) },
    { coords = vector3(4497.631, -4524.405, 4.434) },
    { coords = vector3(4506.147, -4530.915, 4.222) },
    { coords = vector3(4498.468, -4533.589, 4.172) },
    { coords = vector3(4493.375, -4534.790, 4.178) },
    { coords = vector3(4503.788, -4545.333, 4.028) },
    { coords = vector3(4505.035, -4548.897, 4.075) },
    { coords = vector3(4506.198, -4552.540, 4.187) },
    { coords = vector3(4504.101, -4555.455, 4.172) },
    { coords = vector3(4508.259, -4542.025, 4.122) },
    { coords = vector3(4528.208, -4535.411, 7.552) },
    { coords = vector3(4526.707, -4550.475, 4.807) },
    { coords = vector3(4533.341, -4536.428, 4.430) },
    { coords = vector3(4535.530, -4544.192, 4.621) },
    { coords = vector3(4529.760, -4549.644, 4.896) },
    { coords = vector3(4802.972, -4400.210, 19.032) },
    { coords = vector3(4765.504, -4556.734, 25.240) },
    { coords = vector3(4763.118, -4562.839, 24.853) },
    { coords = vector3(4861.886, -4636.233, 14.242) },
    { coords = vector3(4865.530, -4633.221, 14.275) },
    { coords = vector3(4878.914, -4633.558, 13.970) },
    { coords = vector3(4887.207, -4622.756, 14.758) },
    { coords = vector3(4880.731, -4641.941, 13.299) },
    { coords = vector3(4852.938, -4678.960, 10.694) },
    { coords = vector3(5011.844, -4521.164, 7.041) },
    { coords = vector3(5092.571, -4604.153, 2.962) },
    { coords = vector3(5099.608, -4610.044, 2.382) },
    { coords = vector3(5076.796, -4600.286, 2.902) },
    { coords = vector3(5072.186, -4597.217, 2.860) },
    { coords = vector3(5067.829, -4599.057, 2.859) },
    { coords = vector3(5055.976, -4589.519, 2.898) },
    { coords = vector3(5060.184, -4590.288, 2.902) },
    { coords = vector3(5067.804, -4591.621, 2.859) },
    { coords = vector3(5063.717, -4590.117, 2.857) },
    { coords = vector3(5068.904, -4635.471, 2.410) },
    { coords = vector3(5093.636, -4654.967, 1.809) },
    { coords = vector3(5090.384, -4675.237, 2.546) },
    { coords = vector3(5100.281, -4676.642, 2.377) },
    { coords = vector3(5103.672, -4679.353, 3.215) },
    { coords = vector3(5133.420, -4700.493, 2.314) },
    { coords = vector3(5109.117, -4698.716, 3.082) },
    { coords = vector3(4795.576, -4722.732, 5.798) },
    { coords = vector3(4768.164, -4774.287, 6.354) },
    { coords = vector3(5086.715, -4891.031, 18.012) },
    { coords = vector3(5094.163, -4894.450, 18.775) },
    { coords = vector3(4900.493, -4940.965, 4.741) },
    { coords = vector3(4870.190, -4922.372, 4.075) },
    { coords = vector3(4872.354, -4914.307, 4.018) },
    { coords = vector3(4817.741, -4308.063, 6.433) },
    { coords = vector3(4821.927, -4320.014, 6.745) },
    { coords = vector3(4648.825, -4448.039, 8.517) },
    { coords = vector3(5085.468, -4879.109, 19.171) },
    { coords = vector3(5134.010, -4950.505, 17.114) },
    { coords = vector3(5136.778, -4956.761, 15.409) },
    { coords = vector3(5142.349, -4963.630, 15.097) },
    { coords = vector3(5160.600, -4946.873, 15.047) },
    { coords = vector3(5163.258, -4988.507, 13.949) },
    { coords = vector3(5178.357, -4994.036, 14.709) },
    { coords = vector3(5190.081, -5008.292, 15.094) },
    { coords = vector3(5196.409, -5013.478, 15.747) },
    -- 監視塔周辺: 屋根上に prop／マーカーが乗りやすい座標帯のためスロット削除（2026-05-15 実測 vector4 周辺）
    { coords = vector3(5153.632, -5123.489, 2.267) },
    { coords = vector3(5152.825, -5130.602, 2.268) },
    { coords = vector3(5141.704, -5148.246, 2.195) },
    { coords = vector3(5137.104, -5123.279, 2.941) },
    { coords = vector3(5117.054, -5119.171, 2.140) },
    { coords = vector3(5108.314, -5138.652, 1.943) },
    { coords = vector3(5117.646, -5151.438, 2.219) },
    { coords = vector3(5159.814, -5169.446, 1.954) },
    { coords = vector3(5211.970, -5224.207, 19.269) },
    { coords = vector3(5403.432, -5174.399, 32.706) },
    { coords = vector3(5466.923, -5238.344, 45.767) },
    { coords = vector3(5586.520, -5219.740, 16.211) },
    { coords = vector3(5609.138, -5655.284, 11.726) },
    { coords = vector3(5600.470, -5664.295, 13.004) },
    { coords = vector3(5473.278, -5841.319, 21.158) },
    { coords = vector3(5089.060, -5749.936, 18.266) },
    { coords = vector3(5007.612, -5786.963, 18.837) },
    { coords = vector3(5011.828, -5787.558, 18.754) },
    { coords = vector3(5030.492, -5789.919, 18.770) },
    { coords = vector3(5012.028, -5752.475, 29.911) },
    { coords = vector3(4965.327, -5759.838, 22.299) },
    { coords = vector3(4985.591, -5763.727, 21.793) },
    { coords = vector3(4960.474, -5790.619, 27.945) },
    { coords = vector3(5066.180, -5773.649, 17.586) },
    { coords = vector3(5060.404, -5786.846, 17.609) },
    { coords = vector3(4987.933, -5879.643, 21.472) },
    { coords = vector3(4908.958, -5835.014, 29.630) },
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
-- INSTRUCTION-020 v5 確定運用:
--   Cayo Perico は client/main.lua のリソース起動時に SetIslandEnabled(true) で
--   常時 ON 固定。EnableMpDlcMaps は ESC マップ崩壊の主犯と判明したため絶対に呼ばない。
--   bucket 0 のプレイヤーにも海上に Cayo Perico が遠景として見える。
--   任務 bucket 分離は **演出のみ**（天気・時間・タイムサイクル・街灯）。
Config.SiteNine = {
    -- 雪・吹雪系は眩しさ・視界阻害が強いため OFF。陰鬱さは曇り＋夜で担保。
    weather = 'OVERCAST',
    timeHour = 22,                      -- 夜 10 時
    timeMinute = 0,
    timeFreeze = true,
    timecycleModifier = nil,            -- 色味フィルター OFF
    timecycleStrength = 0.0,
    blackout = false,
    thunderEnabled = false,             -- 雷光・遠雷ループとも OFF（眩しさ防止。ON にしないこと推奨）
    thunderIntervalMinMs = 30 * 1000,
    thunderIntervalMaxMs = 90 * 1000,
    weatherKeeperMs = 5000,             -- 天気維持スレッドの周期（他リソースの上書き対抗）
    -- INSTRUCTION-020 v5: 'cayoperico' で Cayo Perico 採用、'none' で MAP 切替なし
    island = 'cayoperico',
    graveStyle = 'dug',                 -- 北ヤンクトン用（互換維持・未使用）
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
    uiScale = 3.0,                      -- NUI 文字サイズの倍率（CSS 変数 --m9-scale に渡る。基準 2.0 比で 1.5 倍）
    -- Phase-C HUD（`#mrd9-hud-root`）: L2 回収数・制限時間・入手トースト・離脱バナー
    stateBroadcastIntervalMs = 1000,    -- `hud:state` サーバ→クライアント周期（未指定時は tickServerMs）
    lootMetricMode = 'L2',              -- 'L2' = 任務全体（拾得数 / 初期スポーン数）、'L1' = 個人論理在庫 / personalLootCap
    personalLootCap = 99,               -- lootMetricMode == 'L1' のときの分母
    partyLeaveBannerMs = 5000,          -- NUI 離脱バナー表示目安（hud.js は 4500ms 固定アニメと併用可）
    extractWarningSec = 60,             -- 制限時間がこの秒以下で点滅
    selfHpMinDelta = 1,                 -- 自分 HP NUI 送信の最小差分（微振動抑制）
    selfHpPollMs = 250,                 -- 自分 HP 監視周期（クライアントのみ）
    killDisplayTarget = 30,             -- キル合計表示の目標値（session.mission.killTarget があればそちら優先）
    hideAmmoHud = true,                 -- 任務中にゲーム標準の弾薬 HUD を非表示（DisplayAmmoThisFrame は毎ティック呼び出し）
    killSeenCap = 1000,                 -- session._hudKillSeen の上限件数（超えたら古い順に 1/4 を削除）
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
    -- 任務開始時にサーバが生成するルート prop の本数。MAP ブリップは座標ごとに1つ相当のため、
    -- 旧実装の「固定座標を毎回ランダムに復元」だと同一 XY に重なり1個に見えやすい → server/loot.lua でシャッフル割当に変更済み。
    maxPerSession = 50,
    -- サーバー権威距離（リーダー報告座標との併用）。prop が地面補正で動いた場合の余裕。
    pickupRadius = 4.5,
    -- リーダーが lootSpawnAck で報告する実座標が、スポーン設計座標から離れすぎている場合は棄却（チート緩和）
    maxPickupReportShift = 35.0,
    spawnAreaRadius = 50.0,
    minDistanceBetween = 4.0,
    spawnPlacementAttempts = 28,
    cooldownMs = 500,
    defaultPropModel = 'prop_paper_bag_01',
    -- 近接案内（ox_lib TextUI）。画面右＋緑背景で視認性を上げる（座標はクライアントが参照）。
    textUiPosition = 'right-center',
    textUiStyle = {
        backgroundColor = '#2e7d32',
        color = '#f1f8e9',
        fontSize = '1.35em',
        padding = '10px 18px',
        borderRadius = '8px',
    },
    -- 黄色円柱マーカー中心の Z オフセット（prop の GetEntityCoords 原点からの m）。負だと地中に沈みやすい。
    markerCylinderZOffset = 0.45,
    -- リーダー `lootSpawnBatch` が各スロットで `resolveLootGroundZ` に使う上限（ms）。本数を順処理するため
    -- 長すぎると全員の lootRegister（MAP ブリップ）が末尾まで同規模で遅れる。足りなければ 900〜1200 程度まで上げる。
    batchGroundResolveMs = 700,
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
    textUiPosition = 'right-center',      -- ルートと同様、画面右（帰還 E 案内）
    textUiStyle = {
        backgroundColor = '#2e7d32',
        color = '#f1f8e9',
        fontSize = '1.35em',
        padding = '10px 18px',
        borderRadius = '8px',
    },
    -- 脱出点の赤円柱マーカー中心 Z（Config.ExtractPoints の z からの m）。負だと地中に沈む。
    markerCylinderZOffset = 0.2,
}

-- ▼ 脱出ポイント上書き ---------------------------------------------
-- INSTRUCTION-020 v5: Cayo Perico 内の脱出 5 ヶ所（実機精査済み座標）。
-- ブリップ色は 1（赤）で 3D マーカーと統一。
Config.ExtractPoints = {
    { coords = vector3(5043.146, -5112.065,  6.164), label = '監視塔',     radius = 4.0, blipSprite = 488, blipColor = 1 },
    { coords = vector3(4884.140, -5283.067,  8.432), label = 'ヘリポート', radius = 4.0, blipSprite = 488, blipColor = 1 },
    { coords = vector3(4892.726, -4919.016,  3.368), label = 'テント',     radius = 4.0, blipSprite = 488, blipColor = 1 },
    { coords = vector3(4429.605, -4463.830,  4.782), label = '飛行場',     radius = 4.0, blipSprite = 488, blipColor = 1 },
    { coords = vector3(5168.241, -4613.965,  2.864), label = '配電施設',   radius = 4.0, blipSprite = 488, blipColor = 1 },
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

-- ▼ ルート回収（案A ロック・監査ログ）--------------------------------
-- pickupRadius / cooldownMs は既存 Config.Loot を使用（本ブロックでは変更しない）。
Config.Loot = Config.Loot or {}
Config.Loot.pickupLockMs = Config.Loot.pickupLockMs or 3000

Config.Reward = Config.Reward or {}
-- standalone で実インベントリへ渡すクライアントイベント（未設定なら論理在庫のみ・現状互換）。
Config.Reward.standaloneItemEvent = Config.Reward.standaloneItemEvent or nil

-- ▼ FictionTags（案γ: tier はサーバー監査専用、クライアントには fictionTag のみ露出）----
-- Config.Items の要素に fictionTag = 'subject_zero' のように付与すると（例: id=data_chip）、
-- ルート登録時にブリップ／ox_target ラベルが上書きされ、接近で server/loot/fiction.lua が反応する。
Config.FictionTags = Config.FictionTags or {
    subject_zero = {
        blip = {
            sprite = 303,
            color = 1,
            scale = 0.9,
            flashing = true,
            label = '異常反応',
        },
        targetLabel = '何か違和感のあるケース',
        onApproach = {
            type = 'spawnZombies',
            count = 3,
            triggerDistance = 20.0,
            rMin = 5.0,
            rMax = 10.0,
            once = true,
            maxConcurrentPerSession = 9,
        },
    },
}

-- ▼ 任務リザルト（サブフェーズ A）------------------------------------------
-- 脱出時査定・付与。論理在庫は session.inventory[src].main / .safe（案S2）。
-- directCashout=true で小切手をスキップし即現金（standalone 等向け）。
Config.Result = Config.Result or {}
Config.Result.baseValueByTier = Config.Result.baseValueByTier or {
    common = 500,
    uncommon = 1500,
    rare = 5000,
    legendary = 20000,
}
Config.Result.fictionBounty = Config.Result.fictionBounty or {
    subject_zero = 50000,
}
Config.Result.extractionBonus = Config.Result.extractionBonus or 1000
Config.Result.creditUnitValue = Config.Result.creditUnitValue or 1000
Config.Result.directCashout = Config.Result.directCashout or false

-- ▼ 換金用アイテム定義（loot 抽選プールとは分離）--------------------------
Config.Currencies = Config.Currencies or {
    mrd9_credit = {
        id = 'mrd9_credit',
        name = 'Vega & Associates 法律事務所の小切手',
        label = '小切手',
        cashoutRate = 1.0,
    },
}
