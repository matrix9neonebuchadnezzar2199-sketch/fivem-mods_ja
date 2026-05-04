-- 情報屋契約（5ロケから1箇所指定・ナビ・現地ギミック→ヤクザ戦闘）
-- 情報屋の座標は運営がゲーム内で調整すること（近接トリガーは coords + radius）。

Config.ContractInformant = {
  -- 情報屋ペッドのモデル（s_m_m_movspace_01 は宇宙服のため非推奨。スーツ系など一般用を推奨）
  model = `a_m_m_business_01`,
  -- 座標と向き（heading は度）
  coords = vector4(399.85, 66.85, 97.98, 163.56),
  -- 会話・受注・キャンセル用トリガー半径
  radius = 2.2,
  -- スポーンZの手動微調整（足が浮く場合は負の小数、沈みすぎる場合は正）
  spawn_z_offset = 0.0,
  -- true のときだけ GetGroundZ で足元補正（ナビが実床より低いと埋まることがある）。jp-slot 測定を信頼するなら false 推奨。
  use_ground_snap = false,
}

-- 受注後、現地で E を押してギミックを開始できる半径
Config.ContractSiteRadius = 2.5

-- 現地までの猶予（秒）。0 なら無制限。
Config.ContractTravelDeadlineSec = 0

-- 契約シナリオID（config/scenarios.lua の enemies_relative シナリオと一致させる）
Config.ContractScenarioId = 'scenario_yakuza_contract'

-- ギミック失敗・戦闘中に倒されたときに付ける闇の指名手配パターン
Config.ContractBountyPatternId = 'dark'

-- 情報屋契約の再受注禁止時間（秒）。成功・失敗（指名付与）・NPC生成失敗で開始。キャンセルのみはカウントしない。
Config.ContractCooldownSec = 3600

-- 契約現場（測定した5箇所）
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
