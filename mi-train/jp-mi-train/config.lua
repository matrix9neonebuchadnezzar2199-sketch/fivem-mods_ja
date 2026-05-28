-- jp-mi-train 設定ファイル
-- マスター（運営者）が触る場所はすべてここに集約

Config = {}

-- ============================================================
-- 全般
-- ============================================================

---@type boolean F8 / サーバーコンソールへ詳細ログを流すか
Config.Debug = true

-- ============================================================
-- 受注 NPC（ヘイスト開始）
-- ============================================================

---@class StartNpcConfig
Config.StartNpc = {
    model   = 's_m_m_highsec_01',                       -- 怪しげな警備員モデル
    coords  = vec4(-687.82, -2417.10, 12.95, 320.78),   -- exp_trainheist と同じ場所（埠頭の倉庫前）
    scenario = 'WORLD_HUMAN_SMOKING',                   -- アイドル時のシナリオ
    blip    = {
        sprite   = 521,                                  -- ハイヒール盗賊風アイコン
        color    = 1,
        scale    = 0.8,
        shortRange = true,
        label    = '謎の依頼人',
    },
    target  = {
        label = 'ヘイストの依頼を受ける',
        icon  = 'fas fa-train',
        resetLabel = 'ヘイストをリセット（中断）',
        resetIcon  = 'fas fa-rotate-left',
    },
}

-- ============================================================
-- 列車スポーン
-- ============================================================

---@class TrainConfig
Config.Train = {
    -- CreateMissionTrain の variation 番号
    -- 0〜22 が freight 系編成、24 が metrotrain
    -- MVP では 0（標準 freight 編成）を使い、Phase 2 で DBuz747 を最後尾に attach する
    variation = 0,

    -- スポーン地点（Track ID 0 = 貨物レール上の点）
    -- Sandy Shores 北東。マスター回答の Nickoos 既定値を採用
    spawn = vec3(2533.0, 2833.0, 38.0),

    -- 進行方向: true = レール正方向、false = 逆方向
    direction = true,

    -- クルーズ速度（m/s）
    -- 20.0 m/s ≒ 72 km/h（Nickoos の freight 既定値と同じ）
    -- MI 風の追跡演出には 18〜22 程度が現実的
    cruiseSpeed = 20.0,

    -- スポーン完了待ちのタイムアウト（ms）
    spawnTimeoutMs = 15000,

    -- CreateMissionTrain 前に必ずロードする貨車・メトロモデル
    -- variation 0 は freightcont2 等を含むため、未ロードだとネイティブが即失敗する
    preloadModels = {
        'freight',
        'freightcar',
        'freightgrain',
        'freightcont1',
        'freightcont2',
        'freighttrailer',
        'tankercar',
        'metrotrain',
        's_m_m_lsmetro_01',
    },

    -- リソース起動時に上記モデルを先読み（ヘイスト開始直後の待ち時間を短縮）
    preloadOnStart = true,

    -- 各モデルの lib.requestModel タイムアウト（ms）
    modelLoadTimeoutMs = 15000,

    -- スポーン成功とみなす最低車両数（機関車 + 貨車 1 以上）
    minWagonCount = 2,

    -- 運転手 NPC（運転席に配置して戦闘で逃げないようにする）
    driver = {
        model = 's_m_m_lsmetro_01',
        invincible = true,
    },
}

-- ============================================================
-- DBuz747 add-on 客車（ハイブリッド attach）
-- ============================================================

---@class AddonCarriageConfig
Config.AddonCarriage = {
    -- false にすると Phase 1 と同じ（freight 最後尾のみ）
    enabled = true,

    -- GTA5-Mods DBuz747 の spawn 名（vehicles.meta の gameName）
    model = 'dbuz747',

    -- add-on リソース名（server.cfg で jp-mi-train より先に ensure）
    requiredResource = 'DBuz747',

    -- モデル未導入時にヘイスト自体を失敗させるか
    failIfMissingModel = false,

    modelLoadTimeoutMs = 15000,
    notifyOnAttach = true,

    -- 最後尾 freight からのローカル offset（z を上げると貨車メッシュとめり込みにくい）
    attachOffset = vec3(0.0, -12.5, 1.05),
    attachRotation = vec3(0.0, 0.0, 0.0),
    boneIndex = 0,
    useSoftPinning = true,

    invincible = true,
    disableCollision = true,

    -- ヘリ屋根侵入: addon 有効時はこちらを優先（未設定なら HeliBoard.roofOffset）
    -- DBuz747 屋根上（外殻。低すぎると車内メッシュにめり込む）
    roofOffset = vec3(0.0, -1.5, 2.85),

    -- [E] 車内に入る でテレポート＋屋根用 Freeze/無衝突を解除
    interiorEntry = {
        enabled = true,
        -- addon ローカル座標（床の上・通路付近。実機で微調整）
        offset = vec3(0.0, 3.5, 0.95),
        headingOffset = 180.0,
    },
}

-- ============================================================
-- ヘリ → 列車屋根侵入
-- ============================================================

