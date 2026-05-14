Config = Config or {}

--[[
  RecipeStarBuff: 料理の「解放ノード段階」に連動するバフ枠（個別定義は後続フェーズ）。

  想定キー構造:
    Config.RecipeStarBuff[recipeId][stage] = { ... }

  - 段階 0: ツリー未投資（調理不可）
  - 段階 1: レシピ解放ライン（調理可能の最低段階）
  - 段階 2～5: 品質向上・付加効果（metadata の starBuff に載る）

  現状は枠のみ。buildCookMetadata は stage に応じて参照する。
]]
Config.RecipeStarBuff = {}
