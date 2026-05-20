# Bulk Japanese labels for shared/config.lua
$path = Join-Path $PSScriptRoot '..\shared\config.lua'
$content = Get-Content -Path $path -Raw -Encoding UTF8

$map = @{
    'name   = ''Trucker Job''' = 'name   = ''トラック運転手'''
    'header = "Complete One Mission !"' = 'header = "ミッションを1件完了"'
    'label = "Complete at least one mission on National T&S."' = 'label = "国立転送・保管（NTS）でミッションを1件以上完了する。"'
    'header = "Complete One Special Delivery!"' = 'header = "特別配送を1件完了"'
    'label = "Earn one companies trust and deliver 1 special delivery!"' = 'label = "企業の信頼を1つ獲得し、特別配送を1件届ける。"'
    'header = "On The Roads !"' = 'header = "路上で働く"'
    'label = "Transport goods for 30 minutes in one day."' = 'label = "1日のうちに合計30分間、貨物を輸送する。"'
    'label = "Packer"' = 'label = "パッカー"'
    'label = "Hauler"' = 'label = "ホーラー"'
    'label = "Phantom Classic"' = 'label = "ファントム・クラシック"'
    'label = "Armored Mule"' = 'label = "装甲ミュール"'
    'label = "Phantom"' = 'label = "ファントム"'
    'label = "Benson"' = 'label = "ベンソン"'
    'label = "Pounder Armored"' = 'label = "装甲パウンダー"'
    'label = "Bison"' = 'label = "バイソン"'
    'label = "Terbyte"' = 'label = "テラバイト"'
    'desc  = "This vehicle is needed for a mission"' = 'desc  = "特定ミッションで必要な車両です"'
    'header = "Paleto Forest Samwill Woods"' = 'header = "パレト森林・サムウィル木材"'
    'header = "Fame Or Shame TV Stuffs"' = 'header = "Fame or Shame テレビ機材"'
    'header = "Paleto Bay Tobaccos"' = 'header = "パレトベイ・タバコ"'
    'header = "Grapeseed Tobaccos"' = 'header = "グレープシード・タバコ"'
    'header = "Grapeseed Grains"' = 'header = "グレープシード・穀物"'
    'header = "Grapeseed Grapes"' = 'header = "グレープシード・ぶどう"'
    'header = "LS Dock Luxury Vehicle Shipment"' = 'header = "LSドック・高級車輸送"'
    'header = "LSA Special Vehicle Shipment"' = 'header = "LSA 特殊車両輸送"'
    'header = "iComputers Shipment"' = 'header = "iComputers 出荷"'
    'header = "Life Invader Chip Cargo"' = 'header = "Lifeinvader チップ貨物"'
    'header = "Paleto Bay Oil Cargo"' = 'header = "パレトベイ・石油貨物"'
    'header = "Murrieta Oil Field Transport"' = 'header = "ムリエタ油田・石油輸送"'
    'header = "MWS Army Tank Transport"' = 'header = "MWS 軍用戦車輸送"'
    'header = "USAF Special Satellite Cargo"' = 'header = "USAF 特殊衛星貨物"'
    'header = "You Tool Furniture Shipment"' = 'header = "You Tool 家具輸送"'
    'header = "You Tool Special Cargo"' = 'header = "You Tool 特殊貨物"'
    'label = "Wood Supply"' = 'label = "木材輸送"'
    'label = "Bale Supply"' = 'label = "梱包資材輸送"'
    'label = "Packed Cigar Supply"' = 'label = "葉巻梱包品"'
    'label = "Packed Tobacco Supply"' = 'label = "タバコ梱包品"'
    'label = "Food Supply"' = 'label = "食品輸送"'
    'label = "Vehicle Transport"' = 'label = "車両輸送"'
    'label = "Computer Transport"' = 'label = "PC輸送"'
    'label = "Chip Delivery"' = 'label = "チップ配送"'
    'label = "Oil Delivery"' = 'label = "石油配送"'
    'label = "Oil Transport"' = 'label = "石油輸送"'
    'label = "Tank Transport"' = 'label = "戦車輸送"'
    'label = "Military Cargo"' = 'label = "軍需物資"'
    'label = "$2,500 Profit"' = 'label = "報酬 $2,500"'
    'label = "$4,500 Profit"' = 'label = "報酬 $4,500"'
    'label = "$5,500 Profit"' = 'label = "報酬 $5,500"'
    'label = "$7,500 Profit"' = 'label = "報酬 $7,500"'
    'label = "$10,500 Profit"' = 'label = "報酬 $10,500"'
    'label = "$14,500 Profit"' = 'label = "報酬 $14,500"'
    'label = "$15,000 Profit"' = 'label = "報酬 $15,000"'
    'label = "$20,000 Profit"' = 'label = "報酬 $20,000"'
    'label = "$25,000 Profit"' = 'label = "報酬 $25,000"'
    'label = "$30,000 Profit"' = 'label = "報酬 $30,000"'
    'label = "$35,000 Profit"' = 'label = "報酬 $35,000"'
    'label = "$50,000 Profit"' = 'label = "報酬 $50,000"'
    'label = "$65,000 Profit"' = 'label = "報酬 $65,000"'
    'label = "$80,000 Profit"' = 'label = "報酬 $80,000"'
    'label = "1 Different Route"' = 'label = "異なるルート 1本"'
    'label = "2 Different Route"' = 'label = "異なるルート 2本"'
    'label = "3 Different Route"' = 'label = "異なるルート 3本"'
    'label = "+1 Company Trust"' = 'label = "企業信頼 +1"'
    "label = 'LS Dock - Paleto Route'" = "label = 'LSドック → パレト'"
    "label = 'Grapeseed - Paleto Route'" = "label = 'グレープシード → パレト'"
    "label = 'Factory - Paleto Route'" = "label = '工場 → パレト'"
    "label = 'LS Dock - Richard Majestic Route'" = "label = 'LSドック → リチャード・マジェスティック'"
    "label = 'Richards Majestic - Galileo Observotory Route'" = "label = 'リチャード・マジェスティック → ガリレオ天文台'"
    "label = 'LS Dock - Paleto Bay Route'" = "label = 'LSドック → パレトベイ'"
    "label = 'Paleto Bay - Elysian Island Route'" = "label = 'パレトベイ → エリシアン島'"
    "label = 'LS Dock - Grapeseed Route'" = "label = 'LSドック → グレープシード'"
    "label = 'Grapeseed - Elysian Island Route'" = "label = 'グレープシード → エリシアン島'"
    "label = 'Grapeseed - Paleto Bay Route'" = "label = 'グレープシード → パレトベイ'"
    "label = 'LS Dock - Strawberry Route'" = "label = 'LSドック → ストロベリー'"
    "label = 'Strawberry - LS Airport Int.'" = "label = 'ストロベリー → LS空港'"
    "label = 'Richman - LS Airport Int. Route'" = "label = 'リッチマン → LS空港'"
    "label = 'Richman - Banham Canyon'" = "label = 'リッチマン → バンハム・キャニオン'"
    "label = 'Tonga Hills - Vespucci Beachs'" = "label = 'トンガ・ヒルズ → ヴェスプッチ・ビーチ'"
    "label = 'LS Dock - Humane Labs'" = "label = 'LSドック → ヒューメイン・ラボ'"
    "label = 'LS Dock - Pacific Bluffs'" = "label = 'LSドック → パシフィック・ブリュフ'"
    "label = 'LS Dock - Pacific Bluffs - 2'" = "label = 'LSドック → パシフィック・ブリュフ 2'"
    "label = 'LS Dock - Rockford Hills '" = "label = 'LSドック → ロックフォード・ヒルズ'"
    "label = 'LS Dock - Galileo Parks'" = "label = 'LSドック → ガリレオ公園'"
    "label = 'Elysian Island - Paleto Bay'" = "label = 'エリシアン島 → パレトベイ'"
    "label = 'Paleto Bay - Elysian Island'" = "label = 'パレトベイ → エリシアン島'"
    "label = 'El Burro Heights - Paleto Bay'" = "label = 'エル・ブロ・ハイツ → パレトベイ'"
    "label = 'El Burro Heights - Greenwich'" = "label = 'エル・ブロ・ハイツ → グリニッジ'"
    "label = 'El Burro Heights - Route 68'" = "label = 'エル・ブロ・ハイツ → ルート68'"
    "label = 'LSI Airport - Fort Zancudo'" = "label = 'LSI空港 → ザンクード要塞'"
    "label = 'Fort Zancudo - Grand Senora Desert'" = "label = 'ザンクード要塞 → グランド・セノーラ砂漠'"
    "label = 'Fort Zancudo - Elysian Island'" = "label = 'ザンクード要塞 → エリシアン島'"
    "label = 'Elysian Island'" = "label = 'エリシアン島'"
    "label = 'LS Dock - You Tool Base'" = "label = 'LSドック → You Tool 拠点'"
    "label = 'Terminal - You Tool Base'" = "label = 'ターミナル → You Tool 拠点'"
    "label = 'LS Dock - You Tool - Elysian Island'" = "label = 'LSドック → You Tool → エリシアン島'"
    "label = 'LS Dock - You Tool - Elysian Island 2'" = "label = 'LSドック → You Tool → エリシアン島 2'"
}

foreach ($pair in $map.GetEnumerator()) {
    $content = $content.Replace($pair.Key, $pair.Value)
}

Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline
Write-Host "Applied $($map.Count) replacements to config.lua"
