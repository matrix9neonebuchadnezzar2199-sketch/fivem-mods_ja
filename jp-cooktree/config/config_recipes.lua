Config = Config or {}

-- レシピ定義（素材システム廃止。unlockNode = 'specId:nodeId' は Specializations と整合）
-- バフ ID は BuffCatalog 参照。アイテム名は ox_inventory の items.lua に定義すること。
Config.Recipes = {
    omurice_special = {
        label           = '特製オムライス',
        unlockNode      = 'western:root',
        result          = { item = 'omurice_special', count = 1 },
        failureResult   = { item = 'failed_dish', count = 1 },
        exp             = 10,
        buffs           = { 'stamina_up' },
        cookTime        = 5000, -- ミニゲーム制限時間 ms（P3c で使用）
    },
}
