-- jp-hospital 共有設定（NUI からは参照しない。運営は此処のみ触る想定）
Config = {}

-- 1カルテクリアあたりの基礎報酬（倍率前・難易度未指定時のフォールバック）
Config.RewardPerKarte = 300

-- 連続正解数に応じた掛け率（1～5段目。6連目以降は max と同扱い）
Config.ComboMultiplier = { 1.0, 1.2, 1.5, 1.8, 2.0 }
-- 倍率配列の上限（コンボ N に対し math.min(N, Config.MaxCombo) 番目を使用）
Config.MaxCombo = 5
-- 不正解時にコンボを0に戻す
Config.ComboResetOnFail = true

-- 就業用 NPC（ピルボックス病院前・座標はゲーム内で調整可）
Config.JobPedModel = 's_m_m_doctor_01'
Config.JobPedCoords = vector4(299.59, -579.26, 43.26, 112.28)
Config.JobPedScenario = 'WORLD_HUMAN_CLIPBOARD'
Config.InteractRadius = 2.0
-- 退勤・NUI 終了用チャットコマンド
Config.ExitCommand = 'hospital'
-- 右のダミー数（難易度未設定時のフォールバック。通常は Config.Difficulties の decoyCount）
Config.DecoyCount = 20
-- サーバーセッション有効秒（カルテ完了前に放置した場合の古い正解捨て）
Config.SessionTtlSec = 600
-- 報酬付与 reason（QBCore 等の付箋用）
Config.MoneyReason = 'jp-hospital-karte'
-- デバッグログ
Config.Debug = false

-- 難易度（kartesKey は Config 上のテーブル名。出題内容は data/kartes_*.lua）
Config.Difficulties = {
    {
        id = 'easy',
        label = '初級 ⭐',
        description = '基本的な症状と薬の組み合わせ（正解 1〜4 個前後）',
        kartesKey = 'Kartes',
        rewardBase = 300,
        decoyCount = 20,
        timeLimit = 0,
    },
    {
        id = 'medium',
        label = '中級 ⭐⭐',
        description = '似た薬の判別が必要（正解 3〜5 個前後）',
        kartesKey = 'KartesMedium',
        rewardBase = 500,
        decoyCount = 22,
        timeLimit = 0,
    },
    {
        id = 'hard',
        label = '上級 ⭐⭐⭐',
        description = '合併症・禁忌の読み分け（正解 3〜6 個前後）',
        kartesKey = 'KartesHard',
        rewardBase = 800,
        decoyCount = 25,
        timeLimit = 0,
    },
}

-- 薬マスタ（30 種：id は一意）
Config.Medicines = {
    { id = 'cold_tablet',     name = '風邪薬（錠剤）',   icon = '💊' },
    { id = 'cold_liquid',     name = '風邪薬（シロップ）', icon = '🧴' },
    { id = 'cold_powder',     name = '風邪薬（粉薬）',   icon = '📦' },
    { id = 'painkiller',      name = '痛み止め（錠剤）',  icon = '💊' },
    { id = 'painkiller_iv',   name = '痛み止め（点滴）',  icon = '💉' },
    { id = 'compress_cold',   name = '湿布（冷感）',     icon = '🩹' },
    { id = 'compress_hot',    name = '湿布（温感）',     icon = '🩹' },
    { id = 'cast',            name = 'ギプス',          icon = '🦴' },
    { id = 'bandage',         name = '包帯',            icon = '🩹' },
    { id = 'gauze',           name = 'ガーゼ',          icon = '🏥' },
    { id = 'eyedrops',        name = '目薬',            icon = '👁' },
    { id = 'bandaid',         name = '絆創膏',          icon = '🩹' },
    { id = 'cough_syrup',     name = '咳止めシロップ',   icon = '🧴' },
    { id = 'cough_tablet',    name = '咳止め（錠剤）',   icon = '💊' },
    { id = 'stomach_med',     name = '胃腸薬',          icon = '💊' },
    { id = 'antidiarrheal',   name = '下痢止め',         icon = '💊' },
    { id = 'laxative',        name = '便秘薬',          icon = '💊' },
    { id = 'antibiotic',      name = '抗生物質',         icon = '💊' },
    { id = 'antihistamine',   name = '抗ヒスタミン薬',   icon = '💊' },
    { id = 'ointment',        name = '塗り薬（軟膏）',   icon = '🧴' },
    { id = 'antiseptic',      name = '消毒液',          icon = '🧪' },
    { id = 'thermometer',     name = '体温計',          icon = '🌡' },
    { id = 'ice_pack',        name = 'アイスパック',     icon = '🧊' },
    { id = 'saline',          name = '生理食塩水',       icon = '💧' },
    { id = 'vitamin_c',       name = 'ビタミンC剤',     icon = '🍊' },
    { id = 'iron_tablet',     name = '鉄剤',            icon = '💊' },
    { id = 'sleeping_pill',   name = '睡眠導入剤',       icon = '😴' },
    { id = 'anti_nausea',     name = '吐き気止め',       icon = '💊' },
    { id = 'ear_drops',       name = '点耳薬',          icon = '👂' },
    { id = 'throat_lozenge',  name = 'のど飴（医療用）',  icon = '🍬' },
}

-- 症状カルテ出題: data/kartes_easy.lua / kartes_medium.lua / kartes_hard.lua
--（fxmanifest で config.lua の直後に shared_script する。answers は上記 Medicines の id 配列）
