-- 中級 30 問: 剤形・近い薬の判別、やや具体的な経過
-- answers は config.lua Config.Medicines の id

Config.KartesMedium = {
    {
        symptom = '37.8℃の微熱、黄色い痰が出る咳、喉の痛みは軽い、鼻は詰まっていないが倦怠感がある',
        diagnosis = '急性気管支炎（細菌性の疑い）',
        answers = { 'antibiotic', 'cough_tablet', 'painkiller', 'thermometer' },
    },
    {
        symptom = '右膝を強打して腫れている、曲げると激痛、歩行は可能だが不安定',
        diagnosis = '膝関節打撲＋靭帯損傷の疑い',
        answers = { 'compress_cold', 'bandage', 'painkiller', 'ice_pack' },
    },
    {
        symptom = '両目が充血してかゆい、鼻水とくしゃみが止まらない、喉もイガイガする（春先）',
        diagnosis = '重度の花粉症（眼・鼻・咽頭症状）',
        answers = { 'eyedrops', 'antihistamine', 'throat_lozenge', 'cold_powder' },
    },
    {
        symptom = '腹痛と水様性の下痢が1日10回以上、嘔吐もあり、口が渇いている',
        diagnosis = '急性胃腸炎（脱水の兆候あり）',
        answers = { 'antidiarrheal', 'anti_nausea', 'saline', 'stomach_med', 'thermometer' },
    },
    {
        symptom = '調理中に手のひらに熱湯がかかった、広範囲に赤くなり一部水ぶくれ、痛みが強い',
        diagnosis = 'Ⅱ度熱傷（広範囲）',
        answers = { 'antiseptic', 'ointment', 'gauze', 'bandage', 'painkiller' },
    },
    {
        symptom = '朝起きたら首が回らない、左側に激痛、肩まで痛みが広がっている',
        diagnosis = '急性頸部痛（寝違え）',
        answers = { 'compress_hot', 'painkiller', 'ointment' },
    },
    {
        symptom = '子供が公園で転んで両膝と両手を擦りむいた、砂が入っている、泣いている',
        diagnosis = '多部位擦過傷（小児）',
        answers = { 'antiseptic', 'gauze', 'bandaid', 'bandage', 'ice_pack' },
    },
    {
        symptom = '38.2℃の発熱、耳の奥がズキズキ痛い、耳だれはないが聞こえにくい、頭痛もある',
        diagnosis = '急性中耳炎＋随伴頭痛',
        answers = { 'ear_drops', 'antibiotic', 'painkiller', 'thermometer' },
    },
    {
        symptom = '3日間便が出ない、お腹が張って食欲がない、ガスも溜まっている感じ',
        diagnosis = '急性便秘＋腹部膨満',
        answers = { 'laxative', 'stomach_med', 'anti_nausea' },
    },
    {
        symptom = '顔色が青白い、立ちくらみが頻繁、爪が割れやすい、氷を異常に食べたがる',
        diagnosis = '重度鉄欠乏性貧血',
        answers = { 'iron_tablet', 'vitamin_c', 'stomach_med' },
    },
    {
        symptom = '腰から右足にかけてしびれるような痛み、長時間座ると悪化、咳やくしゃみで響く',
        diagnosis = '坐骨神経痛（椎間板ヘルニアの疑い）',
        answers = { 'painkiller', 'compress_hot', 'ointment', 'painkiller_iv' },
    },
    {
        symptom = '蜂に刺された、刺された箇所が赤く大きく腫れて熱を持っている、全身のじんましんはない',
        diagnosis = '蜂刺傷（局所反応）',
        answers = { 'antiseptic', 'ointment', 'antihistamine', 'ice_pack', 'painkiller' },
    },
    {
        symptom = '2週間以上眠れない、寝ても途中で何度も起きる、日中の集中力低下、頭痛',
        diagnosis = '慢性不眠症＋緊張型頭痛',
        answers = { 'sleeping_pill', 'painkiller', 'vitamin_c' },
    },
    {
        symptom = '喉が真っ赤で白い膿がついている、39℃の高熱、首のリンパ節が腫れて痛い',
        diagnosis = '急性扁桃周囲膿瘍の疑い',
        answers = { 'antibiotic', 'painkiller_iv', 'throat_lozenge', 'thermometer', 'saline' },
    },
    {
        symptom = '自転車で転倒、左腕に強い痛みと変形がある、指は動くが腫れがひどい',
        diagnosis = '前腕骨折の疑い',
        answers = { 'cast', 'painkiller_iv', 'bandage', 'ice_pack' },
    },
    {
        symptom = '38.0℃の発熱、咳と鼻水に加えて目やにが多い、首の後ろに小さい発疹が出始めた',
        diagnosis = '麻疹（はしか）の疑い',
        answers = { 'cold_liquid', 'eyedrops', 'thermometer', 'saline', 'painkiller' },
    },
    {
        symptom = 'ジョギング中に右アキレス腱付近にブチッと音がした、踵を着けない、後ろを蹴られたような感覚',
        diagnosis = 'アキレス腱断裂の疑い',
        answers = { 'cast', 'painkiller_iv', 'ice_pack', 'bandage' },
    },
    {
        symptom = '指に魚の骨が刺さった、自分で抜いたが先端が折れて残っている、赤くなってきた',
        diagnosis = '異物残留＋感染初期',
        answers = { 'antiseptic', 'antibiotic', 'gauze', 'bandaid', 'ointment' },
    },
    {
        symptom = '朝から激しいめまい、天井がぐるぐる回る、吐き気、耳鳴り、立っていられない',
        diagnosis = '良性発作性頭位めまい症＋随伴嘔気',
        answers = { 'anti_nausea', 'saline', 'sleeping_pill' },
    },
    {
        symptom = '屋外作業中に大量の汗、37.5℃、頭がボーッとする、筋肉がピクピクする、口が渇く',
        diagnosis = '熱中症（中等度）',
        answers = { 'saline', 'ice_pack', 'thermometer', 'vitamin_c' },
    },
    {
        symptom = '犬に手を噛まれた、深い歯形で出血あり、手が腫れ始めている',
        diagnosis = '動物咬傷＋感染リスク',
        answers = { 'antiseptic', 'antibiotic', 'gauze', 'bandage', 'painkiller' },
    },
    {
        symptom = '長時間のデスクワーク後に右手首がしびれる、親指～中指にかけてピリピリする、夜間に悪化',
        diagnosis = '手根管症候群',
        answers = { 'compress_cold', 'painkiller', 'bandage', 'ointment' },
    },
    {
        symptom = '食後30分で顔が赤くなった、唇が腫れている、腹痛もある、蕎麦を食べた',
        diagnosis = '食物アレルギー（蕎麦）',
        answers = { 'antihistamine', 'anti_nausea', 'stomach_med', 'saline' },
    },
    {
        symptom = '草むらで作業後、すねに赤い線状の発疹、強いかゆみ、翌日に水疱ができた',
        diagnosis = '植物性接触皮膚炎（かぶれ）',
        answers = { 'ointment', 'antihistamine', 'gauze', 'antiseptic' },
    },
    {
        symptom = 'スポーツ中に相手と衝突、鼻から出血が止まらない、鼻が曲がっている気がする',
        diagnosis = '鼻骨骨折の疑い＋鼻出血',
        answers = { 'gauze', 'ice_pack', 'painkiller_iv', 'bandage' },
    },
    {
        symptom = '37.2℃の微熱が2週間続く、夜に寝汗、体重が減った、咳は軽いが痰に血が混じる',
        diagnosis = '肺結核の疑い',
        answers = { 'antibiotic', 'cough_syrup', 'thermometer', 'saline', 'vitamin_c' },
    },
    {
        symptom = '尿の回数が増えた、排尿時にしみる痛み、残尿感、下腹部が重い',
        diagnosis = '膀胱炎',
        answers = { 'antibiotic', 'painkiller', 'saline' },
    },
    {
        symptom = '重い物を持ち上げた瞬間に腰にギクッと激痛、前かがみで固まった、立ち上がれない',
        diagnosis = 'ぎっくり腰（急性腰痛症）',
        answers = { 'painkiller_iv', 'compress_cold', 'ice_pack', 'ointment' },
    },
    {
        symptom = '38.5℃、右頬が腫れて痛い、口を大きく開けられない、食事のたびに痛みが増す',
        diagnosis = '急性耳下腺炎（細菌性）',
        answers = { 'antibiotic', 'painkiller', 'ice_pack', 'thermometer', 'anti_nausea' },
    },
    {
        symptom = '子供がクレヨンを鼻に入れた、片方の鼻だけ詰まっている、黄色い鼻水、嫌な臭い',
        diagnosis = '鼻腔内異物＋二次感染',
        answers = { 'antibiotic', 'antiseptic', 'gauze', 'thermometer' },
    },
}
