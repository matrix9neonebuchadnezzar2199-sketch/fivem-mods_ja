-- Los-Mon クライアント用設定（fxmanifest では client_scripts で先に読み込み）
-- 全項目に日本語コメント。

Config = {}

-- 起動用チャットコマンド（/ を付けず識別子だけ）
Config.Command = 'losmon'
-- 孵化にかかる秒数（テスト用に短め。本番は運営で調整）
Config.HatchTime = 180
-- 卵→幼体以外の、各成長段階の長さ（秒）
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
-- 成長期→成熟期の照育スコア用: 理想お世話回数 = floor(成長期経過秒 / ここ)（最低1）
Config.IdealCareIntervalSec = 1200
-- 成年系スプライト未用意時に 06 をグレー代用（normal 向け、JS/CSS で指定）

-- 卵の系統（3 種。見た目は 01_egg 系を共通利用し、ラベルで区別）
Config.EggTypes = {
    { id = 'green',  name = '竜の卵',   line = 'dragon' },
    { id = 'cute',   name = '精霊の卵', line = 'spirit' },
    { id = 'navy',   name = '獣の卵',   line = 'beast'  },
}

-- 進化ツリー（系統 → 最終的な各段階のキャラID）
Config.EvolutionTree = {
    dragon = {
        baby     = { id = 'baby_dino',   name = 'ベビードラゴ' },
        childA   = { id = 'child_dino',  name = 'ドラゴキッズ' },
        childB   = { id = 'child_water', name = 'アクアキッズ' },
        adultGood   = { id = 'adult_good_gryphon', name = 'グリフォンLM' },
        adultNormal = { id = 'adult_good_knight',  name = 'ナイトドラゴ' },
        adultBad    = { id = 'adult_bad_beast',   name = 'ダークビースト' },
    },
    spirit = {
        baby     = { id = 'baby_blob',   name = 'プチモン' },
        childA   = { id = 'child_bird',  name = 'ウィングモン' },
        childB   = { id = 'child_dragon',name = 'リトルウィング' },
        adultGood   = { id = 'adult_good_kirin',   name = 'キリンLM' },
        adultNormal = { id = 'adult_good_knight',  name = 'シルバーナイト' },
        adultBad    = { id = 'adult_bad_dark',    name = 'ダークドラゴ' },
    },
    beast = {
        baby     = { id = 'baby_cat',    name = 'ニャンモン' },
        childA   = { id = 'child_spike', name = 'トゲニャン' },
        childB   = { id = 'child_blue',  name = 'ブルーニャン' },
        adultGood   = { id = 'adult_good_gryphon', name = 'ゴールドグリフォン' },
        adultNormal = { id = 'adult_good_knight',  name = 'アーマービースト' },
        adultBad    = { id = 'adult_bad_demon',   name = 'デモンビースト' },
    },
}

-- 図鑑用の分類用 ID 一覧（解放チェック用）
Config.ZukanIds = {
    'baby_dino', 'baby_blob', 'baby_cat',
    'child_dino', 'child_water', 'child_bird', 'child_dragon', 'child_spike', 'child_blue',
    'adult_good_gryphon', 'adult_good_knight', 'adult_good_kirin',
    'adult_bad_beast', 'adult_bad_dark', 'adult_bad_demon',
    'sick', 'grave',
}

-- 実画像: html/img/ の 01_〜10_ 命名。アクション毎
-- idle / eat / happy / sleep — 病気は sick.*、墓は grave.*
Config.Sprites = {
    egg = {
        idle  = '01_egg_idle.png',
        eat   = '01_egg_eating.png',
        happy = '01_egg_happy.png',
        sleep = '01_egg_sleeping.png',
    },
    egg_crack = {
        idle  = '02_egg_crack_idle.png',
        eat   = '02_egg_crack_eating.png',
        happy = '02_egg_crack_happy.png',
        sleep = '02_egg_crack_sleeping.png',
    },
    baby_dino  = { idle = '03_baby_idle.png',  eat = '03_baby_eating.png',  happy = '03_baby_happy.png',  sleep = '03_baby_sleeping.png' },
    baby_blob  = { idle = '03_baby_idle.png',  eat = '03_baby_eating.png',  happy = '03_baby_happy.png',  sleep = '03_baby_sleeping.png' },
    baby_cat   = { idle = '03_baby_idle.png',  eat = '03_baby_eating.png',  happy = '03_baby_happy.png',  sleep = '03_baby_sleeping.png' },
    child_dino  = { idle = '04_child_a_idle.png',  eat = '04_child_a_eating.png',  happy = '04_child_a_happy.png',  sleep = '04_child_a_sleeping.png' },
    child_bird  = { idle = '04_child_a_idle.png',  eat = '04_child_a_eating.png',  happy = '04_child_a_happy.png',  sleep = '04_child_a_sleeping.png' },
    child_spike = { idle = '04_child_a_idle.png',  eat = '04_child_a_eating.png',  happy = '04_child_a_happy.png',  sleep = '04_child_a_sleeping.png' },
    child_water  = { idle = '05_child_b_idle.png',  eat = '05_child_b_eating.png',  happy = '05_child_b_happy.png',  sleep = '05_child_b_sleeping.png' },
    child_dragon = { idle = '05_child_b_idle.png',  eat = '05_child_b_eating.png',  happy = '05_child_b_happy.png',  sleep = '05_child_b_sleeping.png' },
    child_blue  =  { idle = '05_child_b_idle.png',  eat = '05_child_b_eating.png',  happy = '05_child_b_happy.png',  sleep = '05_child_b_sleeping.png' },
    adult_good_gryphon = { idle = '06_adult_good_idle.png',   eat = '06_adult_good_eating.png',  happy = '06_adult_good_happy.png',  sleep = '06_adult_good_sleeping.png' },
    adult_good_kirin  =  { idle = '06_adult_good_idle.png',   eat = '06_adult_good_eating.png',  happy = '06_adult_good_happy.png',  sleep = '06_adult_good_sleeping.png' },
    -- normal 系: 07（仕様: 同系 06 のグレー代用可 → ここでは 07 を割当）
    adult_good_knight  = { idle = '07_adult_normal_idle.png', eat = '07_adult_normal_eating.png', happy = '07_adult_normal_happy.png', sleep = '07_adult_normal_sleeping.png' },
    adult_bad_beast =   { idle = '08_adult_bad_idle.png',  eat = '08_adult_bad_eating.png',  happy = '08_adult_bad_happy.png',  sleep = '08_adult_bad_sleeping.png' },
    adult_bad_dark  =   { idle = '08_adult_bad_idle.png',  eat = '08_adult_bad_eating.png',  happy = '08_adult_bad_happy.png',  sleep = '08_adult_bad_sleeping.png' },
    adult_bad_demon =   { idle = '08_adult_bad_idle.png',  eat = '08_adult_bad_eating.png',  happy = '08_adult_bad_happy.png',  sleep = '08_adult_bad_sleeping.png' },
    -- 病気: resting リソースは 09_sick_resting（必要なら NUI で切替可）
    sick  = { idle = '09_sick_idle.png',  eat = '09_sick_idle.png',  happy = '09_sick_sad.png', sleep = '09_sick_sleeping.png' },
    grave = { idle = '10_grave_idle.png', eat = '10_grave_idle.png', happy = '10_grave_memorial.png', sleep = '10_grave_idle.png' },
}

-- 成長期→成熟の照育スコアしきい値
Config.EvolutionThresholds = {
    good = 80,
    normal = 40,
}

-- 成長期 A / B 分岐は 50% 乱数
Config.ChildBranchRandom = true
