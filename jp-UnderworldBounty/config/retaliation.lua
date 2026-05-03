-- 報復（闇の指名手配）パターン。シナリオが retaliation_pattern_id で参照する。

Config.RetaliationPatterns = {
  default = {
    duration_sec = 7200,
    max_strikes = 2,
    strike_interval_min_sec = 90,
    strike_interval_max_sec = 180,
    vehicle_model = `baller2`,
    squad_size = 3,
    ped_models = {
      `g_m_m_armboss_01`,
      `g_m_m_armgoon_01`,
      `g_m_m_armgoon_02`,
    },
    weapon = `WEAPON_SMG`,
    approach = 'drive',
    clear_bounty_on_player_death = true,
    neutral_to_cops = true,
    drops = {
      { item = 'markedbills', count_min = 0, count_max = 1, chance = 0.25 },
    },
  },
  light = {
    duration_sec = 3600,
    max_strikes = 1,
    strike_interval_min_sec = 60,
    strike_interval_max_sec = 120,
    vehicle_model = `seminole2`,
    squad_size = 2,
    ped_models = {
      `g_m_y_mexgoon_03`,
      `g_m_y_mexgoon_02`,
    },
    weapon = `WEAPON_PISTOL`,
    approach = 'drive',
    clear_bounty_on_player_death = true,
    neutral_to_cops = true,
    drops = {},
  },
}
