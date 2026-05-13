Config = Config or {}

-- 汎用ツリー: 専門職に依存しない共通スキル
-- type='status'  : 多段強化、SP消費で段階上昇、ステータスバフ（P3 以降で本適用）
-- type='recipe'  : 単発解放、SP消費で調味料/技法レシピ追加
Config.GeneralTree = {
    --------------------------------------------------------------------
    -- 内側リング (radius 540) ステータス入門 8ノード
    --------------------------------------------------------------------
    hp_node = {
        angle = 0, radius = 540, type = 'status', category = 'hp',
        nodeType = 'staged', costPerRank = 1,
        label = '生命力', icon = { type = 'emoji', value = '❤️' },
        maxRank = 5, perRank = { stat = 'max_hp', value = 5 },
        spCostPerRank = 1,
        description = '1段ごとに最大HP+5（最大5段）',
    },
    carry_node = {
        angle = 45, radius = 540, type = 'status', category = 'carry',
        label = '頑強な体', icon = { type = 'emoji', value = '💪' },
        maxRank = 5, perRank = { stat = 'carry_kg', value = 1 },
        spCostPerRank = 1,
        description = '1段ごとに所持重量+1kg（最大5段）',
    },
    crit_node = {
        angle = 90, radius = 540, type = 'status', category = 'crit',
        nodeType = 'staged', costPerRank = 1,
        label = '繊細な手先', icon = { type = 'emoji', value = '⚡' },
        maxRank = 5, perRank = { stat = 'crit_rate', value = 0.01 },
        spCostPerRank = 2,
        description = '1段ごとにクリティカル率+1%（最大5段）',
    },
    exp_node = {
        angle = 135, radius = 540, type = 'status', category = 'exp',
        nodeType = 'staged', costPerRank = 1,
        label = '学習の才', icon = { type = 'emoji', value = '📈' },
        maxRank = 5, perRank = { stat = 'exp_mult', value = 0.05 },
        spCostPerRank = 2,
        description = '1段ごとにEXP獲得+5%（最大5段）',
    },
    armor_cap_node = {
        angle = 180, radius = 540, type = 'status', category = 'armor',
        nodeType = 'staged', costPerRank = 1,
        label = '頑健な装備', icon = { type = 'emoji', value = '🛡️' },
        maxRank = 3, perRank = { stat = 'armor_cap', value = 5 },
        spCostPerRank = 2,
        description = '1段ごとに最大アーマー上限+5（最大3段）',
    },
    buff_dur_node = {
        angle = 225, radius = 540, type = 'status', category = 'buff',
        label = '余韻の持続', icon = { type = 'emoji', value = '⏳' },
        maxRank = 5, perRank = { stat = 'buff_duration', value = 0.05 },
        spCostPerRank = 2,
        description = '1段ごとに食事バフ持続時間+5%（最大5段）',
    },
    cook_speed_node = {
        angle = 270, radius = 540, type = 'status', category = 'speed',
        label = '手際の良さ', icon = { type = 'emoji', value = '🏃' },
        maxRank = 3, perRank = { stat = 'cook_speed', value = 0.05 },
        spCostPerRank = 2,
        description = '1段ごとにミニゲーム制限時間+5%（最大3段）',
    },
    cooldown_node = {
        angle = 315, radius = 540, type = 'status', category = 'cooldown',
        nodeType = 'staged', costPerRank = 1,
        label = '淀みなき動き', icon = { type = 'emoji', value = '⏱️' },
        maxRank = 3, perRank = { stat = 'cooldown_reduce', value = 5 },
        spCostPerRank = 2,
        description = '1段ごとに調理クールダウン-5秒（最大3段）',
    },

    --------------------------------------------------------------------
    -- 中間リング (radius 660-680) ステータス2ノード + レシピ4ノード
    --------------------------------------------------------------------
    star_mult_node = {
        angle = 22, radius = 660, type = 'status', category = 'star',
        nodeType = 'staged', costPerRank = 1,
        label = '精進の証', icon = { type = 'emoji', value = '🌟' },
        maxRank = 3, perRank = { stat = 'star_mult', value = 0.1 },
        spCostPerRank = 3,
        description = '1段ごとに★獲得+10%（最大3段）',
    },
    save_node = {
        angle = 112, radius = 660, type = 'status', category = 'save',
        label = '無駄なき調理', icon = { type = 'emoji', value = '♻️' },
        maxRank = 5, perRank = { stat = 'ingredient_save', value = 0.02 },
        spCostPerRank = 3,
        description = '1段ごとに素材節約率+2%（将来素材導入時に有効、最大5段）',
    },
    recipe_sauce = {
        angle = 67, radius = 680, type = 'recipe', category = 'recipe',
        label = '自家製ソース', icon = { type = 'emoji', value = '🥫' },
        spCost = 2, recipe = 'homemade_sauce',
        description = '調味料レシピ「自家製デミグラスソース」を解放',
    },
    recipe_dressing = {
        angle = 157, radius = 680, type = 'recipe', category = 'recipe',
        label = '秘伝ドレッシング', icon = { type = 'emoji', value = '🫙' },
        spCost = 2, recipe = 'secret_dressing',
        description = '調味料レシピ「秘伝のドレッシング」を解放',
    },
    recipe_stock = {
        angle = 202, radius = 680, type = 'recipe', category = 'recipe',
        label = '極上ブイヨン', icon = { type = 'emoji', value = '🍯' },
        spCost = 2, recipe = 'premium_bouillon',
        description = '調味料レシピ「極上ブイヨン」を解放',
    },
    recipe_garnish = {
        angle = 247, radius = 680, type = 'recipe', category = 'recipe',
        label = '飾り切り技法', icon = { type = 'emoji', value = '🌸' },
        spCost = 2, recipe = 'decorative_cut',
        description = '盛り付け技法「飾り切り」を解放',
    },

    --------------------------------------------------------------------
    -- 外側リング (radius 760-780) 上級ステータス4 + レシピ2
    --------------------------------------------------------------------
    armor_regen_node = {
        angle = 0, radius = 760, type = 'status', category = 'armor_regen',
        label = '不屈の意志', icon = { type = 'emoji', value = '🛡️' },
        maxRank = 3, perRank = { stat = 'armor_regen', value = 0.5 },
        spCostPerRank = 4,
        description = '1段ごとにアーマー自然回復+0.5/秒（最大3段）',
    },
    hp_regen_node = {
        angle = 72, radius = 760, type = 'status', category = 'hp_regen',
        nodeType = 'staged', costPerRank = 1,
        label = '生命の鼓動', icon = { type = 'emoji', value = '💗' },
        maxRank = 3, perRank = { stat = 'hp_regen_mult', value = 0.5 },
        spCostPerRank = 4,
        description = '1段ごとにHP回復速度+50%（最大3段）',
    },
    heat_vision_node = {
        angle = 144, radius = 760, type = 'status', category = 'heat',
        label = '炎の眼', icon = { type = 'emoji', value = '🔥' },
        maxRank = 1, perRank = { stat = 'heat_vision', value = 1 },
        spCostPerRank = 5,
        description = '食事中に熱源検知ビジョン発動（単発スキル）',
    },
    max_hp_big_node = {
        angle = 216, radius = 760, type = 'status', category = 'hp_big',
        label = '豪傑の体躯', icon = { type = 'emoji', value = '💪' },
        maxRank = 3, perRank = { stat = 'max_hp', value = 20 },
        spCostPerRank = 4,
        description = '1段ごとに最大HP+20（最大3段）',
    },
    recipe_appetizer = {
        angle = 288, radius = 780, type = 'recipe', category = 'recipe',
        label = '秘伝の前菜', icon = { type = 'emoji', value = '🍢' },
        spCost = 4, recipe = 'secret_appetizer',
        description = '伝統技法「秘伝の前菜」を解放',
    },
    recipe_dessert = {
        angle = 324, radius = 780, type = 'recipe', category = 'recipe',
        label = '食後の一品', icon = { type = 'emoji', value = '🍨' },
        spCost = 4, recipe = 'after_dessert',
        description = '盛り付け技法「食後の一品」を解放',
    },
}
