-- サーバー専用（クライアントに配信されない）。確率・重み・デバッグ・寄与率はここだけで管理すること。
-- config_shared.lua が先に読み込まれること。

-- ===== デバッグ =====
Config.Debug = true
Config.DebugSettings = {
    SpinDuration = 0.3,
    InitialBalance = 1000000,
    ForceWinNext = false,
    ForceJackpot = false,
    ForceBonus = false, -- true のとき次のスピンで中段を TriggerSymbol 揃いに強制（検証後 false に）
    ShowDebugButtons = true,
}

-- ===== 抽選・内部確率（秘匿） =====
Config.Paytables = {
    normal = {
        symbols = { 'cherry', 'bell', 'watermelon', 'bar', 'seven', 'wild', 'character' },
        weights = { 30, 25, 20, 15, 6, 3, 1 },
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
        symbols = { 'cherry', 'bell', 'watermelon', 'bar', 'seven', 'wild', 'character' },
        weights = { 28, 24, 20, 14, 8, 4, 2 },
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

Config.Jackpot = {
    enabled = true,
    seedAmount = 1000000,
    contributionRate = 0.01,
    triggerTier = 'jackpot',
}

-- カットインは当面画像のみ（動画は Effect で選ばれない）。動画素材投入時は cutin_video を戻す。
Config.EffectProbabilities = {
    win = {
        cutin_image = 85,
        cutin_video = 0,
        none = 15,
    },
    small = {
        cutin_image = 85,
        cutin_video = 0,
        none = 15,
    },
    bigwin = {
        cutin_image = 85,
        cutin_video = 0,
        none = 15,
    },
    jackpot = {
        cutin_image = 100,
    },
    bonus = {
        cutin_image = 100,
        cutin_video = 0,
    },
    bonusCombo = {
        cutin_image = 100,
        cutin_video = 0,
    },
}

-- カットイン抽選に使う重み付きリスト（サーバー権威）。videos は将来用にパスだけ残す。
Config.Cutins = {
    images = {
        { id = 'img_01', file = 'cutins/img_01.png', tiers = { 'win', 'small', 'bonus', 'bonusCombo' }, weight = 60 },
        { id = 'img_02', file = 'cutins/img_02.png', tiers = { 'win', 'bigwin', 'small' }, weight = 35 },
        { id = 'img_03', file = 'cutins/img_03.png', tiers = { 'bigwin', 'jackpot' }, weight = 50 },
    },
    videos = {
        { id = 'vid_01', file = 'cutins/vid_01.webm', tiers = { 'win', 'bigwin', 'small' }, weight = 10, duration = 2.0 },
        { id = 'vid_02', file = 'cutins/vid_02.webm', tiers = { 'bigwin' }, weight = 8, duration = 2.5 },
        { id = 'vid_03', file = 'cutins/vid_03.webm', tiers = { 'jackpot' }, weight = 10, duration = 4.0 },
        { id = 'vid_04', file = 'cutins/vid_04.webm', tiers = { 'bonus' }, weight = 10, duration = 3.0 },
        { id = 'vid_05', file = 'cutins/vid_05.webm', tiers = { 'bonusCombo' }, weight = 10, duration = 3.5 },
    },
}

Config.AdminAce = 'jp-slot.admin'

-- 管理パネル認証（詳細は SPEC.md）
Config.AdminAuth = {
    enabled = true,
    requireAce = true,
    sessionTtl = 30 * 60,
    maxAttempts = 5,
    lockoutSeconds = 5 * 60,
    bootstrapIfMissing = true,
    minLength = 8,
}

Config.AdminCommand = Config.AdminCommand or 'jpslotadmin'

Config.TransactionLog = true
