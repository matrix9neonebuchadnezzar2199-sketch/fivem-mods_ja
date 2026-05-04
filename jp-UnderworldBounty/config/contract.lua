-- 情報屋契約（5ロケから1箇所指定・ナビ・現地ギミック→ヤクザ戦闘）
-- 情報屋の座標は運営がゲーム内で調整すること（近接トリガーは coords + radius）。

Config.ContractInformant = {
  -- 情報屋ペッドのモデル
  model = `s_m_m_movspace_01`,
  -- 座標と向き（heading は度）
  coords = vector4(-656.0, -778.0, 25.2, 95.0),
  -- 会話・受注・キャンセル用トリガー半径
  radius = 2.2,
}

-- 受注後、現地で E を押してギミックを開始できる半径
Config.ContractSiteRadius = 2.5

-- 現地までの猶予（秒）。0 なら無制限。
Config.ContractTravelDeadlineSec = 0

-- 契約シナリオID（config/scenarios.lua の enemies_relative シナリオと一致させる）
Config.ContractScenarioId = 'scenario_yakuza_contract'

-- ギミック失敗・戦闘中に倒されたときに付ける闇の指名手配パターン
Config.ContractBountyPatternId = 'dark'

-- 契約現場（jp-slot で測定した5箇所）
Config.ContractSites = {
  {
    id = 'contract_site_1',
    label_key = 'contract_site_label_1',
    coords = vector3(-691.76, -810.13, 24.01),
    heading = 37.38,
  },
  {
    id = 'contract_site_2',
    label_key = 'contract_site_label_2',
    coords = vector3(-761.88, -617.88, 30.47),
    heading = 105.06,
  },
  {
    id = 'contract_site_3',
    label_key = 'contract_site_label_3',
    coords = vector3(-675.98, -885.18, 24.46),
    heading = 281.31,
  },
  {
    id = 'contract_site_4',
    label_key = 'contract_site_label_4',
    coords = vector3(-604.55, -704.75, 31.24),
    heading = 217.88,
  },
  {
    id = 'contract_site_5',
    label_key = 'contract_site_label_5',
    coords = vector3(-545.87, -873.54, 27.20),
    heading = 29.30,
  },
}
