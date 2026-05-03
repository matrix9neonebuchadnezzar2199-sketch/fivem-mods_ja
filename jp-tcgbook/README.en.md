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

## Card artwork & database master

Paths are **relative to the NUI root `html/`**.

| Slot | Folder | Filename |
|------|--------|----------|
| Character cards | `html/assets/cards/character/` | `tcg_<card_id>.jpg` must match `card_id` in `shared/cards.lua` |
| Monster cards | `html/assets/cards/monster/` | Same rule |

Example: `card_id` `tcg_ur_antares` → file `html/assets/cards/character/tcg_ur_antares.jpg` and `image_path` `assets/cards/character/tcg_ur_antares.jpg`.

**Replace art only**: overwrite the same JPG, then `restart jp-tcgbook`. Names and descriptions **do not** auto-update—edit `name`, `name_en`, `description`, `description_en` in `shared/cards.lua` if the illustration’s identity changed.

**Add a new card**: place the JPG, append a full entry to `TcgCardsMaster` in `shared/cards.lua` (same fields as existing rows). The master row must exist in MySQL before rows in `tcg_player_cards` can reference that `card_id` (foreign key).

**Sync MySQL with Lua** (`config.lua`):

- Set **`Config.SeedCardsFromLua = true`**, restart the resource (or server). All `TcgCardsMaster` rows are **UPSERT**ed into `tcg_cards_master` (existing `card_id` rows are overwritten from Lua).
- Set **`false`** to avoid overwriting an existing populated master on each restart. **First install**: if `tcg_cards_master` is empty, Lua is seeded once regardless of this flag (see `server/database.lua`).
- **Suggested production workflow** after editing masters: turn `true` → restart → verify BOOK and DB → set `false` again.

Save Lua and HTML as **UTF-8 without BOM**. Full operator notes (Japanese): [README.md](README.md) §カード画像 / §カードマスタと DB。

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
| `Config.SeedCardsFromLua` | `true`: UPSERT full master from Lua on startup. `false`: skip that when the table already has rows (empty DB still seeds once). See **Card artwork & database master** above. |

## Screenshots

Add images under `docs/screenshots/` (e.g. collection, deck editor, battle, ranking with badges, match history, language toggle) and link them here after capture.

## License

Released under the **MIT License**. See [LICENSE](LICENSE).

**Art**: Card illustrations under `html/assets/cards/` and rank badges under `html/assets/ranc/` are **original assets shipped with this resource** (JP-Mods). If you replace them with third-party material, ensure your own licensing and optional `docs/CREDITS.md` for attribution.
