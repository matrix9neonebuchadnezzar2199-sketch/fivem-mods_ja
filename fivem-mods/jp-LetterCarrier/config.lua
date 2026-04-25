-- jp-LetterCarrier shared configuration
Config = {}

-- Reward settings
Config.RewardPerDelivery = 500
Config.CompletionBonus5 = 1500
Config.CompletionBonus10 = 4000
Config.CompletionBonus20 = 10000

-- Depot settings
Config.DepotLocation = vector3(67.11, -1560.28, 29.6)
Config.DepotBlipSprite = 478
Config.DepotBlipColor = 5
Config.DepotBlipScale = 0.8

-- NPC order desk (talk to open menu)
Config.JobPedModel = 'a_m_m_business_01'
Config.JobPedCoords = vector4(132.63, -1085.65, 29.19, 315.54)
Config.JobPedScenario = 'WORLD_HUMAN_CLIPBOARD'

-- Delivery vehicle (small white truck/van)
Config.DeliveryVehicleModel = 'speedo'
Config.DeliveryVehicleSpawnOffset = vector3(4.0, 0.0, 0.0) -- relative to player at accept

-- Action timings (seconds)
Config.PickupDuration = 5
Config.DeliveryDuration = 3

-- NUI open command (kept for fallback)
Config.OpenCommand = 'delivery'

-- Interaction radius (meters)
Config.InteractRadius = 2.0

-- Delivery points (md-houserobberies based, south LS focused subset)
Config.DeliveryLocations = {
    vector3(1205.43, -1607.35, 50.73),
    vector3(-148.33, -1687.37, 33.07),
    vector3(-141.46, -1693.5, 33.07),
    vector3(1354.88, -1690.66, 60.49),
    vector3(1314.58, -1733.31, 54.7),
    vector3(1259.21, -1761.91, 49.66),
    vector3(1378.98, -1515.01, 58.44),
    vector3(1261.47, -1616.86, 54.74),
    vector3(1245.37, -1626.89, 53.28),
    vector3(250.15, -1730.73, 29.67),
    vector3(258.66, -1927.04, 25.12),
    vector3(270.59, -1916.81, 25.08),
    vector3(282.97, -1899.44, 26.96),
    vector3(320.34, -1854.47, 26.83),
    vector3(329.42, -1846.29, 27.45),
    vector3(257.78, -1722.6, 29.2),
    vector3(269.69, -1712.85, 28.67),
    vector3(282, -1694.8, 28.65),
    vector3(252.74, -1670.72, 28.66),
    vector3(240.73, -1687.76, 29.7),
    vector3(222.62, -1702.43, 29.7),
    vector3(216.65, -1717.66, 29.68),
    vector3(197.7, -1725.79, 29.66),
    vector3(152.6, -1823.97, 27.87),
    vector3(130.7, -1853.25, 25.23),
    vector3(103.85, -1885.25, 24.32),
    vector3(115.4, -1888.05, 23.93),
    vector3(128.09, -1897.27, 23.67),
    vector3(148.74, -1904.47, 23.53),
    vector3(192.21, -1883.2, 25.05),
    vector3(171.48, -1871.64, 24.4),
    vector3(150.12, -1864.81, 24.59),
    vector3(250.8, -1935.04, 24.7),
    vector3(367.54, -1802.25, 29.06),
    vector3(-1182.78, -1064.47, 2.15),
    vector3(-1200.48, -1031.98, 2.15),
    vector3(-1151.61, -990.5, 2.15),
    vector3(-1103.24, -1014.51, 2.54),
    vector3(-1130.28, -1031.6, 2.15),
    vector3(-1127.58, -1081.48, 4.22),
    vector3(-1034.6, -1147.07, 2.15),
    vector3(-1063.65, -1160.25, 2.74),
    vector3(-1082.55, -1631.18, 4.74),
    vector3(-1097.58, -1673.16, 8.39),
    vector3(-1118.44, -1619, 4.4),
    vector3(-1112.34, -1578.4, 8.68),
    vector3(-1072.2, -1565.82, 4.37),
    vector3(965.13, -542.03, 59.72),
    vector3(1009.67, -572.42, 60.59),
    vector3(1223.11, -697.04, 60.8),
    vector3(1207.31, -620.33, 66.43),
    vector3(100.93, -1912.1, 21.4),
    vector3(56.53, -1922.68, 21.91),
    vector3(46, -1864.2, 23.27),
    vector3(-4.82, -1872.22, 24.15),
    vector3(-34.44, -1847.35, 26.19),
    vector3(1006.4, -510.83, 60.99),
    vector3(1046.38, -498.17, 64.28),
    vector3(1051.09, -470.33, 64.3),
    vector3(1056.16, -448.9, 66.26),
    vector3(1101.08, -411.05, 67.56),
    vector3(1114.51, -391.14, 68.95),
    vector3(1328.8, -535.62, 72.44),
    vector3(1373.17, -555.87, 74.69),
    vector3(1367.38, -606.63, 74.71),
    vector3(1341.29, -597.47, 74.7),
    vector3(1323.56, -583.24, 73.25),
    vector3(-499.56, 181.39, 83.17),
    vector3(-484.15, 198.84, 83.16),
    vector3(-471.58, 184.52, 83.17),
    vector3(-431.94, 83.63, 68.51),
    vector3(-362.18, 57.54, 54.43),
    vector3(-332.74, 57.04, 54.43),
    vector3(-370.96, 23.07, 47.86),
    vector3(-345.36, 17.94, 47.86),
    vector3(-186.27, 65.95, 67.87),
    vector3(-142.79, 62.11, 70.84),
    vector3(-165.75, 75.31, 70.7),
    vector3(-188.23, 88.28, 69.92),
    vector3(280.49, 32.43, 88.61),
}
