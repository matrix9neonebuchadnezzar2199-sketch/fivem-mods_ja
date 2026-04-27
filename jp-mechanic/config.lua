-- jp-mechanic 共有設定（NUI からの参照不可。出題庫は data/slips_*.lua）
Config = {}

-- 1伝票クリアあたりの基礎報酬（倍率前・難易度未指定時のフォールバック）
Config.RewardPerKarte = 300

-- 連続正解数に応じた掛け率（1～5段目）
Config.ComboMultiplier = { 1.0, 1.2, 1.5, 1.8, 2.0 }
Config.MaxCombo = 5
Config.ComboResetOnFail = true

-- 就業用 NPC（整備工場 MLO 付近。運営で座標調整）
Config.JobPedModel = 's_m_m_autoshop_01'
-- テスト配置: x, y, z, heading
Config.JobPedCoords = vector4(221.12, -808.97, 30.66, 60.93)
Config.JobPedScenario = 'WORLD_HUMAN_HAMMERING'
Config.InteractRadius = 2.0
-- E キーで NUI 開始（併用で ox_target 可）
Config.UseEKey = true
Config.ExitCommand = 'mechjob'
-- 部品名以外の「正解に含まない部品」ダミー数（難易度未指定時のフォールバック）
Config.DecoyCount = 20
Config.SessionTtlSec = 600
Config.MoneyReason = 'jp-mechanic-slip'
Config.Debug = false

-- 難易度（kartesKey = Config 上のテーブル名）
Config.Difficulties = {
    {
        id = 'easy',
        label = '初級 ⭐',
        description = '基本的な整備（正解 1～2 個前後）',
        kartesKey = 'Slips',
        rewardBase = 300,
        decoyCount = 20,
        timeLimit = 0,
    },
    {
        id = 'medium',
        label = '中級 ⭐⭐',
        description = '複合トラブル（正解 2～4 個前後）',
        kartesKey = 'SlipsMedium',
        rewardBase = 500,
        decoyCount = 22,
        timeLimit = 0,
    },
    {
        id = 'hard',
        label = '上級 ⭐⭐⭐',
        description = '総合整備・紛らわし（正解 3～6 個前後）',
        kartesKey = 'SlipsHard',
        rewardBase = 800,
        decoyCount = 25,
        timeLimit = 0,
    },
}

-- 部品・作業マスタ（30 種。id は伝票の answers と一致）
Config.Parts = {
    { id = 'engine_oil',       name = 'エンジンオイル',         icon = '🛢' },
    { id = 'oil_filter',       name = 'オイルフィルター',        icon = '🔧' },
    { id = 'air_filter',       name = 'エアフィルター',         icon = '💨' },
    { id = 'spark_plug',       name = 'スパークプラグ',          icon = '⚡' },
    { id = 'battery',          name = 'バッテリー',             icon = '🔋' },
    { id = 'alternator',       name = 'オルタネーター',         icon = '⚙' },
    { id = 'starter_motor',    name = 'スターターモーター',     icon = '🔄' },
    { id = 'brake_pad',        name = 'ブレーキパッド',         icon = '🛑' },
    { id = 'brake_disc',       name = 'ブレーキディスク',        icon = '💿' },
    { id = 'brake_fluid',      name = 'ブレーキフルード',        icon = '💧' },
    { id = 'tire',             name = 'タイヤ',                icon = '⭕' },
    { id = 'wheel_alignment',  name = 'ホイールアライメント調整', icon = '🔩' },
    { id = 'suspension',       name = 'サスペンション',         icon = '🔧' },
    { id = 'shock_absorber',   name = 'ショックアブソーバー',   icon = '📐' },
    { id = 'coolant',          name = '冷却水（クーラント）',  icon = '❄' },
    { id = 'radiator',         name = 'ラジエーター',            icon = '🌡' },
    { id = 'thermostat',       name = 'サーモスタット',         icon = '🌡' },
    { id = 'fan_belt',         name = 'ファンベルト',           icon = '〰' },
    { id = 'timing_belt',      name = 'タイミングベルト',       icon = '⏱' },
    { id = 'water_pump',       name = 'ウォーターポンプ',       icon = '💧' },
    { id = 'fuel_filter',      name = '燃料フィルター',         icon = '⛽' },
    { id = 'fuel_pump',        name = '燃料ポンプ',            icon = '⛽' },
    { id = 'exhaust_pipe',     name = 'マフラー（排気管）',     icon = '💨' },
    { id = 'catalytic_conv',   name = '触媒コンバーター',        icon = '♻' },
    { id = 'transmission_oil', name = 'ミッションオイル',       icon = '🛢' },
    { id = 'clutch',           name = 'クラッチ',               icon = '🦶' },
    { id = 'power_steering',   name = 'パワステフルード',      icon = '🚗' },
    { id = 'wiper_blade',      name = 'ワイパーブレード',        icon = '🌧' },
    { id = 'headlight_bulb',   name = 'ヘッドライトバルブ',     icon = '💡' },
    { id = 'fuse',             name = 'ヒューズ',                icon = '⚡' },
}

-- 出題庫: data/slips_*.lua（config の次に shared_script 読み込み）
