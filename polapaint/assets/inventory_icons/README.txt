polapaint — ox_inventory スロット用アイコン素材置き場

【画像生成プロンプト案】
- `IMAGE_PROMPTS.md`（AI 生成・外注用の日本語/英語プロンプト例）

【推奨仕様】
- サイズ: 128×128 px
- 形式: PNG
- 背景: 透過（なし）推奨

【ファイル名（config.lua の既定アイテム名と一致）】
- polaroid_camera.png … ポラロイドカメラ
- polaroid_photo.png … チェキ（写真）

【2026-05-10 追記・差し替え元】
- ユーザー素材 `VaciKjQ3.png` → `polaroid_camera.png` にリネーム済み
- ユーザー素材 `edfVWep8.png` → `polaroid_photo.png` にリネーム済み
スロットでカメラ／写真が逆に見える場合は、上記 2 ファイルの**中身を入れ替え**るか、ファイル名だけ交換してください。

アイテム名を config で変えた場合は、ここと同じベース名の PNG にリネームするか、items.lua の client.image を合わせてください。

【本番への反映】
1. 上記 PNG を ox_inventory の web/images/（環境によっては同様の画像フォルダ）へコピーする
2. data/items.lua 側では image は「拡張子なし」のベース名で書くのが一般的です（.png を二重に付けない）

※ このフォルダの画像は polapaint の NUI からは参照しません。インベントリ表示専用の保管・差し替え用です。
