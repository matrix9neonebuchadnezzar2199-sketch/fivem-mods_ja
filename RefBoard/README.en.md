<div align="center">

<picture>
  <img src="./docs/logo.svg" width="96" height="96" alt="RefBoard" />
</picture>

# RefBoard

### Match control for referees & staff &nbsp;·&nbsp; **Local-first**, zero network storage

**No live DB sync.** A self-contained FiveM NUI to run the full lifecycle—clock, goals, subs, cards, PKs—entirely on the operator’s machine.

<p>
  <a href="https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/blob/main/RefBoard/fxmanifest.lua"><img src="https://img.shields.io/badge/release-v0.5.1-5b6cf9?style=flat-square" alt="version" /></a>
  <img src="https://img.shields.io/badge/FiveM-cerulean-1a1a2e?style=flat-square" alt="FiveM cerulean" />
  <img src="https://img.shields.io/badge/Vue-3-42b883?style=flat-square&logo=vue.js&logoColor=white" alt="Vue 3" />
  <img src="https://img.shields.io/badge/TypeScript-5-3178c6?style=flat-square&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Lua-5.4-000080?style=flat-square" alt="Lua 5.4" />
  <a href="../LICENSE"><img src="https://img.shields.io/badge/License-MIT-9ca3af?style=flat-square" alt="MIT" /></a>
</p>

[日本語](./README.md) &nbsp;·&nbsp; [CHANGELOG](./CHANGELOG.md) &nbsp;·&nbsp; [HANDOVER (technical)](./docs/HANDOVER.md)

<br />

</div>

---

## Why RefBoard

| | |
|---|---|
| **Privacy** | Match data lives in **`localStorage` on that client only**—nothing is shipped to a central game database. |
| **Standalone** | **No ESX, QBCore, or oxmysql.** One line: `ensure RefBoard`. |
| **Bilingual** | Japanese by default; English via `vue-i18n`. |
| **Field-ready** | Full layout plus **compact dock**, **PK dock**, and contextual **help** (search & reverse index). |

> **v0.4.0 note**  
> The data-management screen and CSV/JSON export have been **removed**. Plan your own record-keeping outside the app. See [CHANGELOG.md](./CHANGELOG.md).

---

## Feature highlights

- **Matches** — list/create/detail, running clock, goal wizard, manual score edits with history  
- **Players** — roster-aware subs, yellow/red, PK logging (three-column first/second kicker layout)  
- **Teams** — registration and roster  
- **Help** — 16 articles (JA/EN), Fuse.js search, per-screen `?` (match detail keeps navigation inside the modal)  
- **Dev** — optional **seed data** from Settings (keep off on production machines)

---

## Quick start (FiveM)

1. Copy the **`RefBoard/`** folder into your server `resources` tree (e.g. `resources/[local]/RefBoard`).  
2. Add **`ensure RefBoard`** to `server.cfg` (**no `oxmysql` required**).  
3. In-game, open the UI with **`F6`** (default) or **`/refboard`**.  
4. Set an optional **display name**, create **teams**, then create a **match**.

Tweak [`config.lua`](./config.lua) for `Config.OpenKey` and `Config.DefaultLocale`.

---

## Building the UI (developers)

```bash
cd RefBoard/web
npm install
npm run dev    # browser-only preview
npm run build  # output → web/dist (what FiveM serves)
npx vue-tsc --noEmit
npm test
```

`fxmanifest.lua` points at `web/dist`. Always run **`npm run build`** before shipping.

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [**docs/HANDOVER.md**](docs/HANDOVER.md) | Architecture, tree, TODOs, roadmap |
| [**CHANGELOG.md**](CHANGELOG.md) | Release notes (breaking changes called out) |
| [**docs/diary/**](docs/diary/) | Dev diary entries |

The legacy **MySQL-backed** tree (v0.8.x) lives outside this folder as **`RefBoard_old/`** (gitignored). The current `RefBoard/` tree **does not** ship `sql/` or `docs/01_database.md`.

---

## License

**MIT** — see [LICENSE](../LICENSE) at the repository root.

---

<div align="center">

<sub>Crafted for Japanese FiveM RP servers · Feedback welcome via <strong>Issues</strong> & <strong>Pull requests</strong></sub>

</div>
