# 日本語化版 変更履歴

## [2.1.2-jp] - 2026-05-05

### 配布構成（重要）

- **`jp-deliveryjobv2` をリソースのルートにフラット化**（`nek_deliveryjobV2/` サブフォルダを廃止）
- サーバーでは **`ensure jp-deliveryjobv2`**（フォルダ名＝リソース名）。`fxmanifest.lua` は `jp-deliveryjobv2/fxmanifest.lua`
- `exports['jp-deliveryjobv2']` に変更（旧: `exports['nek_deliveryjobV2']`）
- README / INSTALL を上記に合わせて全面更新

## [2.1.1-jp] - 2026-05-05

### ルート名・UI

- `Config['Delivery']['Routes']` を `{ name, stops }` 形式に拡張（NUI ヘッダに `配達ルート: 名称` を表示）
- 旧形式（`vec3` の配列のみ）は `NormalizeDeliveryRoutes()` で自動変換し後方互換を維持
- 既定のルート名を GTA V 地区表記に合わせて設定（ヴェスプッチビーチ周辺 / ロックフォード〜ダウンタウン / ヴァインウッドヒルズ）

### 文言・ドキュメント

- ロケール調整（不正検知、スポーン失敗時の行動指示、`error_starting` の具体化）
- `INSTALL.md` に QBCore ジョブ `payment` と `FinalPayout` の別建てである旨を追記

## [2.1.0-jp] - 2026-05-05

### 日本語化

- `config/config.lua` の全 `Locales` とコメントを日本語化（`blip_destination` を追加）
- `Data.sql` のジョブラベルを「配達員」に変更
- `html/index.html` / `html/script.js` の UI 文言を日本語化
- クライアント・サーバー Lua の主要コメントを日本語化（`client/job.lua` 含む）
- Discord Webhook のフィールド名・ユーザー名を日本語化
- バージョンチェッカーのコンソール文言を日本語化（プレフィックス `nek_deliveryV2_jp`）

### 改善

- `server/bridge.lua` に `getIdentifiers` を追加し、`server/utils.lua` の Webhook 用プレイヤー情報取得を動作可能にした
- Webhook の日付表記を `YYYY/MM/DD` 形式に変更
- `playerDropped` 処理で `source` をローカル変数に取り、可読性を上げた
- `fxmanifest.lua` の `author` / `description` / `version` を日本語版向けに更新

### ドキュメント

- `README.md` / `INSTALL.md` / `CHANGELOG_JP.md` を追加
- `LICENSE` に日本語メモ（ライセンス本文は英語 MIT のまま）を追記

### オリジナル v2.1 からのゲームロジック

- 配達フロー・コールバック名・依存リソースはオリジナル準拠（日本語化と Webhook 周りの修正のみ）
