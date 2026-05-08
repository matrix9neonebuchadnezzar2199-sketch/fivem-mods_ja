このフォルダの画像（128×128 想定）— 保管場所は本リソースの html/img（NUI では img/ 配下）

【各ファイルの意味（README・config と一致）】
- disc_128_tight.png … **空 DVD（dvd_blank）のみ**（素の白ディスク）
- dvd_case_128_tight.png … **不織布スリーブ**（dvd_recorded1）
- dvd_jewel_transparent_128.png … **クリアケース**（dvd_recorded2）
- dvd_case_text_transparent_128.png … **トールケース**（dvd_recorded3）。再生メニュー右のケース表示でも使用

差し替える場合は上記ファイル名を維持するか、html/script.js の img 参照・config.lua の Config.InventorySlotImage・ox_inventory の items.lua の image を揃えてください。

ox_inventory では同じ PNG を web/images/ 等にコピーし、items の image 名と一致させます。

※記録時に付く metadata.image は「拡張子なし」ベース名です（ox の Web UI が .png を自動付与するため、.png 付きだと表示されない）。
