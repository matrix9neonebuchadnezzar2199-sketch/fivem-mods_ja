Config = {}

Config.progressPerCatch = 0.05 -- 1匹釣るごとに加算される進捗（XP）

---@class Fish
---@field price integer | { min: integer, max: integer }
---@field chance integer 出現確率（%）
---@field skillcheck SkillCheckDifficulity }

---@type table<string, Fish>
Config.fish = {
    ['iwashi']  = { price = { min = 25,   max = 50   }, chance = 35, skillcheck = { 'easy', 'medium' } },
    ['aji']     = { price = { min = 50,   max = 100  }, chance = 35, skillcheck = { 'easy', 'medium' } },
    ['saba']    = { price = { min = 150,  max = 200  }, chance = 20, skillcheck = { 'easy', 'medium' } },
    ['tai']     = { price = { min = 200,  max = 250  }, chance = 10, skillcheck = { 'easy', 'medium', 'medium' } },
    ['hirame']  = { price = { min = 300,  max = 350  }, chance = 25, skillcheck = { 'easy', 'medium', 'medium', 'medium' } },
    ['unagi']   = { price = { min = 350,  max = 450  }, chance = 25, skillcheck = { 'easy', 'medium', 'hard' } },
    ['buri']    = { price = { min = 400,  max = 450  }, chance = 20, skillcheck = { 'easy', 'medium', 'medium', 'medium' } },
    ['katsuo']  = { price = { min = 450,  max = 500  }, chance = 20, skillcheck = { 'easy', 'medium', 'medium', 'medium' } },
    ['maguro']  = { price = { min = 1250, max = 1500 }, chance = 5,  skillcheck = { 'easy', 'medium', 'hard' } },
    ['ryugu']   = { price = { min = 2250, max = 2750 }, chance = 1,  skillcheck = { 'easy', 'medium', 'hard' } },
}

---@class FishingRod
---@field name string
---@field price integer
---@field minLevel integer 必要レベル
---@field breakChance integer 破損確率（%）

---@type FishingRod[]
Config.fishingRods = {
    { name = 'basic_rod',    price = 1000, minLevel = 1, breakChance = 20 },
    { name = 'graphite_rod', price = 2500, minLevel = 2, breakChance = 10 },
    { name = 'titanium_rod', price = 5000, minLevel = 3, breakChance = 1  },
}

---@class FishingBait
---@field name string
---@field price integer
---@field minLevel integer 必要レベル
---@field waitDivisor number 待ち時間がこの値で除算される（大きいほど早く釣れる）

---@type FishingBait[]
Config.baits = {
    { name = 'worms',           price = 5,  minLevel = 1, waitDivisor = 1.0 },
    { name = 'artificial_bait', price = 50, minLevel = 2, waitDivisor = 3.0 },
}

---@class FishingZone
---@field locations vector3[] ランダムに1つ選ばれる
---@field radius number
---@field minLevel integer
---@field waitTime { min: integer, max: integer }
---@field includeOutside boolean Config.outside の魚も釣れるか
---@field blip BlipData?
---@field message { enter: string, exit: string }?
---@field fishList string[]

---@type FishingZone[]
Config.fishingZones = {
    {
        blip = {
            name = 'サンゴ礁',
            sprite = 317,
            color = 24,
            scale = 0.6
        },
        locations = {
            vector3(-1774.0654, -1796.2740, 0.0),
            vector3(2482.8589, -2575.6780, 0.0)
        },
        radius = 250.0,
        minLevel = 1,
        waitTime = { min = 5, max = 10 },
        includeOutside = true,
        message = { enter = 'サンゴ礁に入りました。', exit = 'サンゴ礁を離れました。' },
        fishList = { 'hirame', 'buri' }
    },
    {
        blip = {
            name = '深海域',
            sprite = 317,
            color = 29,
            scale = 0.6
        },
        locations = {
            vector3(-4941.7964, -2411.9146, 0.0),
        },
        radius = 1000.0,
        minLevel = 3,
        waitTime = { min = 20, max = 40 },
        includeOutside = false,
        message = { enter = '深海域に入りました。', exit = '深海域を離れました。' },
        fishList = { 'katsuo', 'maguro', 'ryugu' }
    },
    {
        blip = {
            name = '沼地',
            sprite = 317,
            color = 56,
            scale = 0.6
        },
        locations = {
            vector3(-2188.1182, 2596.9348, 0.0),
        },
        radius = 200.0,
        minLevel = 2,
        waitTime = { min = 10, max = 20 },
        includeOutside = true,
        message = { enter = '沼地に入りました。', exit = '沼地を離れました。' },
        fishList = { 'unagi' }
    },
}

-- ゾーン外（通常の海岸線）
Config.outside = {
    waitTime = { min = 10, max = 25 },

    ---@type string[]
    fishList = {
        'iwashi', 'aji', 'saba', 'tai'
    }
}

Config.ped = {
    model = `s_m_m_cntrybar_01`,
    buyAccount = 'money',
    sellAccount = 'money',
    blip = {
        name = 'シートレード商会',
        sprite = 356,
        color = 74,
        scale = 0.75
    },

    ---@type vector4[]
    locations = {
        vector4(-2081.3831, 2614.3223, 3.0840, 112.7910),
        vector4(-1492.3639, -939.2579, 10.2140, 144.0305)
    }
}

Config.renting = {
    model = `s_m_m_dockwork_01`, -- NPCモデル
    account = 'money',
    boats = {
        { model = `speeder`, price = 500,  image = 'https://i.postimg.cc/mDSqWj4P/164px-Speeder.webp' },
        { model = `dinghy`,  price = 750,  image = 'https://i.postimg.cc/ZKzjZgj0/164px-Dinghy2.webp'  },
        { model = `tug`,     price = 1250, image = 'https://i.postimg.cc/jq7vpKHG/164px-Tug.webp' }
    },
    blip = {
        name = 'ボートレンタル',
        sprite = 410,
        color = 74,
        scale = 0.75
    },
    returnDivider = 5,   -- 返却時の払い戻し倍率（price ÷ 5）
    returnRadius = 30.0, -- 返却可能な範囲

    ---@type { coords: vector4, spawn: vector4 }[]
    locations = {
        { coords = vector4(-1434.4818, -1512.2745, 2.1486, 25.8666), spawn = vector4(-1494.4496, -1537.6943, 2.3942, 115.6015) }
    }
}
