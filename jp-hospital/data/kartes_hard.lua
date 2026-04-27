-- 上級 出題庫（Config.Difficulties の kartesKey = KartesHard。他難易度と独立）
-- answers は config.lua Config.Medicines の id 配列
-- 初級と同じ出題数・中身。運用で専用問題に差し替え可。ファイルは初級と同一 UTF-8（BOM なし）で保存すること

Config.KartesHard = {
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
