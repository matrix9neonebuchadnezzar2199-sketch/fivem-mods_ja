# Renewed-Banking — Japanese Edition (jp-renewedbanking2)

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

This folder is a **derivative** of **[Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking)** by **uShifty / Renewed-Scripts**, licensed under **CC BY-NC-SA 4.0**. It adds Japanese `locales/ja.json`, Japanese comments in code, in-game help (modal), and Japanese/English documentation files. **Gameplay logic is kept aligned with upstream** unless noted in `CHANGELOG.ja.md`.

## Not an official release

Bug reports for upstream behaviour should go to the **original repository**. Issues specific to this fork (translations, help UI) may be filed in the **fivem-mods_ja** repository.

## Credits

- **Original author**: uShifty — [Renewed-Scripts](https://github.com/Renewed-Scripts/Renewed-Banking)
- **UI 2.0 design**: [qwadebot](https://github.com/qw-scripts)
- **Japanese fork & help UI**: matrix9neonebuchadnezzar2199-sketch

See [`CREDITS.md`](./CREDITS.md) for full credits.

## License

Same as upstream: **CC BY-NC-SA 4.0**. Do not strip credits. **No commercial use** (no Tebex resale, paywalled distribution, etc.). See [`LICENSE`](./LICENSE) (English, legally binding) and [`LICENSE.ja.md`](./LICENSE.ja.md) (Japanese summary).

## Resource name

**Recommended:** deploy as **`Renewed-Banking`** so `exports['Renewed-Banking']` from other resources keeps working.

**As of v1.0.5-ja:** you may **`ensure jp-renewedbanking2`** (monorepo folder name) for local dev — server `LoadResourceFile` and NUI `fetchNui` use the **actual resource name**. Production should still use **`Renewed-Banking`** if other scripts call those exports.

## Dependencies

`fxmanifest.lua` declares `ox_lib`, `oxmysql`, and `ox_target`. See upstream for framework requirements.

## Known limitations

See [`docs/known_issues.md`](./docs/known_issues.md) for items intentionally unchanged from upstream behaviour.

## Locale

Set ox_lib locale to Japanese in `server.cfg`, e.g.:

```cfg
setr ox:locale ja
```

## Upgrade note (v1.0.1-ja)

- Client console command to close the NUI was renamed from **`closeBankUI`** to **`renewedbanking:close`**. Update scripts/macros if needed.

## Hotfix note (v1.0.3-ja)

- Lua sends **`updateLocale`** so main action button labels show in-game (matches `ox:locale` / `locales/*.json`).
- Closing the UI (ESC, ×, or **`renewedbanking:close`**) clears NUI focus and **clears ped tasks** so the character no longer gets stuck after ATMs.
- Main screen and amount popup include a **close (×)** button.
- Server DDL runs only via **`Renewed-Banking.sql` auto-apply** (duplicate inline DDL removed). See [`CHANGELOG.ja.md`](./CHANGELOG.ja.md).

## Install (short)

1. Place as `Renewed-Banking` (folder name = resource name).
2. On first server start, **`Renewed-Banking.sql` runs automatically** and creates `bank_accounts_new` and `player_transactions` (requires **oxmysql** to be running). You can still run the root `Renewed-Banking.sql` manually via phpMyAdmin / HeidiSQL for DDL review or restore from backup.
3. In `web/`: **`pnpm install`** then **`pnpm run build`** (lockfile is `pnpm-lock.yaml` only; with npm prefer `npm install --no-package-lock`).
4. `ensure Renewed-Banking` in `server.cfg`.

Use **`renewedbanking:close`** in the F8 client console to close the banking NUI (replaces legacy `closeBankUI` as of v1.0.1-ja).

Full steps and screenshots placeholders are in [`README.md`](./README.md) (Japanese).

## Changelog (fork)

[`CHANGELOG.ja.md`](./CHANGELOG.ja.md) (Japanese; lists fork-specific changes).
