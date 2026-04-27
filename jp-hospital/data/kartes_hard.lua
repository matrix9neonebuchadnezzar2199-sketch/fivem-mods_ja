-- 上級 30 問: 合併症・鑑別・在宅/禁忌の読み分け
-- answers は config.lua Config.Medicines の id
-- 各条の行末コメントは出題意図メモ

Config.KartesHard = {
    {
        symptom = '38.9℃の高熱が3日間続く、激しい咳と息切れ、黄緑色の痰、胸の右側が呼吸のたびに痛む、食欲なく2日間ほぼ食べていない',
        diagnosis = '細菌性肺炎＋脱水',
        answers = { 'antibiotic', 'cough_syrup', 'painkiller_iv', 'thermometer', 'saline', 'stomach_med' },
    },
    {
        symptom = '交通事故で右大腿部を打撲、大きな裂傷あり出血中、膝も腫れている、意識はあるが顔面蒼白',
        diagnosis = '大腿部裂傷＋膝打撲＋出血性ショック前段階',
        answers = { 'antiseptic', 'gauze', 'bandage', 'painkiller_iv', 'saline', 'ice_pack' },
    },
    {
        symptom = '全身に蕁麻疹、両目が腫れぼったい、喉の違和感、37.5℃の微熱、昼に食べたエビが原因かもしれない',
        diagnosis = '食物アレルギー（甲殻類）＋軽度アナフィラキシー',
        answers = { 'antihistamine', 'ointment', 'eyedrops', 'thermometer', 'saline' },
    },
    {
        symptom = '69歳女性、3日前から腰が重く昨日から動けない、両足にしびれ、便秘も始まった、以前から貧血気味と言われている',
        diagnosis = '腰部脊柱管狭窄症＋慢性貧血＋便秘',
        answers = { 'painkiller', 'compress_hot', 'ointment', 'iron_tablet', 'vitamin_c', 'laxative' },
    },
    {
        symptom = '発熱39.2℃、全身の関節痛、悪寒と震え、水様性の下痢も始まった、周囲でインフルエンザ流行中',
        diagnosis = 'インフルエンザ＋随伴性胃腸症状',
        answers = { 'cold_powder', 'painkiller', 'antidiarrheal', 'saline', 'thermometer', 'anti_nausea' },
    },
    {
        symptom = '建設現場で足場から落ちた、右足首が明らかに変形、左膝に大きな擦り傷、頭も打ったがたんこぶ程度',
        diagnosis = '右足首骨折＋左膝擦過傷＋頭部打撲',
        answers = { 'cast', 'painkiller_iv', 'bandage', 'antiseptic', 'gauze', 'ice_pack' },
    },
    {
        symptom = '5歳児、40℃の高熱、喉が赤い、耳を痛がる、食事を拒否、ぐったりしている',
        diagnosis = '小児扁桃炎＋中耳炎合併＋脱水の兆候',
        answers = { 'antibiotic', 'ear_drops', 'cold_liquid', 'thermometer', 'saline', 'throat_lozenge' },
    },
    {
        symptom = '糖尿病の持病あり、足の小指の傷が2週間治らない、赤黒く変色、膿が出ている、微熱が続く',
        diagnosis = '糖尿病性足潰瘍＋二次感染',
        answers = { 'antibiotic', 'antiseptic', 'ointment', 'gauze', 'bandage', 'thermometer' },
    },
    {
        symptom = '激しい頭痛、吐き気、光がまぶしい、音に敏感、こめかみがドクドク脈打つ、4時間以上続いている',
        diagnosis = '片頭痛発作',
        answers = { 'painkiller_iv', 'anti_nausea', 'eyedrops', 'sleeping_pill' },
    },
    {
        symptom = '全身の倦怠感、微熱37.4℃が1週間、口内炎が複数、歯茎から出血、あざができやすい',
        diagnosis = '免疫低下（血液疾患の疑い）＋口内症状',
        answers = { 'antibiotic', 'vitamin_c', 'iron_tablet', 'ointment', 'thermometer', 'saline' },
    },
    {
        symptom = '登山中に足を滑らせて斜面を転がった、背中と腕に広範囲の擦り傷、右肩が上がらない、手首も腫れている',
        diagnosis = '多部位外傷（右肩脱臼の疑い＋手首捻挫＋広範囲擦過傷）',
        answers = { 'antiseptic', 'gauze', 'bandage', 'compress_cold', 'painkiller_iv', 'ice_pack' },
    },
    {
        symptom = '38.0℃の発熱、右の耳下腺が腫れて痛い、口が開けにくい、食事の時に特に痛む、周囲で流行あり',
        diagnosis = '流行性耳下腺炎（おたふくかぜ）',
        answers = { 'painkiller', 'ice_pack', 'thermometer', 'anti_nausea', 'saline' },
    },
    {
        symptom = '妊娠中の女性、激しいつわり、1日5回以上嘔吐、水も飲めない、ふらつき、体重減少',
        diagnosis = '妊娠悪阻（重症つわり）',
        answers = { 'anti_nausea', 'saline', 'vitamin_c' },
    },
    {
        symptom = '高齢者、誤って階段から5段落ちた、肋骨付近を打って呼吸すると痛い、腕と膝にも打撲痕、持病に骨粗しょう症あり',
        diagnosis = '肋骨骨折の疑い＋多部位打撲（高齢・骨粗しょう症）',
        answers = { 'painkiller_iv', 'bandage', 'compress_cold', 'ice_pack', 'thermometer', 'gauze' },
    },
    {
        symptom = '39.5℃の高熱、全身の筋肉痛、目の奥が痛い、発疹が手足に出始めた、先週東南アジアから帰国',
        diagnosis = 'デング熱の疑い（渡航感染症）',
        answers = { 'saline', 'thermometer', 'anti_nausea', 'ice_pack', 'vitamin_c' },
    },
    {
        symptom = '80歳男性、朝から右半身が動かない、呂律が回らない、顔の右側が垂れている、発症から2時間経過、高血圧の持病',
        diagnosis = '脳梗塞の疑い（急性期対症療法）',
        answers = { 'saline', 'thermometer', 'painkiller_iv', 'anti_nausea' },
    },
    {
        symptom = '溶接作業後に両目が激痛、涙が止まらない、光が見られない、充血がひどい、6時間前に保護メガネなしで作業',
        diagnosis = '電気性眼炎（雪目・溶接眼）',
        answers = { 'eyedrops', 'painkiller', 'gauze', 'sleeping_pill', 'ice_pack' },
    },
    {
        symptom = '1歳児、38.8℃の高熱、全身に小さな水疱、かゆがって泣いている、食欲がない、保育園で流行中',
        diagnosis = '水痘（みずぼうそう）＋小児脱水リスク',
        answers = { 'ointment', 'antihistamine', 'cold_liquid', 'thermometer', 'saline' },
    },
    {
        symptom = '工場で薬品が顔にかかった、左目と左頬がヒリヒリ、目が開けられない、皮膚が赤くただれている',
        diagnosis = '化学熱傷（顔面・眼）',
        answers = { 'saline', 'eyedrops', 'antiseptic', 'gauze', 'ointment', 'painkiller_iv' },
    },
    {
        symptom = '55歳男性、胸の真ん中が締め付けられる痛み、左肩に放散、冷や汗、吐き気、階段を上った後に発症',
        diagnosis = '急性冠症候群（心筋梗塞の疑い）の対症療法',
        answers = { 'painkiller_iv', 'anti_nausea', 'saline', 'thermometer' },
    },
    {
        symptom = '登山中に標高3000mで激しい頭痛、吐き気、ふらつき、息切れ、手足のむくみ、判断力が鈍い',
        diagnosis = '高山病（急性高地障害）',
        answers = { 'painkiller', 'anti_nausea', 'saline', 'thermometer', 'vitamin_c' },
    },
    {
        symptom = '海水浴中にクラゲに刺された、右腕に赤い線状の腫れ、激痛、吐き気、全身にじんましんが広がりつつある',
        diagnosis = 'クラゲ刺傷＋全身アレルギー反応',
        answers = { 'antiseptic', 'antihistamine', 'ointment', 'painkiller_iv', 'ice_pack', 'saline' },
    },
    {
        symptom = '75歳女性、転倒して起き上がれない、右足を外側に回旋した状態で動かせない、足の付け根に激痛、骨粗しょう症の既往',
        diagnosis = '大腿骨頸部骨折',
        answers = { 'painkiller_iv', 'bandage', 'ice_pack', 'saline', 'thermometer' },
    },
    {
        symptom = '30歳女性、突然の右下腹部痛、38.2℃の発熱、吐き気、歩くと響く、昨日から食欲がなく何も食べていない',
        diagnosis = '急性虫垂炎の疑い＋脱水',
        answers = { 'painkiller_iv', 'anti_nausea', 'saline', 'thermometer', 'antibiotic' },
    },
    {
        symptom = '60歳男性、痛風の既往、今朝から右足親指の付け根が真っ赤に腫れ上がって触れないほど痛い、微熱、尿が濃い',
        diagnosis = '痛風発作＋軽度脱水',
        answers = { 'painkiller_iv', 'ice_pack', 'saline', 'compress_cold', 'thermometer' },
    },
    {
        symptom = '40歳男性、2日前から右目が赤い、まぶたが腫れて開きにくい、黄色い目やに、左目にも広がりつつある、家族も同症状',
        diagnosis = '細菌性結膜炎（伝染性）',
        answers = { 'eyedrops', 'antibiotic', 'antiseptic', 'gauze', 'thermometer' },
    },
    {
        symptom = '生後8ヶ月の乳児、39.5℃の高熱が3日続いた後に解熱、解熱と同時に全身にピンク色の発疹、機嫌は回復、食欲あり',
        diagnosis = '突発性発疹（解熱後の発疹期）',
        answers = { 'thermometer', 'saline', 'cold_liquid' },
    },
    {
        symptom = '25歳女性、激しい腹痛で救急搬送、右肩にも痛みがある、最終月経から6週間、少量の不正出血、顔面蒼白、血圧低下',
        diagnosis = '子宮外妊娠破裂の疑い（対症療法）',
        answers = { 'painkiller_iv', 'saline', 'thermometer', 'gauze' },
    },
    {
        symptom = '45歳男性、夜中に突然右わき腹に激痛、背中に放散、じっとしていられない、血尿、吐き気、家族に腎臓結石の人がいる',
        diagnosis = '尿管結石（腎疝痛）',
        answers = { 'painkiller_iv', 'anti_nausea', 'saline', 'thermometer' },
    },
    {
        symptom = '70歳男性、糖尿病＋高血圧の持病、3日前にすねをぶつけた傷が化膿、赤く腫れて広がっている、38.5℃の発熱、傷の周囲に赤い線が走っている',
        diagnosis = '蜂窩織炎（重症感染＋糖尿病合併）',
        answers = { 'antibiotic', 'antiseptic', 'gauze', 'bandage', 'painkiller_iv', 'thermometer' },
    },
}
