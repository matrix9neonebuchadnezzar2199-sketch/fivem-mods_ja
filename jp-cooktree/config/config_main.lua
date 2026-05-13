Config = Config or {}

-- 全体設定（運営の主な調整項目はここ）
Config.Cooldowns = { perRecipeSec = 60, globalSec = 5 }
Config.Debug = true  -- 開発中は true。本番リリース時に false へ

-- 料理専用 XP テーブル（累積 XP が閾値以上ならそのレベルに到達。キーは飛び番可）
-- 検証向け: Lv1→2 は 100 XP（訓練レシピ 10 XP ×10 回成功でレベルアップ）
Config.LevelTable = {
    [1]  = 0,
    [2]  = 100,
    [3]  = 250,
    [4]  = 450,
    [5]  = 700,
    [6]  = 1000,
    [7]  = 1350,
    [8]  = 1750,
    [9]  = 2200,
    [10] = 2700,
    [15] = 6000,
    [20] = 11000,
    [25] = 17000,
    [30] = 25000,
    [40] = 45000,
    [50] = 75000,
}

-- レベルアップ 1 段階ごとに付与する SP（将来のツリー SP 消費用）
Config.SpPerLevel = 1

-- P3c: ミニゲーム成功後のクリティカル（Glitch の戻り値は boolean のみのため確率判定）
Config.CriticalChance = 0.10
Config.CriticalMultiplier = {
    exp = 2,
    stars = 2,
}

-- Glitch Minigames の ensure 名（monorepo 既定: jp-glitch28。`glitch-minigames` にリネームしたサーバーはここを変更）
Config.GlitchMinigamesResource = 'jp-glitch28'

-- P3d: 調理品 metadata の売却倍率（実売却ロジックは P3g。ここは定数のみ）
Config.SellPriceMultiplier = {
    normal = 1.0,
    critical = 2.0,
    failed = 0.0,
}
