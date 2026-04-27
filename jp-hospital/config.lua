-- jp-hospital 共有設定（NUI からは参照しない。運営は此処のみ触る想定）
Config = {}

-- 1カルテクリアあたりの基礎報酬（現金・倍率前）
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
-- 右のチェックリストに混ぜる「正解に含まれない薬」ダミー数
Config.DecoyCount = 20
-- サーバーセッション有効秒（カルテ完了前に放置した場合の古い正解捨て）
Config.SessionTtlSec = 600
-- 報酬付与 reason（QBCore 等の付箋用）
Config.MoneyReason = 'jp-hospital-karte'
-- デバッグログ
Config.Debug = false

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

-- 症状カルテ（20 通り以上。answers は上記 id の配列＝正解の集合）
Config.Kartes = {
    {
        symptom = '38.5℃の発熱、喉の痛み、鼻水、くしゃみ',
        diagnosis = '風邪（上気道感染症）',
        answers = { 'cold_tablet', 'throat_lozenge', 'thermometer' },
    },
    {
        symptom = '激しい咳が3日続く、痰が絡む、微熱',
        diagnosis = '気管支炎の疑い',
        answers = { 'cough_syrup', 'antibiotic', 'thermometer' },
    },
    {
        symptom = '右足首を捻った、腫れている、歩くと痛い',
        diagnosis = '足首捻挫',
        answers = { 'compress_cold', 'bandage', 'painkiller' },
    },
    {
        symptom = '目が充血、かゆみ、涙が止まらない',
        diagnosis = 'アレルギー性結膜炎',
        answers = { 'eyedrops', 'antihistamine' },
    },
    {
        symptom = '腹痛、下痢が続く、食欲不振',
        diagnosis = '急性胃腸炎',
        answers = { 'stomach_med', 'antidiarrheal', 'saline' },
    },
    {
        symptom = '料理中に指を包丁で切った、出血あり',
        diagnosis = '切り傷（裂傷）',
        answers = { 'antiseptic', 'gauze', 'bandaid' },
    },
    {
        symptom = '頭痛、肩こり、目の疲れ',
        diagnosis = '緊張型頭痛',
        answers = { 'painkiller', 'compress_hot', 'eyedrops' },
    },
    {
        symptom = '39℃の高熱、関節痛、全身倦怠感、悪寒',
        diagnosis = 'インフルエンザの疑い',
        answers = { 'cold_powder', 'painkiller', 'thermometer', 'saline' },
    },
    {
        symptom = '転倒して膝を擦りむいた、砂利が入っている',
        diagnosis = '擦過傷（すり傷）',
        answers = { 'antiseptic', 'gauze', 'bandage', 'bandaid' },
    },
    {
        symptom = '胃がむかむかする、食後に吐き気、胸やけ',
        diagnosis = '逆流性食道炎の疑い',
        answers = { 'stomach_med', 'anti_nausea' },
    },
    {
        symptom = '腕の骨折（レントゲンで確認済み）、激しい痛み',
        diagnosis = '上腕骨折',
        answers = { 'cast', 'painkiller_iv', 'bandage' },
    },
    {
        symptom = '耳が痛い、耳だれ、聞こえにくい',
        diagnosis = '中耳炎',
        answers = { 'ear_drops', 'antibiotic', 'painkiller' },
    },
    {
        symptom = '便秘が1週間続く、お腹が張る',
        diagnosis = '慢性便秘',
        answers = { 'laxative', 'stomach_med' },
    },
    {
        symptom = '虫に刺された、赤く腫れている、かゆい',
        diagnosis = '虫刺され（虫刺症）',
        answers = { 'ointment', 'antihistamine', 'ice_pack' },
    },
    {
        symptom = '鼻水、くしゃみが止まらない、目もかゆい（春先）',
        diagnosis = '花粉症（季節性アレルギー性鼻炎）',
        answers = { 'antihistamine', 'eyedrops', 'throat_lozenge' },
    },
    {
        symptom = '38℃の熱、喉が赤く腫れている、扁桃腺が白い',
        diagnosis = '扁桃炎',
        answers = { 'antibiotic', 'painkiller', 'throat_lozenge', 'thermometer' },
    },
    {
        symptom = 'やけどで皮膚が赤くなっている、水ぶくれ',
        diagnosis = 'Ⅱ度熱傷',
        answers = { 'antiseptic', 'ointment', 'gauze', 'bandage' },
    },
    {
        symptom = '立ちくらみ、顔色が悪い、疲れやすい',
        diagnosis = '鉄欠乏性貧血',
        answers = { 'iron_tablet', 'vitamin_c' },
    },
    {
        symptom = '眠れない日が続く、日中の倦怠感',
        diagnosis = '不眠症',
        answers = { 'sleeping_pill' },
    },
    {
        symptom = '腰が重い、前かがみで痛む、朝起きるとつらい',
        diagnosis = '腰痛症',
        answers = { 'compress_hot', 'painkiller', 'ointment' },
    },
    {
        symptom = '高熱、咳、痰、息苦しい、胸が痛い',
        diagnosis = '肺炎の疑い',
        answers = { 'antibiotic', 'cough_tablet', 'painkiller_iv', 'thermometer' },
    },
    {
        symptom = '子供が転んで額を打った、たんこぶ、軽い出血',
        diagnosis = '頭部打撲＋小切傷',
        answers = { 'ice_pack', 'antiseptic', 'gauze', 'bandaid' },
    },
}
