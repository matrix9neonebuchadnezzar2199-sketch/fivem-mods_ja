-- シナリオ定義（敵・報酬・報復参照のみ Config に置く。座標は enemies[].coords）

local v4 = vector4

Config.Scenarios = {
  {
    id = 'scenario_training_yard',
    difficulty = 'easy',
    flavor_key = 'scenario_flavor_training',
    entry_minigame = 'none',
    time_limit_sec = 600,
    required_items = {},
    enemies = {
      {
        model = `g_m_y_mexgoon_03`,
        weapon = `WEAPON_PISTOL`,
        coords = v4(-1177.02, -1574.48, 4.36, 127.0),
        behavior = 'aggressive',
      },
      {
        model = `g_m_y_mexgoon_02`,
        weapon = `WEAPON_PISTOL`,
        coords = v4(-1179.55, -1572.12, 4.36, 90.0),
        behavior = 'alert',
      },
    },
    reward_table_id = 'reward_small',
    retaliation_pattern_id = 'light',
    success_condition = 'eliminate_all',
  },
  {
    id = 'scenario_docks_gamblers',
    difficulty = 'normal',
    flavor_key = 'scenario_flavor_docks',
    entry_minigame = 'lockpick',
    time_limit_sec = 720,
    required_items = {},
    enemies = {
      {
        model = `g_m_m_armboss_01`,
        weapon = `WEAPON_MICROSMG`,
        coords = v4(-1599.41, -993.59, 13.02, 320.0),
        behavior = 'boss',
      },
      {
        model = `g_m_m_armgoon_01`,
        weapon = `WEAPON_PISTOL`,
        coords = v4(-1602.10, -995.80, 13.02, 300.0),
        behavior = 'aggressive',
      },
      {
        model = `g_m_m_armgoon_02`,
        weapon = `WEAPON_PISTOL`,
        coords = v4(-1596.90, -996.40, 13.02, 350.0),
        behavior = 'aggressive',
      },
    },
    reward_table_id = 'reward_medium',
    retaliation_pattern_id = 'default',
    success_condition = 'eliminate_all',
  },
  {
    id = 'scenario_vinewood_backroom',
    difficulty = 'hard',
    flavor_key = 'scenario_flavor_vinewood',
    entry_minigame = 'hacking',
    time_limit_sec = 900,
    required_items = {},
    enemies = {
      {
        model = `g_m_m_armlieut_01`,
        weapon = `WEAPON_ASSAULTRIFLE`,
        coords = v4(252.79, -914.69, 29.31, 340.0),
        behavior = 'boss',
      },
      {
        model = `g_m_m_armgoon_01`,
        weapon = `WEAPON_MICROSMG`,
        coords = v4(249.50, -913.20, 29.31, 320.0),
        behavior = 'aggressive',
      },
      {
        model = `g_m_m_armgoon_02`,
        weapon = `WEAPON_MICROSMG`,
        coords = v4(255.10, -917.40, 29.31, 10.0),
        behavior = 'alert',
      },
      {
        model = `g_m_m_armgoon_01`,
        weapon = `WEAPON_PISTOL`,
        coords = v4(247.90, -916.80, 29.31, 280.0),
        behavior = 'passive',
      },
    },
    reward_table_id = 'reward_large',
    retaliation_pattern_id = 'default',
    success_condition = 'eliminate_all',
  },
}
