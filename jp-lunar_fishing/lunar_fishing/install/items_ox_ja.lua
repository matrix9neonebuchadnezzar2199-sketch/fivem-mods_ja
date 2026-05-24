-- =============================================================
--  jp-lunar_fishing - ox_inventory 用アイテム定義（日本語ラベル）
-- =============================================================
--
--  使い方:
--  ox_inventory/data/items.lua の return { ... } ブロックの中に、
--  下記の各エントリを追記してください。既存アイテムと衝突する場合は、
--  そのキーをリネームし、config.lua / items_ox_ja.lua の双方を合わせて
--  修正してください。
--
--  画像配置:
--  assets/fish_images/ 配下の PNG を、ox_inventory/web/images/ に
--  コピーしてください（ファイル名はキーと完全一致、小文字、拡張子 .png）。
--
--  ライセンス: GPL-3.0（jp-lunar_fishing 全体に従う）
-- =============================================================

return {
    -- ===== 魚（10種） =====
    ['iwashi'] = {
        label  = 'イワシ',
        weight = 100,
        stack  = true,
        close  = true,
        description = '日本近海で最も馴染み深い小魚。安価だが数が稼げる。',
    },
    ['aji'] = {
        label  = 'アジ',
        weight = 150,
        stack  = true,
        close  = true,
        description = '回遊魚。塩焼きや刺身で親しまれる定番魚。',
    },
    ['saba'] = {
        label  = 'サバ',
        weight = 200,
        stack  = true,
        close  = true,
        description = '青魚の代表格。脂が乗っていて市場価値も安定している。',
    },
    ['tai'] = {
        label  = 'マダイ',
        weight = 500,
        stack  = true,
        close  = true,
        description = '祝い事に欠かせない高級魚。沿岸でも釣れる。',
    },
    ['hirame'] = {
        label  = 'ヒラメ',
        weight = 600,
        stack  = true,
        close  = true,
        description = 'サンゴ礁の砂地に潜む高級白身魚。',
    },
    ['unagi'] = {
        label  = 'ウナギ',
        weight = 400,
        stack  = true,
        close  = true,
        description = '沼地や淡水域に潜む。ぬめりが強く扱いが難しい。',
    },
    ['buri'] = {
        label  = 'ブリ',
        weight = 800,
        stack  = true,
        close  = true,
        description = '出世魚として知られる大型の回遊魚。脂の乗りが絶品。',
    },
    ['katsuo'] = {
        label  = 'カツオ',
        weight = 1000,
        stack  = true,
        close  = true,
        description = '黒潮に乗って回遊する高速魚。たたきは日本の伝統料理。',
    },
    ['maguro'] = {
        label  = 'クロマグロ',
        weight = 3000,
        stack  = true,
        close  = true,
        description = '深海を泳ぐ高級魚の王様。市場で高値が付く。',
    },
    ['ryugu'] = {
        label  = 'リュウグウノツカイ',
        weight = 2000,
        stack  = true,
        close  = true,
        description = '深海に棲む幻の魚。古来より竜宮の使いと呼ばれる。',
    },

    -- ===== 釣り竿（3種） =====
    ['basic_rod'] = {
        label  = '初心者の釣り竿',
        weight = 1500,
        stack  = false,
        close  = true,
        description = '入門用の釣り竿。耐久性は低いが安価。',
    },
    ['graphite_rod'] = {
        label  = 'グラファイト竿',
        weight = 1200,
        stack  = false,
        close  = true,
        description = '軽くてしなやかな中級者向け釣り竿。',
    },
    ['titanium_rod'] = {
        label  = 'チタン竿',
        weight = 1000,
        stack  = false,
        close  = true,
        description = '高剛性のプロ仕様釣り竿。ほとんど折れない。',
    },

    -- ===== 餌（2種） =====
    ['worms'] = {
        label  = 'ミミズ',
        weight = 50,
        stack  = true,
        close  = true,
        description = '定番の生き餌。万能だが特別な誘引力はない。',
    },
    ['artificial_bait'] = {
        label  = 'ルアー',
        weight = 30,
        stack  = true,
        close  = true,
        description = '人工餌。釣り時間を大幅に短縮できる。',
    },
}
