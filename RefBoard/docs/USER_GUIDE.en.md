# RefBoard User Guide (English)

## What is RefBoard?

RefBoard is a FiveM NUI tool for referees to record match score, timeline events, and rosters in MySQL with audit-friendly history.

## Install

1. Put the resource under `resources/` and `ensure RefBoard` after `ensure oxmysql` in `server.cfg`.
2. Run `sql/install.sql` on MySQL. For **existing databases**, apply prior migrations and then `sql/migration_004_team_roster.sql`.
3. Optional: `sql/seed_dev_teams.sql` for two sample teams.
4. Grant ACE `refboard.referee` (see `Config.RefereePermission` in `config.lua`).

## Open the UI

Use **`/refboard`** or **`F6`**. Pick **Edit** or **View** on the launcher.

## Initial setup

1. **Teams** (sidebar): register teams (name, short name, color, emoji emblem).
2. Add **roster** members for frequent lineups (optional `license` reduces repeated server-id entry).
3. **Matches**: create a match and acquire the edit lock.

## During a match

1. Add players (**by server id** or **from roster**).
2. Advance halves in **Match status**. In PK mode, use **Penalty shootout** panel.
3. When the shootout is decided, everyone sees the winner overlay; the editor gets a **finish match** prompt.
4. **Finish match** sets status to `finished` (reopen later if needed).

## Data

Use **Data** tabs for history, team stats, player stats, and manual score edit audit log. **Export CSV** uses UTF-8 BOM for Excel.

## Settings

Settings are stored in browser `localStorage` for the NUI session. Server-wide defaults remain in `config.lua`.

## Keyboard shortcuts (match detail, editor)

| Key | Action |
|-----|--------|
| G | Goal wizard |
| S | Substitution dialog |
| Esc | Close modals |
| Ctrl+S | Save (release lock, back to list) |

## Troubleshooting

- **Cannot edit**: another referee holds the lock. Open view-only or ask them to release.
- **Empty roster**: open **Teams**, select the team, add roster members.
- **DB errors**: check `oxmysql` logs and migration order; missing columns usually mean a migration was skipped.

## More docs

- [README.md](../README.md)
- [docs/01_database.md](01_database.md)
- [docs/02_server.md](02_server.md)
- [docs/03_frontend.md](03_frontend.md)
