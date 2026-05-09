PolaPaint — ox_inventory スロット用アイコン素材置き場

【推奨仕様】
- サイズ: 128×128 px
- 形式: PNG
- 背景: 透過（なし）推奨

【ファイル名（config.lua の既定アイテム名と一致）】
- polaroid_camera.png … ポラロイドカメラ
- polaroid_photo.png … チェキ（写真）

アイテム名を config で変えた場合は、ここと同じベース名の PNG にリネームするか、items.lua の client.image を合わせてください。

【本番への反映】
1. 上記 PNG を ox_inventory の web/images/（環境によっては同様の画像フォルダ）へコピーする
2. data/items.lua 側では image は「拡張子なし」のベース名で書くのが一般的です（.png を二重に付けない）

※ このフォルダの画像は PolaPaint の NUI からは参照しません。インベントリ表示専用の保管・差し替え用です。