---@class HeliBoardConfig
Config.HeliBoard = {
    -- true: ヘリの [E] で屋根を経由せず DBuz747 車内へ直行
    boardDirectToInterior = true,
    boardPrompt = '[E] 車内に飛び込む',

    -- 最後尾車両から「侵入可能」と判定する半径（メートル）
    detectRadius = 15.0,

    -- 黄色サークルを描画し始める距離（メートル）
    markerDrawDistance = 120.0,

    -- 列車との垂直方向の許容差（メートル、ヘリが上空にいる前提）
    maxAltitudeAbove = 25.0,
    minAltitudeAbove = -3.0,

    -- E キーで侵入を実行するまでにヘリに乗っている必要があるか
    requireHeliVehicle = true,

    -- 非ホスト: Blip 座標がこれより古いとマーカー/E を無効（ms）
    maxCoordsAgeMs = 2500,

    -- E 押下時、プレイヤーと最後尾の水平距離がこれを超えたら乗車拒否（スナップ防止）
    maxBoardingSnapDistance = 18.0,

    -- 車内から安全降車（客車の横へテレポート。コリジョン OFF 後に移動）
    exitOffset = vec3(4.5, 0.0, 1.2),
    exitTrainPrompt = '[E] 列車から降りる',

    -- 車内とみなす addon ローカル範囲（超えたら自動 safe exit）
    interiorBounds = {
        maxLocalX = 6.0,
        maxLocalY = 12.0,
        minLocalZ = -0.8,
        maxLocalZ = 3.5,
    },

    -- freight のみ時の屋根 offset（boardDirectToInterior=false 時）
    roofOffset = vec3(0.0, 0.0, 2.4),

    -- 侵入地点の黄色サークル（DrawMarker）
    marker = {
        type = 25,              -- 水平リング
        scale = vec3(12.0, 12.0, 1.2),
        color = { r = 255, g = 205, b = 0, a = 180 },
        zOffset = 1.0,          -- Blip 座標のみのときの高さ補正
        roofHeightOffset = 2.8, -- 実車両エンティティがあるとき屋根付近の高さ
    },
}

-- ============================================================
-- ヘイスト全体
-- ============================================================

-- ============================================================
-- MAP Blip（受注中の列車位置表示）
-- ============================================================

---@class BlipConfig
Config.Blip = {
    -- 機関車の Blip（ヘイスト参加者全員に見える）
    train = {
        -- 660 = FiveM-Trains 系で実績のある列車アイコン（795 は環境によって非表示になる）
        sprite     = 660,
        color      = 3,                          -- 青
        scale      = 0.9,
        shortRange = false,                     -- マップ全域から見える
        label      = 'ヘイスト列車',
        flash      = true,                      -- マップ上で点滅（どの列車か識別しやすく）
        showRoute  = true,                      -- GPS ルートを列車へ表示
        priority   = 10,
    },

    -- 最後尾車両の Blip（ヘリ侵入の目標点）
    lastWagon = {
        sprite     = 1,                         -- 標準マーカー（全クライアントで表示される）
        color      = 1,                          -- 赤
        scale      = 0.7,
        shortRange = false,
        label      = '最後尾（侵入点）',
        flash      = true,
        showRoute  = false,
        priority   = 9,
    },

    -- スポーン完了前の仮 Blip（侵入マーカーは出さない）
    bootstrap = {
        sprite     = 660,
        color      = 5,                          -- 黄
        scale      = 0.75,
        shortRange = false,
        label      = '列車（展開待ち）',
        flash      = true,
        showRoute  = false,
        priority   = 8,
    },

    -- 列車座標をサーバー経由で broadcast する間隔（ms）
    -- 短くするほど Blip が滑らかに追従するが、ネットワーク負荷が増える
    -- 1000ms ≒ 約 20m 単位で更新（速度 20m/s 時）
    updateIntervalMs = 500,
}

---@class HeistConfig
Config.Heist = {
    -- ヘイスト最大時間（ms）。これを超えると自動的にクリーンアップ
    maxDurationMs = 30 * 60 * 1000,  -- 30 分

    -- ヘイスト終了後、再受注可能になるまでのクールダウン（ms）
    cooldownMs = 10 * 60 * 1000,     -- 10 分（MVP では短め、運用では 1〜2 時間推奨）

    -- true: 進行中なら誰でも依頼人からリセット可（テストサーバー向け）
    resetAllowAnyone = true,

    -- ヘイスト中にトラック自動スポーンを停止するか
    disableRandomTrainsDuringHeist = true,

    -- 列車エンティティ消失と判定するまでの猶予（ms）と連続失敗回数
    trainLostGraceMs = 30000,
    trainLostMissCount = 5,
}

-- ============================================================
-- 管理者コマンド
-- ============================================================

---@class CommandConfig
Config.Commands = {
    -- /mitrain start | stop | status を有効にするか（MVP テスト用）
    enableAdminCommand = true,

    -- 管理者コマンドを実行できる ACE 権限（未設定なら全員実行可、MVP テスト想定）
    adminAce = nil,  -- 例: 'command.mitrain'
}
