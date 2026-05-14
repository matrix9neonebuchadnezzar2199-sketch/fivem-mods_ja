Config = Config or {}
Config.Specializations = Config.Specializations or {}

-- スイーツ（プレースホルダ 3 ノード）
Config.Specializations.sweets = {
    id = 'sweets',
    label = 'スイーツ',
    icon = { type = 'emoji', value = '🍰' },
    color = '#e91e63',
    description = '甘味と盛り付けの芸術',
    nodes = {
        root = {
            angle = 270, radius = 120, lv = 1,
            label = 'なめらかプリン',
            icon = { type = 'emoji', value = '🍮' },
            recipe = 'pudding',
            requires = {},
            nodeType = 'staged',
            maxRank = 5,
            spCostStages = { 2, 3, 4, 5, 6 },
        },
        macaron = {
            angle = 30, radius = 280, lv = 15,
            label = 'マカロン',
            icon = { type = 'emoji', value = '🌈' },
            recipe = 'macaron',
            requires = { 'root' },
            nodeType = 'staged',
            maxRank = 5,
            spCostStages = { 2, 3, 4, 5, 6 },
        },
        croquembouche = {
            angle = 150, radius = 440, lv = 40,
            label = 'クロカンブッシュ',
            icon = { type = 'emoji', value = '🗼' },
            recipe = 'croquembouche',
            requires = { 'macaron' },
            nodeType = 'staged',
            maxRank = 5,
            spCostStages = { 2, 3, 4, 5, 6 },
        },
    },
}
