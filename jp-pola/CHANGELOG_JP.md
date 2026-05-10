# CHANGELOG（日本語版）

バージョン規則: **オリジナル版番＋ `-jp.N`**（[CONTRIBUTING_JP.md §5](../CONTRIBUTING_JP.md)）。

## 1.1.0-jp.2 — 2026-05-10

### 修正・追加

- **Discord Webhook 撮影**: `screenshot-basic` の `requestScreenshotUpload` に **`encoding = 'png'`** を渡す（原作は Fivemerr 側のみ指定しており、Discord 側で `internal network error`（40333）になることがあった）。
- **ox_lib 警告**: `locales/en.json` / `locales/ja.json` を空オブジェクト `{}` で同梱し `files` に列挙（`@ox_lib/init.lua` を誤って足した環境での `could not load 'locales/ja.json'` を防止）。
- `Config.Debug` のリポジトリ既定を `false` に戻す。

## 1.1.0-jp.1 — 2026-05-10

オリジナル `1.1.0`（Project Sloth Team）をベースに完全日本語化。

### 変更点

#### 翻訳

- NUI（`client/nui/index.html` / `main.css`）
  - タイトル `PS Camera` → `jp-pola — 写真撮影`
  - `Location` / `Unknown` / `URL coppied to clipboard!`（typo） → 日本語化
  - フラッシュ HUD `ON / OFF` → `オン / オフ`
  - REC HUD → `録画`
  - `lang="en"` → `lang="ja"`
- サーバー（`server/sv_main.lua`）
  - プレイヤー通知（`Cheater Detected` / `Can not carry photo!` / `U don't have a camera`）を日本語化
  - コンソールエラー（`^1[Error] ...`）を日本語化
- 通知文言は `locales/ja.lua` に集約

#### 整備（運用品質向上）

- `fxmanifest`
  - `fx_version 'adamant'` → `'cerulean'`
  - `dependencies { 'qb-core', 'screenshot-basic' }` を明示
  - `description` 日本語化、`version` を `1.1.0-jp.1` へ
  - `author` は原作者を残しつつ JP fork を明記
- `server/sv_main.lua`
  - Webhook / Fivemerr トークンを **convar** から読めるように
    - `set jp-pola_webhook "..."`
    - `set jp-pola_fivemerr_token "..."`
  - 既存の `SvConfig.webhook` / `SvConfig.FivemerrApiToken` 直書きも後方互換で有効
  - `local source = source` を `local src = source` に統一（`fivem-server-authority` 準拠）
- `client/cl_main.lua`
  - `print("Player Cheating")` を `Config.Debug` ガード ＋ リソース名タグ
  - `onResourceStop` でカメラ／写真プロップ・NUI フォーカス・タイムサイクル・スクリプトカメラを必ず復元
- `config.lua` に日本語コメントと `Config.Debug` を追加（既存値は維持）

### 変更していないところ（互換維持）

- イベント名（`ps-camera:*`）
- アイテム名（`camera` / `photo`）
- ゲームロジック（撮影フロー・ズーム・フラッシュの挙動）
- アセット（`stream/ps_camera.ydr` / `.ytyp`、`images/*.png`）
- カメラ装飾 HUD の英数字（`FULL HD`、`60 FPS`、`ISO200`、`1/250`、`1X ZOOM`、`69%`）
