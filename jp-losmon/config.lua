-- Los-Mon クライアント用設定（fxmanifest では client_scripts で先に読み込み）
-- 全項目に日本語コメント。

Config = {}

-- 起動用チャットコマンド（/ を付けず識別子だけ）
Config.Command = 'losmon'
-- 新規: 常に卵1種からスタート。孵化までの秒数（30分=1800）
Config.HatchTime = 1800
-- 孵化直前、殻割れ画に切替える残り秒数（NUI 比較用）
Config.EggShowCrackSec = 30
-- 新規: 拡大画面で表示するペットの通称
Config.DefaultPetName = 'ぼく'
-- 卵→幼体以降、各成長段階の長さ（秒）
Config.GrowthInterval = 14400
-- 1 分あたり各ステータスが減少する量（%ポイント。オンライン中のみ tickOnline で適用）
Config.StatDecayRate = 0.07
-- この空腹 % 以下で病気
Config.SickThreshold = 10
-- 病気から死亡まで（秒）放置可能時間
Config.DeathTime = 14400
-- 各アクションのクールダウン（秒）
Config.FeedCooldown = 30
Config.PlayCooldown = 60
Config.SleepCooldown = 120
Config.CleanCooldown = 60
-- ミニ常駐の初期表示位置（画面 0〜1）
Config.MiniPosDefault = { x = 0.12, y = 0.88 }

-- ===== 成熟期への抽選 =====
-- 抽選周期（秒）。オンライン累積でこの間隔ごとに1回抽選
Config.AdultLotteryIntervalSec = 3600
-- 1回の抽選で adult に進化する確率（%）
Config.AdultLotteryChancePercent = 10
-- 抽選資格: 最低レベル
Config.AdultLotteryMinLevel = 5
-- 抽選資格: 最低歩数
Config.AdultLotteryMinSteps = 1000
-- 抽選資格: child フェーズ最低滞在秒
Config.AdultLotteryMinChildSec = 1800

-- ===== 成熟期の系統重み（合計値で正規化）=====
Config.AdultFormWeights = {
    adult_a = 30,
    adult_b = 30,
    adult_c = 30,
    adult_d = 10,
}

-- ===== オフライン時の挙動 =====
-- これ秒数以上更新がなければ「離席」として時間累積しない
Config.OfflineThresholdSec = 120

-- ===== 病気復帰条件 =====
-- 復帰には hunger > SickThreshold かつ clean >= SickCleanThreshold が必要
Config.SickCleanThreshold = 50

-- ===== デバッグモード =====
Config.Debug = false
if Config.Debug then
    Config.HatchTime = 60
    Config.GrowthInterval = 120
    Config.AdultLotteryIntervalSec = 30
    Config.AdultLotteryMinChildSec = 30
    Config.AdultLotteryMinLevel = 1
    Config.AdultLotteryMinSteps = 0
    Config.StatDecayRate = 1.0
    Config.DeathTime = 180
end

