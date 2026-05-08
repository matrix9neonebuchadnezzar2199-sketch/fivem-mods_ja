<div align="center">

<img src="./docs/screenshots/03_match_detail.png" width="100%" alt="RefBoard Match Detail Screen" />

<p><em>サッカー試合管理を、シンプルに、安全に。</em></p>

<img src="./docs/logo.svg" width="120" alt="RefBoard logo" />

# RefBoard

**FiveM 向けオープンソースのサッカー試合管理ツール（改ざん防止履歴・編集ロック・日本語/英語 UI）**

[English](./README.en.md)

[![License: MIT](LICENSE)](LICENSE)

</div>

---

## 概要

RefBoard は、**審判（運営）**が試合スコア・経過・メンバーを **MySQL 上に権威付きで記録**するための NUI ツールです。複数クライアント間で状態を共有し、**単一編集ロック**と **append-only のスコア履歴** を前提に設計されています。

- **リソースフォルダ名**: `RefBoard`（`ensure RefBoard`）
- **依存**: [oxmysql](https://github.com/overextended/oxmysql)
- **編集モード**: `config.lua` の `Config.EditPassword`（既定 `ref`）をランチャーで入力して入室。閲覧モードはパスワード不要。

## インストール

1. 本フォルダを `resources/[local]/RefBoard` などに配置。
2. **MySQL（必須・初回）**: **`server.cfg` の oxmysql 接続先と同じデータベース**（例: `fivem_db`）を選び、`sql/install.sql` を実行する。
   - 別名の DB にだけ流すと、`Table 'fivem_db.teams' doesn't exist` のように **接続先にはテーブルが無い**状態になる。
   - CLI の例: `mysql -u USER -p fivem_db < sql/install.sql`（`fivem_db` は接続文字列の DB 名に合わせる）
   - 開発時は続けて `sql/seed_dev_teams.sql` でサンプル2チーム投入を推奨。
   - **既存 DB**（install 済みの環境）: これまでのマイグレーションに続けて `sql/migration_004_team_roster.sql`（ロスター・エンブレム列）を適用。
   - **5チーム × ロスター15人**のテストデータ: 既定では **`Config.SeedDemoTeamsOnStart = true`** により **リソース起動時に自動実行**（`sql/seed_test_5teams_15roster.sql`）。本番で不要なら `config.lua` で **false** にし、必要時のみ CLI で `mysql ... < sql/seed_test_5teams_15roster.sql`。
3. `server.cfg` に `ensure oxmysql` のあと `ensure RefBoard`。
4. 審判用プレイヤーに `add_ace identifier.license:xxxxxxxx refboard.referee allow` 等を付与。

### よくあるエラー

- **`Table '…​.teams' doesn't exist` / `…​matches` / `…​editor_locks`**: 上記 **手順 2 を未実施**か **DB 名の取り違え**。`install.sql` を oxmysql が使っている DB で再実行する。

## 操作

- ゲーム内: **`/refboard`** または **`F6`**（`config.lua` の `Config.OpenKey`）で NUI を開閉。

## ドキュメント索引

### 設計・アーキテクチャ

| 文書 | 概要 |
|------|------|
| [docs/01_database.md](docs/01_database.md) | DB 方針・テーブル関係。DDL の正は `sql/install.sql` |
| [docs/02_server.md](docs/02_server.md) | FiveM サーバー Lua、`refboard:` NetEvent / ACK の流れ |
| [docs/03_frontend.md](docs/03_frontend.md) | Vue 3 / Vite / NUI、`useNui` とルーティング |
| [docs/04_design_mockup.md](docs/04_design_mockup.md) | 画面モック・情報設計のたたき台 |
| [docs/error_handling.md](docs/error_handling.md) | エラーコード（`ErrorCodes` / `MakeError`）、`RefboardGuard`、`Logger`、NUI 側の扱い |
| [docs/help_system_design.md](docs/help_system_design.md) | **v0.6.0 予定**: アプリ内ヘルプ（ツリー／逆引き／検索／コンテキスト `?`／Toast からエラー誘導）の設計 |

### テスト・品質

| 文書 | 概要 |
|------|------|
| [docs/testing/release_test_plan.md](docs/testing/release_test_plan.md) | リリース前の実機テスト計画（フェーズ・シナリオ） |
| [docs/testing/test_results.md](docs/testing/test_results.md) | テスト実行結果の記録用テンプレート |
| [docs/testing/known_issues.md](docs/testing/known_issues.md) | 既知の不具合・回避策の一覧 |
| [docs/testing/transaction_test.md](docs/testing/transaction_test.md) | DB トランザクション検証手順（`Config.EnableTestCommands` 連動） |

### スプリント記録（変更の文脈）

| 文書 | 概要 |
|------|------|
| [docs/sprints/sprint_02.md](docs/sprints/sprint_02.md) | v0.2.0 相当：試合一覧・作成、ロック、オートセーブ |
| [docs/sprints/sprint_03.md](docs/sprints/sprint_03.md) | v0.3.0 相当：`match:get` / スコア・選手・終了再編集 |
| [docs/sprints/sprint_04.md](docs/sprints/sprint_04.md) | v0.4.0 相当：交代・カード・PK・プレゼンスフォーカス |
| [docs/sprints/sprint_05.md](docs/sprints/sprint_05.md) | v0.5.0 相当：チーム／ロスター、データ管理、設定、PK 決着 UI |
| [docs/sprints/sprint_06.md](docs/sprints/sprint_06.md) | v0.9.0 方面：実機検証・堅牢性などの計画 |
| [docs/sprints/sprint_06_pretriage.md](docs/sprints/sprint_06_pretriage.md) | v0.5.1：実機前夜のトリアージ強化（観測・ガード・ヘルス等） |
| [docs/sprints/sprint_07.md](docs/sprints/sprint_07.md) | **v0.6.0 予定**: アプリ内ヘルプ実装スプリント（受け入れ基準・B 案ロードマップ） |
| [docs/sprints/sprint_08_marquee.md](docs/sprints/sprint_08_marquee.md) | **v0.6.1**: マーキー基盤〜全域適用（Sprint 07 と別ノート・3 フェーズ PR 案） |
| [docs/sprints/sprint_07_uiux_findings.md](docs/sprints/sprint_07_uiux_findings.md) | ヘルプ執筆中の UI/UX 気づき（v0.9.1 改善のタスク元） |

### 変更履歴・ユーザー向け

| 文書 | 概要 |
|------|------|
| [CHANGELOG.md](CHANGELOG.md) | バージョンごとの機能・修正の要約 |
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | 審判・運営向け操作ガイド（日本語） |
| [docs/USER_GUIDE.en.md](docs/USER_GUIDE.en.md) | 同上（English） |

## UI 開発

```powershell
cd RefBoard/web
npm install
npm run dev
```

本番ビルド: `npm run build` → `web/dist` を FiveM が読み込みます。

## ステータス

**v0.6.0（計画）** — アプリ内ヘルプ（項目ごと＋やりたいこと逆引き、検索、主要画面の `?`、エラーからヘルプへ）。設計は [docs/help_system_design.md](docs/help_system_design.md)、実装スプリントは [docs/sprints/sprint_07.md](docs/sprints/sprint_07.md)。**B 案**: ヘルプを先に仕上げてから本格の実機テストへ。

**v0.5.1** — 実機テスト向けトリアージ：`ErrorCodes` / `MakeError`、`Logger`、`RefboardGuard`、NUI 通信トレース、ヘルスチェック。詳細は `docs/error_handling.md` と `docs/sprints/sprint_06_pretriage.md`。

**v0.5.0** — チーム管理（ロスター）、データ管理・CSV、設定画面、PK 決着後フロー、UX ポリッシュ、スクリーンショット・ユーザーガイド。`docs/sprints/sprint_05.md`。

**v0.3.0** — ゴール記録ウィザード、選手追加、スコア手動編集・履歴、試合終了／再編集、`match:get` / `match:state` 本番配線、Vite 単体用 NUI モック。`docs/sprints/sprint_03.md`。

**v0.2.0** — 試合一覧・作成、`MatchDetail` モック、編集ロック、オートセーブ。`docs/sprints/sprint_02.md`。

**v0.1.1** — プレゼンス（A 案）、設計書 04、試合メタ列。

**v0.1.0** — 初回スキャフォールド。

## ライセンス

MIT — 詳細は [LICENSE](LICENSE)。
