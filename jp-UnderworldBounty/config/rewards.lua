-- 報酬テーブル（サーバー側のみで抽選・付与）。シナリオは reward_table_id で参照する。

Config.RewardTables = {
  reward_small = {
    cash = { min = 500, max = 1500, chance = 1.0 },
    items = {
      { item = 'markedbills', count_min = 1, count_max = 2, chance = 0.35 },
    },
  },
  reward_medium = {
    cash = { min = 2000, max = 4500, chance = 1.0 },
    items = {
      { item = 'markedbills', count_min = 2, count_max = 4, chance = 0.55 },
    },
  },
  reward_large = {
    cash = { min = 5000, max = 9000, chance = 1.0 },
    items = {
      { item = 'markedbills', count_min = 4, count_max = 8, chance = 0.7 },
    },
  },
  -- 情報屋契約：ギミック成功後にヤクザを全滅させたときの報酬
  reward_contract = {
    cash = { min = 3500, max = 7000, chance = 1.0 },
    items = {
      { item = 'markedbills', count_min = 1, count_max = 3, chance = 0.45 },
    },
  },
}
