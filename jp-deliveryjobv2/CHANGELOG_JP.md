# 日本語化版 変更履歴

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
