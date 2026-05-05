<div align="center">

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
- **権限**: ACE `refboard.referee`（`config.lua` の `Config.RefereePermission`）

## インストール

1. 本フォルダを `resources/[local]/RefBoard` などに配置。
2. MySQL で `sql/install.sql` を実行（開発時は続けて `sql/seed_dev_teams.sql` でサンプル2チームを投入推奨）。
3. `server.cfg` に `ensure oxmysql` のあと `ensure RefBoard`。
4. 審判用プレイヤーに `add_ace identifier.license:xxxxxxxx refboard.referee allow` 等を付与。

## 操作

- ゲーム内: **`/refboard`** または **`F6`**（`config.lua` の `Config.OpenKey`）で NUI を開閉。

## ドキュメント（設計）

| ファイル | 内容 |
|----------|------|
| [docs/01_database.md](docs/01_database.md) | DB 方針・テーブル一覧（DDL は `sql/install.sql`） |
| [docs/02_server.md](docs/02_server.md) | Lua サーバー・イベント `refboard:` |
| [docs/03_frontend.md](docs/03_frontend.md) | Vue 3 / Vite / NUI |

## UI 開発

```powershell
cd RefBoard/web
npm install
npm run dev
```

本番ビルド: `npm run build` → `web/dist` を FiveM が読み込みます。

## ステータス

**v0.2.0** — 試合一覧・作成、`MatchDetail` モック画面、編集ロック本番配線、オートセーブ表示・`match_drafts` 保存。スプリント記録: `docs/sprints/sprint_02.md`。

**v0.1.1** — プレゼンス（A 案）、設計書 04、試合メタ列。

**v0.1.0** — 初回スキャフォールド。

## ライセンス

MIT — 詳細は [LICENSE](LICENSE)。
