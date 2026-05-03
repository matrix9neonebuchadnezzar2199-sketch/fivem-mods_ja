-- 賭場ロケーション（トリガーは coords + radius）。scenario_id で Config.Scenarios と結び付ける。

Config.Locations = {
  {
    id = 'loc_training_yard',
    label_key = 'loc_label_training',
    enabled = true,
    scenario_id = 'scenario_training_yard',
    trigger = { coords = vector3(-1175.40, -1572.90, 4.36), radius = 2.5 },
  },
  {
    id = 'loc_docks_gamblers',
    label_key = 'loc_label_docks',
    enabled = true,
    scenario_id = 'scenario_docks_gamblers',
    trigger = { coords = vector3(-1598.10, -991.80, 13.02), radius = 2.5 },
  },
  {
    id = 'loc_vinewood_backroom',
    label_key = 'loc_label_vinewood',
    enabled = true,
    scenario_id = 'scenario_vinewood_backroom',
    trigger = { coords = vector3(251.20, -913.10, 29.31), radius = 2.5 },
  },
}
