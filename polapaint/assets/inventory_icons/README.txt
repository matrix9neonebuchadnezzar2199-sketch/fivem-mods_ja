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

【本番への反映（どちらか）】
A. **推奨**: `polapaint/html/images/` に同名 PNG を置き（リポでは `assets` からコピー済み）、`items.lua` の `client.image` を  
   `nui://polapaint/html/images/polaroid_camera.png`（写真は `polaroid_photo.png`）にする → **ox 側へのコピー不要**。
B. 従来どおり: 上記 PNG を `ox_inventory/web/images/` へコピーし、`image = 'polaroid_camera'` のように拡張子なしベース名で指定する。

※ `assets/inventory_icons/` は差し替え・生成用の置き場。実行時は `html/images/` か ox の `web/images/` が参照先になります。
