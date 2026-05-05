<div align="center">

<img src="./docs/logo.svg" width="120" alt="RefBoard logo" />

# RefBoard

**Open-source soccer match management for FiveM — tamper-evident score history, edit lock, JA/EN UI.**

[日本語](./README.md)

[![License: MIT](LICENSE)](LICENSE)

</div>

---

## Overview

RefBoard lets **referees / staff** record match scores, clock, and rosters with **MySQL as the source of truth**. It targets a **single-editor lock** and **append-only score history** (see `docs/01_database.md`).

- **Resource folder**: `RefBoard` (`ensure RefBoard`)
- **Dependency**: [oxmysql](https://github.com/overextended/oxmysql)
- **Permission**: ACE `refboard.referee` (`Config.RefereePermission` in `config.lua`)

## Install

1. Copy this folder under `resources/.../RefBoard`.
2. Run `sql/install.sql` on your MySQL database (for local testing, also run `sql/seed_dev_teams.sql` for two sample teams).
3. Add `ensure RefBoard` after `ensure oxmysql` in `server.cfg`.
4. Grant `refboard.referee` to referee accounts (example: `add_ace identifier.license:xxxx refboard.referee allow`).

## Usage

- In game: **`/refboard`** or **`F6`** (see `Config.OpenKey`).

## Design docs

| File | Topic |
|------|--------|
| [docs/01_database.md](docs/01_database.md) | Database design |
| [docs/02_server.md](docs/02_server.md) | FiveM server / `refboard:` events |
| [docs/03_frontend.md](docs/03_frontend.md) | Vue 3 / Vite / NUI |

## UI development

```bash
cd RefBoard/web
npm install
npm run dev
```

Production: `npm run build` outputs to `web/dist`.

## Status

**v0.2.0** — Match list + create, `MatchDetail` mock UI, editor lock wiring + DB timeouts, autosave draft + indicator. Sprint notes: `docs/sprints/sprint_02.md`.

**v0.1.1** — Presence (option A), design doc 04, match meta columns.

**v0.1.0** — Initial scaffolding.

## License

MIT — see [LICENSE](LICENSE).
