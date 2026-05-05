Config = {}

-- 言語: "ja"（日本語） / "en"（英語） / "fr"（フランス語）
Config.Locale = "ja"

-- ドキュメントを開いたときにペッドシナリオを再生するか
Config.UseAnimation = false

-- フレームワーク: "auto", "esx", "qbcore", "qbox", "standalone"
Config.Framework = "auto"

-- インベントリ: "auto", "ox_inventory", "qb-inventory", "esx_inventory"
-- esx_inventory は標準 ESX インベントリ（metadata 非対応のため DB リンクで擬似対応）
Config.Inventory = "auto"

-- 用紙の再取得クールタイム（秒）
Config.PaperCooldown = 30

-- ox_target を優先するか（無効でも qb-target または [E] 距離フォールバックあり）
Config.UseOxTarget = true

-- ox_inventory / qb / ESX 側で登録するアイテム名（定義と一致させる）
-- 白紙は本 MOD が常に空メタ {} で配るため、ox_inventory の items.lua では **stack = true** 推奨（未使用同士がスタックする）。
-- document は docId 等でメタが個別のため **stack = false** のまま。
Config.Items = {
    blank = "paper_blank",
    document = "document",
}

-- 配布拠点（白紙の用紙）
Config.DistributionPoints = {
    {
        name = "市役所",
        coords = vector3(-544.7, -204.1, 40),
        heading = 210.5,
        usePed = true,
        pedModel = "s_m_m_postal_01",
        targetLabel = "白紙の用紙を受け取る",
        targetIcon = "fas fa-file-signature"
    },
    {
        name = "警察署",
        coords = vector3(440.953857, -980.228577, 31.925293),
        heading = 170.0,
        usePed = false,
        pedModel = "",
        targetLabel = "白紙の用紙を受け取る",
        targetIcon = "fas fa-clipboard"
    },
}

function T(key)
    return (Locale and Locale[key]) or ("[" .. tostring(key) .. "]")
end
