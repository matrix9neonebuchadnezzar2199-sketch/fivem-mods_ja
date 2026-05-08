Config = {}

-- ox_inventory のアイテム名（items.lua のキーと一致させる）
Config.BlankItem = 'dvd_blank'

--[[ 記録時に選ぶパッケージ種類（metadata.pack に保存される値）=> 付与するアイテム名 ]]
Config.RecordedByPack = {
    fushokufu = 'dvd_recorded1', -- 不織布スリーブ想定
    clear = 'dvd_recorded2', -- クリアケース
    tall = 'dvd_recorded3', -- トールケース（表紙 URL 任意）
}

--[[ ox_inventory のスロット画像用（metadata.image）。
     ★拡張子 .png は書かないこと。Web UI が自動で「値 + .png」として読むため、.png 付きだと二重になり画像が出ない。
     実ファイルは web/images/ に「値 + .png」で置く（例: dvd_case_128_tight.png）。 ]]
Config.InventorySlotImage = {
    fushokufu = 'dvd_case_128_tight',
    clear = 'dvd_jewel_transparent_128',
    tall = 'dvd_case_text_transparent_128',
}

-- 記録タイトルの最大文字数（UTF-8 文字単位でサーバー側でも検証）
Config.MaxTitleLength = 40

-- トールケースの表紙 URL（https）の最大バイト長
Config.MaxCoverUrlLength = 768
