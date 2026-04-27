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
-- 1 分あたり各ステータスが減少する量（%ポイント）
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
-- 照育: 幼年期→成長期の分岐。理想回数 = floor(経過秒/ここ)。回数比で 50% 超なら成長期（良）
Config.IdealCareIntervalSec = 1200
Config.ChildToGoodChildThreshold = 50
-- 幼年期の後半から成熟期へ。レアDの出現率（%）残り 90% は a/b/c を均等
Config.AdultRarePercent = 10
-- NUI: 横4コマ1枚のスプライト（512×128 等）。1ポーズ1ファイルのときは 1
Config.SpriteStripFrames = 4
-- 卵・幼体・成長等と同じく横4コマ1枚。殻割れ `01_egg_crack` も同形式推奨
Config.EggSpriteStripFrames = 4
-- 旅立ち（05_d 単一画）のみ 1
Config.GraveSpriteStripFrames = 1
-- 旧仕様。未使用（互換用に残置）
Config.EvolutionTree = { default = {} }
-- 図鑑 ID（新フォーム）
Config.ZukanIds = {
    'baby_a', 'baby_b', 'child_a', 'child_b', 'adult_a', 'adult_b', 'adult_c', 'adult_d', 'sick', 'grave',
}
-- 画面・図鑑用の系統名（通称 / 名前差は通称。フォーム名は evName 側）
Config.FormNames = {
    egg     = '卵',
    baby_a  = '幼年A',
    baby_b  = '幼年B',
    child_a = '成長期（良）',
    child_b = '成長期（悪）',
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
    baby_a  = { idle  = '02_baby/02_baby_a-1.png', play  = '02_baby/02_baby_a-2.png', eat  = '02_baby/02_baby_a-3.png', sleep  = '02_baby/02_baby_a-4.png', happy  = '02_baby/02_baby_a-1.png', clean  = '02_baby/02_baby_a-1.png' },
    baby_b  = { idle  = '02_baby/02_baby_b-1.png', play  = '02_baby/02_baby_b-2.png', eat  = '02_baby/02_baby_b-3.png', sleep  = '02_baby/02_baby_b-4.png', happy  = '02_baby/02_baby_b-1.png', clean  = '02_baby/02_baby_b-1.png' },
    child_a = { idle  = '03_child/03_child_a-1.png', play  = '03_child/03_child_a-2.png', eat  = '03_child/03_child_a-3.png', sleep  = '03_child/03_child_a-4.png', happy  = '03_child/03_child_a-1.png', clean  = '03_child/03_child_a-1.png' },
    child_b = { idle  = '03_child/03_child_b-1.png', play  = '03_child/03_child_b-2.png', eat  = '03_child/03_child_b-3.png', sleep  = '03_child/03_child_b-4.png', happy  = '03_child/03_child_b-1.png', clean  = '03_child/03_child_b-1.png' },
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
