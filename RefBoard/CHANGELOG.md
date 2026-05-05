# Changelog

## v0.1.0 — 2026-05-05

- Initial scaffolding: `sql/install.sql`, `fxmanifest.lua`, `config.lua`, docs (`01_database`, `02_server`, `03_frontend`), logo SVG.
- Server: `refboard:*` net events stub + `editor_locks` reset on resource start.
- Client: `/refboard` + key mapping, NUI open/close, NUI callbacks forwarding to server.
- Web: Vue 3 + Vite + TypeScript + Tailwind + Pinia + Vue Router + vue-i18n minimal shell (`Launcher`, `MainLayout`).
