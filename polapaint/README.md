# polapaint

ポラロイド風カメラ・写真のローカル保存・署名付き HTTP 配信・NUI による閲覧／ペイント編集。**ESX / QBCore 非依存**のスタンドアロンリソースです。

本フォルダは [fivem-mods（JP-Mods）](../README.md) **モノレポの一部**として保守されています。**`polapaint` だけを `resources` に置いて `ensure polapaint` する**運用で問題ありません。

| | |
| --- | --- |
| **FiveM** | `fx_version cerulean` · `lua54 'yes'` |
| **作者** | JP-Mods（`fxmanifest.lua` の `author`） |
| **版** | `fxmanifest.lua` の `version` を参照 |
| **ライセンス** | **GPL-3.0-or-later**（このフォルダの [`LICENSE`](LICENSE)。モノレポルートの [`LICENSE`](../LICENSE) は **MIT** で別） |
| **ソース** | GitHub リポジトリ [`fivem-mods_ja`](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja) 内の **`polapaint/`** |

---

## 目次

- [モノレポでの位置づけ](#モノレポでの位置づけ)
- [概要](#概要)
- [要件](#要件)
- [インストール](#インストール)
- [設定リファレンス（`config.lua`）](#設定リファレンスconfiglua)
- [インベントリアイテム（命名と画像ファイル）](#インベントリアイテム命名と画像ファイル)
- [プレイヤー視点の動き](#プレイヤー視点の動き)
- [技術フロー（データ経路）](#技術フローデータ経路)
- [HTTP・署名・他リソースとの共存](#http署名他リソースとの共存)
- [Discord Webhook・公開 URL](#discord-webhook公開-url)
- [運用・バックアップ](#運用バックアップ)
- [トラブルシュート](#トラブルシュート)
- [ライセンス](#ライセンス)

---

## モノレポでの位置づけ

| 項目 | 内容 |
| --- | --- |
| **入手** | リポジトリ全体を clone するか、**`polapaint` ディレクトリのみ**をサーバーの `resources` にコピーする。 |
| **親 README** | 収録一覧・共通トラブルシュートは [ルート `README.md`](../README.md)。 |
| **開発ルール** | [`AGENTS.md`](../AGENTS.md)（イベント名・開発日記）、[`docs/STYLEGUIDE.md`](../docs/STYLEGUIDE.md)（UTF-8 **BOM 禁止** 等）。 |

---

## 概要

- **撮影（カメラアイテム）**: クライアントで画面キャプチャ → 名前入力 → サーバーへ JPEG を転送し、`data/photos/` に保存。インベントリに「写真アイテム」を **1 枚追加**（メタデータに表示名・画像 URL の参照が載る）。
- **編集（写真アイテム USE）**: サーバーが短期トークンを発行し、NUI でペイント。**保存時は新しいファイル ID に保存し、同一スロットのメタデータ URL を差し替え**。
- **閲覧（ox_inventory のボタン等）**: `openPhotoViewer` でビューワのみ（編集トークンは不要）。
- **画像配信**: `SetHttpHandler` の **GET のみ**（`/photo/<signed>.jpg`）。アップロードは **NUI の HTTP POST ではなく** `RegisterNUICallback` → `TriggerLatentServerEvent`（大容量 JPEG 対応）。

---

## 要件

| 依存 | 役割 |
| --- | --- |
| **[screenshot-basic](https://github.com/citizenfx/screenshot-basic)** | 撮影時の JPEG（data URI）取得。**`fxmanifest` の `dependencies` に含める。** |
| **[ox_lib](https://github.com/overextended/ox_lib)** | 撮影後の名前入力 `lib.inputDialog`。 |
| **ox_inventory** または **qb-core / qb-inventory** | アイテムの付与・メタデータ更新。`Config.Framework = 'auto'` で自動判定。 |

Lua は **5.4**（`lua54 'yes'`）。

---

## インストール

1. 本フォルダを `resources` 配下に配置（例: `[jp-mods]/polapaint`）。
2. **`server.cfg`** に `ensure polapaint` を追加。
3. **依存リソース**を先に起動する（例）:

   ```
   ensure screenshot-basic
   ensure ox_lib
   ensure ox_inventory
   ensure polapaint
   ```

   `Config.Framework = 'auto'` で ox が認識されない場合は、**`ensure ox_inventory` が `ensure polapaint` より前**にあるか確認してください。

4. **インベントリ定義**にカメラ・写真アイテムを追加（次節・[`snippets/ox_inventory_items.lua.example`](snippets/ox_inventory_items.lua.example)）。
5. （任意）[`server.cfg` の Webhook](#discord-webhook公開-url)。

リソース名は **`fxmanifest` のフォルダ名**そのままが HTTP パスに使われます（例: `https://<endpoint>/<resourceName>/photo/...`）。

---

## 設定リファレンス（`config.lua`）

運営が触るのは主にこのファイルです。**文字コードは UTF-8（BOM なし）**を推奨します。

### 言語・フレームワーク

| キー | 説明 |
| --- | --- |
| `Config.Locale` | `'ja'` / `'en'`（`locales/*.lua`）。 |
| `Config.Framework` | `'ox'` · `'qb'` · `'auto'`（自動判定。**推奨は `auto`**）。 |

### アイテム名（items の「キー」と一致させる）

| キー | 既定値 | 意味 |
| --- | --- | --- |
| `Config.Items.camera` | `polaroid_camera` | 撮影に使うアイテムの **items.lua のキー**。 |
| `Config.Items.photo` | `polaroid_photo` | 保存される写真アイテムの **items.lua のキー**。 |

ここを変えたら **ox / QB の items 定義側のキーも同じ文字列**にしてください（後述の「命名と画像」）。

### 撮影・編集の数値

| キー | 既定 | 説明 |
| --- | --- | --- |
| `Config.MaxImageWidth` | `2560` | 仕様上の最大幅（px）。実装の参照用。 |
| `Config.JpegQuality` | `0.85` | screenshot-basic への JPEG 品質。 |
| `Config.MaxPhotoNameLength` | `40` | 撮影時の写真名。**UTF-8 グラフェムクラスタ単位**（制御文字は不可）。 |
| `Config.CaptureCooldownSec` | `4` | 連続撮影のクールダウン（秒）。 |
| `Config.EditSaveCooldownSec` | `3` | 編集保存のクールダウン（秒）。 |
| `Config.CaptureSessionTTLSec` | `30` | （将来互換）撮影セッション TTL の記載値。 |
| `Config.EditSessionTTLSec` | `120` | 編集トークンの有効時間（秒）。超えると保存は拒否。 |

### ストレージ（`Config.Storage`）

| キー | 説明 |
| --- | --- |
| `httpRoute` | 公開パスのサフィックス（通常 `/photo/` のまま）。 |
| `maxBytes` | 保存許容の画像サイズ（バイト）。base64 転送時は概ね **この値の 1.4 倍 + 余裕**までクライアント送信を許可。 |
| `retentionSec` | `0` で無効。`0` より大きいと起動時に古い `jpg` を削除する用途（運用ポリシーに合わせて設定）。 |

ディスク上の配置は **`data/photos/<2桁シャード>/<id>.jpg`** を優先し、環境によってシャード書き込みが失敗した場合は **`data/photos/<id>.jpg`** にフォールバックします。

### Webhook（`Config.Webhook`）

| キー | 説明 |
| --- | --- |
| `enabled` | `false` で Discord 通知を止める。 |
| `convarName` | 既定 `'polapaint_webhook'`。実際の URL は **`server.cfg` で `set`**（後述）。 |
| `username` | Webhook 投稿の表示名。 |
| `publicBaseUrl` | 埋め込み画像に使う **外向き URL のベース**。空ならテキスト中心の通知（ゲーム内 NUI の表示には不要）。 |

### その他

| キー | 説明 |
| --- | --- |
| `Config.HttpToken` | HTTP 経路の簡易認可。`enabled = false` は「署名 URL のみで緩い公開」に近い挙動（閉じたサーバ向け）。 |
| `Config.Debug` | `true` でサーバーに詳細ログ。本番では通常 `false`。 |

---

## インベントリアイテム（命名と画像ファイル）

### 「キー」「label」「画像ファイル名」は別物

ox_inventory の items は次のように役割が分かれます。

| 項目 | 例 | 役割 |
| --- | --- | --- |
| **テーブルキー** | `['polaroid_photo']` | **`Config.Items.photo` と完全一致**させる。ここがズレると付与失敗や「未定義」扱いになる。 |
| **`label`** | `'ポラロイド写真'` | インベントリ UI に表示される名前。**Config とは連動しない**（任意の日本語でよい）。 |
| **`client.image`** | `'polaroid_photo.png'` | ox_inventory が参照する **インベントリ用アイコン画像のファイル名**。通常 **`ox_inventory/web/images/`** に配置（運営の ox の作法に従う）。 |

本リソースの `html/images/` に同梱している **`polaroid_camera.png` / `polaroid_photo.png`** は **NUI 用・サンプル用**です。運営環境では ox の画像フォルダへコピーし、`client.image` のファイル名と揃えるとよいです。

### エクスポート名（変更しない）

スニペットでは次の **文字列は固定**です（`fxmanifest` のリソース名が `polapaint` の場合）。

- カメラ: `export = 'polapaint.useCamera'`
- 写真: `export = 'polapaint.usePhoto'`

リソース名をフォークで変える場合は **`fxmanifest` のフォルダ名／ensure 名**とあわせて export も変わるため、items の `export` を同期してください。

### ox_inventory スニペットの動き

[`snippets/ox_inventory_items.lua.example`](snippets/ox_inventory_items.lua.example)

- **`polaroid_camera`**: USE → 撮影フロー。
- **`polaroid_photo`**: USE → **ペイント編集**。コンテキストメニューの **「閲覧」** → `openPhotoViewer`（閲覧のみ）。

---

## プレイヤー視点の動き

| 操作 | 結果 |
| --- | --- |
| **カメラ USE** | 撮影 → 名前入力 → サーバー保存 → **写真アイテムが 1 枚入る**（カメラ所持が条件のチェックあり）。 |
| **写真 USE** | **編集 NUI**（サーバーが短期トークン発行）。保存で上書き保存。 |
| **写真「閲覧」ボタン**（ox） | **ビューワのみ**。編集保存はしない。 |
| **ESC**（NUI 表示中） | 編集／閲覧 UI を閉じる（実装依存でポーリング）。 |

---

## 技術フロー（データ経路）

### 撮影

1. `screenshot-basic` が JPEG の data URI を返す。
2. `lib.inputDialog` で写真名を入力。
3. **`TriggerLatentServerEvent('polapaint:server:uploadCapture', …)`** で base64 を送信（大きい画像は通常の `TriggerServerEvent` では欠けることがあるため）。
4. サーバーがデコード・保存・`givePhoto`。メタデータに `polapaint://photo/<signed>` 形式の URL とラベルを格納。

### 編集

1. **`polapaint:server:requestEdit`** でスロット検証 → `pendingEdit` にトークン。
2. **`polapaint:client:openPaint`** で NUI。画像 URL はクライアントで `https://<resource>/photo/<signed>.jpg` に解決。
3. 保存は **`savePaint` NUI コールバック** → **`TriggerLatentServerEvent('polapaint:server:uploadEdit', …)`**。
4. 新しいファイルを保存し、**同一スロットの metadata.url を更新**。

### 画像の読み出し

- NUI / CEF は **`GetParentResourceName()` ベースの HTTPS URL** で JPEG を GET する。
- サーバーは **`SetHttpHandler`** で **`GET .../photo/<signed>.jpg`** のみ処理（POST アップロードは使わない）。

---

## HTTP・署名・他リソースとの共存

- FiveM では **`SetHttpHandler` はリソースごとに 1 つ**。ルーティングは **URL 先頭のリソース名**で分かれるため、`screenshot-basic` のパスと **衝突しません**。
- 公開 URL の形: **`https://<サーバエンドポイント>/<resourceName>/photo/<signed>.jpg`**（`<signed>` はストレージ層が検証）。

---

## Discord Webhook・公開 URL

### Convar（シークレットを config に書かない）

`server.cfg`:

```
set polapaint_webhook "https://discord.com/api/webhooks/..."
```

空のままなら（または `Config.Webhook.enabled = false` で）通知無効。

### `publicBaseUrl`

Discord の埋め込み画像は **Discord のサーバーが取得できる URL** である必要があります。プライベート IP だけでは埋め込み画像は表示されません。**ゲーム内で写真を見るだけ**なら `publicBaseUrl` は空で問題ありません。

末尾スラッシュ・パス構成の注意は実装どおり次のとおりです。

| `publicBaseUrl` の例 | 組み立て後のイメージ |
| --- | --- |
| `https://photos.example.com/polapaint` | `https://photos.example.com/polapaint/photo/<signed>.jpg` ✓ |
| `https://photos.example.com/polapaint/` | 末尾スラッシュはコード側で除去 ✓ |
| `https://photos.example.com/` | リソースパスがずれやすい ✗ |
| `https://photos.example.com/photo` | `/photo/photo/...` になりやすい ✗ |

リバースプロキシ例:

```nginx
location /polapaint/ {
    proxy_pass http://127.0.0.1:30120/polapaint/;
    proxy_set_header Host $host;
}
```

（ポート・upstream は環境に合わせて変更）

---

## 運用・バックアップ

1. **バックアップ対象**: リソース直下の **`data/photos/`** を丸ごと（シャード配下 + フラットフォールバック両方）。
2. **マルチノード / LB**: ディスクが共有されないため、オブジェクトストレージ等への差し替えが必要な場合は `server/storage.lua` を参照・置換。
3. **`polapaint_old/`** は旧版アーカイブ用。`fxmanifest` が無効化されていれば **ensure 対象にしない**こと。

---

## トラブルシュート

| 現象 | 確認すること |
| --- | --- |
| **写真アイテム未定義／付与失敗** | `items.lua` のキーが **`Config.Items.photo` と同一か**（既定は `polaroid_photo`）。追加後 **`refresh ox_inventory`** または再起動。 |
| **撮影できない** | `screenshot-basic` と `ox_lib` が **started** か、`dependencies` 順序。 |
| **キック／AFK** | 名前入力・NUI 中は無操作扱いになりやすい。polapaint は **`state.polapaint_busy`** を約 500ms ごと更新するので、AFK リソース側で **`Player(source).state.polapaint_busy`** を参照して除外できる。 |
| **編集がセッション期限切れ** | `Config.EditSessionTTLSec` を延ばす、または素早く保存。 |

### QBCore（qb-inventory）

ox のような標準 **「閲覧」ボタンが無い**ため、素の QB だけではチェキ風ビューワの導線が限定されます。本リソースの QB 登録では **写真 USE → 編集**です。**閲覧だけ**必要な場合は `exports['polapaint']:openPhotoViewer(slot)` をコマンドや target から呼ぶ運用を検討してください。

---

## ライセンス

- **本リソース（`polapaint/`）** は **GPL-3.0-or-later**。全文は当フォルダの [`LICENSE`](LICENSE)。
- **モノレポルート** の [`LICENSE`](../LICENSE) は **MIT**（他フォルダ向け）。polapaint を配布・改変する際は **必ず `polapaint/LICENSE`** に従ってください。
