# Changelog

## v0.1.1 — 2026-05-05

- **プレゼンス（A 案）**: ツール接続人数の表示。`server/presence.lua`、`refboard:presence:list` / `refboard:presence:update`、NUI `PresenceBadge` / `UserAvatar` / `stores/presence`。
- **設計書**: `docs/04_design_mockup.md` 追加、`01`〜`03` にプレゼンス・試合メタ・UI モック追記。
- **DB**: `matches` に `match_name` / `venue` / `kickoff_time`（新規 `install.sql`、既存向け `sql/migration_001_match_meta.sql`）。

## v0.1.0 — 2026-05-05

- Initial scaffolding: `sql/install.sql`, `fxmanifest.lua`, `config.lua`, docs (`01_database`, `02_server`, `03_frontend`), logo SVG.
- Server: `refboard:*` net events stub + `editor_locks` reset on resource start.
- Client: `/refboard` + key mapping, NUI open/close, NUI callbacks forwarding to server.
- Web: Vue 3 + Vite + TypeScript + Tailwind + Pinia + Vue Router + vue-i18n minimal shell (`Launcher`, `MainLayout`).
