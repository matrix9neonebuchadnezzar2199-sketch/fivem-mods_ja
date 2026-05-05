Config = Config or {}
Locales = Locales or {}

-- ┌───────────────────────────────────┐
-- │  ____                           _ │
-- │ / ___| ___ _ __   ___ _ __ __ _| |│
-- │| |  _ / _ \ '_ \ / _ \ '__/ _` | |│
-- │| |_| |  __/ | | |  __/ | | (_| | |│
-- │ \____|\___|_| |_|\___|_|  \__,_|_|│
-- └───────────────────────────────────┘

--[[
    スクリプトの言語コード。'en', 'es', 'de' など locales フォルダにあるものから選べます。
    追加言語は locales にファイルを足して定義してください。
]]

Config.Language = 'ja' -- 日本語版デフォルト（locales/ja.lua を参照）


--[[
    全般設定。レイキャスト距離、炎の持続時間、起動時に枯れた植物を掃除するか、
    プレイヤーが同時に持てる植物の上限などを指定します。
]]
Config.rayCastingDistance = 7.0 -- レイキャスト距離（メートル）
Config.FireTime = 10000 -- 炎の時間（ミリ秒）
Config.ClearOnStartup = true -- true ならスクリプト起動時に枯れた植物を削除
Config.PlayerPlantLimit = 10 -- プレイヤーが同時に持てる植物の最大数

-- ┌───────────────────────────┐
-- │ _____                     │
-- │|__  /___  _ __   ___  ___ │
-- │  / // _ \| '_ \ / _ \/ __|│
-- │ / /| (_) | | | |  __/\__ \│
-- │/____\___/|_| |_|\___||___/│
-- └───────────────────────────┘

Config.GlobalGrowTime = 30 -- 植物が成長完了するまでの基準時間（分）

Config.Zones = {
    ['weed_zone_one'] = { -- ゾーンID（一意であること）
        points = {
            vec3(2031.0, 4853.0, 43.0),
            vec3(2007.0, 4877.0, 43.0),
            vec3(1981.0, 4903.0, 43.0),
            vec3(2006.0, 4929.0, 43.0),
            vec3(2032.0, 4903.0, 43.0),
            vec3(2057.0, 4878.0, 43.0),
        },
        thickness = 4.0,
        growMultiplier = 2, -- このゾーン内の成長時間（分）= GlobalGrowTime / growMultiplier

        blip = {
            display = true, -- マップにブリップを表示するか
            sprite = 469, -- スプライトID（https://docs.fivem.net/docs/game-references/blips/）
            displayColor = 2, -- 色ID（https://docs.fivem.net/docs/game-references/blips/）
            displayText = 'Weed Zone',
        },
    },
    ['weed_zone_two'] = { -- ゾーンID（一意であること）
        points = {
            vec3(2067.0, 4890.0, 41.0),
            vec3(2043.0, 4914.0, 41.0),
            vec3(2017.0, 4940.0, 41.0),
            vec3(2045.0, 4969.0, 41.0),
            vec3(2069.0, 4946.0, 41.0),
            vec3(2097.0, 4918.0, 41.0),
        },
        thickness = 4.0,
        growMultiplier = 2, -- このゾーン内の成長時間（分）= GlobalGrowTime / growMultiplier
        blip = {
            display = true, -- マップにブリップを表示するか
            sprite = 469, -- スプライトID（https://docs.fivem.net/docs/game-references/blips/）
            displayColor = 2, -- 色ID（https://docs.fivem.net/docs/game-references/blips/）
            displayText = 'Weed Zone',
        },
    },
}


-- ┌─────────────────────────────┐
-- │ ____  _             _       │
-- │|  _ \| | __ _ _ __ | |_ ___ │
-- │| |_) | |/ _` | '_ \| __/ __|│
-- │|  __/| | (_| | | | | |_\__ \│
-- │|_|   |_|\__,_|_| |_|\__|___/│
-- └─────────────────────────────┘

Config.PlantDistance = 1.5 -- 植物同士の最小間隔（メートル）

Config.OnlyAllowedGrounds = false -- true なら許可した地面タイプでのみ栽培可能
Config.AllowedGrounds = {   -- 植え付けを許可する地面マテリアル（ハッシュ）
    1109728704, -- 畑
    -1942898710, -- 草地・土
    510490462, -- 土の道
    -1286696947,
    -1885547121,
    223086562,
    -461750719,
    1333033863,
    -1907520769,
}

Config.WaterDecay = 1 -- 水分が毎分減る割合（%）
Config.FertilizerDecay = 0.7 -- 肥料が毎分減る割合（%）

Config.FertilizerThreshold = 10
Config.WaterThreshold = 10
Config.HealthBaseDecay = {7, 10} -- 水分・肥料が閾値未満のとき、体力が毎分減る量の最小〜最大

Config.ItemToDestroyPlant = false -- true なら植物破棄にアイテムが必要
Config.DestroyItemName = "lighter"


Config.Items = {
    ['watering_can'] = {
        water = 25,
        fertilizer = 0,
        itemBack = nil, -- 使用後に戻すアイテム名。例: itemBack = 'watering_can'
    },
    ['liquid_fertilizer'] = {
        water = 15,
        fertilizer = 15,
        itemBack = nil,
    },
    ['fertilizer'] = {
        water = 0,
        fertilizer = 25,
        itemBack = nil,
    },
    ['advanced_fertilizer'] = {
        water = 0,
        fertilizer = 40,
        itemBack = nil,
    },
}

Config.PlantTypes = {
    -- small=成長0〜30%、medium=30〜80%、large=80〜100%
    ["plantLemon"] = {
        [1] = {"an_weed_yellow_01_small_01b", -0.5}, -- -0.5 で地面にめり込ませて表示
        [2] = {"an_weed_yellow_med_01b", -0.5},
        [3] = {"an_weed_yellow_lrg_01b", -0.5},
    },
    ["plantOg"] = {
        [1] = {"bkr_prop_weed_01_small_01a", -0.5}, -- -0.5 で地面にめり込ませて表示
        [2] = {"bkr_prop_weed_med_01a", -0.5},
        [3] = {"bkr_prop_weed_lrg_01a", -0.5},
    },
    ["plantPurple"] = {
        [1] = {"an_weed_purple_01_small_01b", -0.5},
        [2] = {"an_weed_purple_med_01b",-0.5},
        [3] = {"an_weed_purple_lrg_01b", -0.5},
    },
    ["plantWhite"] = {
        [1] = {"an_weed_white_01_small_01b", -0.5},
        [2] = {"an_weed_white_med_01b",-0.5},
        [3] = {"an_weed_white_lrg_01b", -0.5},
    },
    ["plantBlue"] = {
        [1] = {"an_weed_blue_01_small_01b", -0.5},
        [2] = {"an_weed_blue_med_01b",-0.5},
        [3] = {"an_weed_blue_lrg_01b", -0.5},
    },
    ["small_plant"] = {
        [1] = {"h4_prop_bush_cocaplant_01", -1.0},
        [2] = {"h4_prop_bush_cocaplant_01", -0.75},
        [3] = {"h4_prop_bush_cocaplant_01", 0},
    },
}

Config.Plants = { -- 種から育てる植物の定義
    ['weed_lemonhaze_seed'] = {
        label = 'Lemon Haze', -- メニュー等に出る植物名
        plantType = 'plantLemon', -- Config.PlantTypes のキー
        growthTime = false, -- 成長時間（分）。false で Config.GlobalGrowTime（とゾーン倍率）を使用
        onlyZone = false, -- 特定ゾーンのみならゾーンIDの文字列を指定
        zones = {'weed_zone_one', 'weed_zone_two'}, -- 植え付けを許可するゾーンIDのリスト
        products = { -- 収穫時に得るアイテムと数量範囲
            ['weed_lemonhaze'] = {min = 1, max = 4},
            --['other_item'] = {min = 1, max = 2}
        },
        seed = {
            chance = 50, -- 種が返ってくる確率（%）
            min = 1, -- 返る種の最小個数
            max = 2 -- 返る種の最大個数
        },
        time = 3000, -- 植え付け・収穫の所要時間（ミリ秒）
    },
    ['weed_og_seed'] = {
        label = 'Og Kush', -- メニュー等に出る植物名
        plantType = 'plantOg', -- Config.PlantTypes のキー
        growthTime = false, -- 成長時間（分）。false でグローバル設定を使用
        onlyZone = false, -- 特定ゾーンのみならゾーンID
        zones = {'weed_zone_one', 'weed_zone_two'}, -- 植え付け可能ゾーン
        products = { -- 収穫アイテム
            ['weed_Og'] = {min = 1, max = 4},
            --['other_item'] = {min = 1, max = 2}
        },
        seed = {
            chance = 50, -- 種が返る確率（%）
            min = 1,
            max = 2
        },
        time = 3000, -- 植え付け・収穫（ミリ秒）
    },
    ['weed_purple_haze_seed'] = {
        label = 'Purple Haze', -- メニュー等に出る植物名
        plantType = 'plantPurple', -- Config.PlantTypes のキー
        growthTime = false,
        onlyZone = false,
        zones = {'weed_zone_one', 'weed_zone_two'},
        products = {
            ['weed_purple_haze'] = {min = 1, max = 4},
            --['other_item'] = {min = 1, max = 2}
        },
        seed = {
            chance = 50,
            min = 1,
            max = 2
        },
        time = 3000,
    },
    ['weed_white_widow_seed'] = {
        label = 'White Widow', -- メニュー等に出る植物名
        plantType = 'plantWhite', -- Config.PlantTypes のキー
        growthTime = false,
        onlyZone = false,
        zones = {'weed_zone_one', 'weed_zone_two'},
        products = {
            ['weed_white_widow'] = {min = 1, max = 4},
            --['other_item'] = {min = 1, max = 2}
        },
        seed = {
            chance = 50,
            min = 1,
            max = 2
        },
        time = 3000,
    },
    ['weed_blueberry_seed'] = {
        label = 'Blueberry', -- メニュー等に出る植物名
        plantType = 'plantBlue', -- Config.PlantTypes のキー
        growthTime = false,
        onlyZone = false,
        zones = {'weed_zone_one', 'weed_zone_two'},
        products = {
            ['weed_blueberry'] = {min = 1, max = 4},
            --['other_item'] = {min = 1, max = 2}
        },
        seed = {
            chance = 50,
            min = 1,
            max = 2
        },
        time = 3000,
    },
    ['coca_seed'] = {
        growthTime = 45, -- 成長時間（分）。false でグローバル設定
        onlyZone = false,
        label = 'Coca Plant', -- メニュー等に出る植物名
        zones = {}, -- 空ならゾーン制限なし（マップ全域の扱いはスクリプト仕様に依存）
        plantType = 'small_plant', -- Config.PlantTypes のキー（モデル変更は client 側も参照）
        products = {
            ['coca']= {min = 1, max = 2}
        },
        seed = {
            chance = 50,
            min = 1,
            max = 2
        },
        time = 3000 -- 収穫などの所要時間（ミリ秒）
    },
}

-- ┌─────────────────────────────────────────────────┐
-- │ ____                              _             │
-- │|  _ \ _ __ ___   ___ ___  ___ ___(_)_ __   __ _ │
-- │| |_) | '__/ _ \ / __/ _ \/ __/ __| | '_ \ / _` |│
-- │|  __/| | | (_) | (_|  __/\__ \__ \ | | | | (_| |│
-- │|_|   |_|  \___/ \___\___||___/___/_|_| |_|\__, |│
-- │                                           |___/ │
-- └─────────────────────────────────────────────────┘

--[[
    精製（加工）テーブルの設定。テーブルはいくつでも追加可能。
    レシピの材料・個数・加工時間などを定義する。同じドラッグ用に複数テーブルを置いてもよい。
]]

Config.EnableProcessing = true -- 精製クラフトを有効にするか

Config.ProcessingSkillCheck = false -- true ならプログレスバーの代わりにスキルチェック
Config.SkillCheck = {
    difficulty = {'easy', 'easy', 'medium', 'easy'},
    keys = {'w', 'a', 's', 'd'}
}

Config.ProcessingTables = { -- 設置型の加工テーブル定義
    ['weed_processing_table'] = {
        label = 'Weed Processing Table', -- 表示名
        model = 'freeze_it-scripts_weed_table', -- 例: freeze_it-scripts_empty_table, freeze_it-scripts_weed_table, freeze_it-scripts_coke_table, freeze_it-scripts_meth_table
        recipes = {
            ['joint_lemon_haze'] = {
                label = 'Joint lemon haze',
                ingrediants = {
                    ['weed_lemonhaze'] = {amount = 3, remove = true},
                    ['paper'] = {amount = 1, remove = true}
                },
                outputs = {
                    ['joint'] = 2
                },
                processTime = 15,
                failChance = 15,
                showIngrediants = true,
                animation = {
                    dict = 'anim@amb@drug_processors@coke@female_a@idles',
                    anim = 'idle_a',
                },
            },
            ['joint_og'] = {
                label = 'Joint og kush',
                ingrediants = {
                    ['weed_og'] = {amount = 3, remove = true},
                    ['paper'] = {amount = 1, remove = true}
                },
                outputs = {
                    ['joint'] = 2
                },
                processTime = 15,
                failChance = 15,
                showIngrediants = true,
                animation = {
                    dict = 'anim@amb@drug_processors@coke@female_a@idles',
                    anim = 'idle_a',
                },
            },
        }
    },

    ['cocaine_processing_table'] = {
        label = 'Cocaine Processing Table', -- 表示名
        model = 'freeze_it-scripts_coke_table', -- 上記と同様にモデル名を指定
        recipes = {
            ['cocaine'] = {
                label = 'Cocaine',
                ingrediants = {
                    ['coca'] = {amount = 3, remove = true},
                    ['nitrous'] = {amount = 1, remove = true}
                },
                outputs = {
                    ['cocaine'] = 2
                },
                processTime = 10,
                failChance = 15,
                showIngrediants = true,
                animation = {
                    dict = 'anim@amb@drug_processors@coke@female_a@idles',
                    anim = 'idle_a',
                }
            },
        }
    },
}

-- ┌────────────────────────────┐
-- │ ____                       │
-- │|  _ \ _ __ _   _  __ _ ___ │
-- │| | | | '__| | | |/ _` / __|│
-- │| |_| | |  | |_| | (_| \__ \│
-- │|____/|_|   \__,_|\__, |___/│
-- │                  |___/     │
-- └────────────────────────────┘

-- 利用可能なドラッグ効果一覧: https://help.it-scripts.com/scripts/it-drugs/adjustments/drugs#all-possible-drug-effects

Config.EnableDrugs = true -- 使用時のドラッグ効果を有効にするか
Config.Drugs = { -- 使用可能なドラッグと効果の定義

    ['joint'] = {
        label = 'Joint',
        animation = 'smoke', -- 使用アニメ: blunt, sniff, pill
        time = 80, -- 効果の持続時間（秒）
        effects = { -- 効果キー: runningSpeedIncrease, infinateStamina, moreStrength, healthRegen, foodRegen, drunkWalk, psycoWalk, outOfBody, cameraShake, fogEffect, confusionEffect, whiteoutEffect, intenseEffect, focusEffect など
            'intenseEffect',
            'healthRegen',
            'moreStrength',
            'drunkWalk'
        },
        cooldown = 360, -- 再使用までのクールダウン（秒）
    },
    ['cocaine'] = {
        label = 'Cocaine',
        animation = 'sniff', -- 使用アニメ: blunt, sniff, pill
        time = 60, -- 効果の持続時間（秒）
        effects = {
            'runningSpeedIncrease',
            'infinateStamina',
            'fogEffect',
            'psycoWalk'
        },
        cooldown = 480, -- 再使用までのクールダウン（秒）
    },
}

--[[
    NPC への売却設定。売却ゾーンはいくつでも追加可能。
    ゾーンごとにドラッグ単価や支払いタイプ（現金/銀行）を変えられる。
]]

-- ┌──────────────────────────────┐
-- │ ____       _ _ _             │
-- │/ ___|  ___| | (_)_ __   __ _ │
-- │\___ \ / _ \ | | | '_ \ / _` |│
-- │ ___) |  __/ | | | | | | (_| |│
-- │|____/ \___|_|_|_|_| |_|\__, |│
-- │                        |___/ │
-- └──────────────────────────────┘

Config.EnableSelling = true -- NPC 売却システムを有効にするか

Config.MinimumCops = 0 -- 売却に必要な警察の最低人数
Config.OnlyCopsOnDuty = true -- オン勤務のみカウント（QBCore 向け）
Config.PoliceJobs = {
    'police',
    'offpolice',
    'sheriff',
    'offsheriff',
}

Config.SellSettings = {
    ['onlyAvailableItems'] = true, -- true なら所持しているドラッグだけオファーに出る
    ['sellChance'] = 70, -- 売却が成立する確率（%）
    ['stealChance'] = 20, -- 代金を払わずに逃げられる確率（%）
    ['sellAmount'] = { -- 一度に売れる個数の範囲
        min = 1,
        max = 6,
    },
    ['sellTimeout'] = 20, -- メニューで選べる最大時間（秒）
    ['giveBonusOnPolice'] = true, -- 警察オンライン時にボーナス倍率 | 1〜2人:x1.2 | 3〜6:x1.5 | 7〜10:x1.7 | 11人以上:x2.0
}

Config.SellEverywhere = {
    ['enabled'] = false, -- true ならゾーン外でも売却可能
    drugs = {
        ['cocaine'] = {price = math.random(100, 200), moneyType = 'bank'},
        ['joint'] = {price = math.random(50, 100), moneyType = 'cash'},
        ['weed_lemonhaze'] = {price = math.random(50, 100), moneyType = 'cash'},
    }
}

Config.SellZones = {
    ['groove'] = {
        points = {
            vec3(-154.0, -1778.0, 30.0),
            vec3(48.0, -1690.0, 30.0),
            vec3(250.0, -1860.0, 30.0),
            vec3(142.0, -1993.0, 30.0),
            vec3(130.0, -2029.0, 30.0),
        },
        thickness = 27,
        drugs = {
            ['cocaine'] = {price = math.random(100, 200), moneyType = 'cash'},
            ['joint'] = {price = math.random(50, 100), moneyType = 'cash'},
            ['weed_lemonhaze'] = {price = math.random(50, 100), moneyType = 'cash'},
        }
    },
    ['vinewood'] = {
        points = {
            vec3(685.0, 36.0, 84.0),
            vec3(647.0, 53.0, 84.0),
            vec3(575.0, 81.0, 84.0),
            vec3(529.0, 100.0, 84.0),
            vec3(52.0, 274.0, 84.0),
            vec3(-34.0, 42.0, 84.0),
            vec3(426.0, -125.0, 84.0),
            vec3(494.0, -140.0, 84.0),
            vec3(518.0, -101.0, 84.0),
            vec3(595.0, -60.0, 84.0),
            vec3(667.0, -9.0, 84.0),
        },
        thickness = 59.0,
        drugs = {
            ['cocaine'] = {price = math.random(100, 200), moneyType = 'cash'},
            ['joint'] = {price = math.random(50, 100), moneyType = 'cash'},
            ['weed_lemonhaze'] = {price = math.random(50, 100), moneyType = 'cash'},
        }
    },
    ['beach'] = {
        points = {
            vec3(-1328.0, -1340.0, 5.0),
            vec3(-1307.0, -1399.0, 5.0),
            vec3(-1297.0, -1421.0, 5.0),
            vec3(-1266.0, -1466.0, 5.0),
            vec3(-1139.0, -1646.0, 5.0),
            vec3(-1129.0, -1640.0, 5.0),
            vec3(-1307.0, -1358.0, 5.0),
            vec3(-1335.0, -1279.0, 5.0),
            vec3(-1349.0, -1285.0, 5.0),
        },
        thickness = 4.0,
        drugs = {
            ['cocaine'] = {price = math.random(100, 200), moneyType = 'cash'},
            ['joint'] = {price = math.random(50, 100), moneyType = 'cash'},
            ['weed_lemonhaze'] = {price = math.random(50, 100), moneyType = 'cash'},
        }
    },
}


-- ┌──────────────────────────────────┐
-- │ ____             _               │
-- │|  _ \  ___  __ _| | ___ _ __ ___ │
-- │| | | |/ _ \/ _` | |/ _ \ '__/ __|│
-- │| |_| |  __/ (_| | |  __/ |  \__ \│
-- │|____/ \___|\__,_|_|\___|_|  |___/│
-- └──────────────────────────────────┘

-- 売人（ディーラー）: 種などの売買 NPC をスポーンさせる
Config.EnableDealers = true -- 売人システムを有効にするか

Config.DrugDealers = {
    ['seed_dealer'] = { -- 売人ID（一意であること）
        label = 'Seed Dealer', -- 表示名
        locations = { -- 固定スポーン（Tongva Hills 〜 Banham Canyon 付近の山中）
            vector4(-49.42, 1903.67, 194.36, 95.72),
        },
        ped = 's_m_y_dealer_01', -- Ped モデル名
        blip = {
            display = false, -- マップにブリップを出すか
            sprite = 140, -- スプライトID
            displayColor = 2, -- 色ID
            displayText = 'Seed Dealer',
        },
        items = {
            ['buying'] = { -- プレイヤーが売人に「売る」アイテム
                ['weed_og'] = {min = 100, max = 200, moneyType = 'cash'}, -- 価格の最小〜最大
                ['weed_lemonhaze'] = {min = 200, max = 300, moneyType = 'cash'},
                ['weed_purple_haze'] = {min = 300, max = 400, moneyType = 'cash'},
                ['weed_white_widow'] = {min = 400, max = 500, moneyType = 'cash'},
                ['weed_blueberry'] = {min = 500, max = 600, moneyType = 'cash'},
            },
            ['selling'] = { -- プレイヤーが売人から「買う」アイテム
                ['weed_og_seed'] = {min = 100, max = 200, moneyType = 'bank'},
                ['weed_lemonhaze_seed'] = {min = 300, max = 400, moneyType = 'cash'},
                ['weed_purple_haze_seed'] = {min = 400, max = 500, moneyType = 'cash'},
                ['weed_white_widow_seed'] = {min = 500, max = 600, moneyType = 'cash'},
                ['weed_blueberry_seed'] = {min = 600, max = 700, moneyType = 'cash'},
                ['coca_seed'] = {min = 100, max = 300, moneyType = 'cash'},
            },
        },
    },
}

Config.BlacklistPeds = {
    -- ドラッグを売れない Ped モデル
    "mp_m_shopkeep_01",
    "s_m_y_ammucity_01",
    "s_m_m_lathandy_01",
    "s_f_y_clubbar_01",
    "ig_talcc",
    "g_f_y_vagos_01",
    "hc_hacker",
    "s_m_m_migrant_01",
}

--[[
    デバッグ用。開発時のみ true にするとログが増える。
]]
Config.ManualZoneChecker = false -- true にすると自動ゾーンチェッカーを有効（原作のコメント表記どおり）
-- false: 起動時に it-drugs.sql 相当の CREATE TABLE を自動実行（推奨）。true: 自動作成しない（手動インポートのみ・DDL 禁止ホスト向け）
Config.ManualDatabaseSetup = false

Config.EnableVersionCheck = true -- バージョンチェックを有効にするか
Config.Branch = 'main' -- 参照ブランチ: 'master' または 'development' など
Config.Debug = false -- true でデバッグログ
Config.DebugPoly = false -- true で PolyZone のデバッグ表示
