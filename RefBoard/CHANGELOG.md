# Changelog

## v0.2.0 — 2026-05-05

- **Match UI**: `MatchDetail.vue` フルモック（ヒーロー・上段3カラム・下段65/35・静的「編集中」バッジ）、`MatchList.vue`、`CreateMatchDialog.vue`。
- **試合 CRUD（MVP）**: `refboard:match:create` / `refboard:match:list`、`server/match.lua` / `team.lua` 実装。
- **編集ロック**: `server/lock.lua`（`editor_locks` + ハートビートタイムアウト + `refboard:lock:acquire:result`）、NUI `session.enterEdit` 配線、`Launcher` ロック失敗ダイアログ。
- **オートセーブ**: `refboard:autosave:draft` → `match_drafts` デバウンス → `refboard:autosave:saved`、`stores/autosave.ts`、`AutosaveIndicator.vue`。
- **ルーター**: `/workspace` シェル + 子ルート `matches` / `matches/:id`。
- **SQL**: `sql/seed_dev_teams.sql`（開発用チーム2件）。
- **ドキュメント**: `docs/sprints/sprint_02.md`。

## v0.1.1 — 2026-05-05

- **プレゼンス（A 案）**: ツール接続人数の表示。`server/presence.lua`、`refboard:presence:list` / `refboard:presence:update`、NUI `PresenceBadge` / `UserAvatar` / `stores/presence`。
- **設計書**: `docs/04_design_mockup.md` 追加、`01`〜`03` にプレゼンス・試合メタ・UI モック追記。
- **DB**: `matches` に `match_name` / `venue` / `kickoff_time`（新規 `install.sql`、既存向け `sql/migration_001_match_meta.sql`）。

## v0.1.0 — 2026-05-05

- Initial scaffolding: `sql/install.sql`, `fxmanifest.lua`, `config.lua`, docs (`01_database`, `02_server`, `03_frontend`), logo SVG.
- Server: `refboard:*` net events stub + `editor_locks` reset on resource start.
- Client: `/refboard` + key mapping, NUI open/close, NUI callbacks forwarding to server.
- Web: Vue 3 + Vite + TypeScript + Tailwind + Pinia + Vue Router + vue-i18n minimal shell (`Launcher`, `MainLayout`).
