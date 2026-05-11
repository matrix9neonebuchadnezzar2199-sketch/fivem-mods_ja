Config = Config or {}
Config.Specializations = Config.Specializations or {}

-- 西欧料理（最初に実装する専門職）
-- ノードは極座標（angle / radius）。依存は requires。
Config.Specializations.western = {
    id = 'western',
    label = '西欧料理',
    icon = { type = 'emoji', value = '🍳' },
    color = '#d4823a',
    description = '西欧の伝統料理を学ぶ修行の道',
    nodes = {
        root = {
            angle = 270, radius = 120, lv = 1,
            label = '特製オムライス',
            icon = { type = 'emoji', value = '🍳' },
            recipe = 'omurice_special',
            requires = {},
        },
        soup_basic = {
            angle = 315, radius = 200, lv = 5,
            label = 'オニオングラタンスープ',
            icon = { type = 'emoji', value = '🍲' },
            recipe = 'onion_gratin_soup',
            requires = { 'root' },
        },
        salad_basic = {
            angle = 225, radius = 200, lv = 8,
            label = 'シーザーサラダ',
            icon = { type = 'emoji', value = '🥗' },
            recipe = 'caesar_salad',
            requires = { 'root' },
        },
        pasta_basic = {
            angle = 345, radius = 280, lv = 12,
            label = 'カルボナーラ',
            icon = { type = 'emoji', value = '🍝' },
            recipe = 'carbonara',
            requires = { 'soup_basic' },
        },
        risotto = {
            angle = 195, radius = 280, lv = 15,
            label = 'きのこリゾット',
            icon = { type = 'emoji', value = '🍚' },
            recipe = 'mushroom_risotto',
            requires = { 'salad_basic' },
        },
        steakhouse = {
            angle = 30, radius = 280, lv = 20,
            label = '熟成ハラミステーキ',
            icon = { type = 'emoji', value = '🥩' },
            recipe = 'harami_aged',
            requires = { 'pasta_basic' },
        },
        foie_gras = {
            angle = 60, radius = 360, lv = 30,
            label = 'フォアグラのポワレ',
            icon = { type = 'emoji', value = '🦆' },
            recipe = 'foie_gras',
            requires = { 'steakhouse' },
        },
        bouillabaisse = {
            angle = 165, radius = 360, lv = 35,
            label = 'ブイヤベース',
            icon = { type = 'emoji', value = '🐟' },
            recipe = 'bouillabaisse',
            requires = { 'risotto' },
        },
        truffle_pasta = {
            angle = 300, radius = 360, lv = 40,
            label = '黒トリュフのタヤリン',
            icon = { type = 'emoji', value = '🍄' },
            recipe = 'truffle_tagliolini',
            requires = { 'pasta_basic' },
        },
        caviar_master = {
            angle = 130, radius = 440, lv = 50,
            label = '幻のキャビア丼',
            icon = { type = 'emoji', value = '🍣' },
            recipe = 'caviar_phantom',
            requires = { 'bouillabaisse', 'foie_gras' },
        },
    },
}
