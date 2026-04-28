-- クライアントにも配信される設定（確率・重み・サーバー専用項目は config_server.lua）
Config = {}

-- ===== フレームワーク（種別の検出に使用。口座は運営が変更） =====
Config.Framework = 'auto'
Config.MoneyAccount = 'cash'

-- ===== 言語 =====
Config.Locale = 'ja'

-- ===== スピン演出の見た目（クライアントのリール時間の基準。Debug の短縮はサーバーが seatGranted で送る） =====
Config.SpinDurationDefault = 2.5
Config.EffectPaylineMs = 500
Config.EffectFlashMs = 600

-- ===== スロット台3Dモデル =====
Config.PropModels = {
    standard = 'vw_prop_casino_slot_01a',
    cherry_theme = 'vw_prop_casino_slot_02a',
    seven_theme = 'vw_prop_casino_slot_03a',
    diamond_theme = 'vw_prop_casino_slot_04a',
}

-- ===== 台の物理配置 =====
Config.Machines = {
    {
        id = 'machine_01',
        coords = vector3(933.28, 42.30, 81.10),
        heading = 274.95,
        prop = Config.PropModels.cherry_theme,
        characterId = 'luna',
        paytableId = 'normal',
        minBet = 100,
        maxBet = 10000,
        themeOverride = nil,
        displayName = 'machine_01_name',
        machineDescriptionLocaleKey = 'machine_01_desc',
    },
}

Config.InteractDistance = 5.0
Config.SeatRequestCooldownMs = 800

-- ===== 配当表（表示のみ：倍率・組み合わせ名。出現重みは含めない／サーバー側 Config.Paytables を参照） =====
Config.PaytableDisplay = {
    normal = {
        payouts = {
            { combo = 'character,character,character', multiplier = 500, tier = 'jackpot' },
            { combo = 'seven,seven,seven', multiplier = 100, tier = 'bigwin' },
            { combo = 'wild,wild,wild', multiplier = 50, tier = 'bigwin' },
            { combo = 'bar,bar,bar', multiplier = 20, tier = 'win' },
            { combo = 'bell,bell,bell', multiplier = 10, tier = 'win' },
            { combo = 'watermelon,watermelon,watermelon', multiplier = 8, tier = 'win' },
            { combo = 'cherry,cherry,cherry', multiplier = 5, tier = 'win' },
            { combo = 'cherry,cherry,*', multiplier = 2, tier = 'small' },
        },
    },
    high = {
        payouts = {
            { combo = 'character,character,character', multiplier = 400, tier = 'jackpot' },
            { combo = 'seven,seven,seven', multiplier = 80, tier = 'bigwin' },
            { combo = 'wild,wild,wild', multiplier = 45, tier = 'bigwin' },
            { combo = 'bar,bar,bar', multiplier = 18, tier = 'win' },
            { combo = 'bell,bell,bell', multiplier = 10, tier = 'win' },
            { combo = 'watermelon,watermelon,watermelon', multiplier = 8, tier = 'win' },
            { combo = 'cherry,cherry,cherry', multiplier = 5, tier = 'win' },
            { combo = 'cherry,cherry,*', multiplier = 2, tier = 'small' },
        },
    },
}

-- ===== カットイン・キャラの素材パス（表示用。重み付きリストはサーバー専用 Config.Cutins） =====
Config.Characters = {
    luna = {
        displayName = 'character_luna_name',
        idle = { type = 'image', file = 'characters/luna/idle.png' },
        win = { type = 'video', file = 'characters/luna/win.webm', loop = false },
        bigwin = { type = 'video', file = 'characters/luna/bigwin.webm', loop = true },
    },
}

Config.DefaultTheme = {
    name = 'Luxury Modern',
    preset = 'luxury',
    colors = {
        bgPrimary = '#0a0608',
        bgSecondary = '#1a0e12',
        accent1 = '#d4af37',
        accent2 = '#f5e6a8',
        accent3 = '#8b1538',
        textPrimary = '#f5e6c8',
        textMuted = '#a89070',
        borderFrame = '#d4af37',
        glowColor = '#ffd700',
        reelBg = '#000000',
        buttonSpin = '#c9302c',
    },
    fonts = {
        title = 'Cinzel',
        body = 'Noto Serif JP',
    },
    effectIntensity = 60,
}

-- 管理者コマンド名（公開情報。権限チェックはサーバー側 Config.AdminAce）
Config.AdminCommand = 'jpslotadmin'

-- 動的設置（ゲーム内コマンド。永続はサーバー KVS `jp-slot:dynamic_machines`）
-- GroundOffset は静的台・動的台のスポーン後にも適用（PlaceObjectOnGroundProperly のあとに Z 加算）
Config.DynamicPlacement = {
    DefaultProp = 'cherry_theme',
    DefaultChar = 'luna',
    DefaultPaytable = 'normal',
    DefaultMinBet = 100,
    DefaultMaxBet = 10000,
    PlaceDistance = 1.5,
    SearchRadius = 3.0,
    DuplicateGuard = 1.0,
    GroundOffset = 0.0,
}

-- スポーン直後に床へスナップ（カジノ内部など /getpos の Z だけだと浮いて見える場合の対策）
Config.MachineGroundSnap = {
    Enabled = true,
}

-- UI サイズ（管理画面で上書き可能、サーバー KVS `jp-slot:ui_size` に保存）
Config.UISize = {
    widthPercent = 90,
    heightPercent = 90,
    maxWidthPx = 0,
}

-- NUI リール上下マーキー文言（クライアント init で NUI に渡す）
Config.Marquee = {
    Hype = {
        '🎰 本日も大当たりラッシュ進行中！',
        '💎 ジャックポット累積中、引き当てるのは君だ！',
        '🍒 チェリー2つでも小役、3つで大当たり！',
        '✨ キャラクター×3でフリースピン突入！',
        '🔥 SPACE / Enter キーでもスピンOK！',
        '🌙 ルナ・セラフィナがあなたの幸運を見守っています',
        '🥂 高ベットほど夢が広がる、MAX BET も試してみて',
        '🎉 ようこそ、ロスサントス公式カジノへ',
    },
    Info = {
        '本日の人気台：チェリー・マシーン #1',
        '現在のジャックポット：自動表示中',
        '配当倍率：キャラ×3 = 500倍',
        'フリースピン中の倍率は ×2、リトリガーで +5回',
        'Esc キーで台から離れられます',
        'ベット範囲は config_shared.lua から変更可能',
    },
}

-- ボーナスフリースピン（サーバーで残数・配当倍率を適用。確率は変更しない）
Config.Bonus = {
    Enabled = true,
    TriggerSymbol = 'character', -- 中段3揃い（リール中心行）でトリガー
    TriggerCount = 3,
    FreeSpins = 8,
    RetriggerEnable = true,
    RetriggerAdd = 5,
    MultiplierBase = 2, -- FS 中の配当に掛ける倍率
}

-- 開発用デバッグ（クライアントへ pushInit で渡し、NUI で参照）
Config.Debug = {
    enabled = false, -- 本番では false、開発時のみ true
    nuiVerbose = false, -- true のときのみ CLICK_TARGET / F1 スタック等を F8 に出す
    forceBonus = false, -- サーバー側は config_server の DebugSettings.ForceBonus を優先
}