-- レベル（EXP）: 合計 EXP から L = min(LevelMax, floor((1+sqrt(1+8*E/ExpBasePer100))/2))。LV1 の領域は 0 〜 未満 ExpBasePer100
-- レベル L へ到達に必要な累計 EXP（開始時点）: ExpBasePer100 * (L-1) * L / 2
Config.LevelMax = 999
-- 上式の 100 相当。変えると同じ EXP でも到達 L が変わる
Config.ExpBasePer100 = 100.0
-- 歩行（歩道・地上）1m あたり得る EXP（0 にすると歩行分なし）
Config.ExpPerMeterOnFoot = 0.12
-- 乗用車両同乗中 1m 走行あたり EXP（0 に車両分はなし）。運転席・同乗者とも距離分を加算
Config.ExpPerMeterInVehicle = 0.04
-- 歩行距離表示用: 1歩 ≒ 何 m とみなすか（EXP ではなく純粋表示向け。例: 0.75m/歩）
Config.MetersPerStepDisplay = 0.75
-- 1 秒で移動距離に換算しすぎない上限（m）。テレポート等の取りこぼし用
Config.ExpMaxDistancePerTick = 45.0
-- ペット名の最大文字数（NUI 入力の maxlength と一致させる）
Config.PetNameMaxLength = 12
-- NUI: 横4コマ1枚のスプライト（512×128 等）。1ポーズ1ファイルのときは 1
Config.SpriteStripFrames = 4
-- 卵・幼体・成長等と同じく横4コマ1枚。殻割れ `01_egg_crack` も同形式推奨
Config.EggSpriteStripFrames = 4
-- 旅立ち（05_d 単一画）のみ 1
Config.GraveSpriteStripFrames = 1
-- 旧仕様。未使用（互換用に残置）
Config.EvolutionTree = { default = {} }
-- 図鑑 ID
Config.ZukanIds = { 'baby', 'child', 'adult_a', 'adult_b', 'adult_c', 'adult_d', 'sick', 'grave' }
-- 画面・図鑑用の系統名（通称 / 名前差は通称。フォーム名は evName 側）
Config.FormNames = {
    egg     = '卵',
    baby    = '幼年期',
    child   = '成長期',
    adult_a = '成熟期A',
    adult_b = '成熟期B',
    adult_c = '成熟期C',
    adult_d = '成熟期D（レア）',
    sick    = '病気',
    grave   = '旅立ち',
}
-- 実画像: html/img/ 下のサブフォルダ
-- キー: idle=1通常 play=2遊び eat=3食事 sleep=4寝。happy は病気用フォールバック用に idle を想定
Config.Sprites = {
    egg = {
        idle  = '01_egg/01_egg_sleeping.png',
        eat   = '01_egg/01_egg_sleeping.png',
        happy = '01_egg/01_egg_sleeping.png',
        sleep = '01_egg/01_egg_sleeping.png',
    },
    egg_crack = {
        idle  = '01_egg/01_egg_crack.png',
        eat   = '01_egg/01_egg_crack.png',
        happy = '01_egg/01_egg_crack.png',
        sleep = '01_egg/01_egg_crack.png',
    },
    baby  = { idle  = '02_baby/02_baby_a-1.png', play  = '02_baby/02_baby_a-2.png', eat  = '02_baby/02_baby_a-3.png', sleep  = '02_baby/02_baby_a-4.png', happy  = '02_baby/02_baby_a-1.png', clean  = '02_baby/02_baby_a-1.png' },
    child = { idle  = '03_child/03_child_a-1.png', play  = '03_child/03_child_a-2.png', eat  = '03_child/03_child_a-3.png', sleep  = '03_child/03_child_a-4.png', happy  = '03_child/03_child_a-1.png', clean  = '03_child/03_child_a-1.png' },
    adult_a = { idle  = '04_adult/04_adult_a-1.png', play  = '04_adult/04_adult_a-2.png', eat  = '04_adult/04_adult_a-3.png', sleep  = '04_adult/04_adult_a-4.png', happy  = '04_adult/04_adult_a-1.png', clean  = '04_adult/04_adult_a-1.png' },
    adult_b = { idle  = '04_adult/04_adult_b-1.png', play  = '04_adult/04_adult_b-2.png', eat  = '04_adult/04_adult_b-3.png', sleep  = '04_adult/04_adult_b-4.png', happy  = '04_adult/04_adult_b-1.png', clean  = '04_adult/04_adult_b-1.png' },
    adult_c = { idle  = '04_adult/04_adult_c-1.png', play  = '04_adult/04_adult_c-2.png', eat  = '04_adult/04_adult_c-3.png', sleep  = '04_adult/04_adult_c-4.png', happy  = '04_adult/04_adult_c-1.png', clean  = '04_adult/04_adult_c-1.png' },
    adult_d = { idle  = '04_adult/04_adult_d-1.png', play  = '04_adult/04_adult_d-2.png', eat  = '04_adult/04_adult_d-3.png', sleep  = '04_adult/04_adult_d-4.png', happy  = '04_adult/04_adult_d-1.png', clean  = '04_adult/04_adult_d-1.png' },
    sick  = { idle = '09_sick_idle.png',  eat = '09_sick_idle.png',  happy = '09_sick_sad.png', sleep = '09_sick_sleeping.png' },
    -- 死亡：単一画（NUI は idle 基準。playAction 等で同画を出す）
    grave = { idle = '05_d/05_d.png', eat = '05_d/05_d.png', happy = '05_d/05_d.png', sleep = '05_d/05_d.png' },
}
-- NUI ティッカー: 次の孵化/進化が近いと表示
Config.TickerNearHatchMaxSec = 90
Config.TickerNearPhaseMaxSec = 600
