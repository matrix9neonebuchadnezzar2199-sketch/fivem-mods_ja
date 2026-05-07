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

**Ensure name in `server.cfg` must be `Renewed-Banking`** (not the monorepo folder name `jp-renewedbanking2`). Keep the deployed folder/resource name **`Renewed-Banking`** so that `exports['Renewed-Banking']` from other resources keeps working.

## Dependencies

`fxmanifest.lua` declares `ox_lib`, `oxmysql`, and `ox_target`. See upstream for framework requirements.

## Known limitations

See [`docs/known_issues.md`](./docs/known_issues.md) for items intentionally unchanged from upstream behaviour.

## Locale

Set ox_lib locale to Japanese in `server.cfg`, e.g.:

```cfg
setr ox:locale ja
```

## Install (short)

1. Place as `Renewed-Banking` (folder name = resource name).
2. Import `Renewed-Banking.sql`.
3. In `web/`: **`pnpm install`** then **`pnpm run build`** (lockfile is `pnpm-lock.yaml` only; with npm prefer `npm install --no-package-lock`).
4. `ensure Renewed-Banking` in `server.cfg`.

Use **`renewedbanking:close`** in the F8 client console to close the banking NUI (replaces legacy `closeBankUI` as of v1.0.1-ja).

Full steps and screenshots placeholders are in [`README.md`](./README.md) (Japanese).

## Changelog (fork)

[`CHANGELOG.ja.md`](./CHANGELOG.ja.md) (Japanese; lists fork-specific changes).
