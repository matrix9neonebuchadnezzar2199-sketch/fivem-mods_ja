Config = Config or {}
Config.Specializations = Config.Specializations or {}

-- 中華料理（プレースホルダ 3 ノード）
Config.Specializations.chinese = {
    id = 'chinese',
    label = '中華料理',
    icon = { type = 'emoji', value = '🥢' },
    color = '#c0392b',
    description = '中華の奥義を極める道',
    nodes = {
        root = {
            angle = 270, radius = 120, lv = 1,
            label = '玉子炒飯',
            icon = { type = 'emoji', value = '🍳' },
            recipe = 'egg_fried_rice',
            requires = {},
        },
        mapo = {
            angle = 30, radius = 280, lv = 15,
            label = '麻婆豆腐',
            icon = { type = 'emoji', value = '🌶️' },
            recipe = 'mapo_tofu',
            requires = { 'root' },
        },
        peking = {
            angle = 150, radius = 440, lv = 40,
            label = '北京ダック',
            icon = { type = 'emoji', value = '🦆' },
            recipe = 'peking_duck',
            requires = { 'mapo' },
        },
    },
}
