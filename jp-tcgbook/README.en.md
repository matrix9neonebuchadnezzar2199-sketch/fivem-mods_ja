# jp-tcgbook

A trading card game (TCG) resource for FiveM: card collection, deck building, CPU and peer PvP, Elo rating, match history, leaderboard UI, nine rank tiers with badge art, and Japanese / English UI including localized card names.

**Maintainer testing**: primarily on **QBox** (`qbx_core`). **QBCore** and **ESX** hooks exist in `shared/identity.lua` for character display names but are **not regularly verified** by the maintainers—please report gaps if you rely on them.

[日本語 README](README.md)

## Features

- **Collection & decks**: Up to 10 decks per player, 10 cards per deck, shitei (UR/SS) slots plus free slots, configurable per-rank duplicate limits inside a deck.
- **Battles**: Server-authoritative placement, side-stat comparison, hands, turn flow—CPU duels and real two-player PvP.
- **Rating & rank tiers**: Elo (default initial 1500, K=32) with nine visual tiers (Wood → Mythology) via `html/assets/ranc/` badges (filenames are case-sensitive on Linux).
- **Ranking UI**: On-demand fetch, configurable top N (default 50), “around me” with stable tie-breaks; excluded citizen IDs in config (e.g. verification dummy).
- **PvP EXP & win streak**: Cumulative EXP with streak bonus; display level cap 99 with configurable thresholds.
- **Match history**: Bundled with BOOK open (default 50 rows), hard cap 100 on queries.
- **Internationalization**: JA/EN chrome and localized card names / descriptions (`name_en`, `description_en`); long titles use a subtle marquee in the UI.
- **Daily counters & defeat reward**: JST daily counters for real PvP; optional one-card copy from winner to loser on real PvP normal finishes (PHASE 2d).

## Requirements

- **FiveM** server (recent artifacts recommended).
- **oxmysql** and **MySQL 5.7+** or **MariaDB 10.3+** (`mysql_connection_string` in `server.cfg`).
- **Optional frameworks** (display names only): `qbx_core`, `qb-core`, or ESX-style global `ESX`. Player persistence uses **standalone identifiers** (`license`, then discord / fivem / steam) via `GetPlayerUid`; frameworks are not hard dependencies.

## Installation

1. Copy `jp-tcgbook` into your `resources` folder (e.g. monorepo checkout under `fivem-mods_ja/jp-tcgbook`).
2. Ensure **oxmysql** before this resource:

   ```cfg
   ensure oxmysql
   ensure jp-tcgbook
   ```

3. Configure `set mysql_connection_string "mysql://..."`. On first start the resource runs statements from `server/sql/install.sql` and seeds an empty card master from `shared/cards.lua`. Existing databases receive additive **`ApplyOptionalSchemaPatches`** (columns/indexes) without wiping data.
4. **Optional ACE**: book admin UI — `add_ace group.admin command.tcg_book_admin allow` (see `Config.BookAdminAce`).
5. **Production**: keep `Config.Debug`, `Config.DebugCommands`, and `Config.BattleWireLog` at **`false`** (see `config.lua`). Operators may grant `command.tcg_debug` for `/tcg_*` tools when `DebugCommands` is enabled.

## Configuration

All tunables are in **`config.lua`** (Japanese comments). Highlights:

| Key | Purpose |
|-----|---------|
| `Config.EnableRankingUi` | Show or hide the ranking tab (default `true`). |
| `Config.RankingDisplayLimit` / `Config.RankingMaxLimit` | Leaderboard size and server-side clamp. |
| `Config.RankingExcludeCitizenids` | Rows excluded from leaderboard counts and listings. |
| `Config.PvpRankTiers` | Thresholds and badge filenames under `html/assets/ranc/`. |
| `Config.InitialRating` / `Config.EloKFactor` | Rating parameters. |
| `Config.Debug` / `Config.DebugCommands` / `Config.BattleWireLog` | Diagnostics and wire tracing—off in production. |
| `Config.SeedCardsFromLua` | When `false`, existing master rows are not overwritten on restart (admin UI edits preserved). |

## Screenshots

Add images under `docs/screenshots/` (e.g. collection, deck editor, battle, ranking with badges, match history, language toggle) and link them here after capture.

## License

Released under the **MIT License**. See [LICENSE](LICENSE).

**Art**: Card illustrations under `html/assets/cards/` and rank badges under `html/assets/ranc/` are **original assets shipped with this resource** (JP-Mods). If you replace them with third-party material, ensure your own licensing and optional `docs/CREDITS.md` for attribution.
