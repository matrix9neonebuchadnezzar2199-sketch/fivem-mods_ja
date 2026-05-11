Config = Config or {}

-- バフ・カタログ
-- 一時バフ（料理摂取で ON、durSec 秒で自動 OFF）
-- 恒久パッシブ（ノード/★解放で常時 ON）
-- レシピや★パッシブからは ID（テーブルキー）参照のみ。仕様変更はここを直すだけ。
Config.BuffCatalog = {
    -- ===== 一時バフ =====
    stamina_up = {
        category = 'temporary', kind = 'stamina', power = 1.5, durSec = 600,
        label = 'スタミナ微増', icon = '🏃', description = 'スタミナ消費が緩和',
    },
    max_hp_up = {
        category = 'temporary', kind = 'max_hp', power = 250, durSec = 1200,
        label = '最大HP +50', icon = '💪', description = '最大HPが50増加',
    },
    -- 旧キー armor_regen は P2.7 の汎用パッシブ armor_regen と衝突するため改名
    armor_regen_burst = {
        category = 'temporary', kind = 'armor_regen', power = 5, durSec = 300,
        label = 'アーマー自動回復', icon = '🛡️', description = 'アーマーが自動で回復する',
    },

    -- ===== 恒久パッシブ =====
    crit_rate_5 = {
        category = 'passive', kind = 'crit_rate', power = 0.05,
        label = 'クリティカル率+5%', icon = '⚡', description = '料理作成のクリティカル発生率+5%',
    },
    exp_boost_10 = {
        category = 'passive', kind = 'exp_mult', power = 1.10,
        label = 'EXP獲得+10%', icon = '📈', description = '取得EXPが10%増加',
    },

    -- ===== P2.7: 汎用ツリー由来（将来ノード解放とリンク） =====
    carry_kg = {
        category = 'passive', kind = 'carry_kg', power = 1,
        label = '所持重量+1kg', icon = '💪', description = '1段ごとに所持重量+1kg',
    },
    armor_cap = {
        category = 'passive', kind = 'armor_cap', power = 5,
        label = 'アーマー上限+5', icon = '🛡️', description = '1段ごとに最大アーマー上限+5',
    },
    buff_duration = {
        category = 'passive', kind = 'buff_duration', power = 0.05,
        label = '食事バフ持続+5%', icon = '⏳', description = '1段ごとに食事バフ持続+5%',
    },
    cook_speed = {
        category = 'passive', kind = 'cook_speed', power = 0.05,
        label = 'ミニゲーム時間+5%', icon = '🏃', description = '1段ごとにミニゲーム制限時間+5%',
    },
    cooldown_reduce = {
        category = 'passive', kind = 'cooldown_reduce', power = 5,
        label = 'クールダウン-5秒', icon = '⏱️', description = '1段ごとに調理クールダウン-5秒',
    },
    star_mult = {
        category = 'passive', kind = 'star_mult', power = 0.1,
        label = '★獲得+10%', icon = '🌟', description = '1段ごとに★獲得+10%',
    },
    ingredient_save = {
        category = 'passive', kind = 'ingredient_save', power = 0.02,
        label = '素材節約+2%', icon = '♻️', description = '1段ごとに素材節約+2%',
    },
    armor_regen = {
        category = 'passive', kind = 'armor_regen', power = 0.5,
        label = 'アーマー回復+0.5/s', icon = '🛡️', description = '1段ごとにアーマー自然回復+0.5/秒',
    },
    hp_regen_mult = {
        category = 'passive', kind = 'hp_regen_mult', power = 0.5,
        label = 'HP回復+50%', icon = '💗', description = '1段ごとにHP回復速度+50%',
    },
    heat_vision = {
        category = 'passive', kind = 'heat_vision', power = 1,
        label = '熱源検知ビジョン', icon = '🔥', description = '食事中に熱源検知発動',
    },
}
