const e=`---
title: Compact dock mode
category: intro
tags: [compact, dock, stadium, F6, clock, score, operator, recent events, small window]
related: [intro_setup, match_pk_recording]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Compact dock mode

## What this page covers

- How to enter **compact dock** from match detail
- What appears (clock, score, status, operator, recent events)
- Behaviour **during PK** and how **F6** fits in

## How to open

1. Open **match detail** (editor view)
2. Tap **Compact mode** in the header

Main cards hide; a **bottom dock** shows the scoreboard (embedded), match status, and **restore full UI**. Hints may mention **Ctrl+B** to favour game input (per NUI behaviour).

## What you see

- **Clock / remaining time** (inside the scoreboard)
- **Match status** (half changes, etc.)
- **Operator** line (Settings display name, or “unset”)
- **Recent events** (newest first, scrollable; **hidden during PK**)

Modal overlays can use **transparent** chrome so the game stays visible behind dialogs.

## During PK

In PK phase the dock **does not show**; use the **full PK panel** instead. To use the dock again, leave PK (change half) and re-enable compact mode if needed.

## F6

**F6** toggles the RefBoard UI (default **OpenKey** in \`config.lua\`). It is not dock-specific, but is the usual way to close the UI while playing.

## See also

- First-time setup: [#/workspace/help/article/intro_setup](#/workspace/help/article/intro_setup)
- PK recording: [#/workspace/help/article/match_pk_recording](#/workspace/help/article/match_pk_recording)
`,n=`---
title: Open CSV in Excel
category: data
tags: [Excel, CSV, encoding, BOM, UTF-8, date, apostrophe, import, garbled]
related: [data_export, data_csv_format]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Open CSV in Excel

## What this page covers

- RefBoard CSV is **UTF-8 with BOM**, which Excel usually reads correctly
- When values like **\`45+2'\`** are mistaken for **dates**

## Avoiding mojibake

Match CSV files include a **BOM**. Double-clicking in Excel often shows Japanese text correctly.

If characters are wrong:

1. In Excel: **Data** → **From Text/CSV**
2. Pick the file and set encoding to **65001: Unicode (UTF-8)**
3. Use **comma** as the delimiter and finish

## \`45+2'\` turning into a date

Excel may auto-convert **\`10'\`** or **\`45+2'\`** in \`minute_label\` to a date/time.

**Mitigations**

- Set the column format to **Text** before or after import
- In **Get Data**, set the column type to **Text**
- For analysis, prefer numeric **\`event_minute\`** / **\`event_stoppage\`** (detailed export)

## See also

- Column reference: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
`,t='---\ntitle: CSV export format (v0.3.0)\ncategory: data\ntags: [CSV, export, format, standard, detailed, summary, events, BOM, UTF-8, columns]\nrelated: [data_export, data_import, data_csv_excel_open]\nshortcut: null\nactionUrl: "#/workspace/data"\nerrorCode: null\n---\n\n# CSV export format (v0.3.0)\n\n## What this page covers\n\n- **Summary** and **events** delivered as **two files**\n- **Standard (13 columns)** vs **detailed (26 columns)**\n- How filenames are built\n\n## Two files per export\n\nFor each match, two downloads run about **0.2 s** apart:\n\n1. **`refboard_m{id}_{YYYY-MM-DD}_summary.csv`** — one metadata row (**9 columns**)\n2. **`refboard_m{id}_{YYYY-MM-DD}_events.csv`** — one row per event (**13 or 26 columns**)\n\nIn **Data** (finished match row) or **Match detail** header, choose **Standard** / **Detailed** in the dropdown, then export.\n\n## Summary CSV (9 columns)\n\n`match_id`, `match_title`, `match_date`, `home_team`, `away_team`, `final_score`, `match_status`, `operator`, `exported_at`\n\n- `match_id` uses an **`m_`** prefix (e.g. `m_42`)\n- `final_score` can include PK, e.g. `1-1 (PK 2-2)`\n- `operator` is **Settings display name** (may be empty if unset)\n\n## Events CSV — standard (13 columns)\n\n`match_id`, `match_title`, `match_date`, `home_team`, `away_team`, `final_score`, `event_index`, `event_kind`, `event_team`, `minute_label`, `event_minute`, `event_text`, `recorded_at_iso`\n\n- `event_kind` values include `goal`, `substitution`, `pk_goal`, `pk_miss`, `yellow`, `red`, …\n- `minute_label` uses display form e.g. `45+2\'` or `PK` for shootout kicks\n- Substitutions use a **single `sub_out` row** (no separate `sub_in` row)\n\n## Events CSV — detailed (26 columns)\n\nAdds stoppage, player/assist numbers and names, card colour, sub in/out, PK result and per-team `pk_shot_index`, `operator` on each row, etc.\n\n## See also\n\n- Flow overview: [#/workspace/help/article/data_export](#/workspace/help/article/data_export)\n- Excel tips: [#/workspace/help/article/data_csv_excel_open](#/workspace/help/article/data_csv_excel_open)\n',a=`---
title: Export to CSV
category: data
tags: [CSV, export, BOM, Excel, csv export]
related: [data_view_history, data_csv_format, data_csv_excel_open]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Export to CSV

## What you will learn

- Export from **Data** and **match detail**
- **UTF-8 BOM** for Excel-friendly open

## Prerequisites

- NUI allows **blob download**.
- Referee permissions for the dataset.

## From Data

1. On a tab, use **Export CSV** when shown.
2. Filename usually includes date/type (per \`refboard_filename\` helper).

## From match detail (events)

1. Pick **CSV format** (standard / detailed), then use **CSV** to download **summary** and **events** as **two files** ~200ms apart (v0.3.0+). See [CSV format](#/workspace/help/article/data_csv_format).
2. **JSON** is a separate one-file export.

## After export

- Files saved locally; **BOM** helps Excel decode UTF-8. For Excel quirks see [Open CSV in Excel](#/workspace/help/article/data_csv_excel_open).
- **No change** to database (read-only copy).

## FAQ

**Q. Google Sheets**  
A. Use **Import** or ensure UTF-8 with BOM in import settings.

**Q. Every column including PK?**  
A. **Detailed** mode includes PK result and \`pk_shot_index\`. See [CSV format](#/workspace/help/article/data_csv_format). Use **JSON export** if you need raw data.

## See also

- [View history in Data](#/workspace/help/article/data_view_history)
- [Finish or reopen a match](#/workspace/help/article/match_finish) (reopen vs exported snapshots)
`,o=`---
title: Import a JSON backup
category: data
tags: [data, backup, import, json, restore, migration, 取り込み, partial merge, selective]
related: [data_export, data_view_history]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Import a JSON backup

## What this page covers

- How to restore a **full-data JSON** backup from **Data**
- The difference between **Replace** and **Merge**, and **selective merge** (pick teams / roster / matches)
- Why you must **reload the page** after importing
- **Import history** stays on this browser/device only

## Prerequisites

- The file must be a **RefBoard full backup** with \`schemaVersion: 1\`. Single-match JSON and CSV are not imported here.
- Invalid or truncated JSON is rejected during preview; **localStorage is not changed** until you confirm an import.

## Steps

1. Open **Data** and choose **Import from JSON**.
2. Pick the backup **.json** file. Review the counts and the **lists of teams, roster rows, and matches** from the file.
3. Understand **Replace** vs **Merge**:
   - **Replace**: **Deletes everything** locally, then writes the backup. There is **no per-entity selection** (full file only). A **two-step confirmation** reduces mistakes. Import history is preserved and merged with a new head entry.
   - **Merge**: Append teams, roster rows, and matches with **new IDs**. **Settings (display name, etc.) stay** on this device.
4. When **Merge** is selected, you can **check teams, roster rows, and matches individually** (v0.2.0). Use **Select all / Clear** per section.
5. **When a match is selected, also include related teams and roster** (default **on**): home/away teams for checked matches and any **rosterMemberId** referenced by those matches’ players are auto-checked. Turn it **off** only if you intend to select everything manually; validation blocks confirm until home/away teams and required roster rows are covered.
6. After success, click **Reload to apply** so the page reloads. Pinia stores must rehydrate from disk.

## After you import

- **Import history** (up to 20 rows) lists time, operator label, mode, and counts. **Partial merge** rows are labeled accordingly. Nothing is sent to a server.
- To move devices: export **Full data backup (JSON)** on the old device, then import on the new one.

## FAQ

**Q. “Unsupported schema”**  
A. This build only accepts the schema version it was built for (currently **1**). Update the app if backups use a newer schema.

**Q. I closed without reloading**  
A. Lists may stay stale. Reload the browser or revisit Data after a full refresh.
`,r=`---
title: Move data to another PC (JSON)
category: data
tags: [migration, backup, JSON, import, replace, merge, device, selfName, partial]
related: [data_import, data_export, intro_setup]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Move data to another PC (JSON)

## What this page covers

- Exporting **full JSON backup** and restoring on another machine
- **Replace** vs **merge**
- **Display name (selfName)** is per-device

## Overview

### 1. Export on the old PC

1. Open **Data**
2. Run **Full data backup (JSON)**
3. Copy \`refboard_backup_*.json\` to the new PC (USB, cloud, etc.)

### 2. Import on the new PC

1. Open **Data** → **Import from JSON**
2. Choose mode  
   - **Replace**: wipe this device and use only the backup (**first-time migration**)  
   - **Merge**: keep existing data and reassign IDs (**add** another device’s data)
3. Partial merge lets you pick teams / rosters / matches. Importing matches can auto-include related teams.

### 3. After import

- **Reload the page** as prompted so Pinia reloads.
- **Display name** lives in \`refboard_settings\`; you may need to set it again in **Settings** (separate from CSV \`operator\`).

## FAQ

**Q. Isn’t CSV enough?**  
A. CSV is flat columns; JSON keeps the full structure. Use **JSON for full moves**, **CSV (summary + events)** for spreadsheets.

## See also

- Import UI: [#/workspace/help/article/data_import](#/workspace/help/article/data_import)
- CSV columns: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
`,s=`---
title: View history in Data
category: data
tags: [data, match history, stats, log]
related: [data_export, match_finish]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# View history in Data

## What you will learn

- **Data** tabs: matches, teams, players, logs
- Filters and opening a match from the table

## Prerequisites

- **\`refboard.referee\` ACE** (server enforces access).

## Steps

1. Open **Data** from the sidebar.
2. Pick a tab:
   - **Matches**: filters by date, team, status, etc.
   - **Teams / Players**: aggregate rows (columns per build).
   - **Logs**: audit \`edit_logs\` excerpts when available.
3. From **Matches**, use **Open** (or equivalent) to jump to match detail.

## Behavior

- Tabs are **read-heavy**; editing happens in match detail, not here.
- Changing filters **re-queries** the server.

## FAQ

**Q. Numbers differ from match detail**  
A. Filters or **reopen** state may differ — open the match and compare timeline.

**Q. Live updates**  
A. View reflects **last load**; switch tabs or reopen to refresh (auto-poll may be absent).

## See also

- [Export to CSV](#/workspace/help/article/data_export)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
`,i=`---
title: Get started with RefBoard
category: intro
tags: [setup, display name, teams, match, localStorage, backup]
related: [intro_what_is_refboard, data_export]
shortcut: null
actionUrl: null
errorCode: null
---

# Get started with RefBoard

1. Open the UI with **F6** or the **\`/refboard\`** chat command.
2. Enter your **display name** (saved on this device only; no network calls).
3. In **Team management**, create **at least two** teams you will use.
4. Go to **Matches** → **New** and create a match.
5. On the **match detail** screen, start the clock and record goals, cards, and substitutions.
6. On the **Data** screen, export a backup as **CSV** or **JSON**.

## Important

RefBoard **does not talk to a game server** for storage. Data lives in this browser’s **\`localStorage\`**. When you move to another PC, use **Data** → **Full data backup (JSON)** to write a file you can carry over.

## See also

- [What is RefBoard?](#/workspace/help/article/intro_what_is_refboard)
- [Export to CSV](#/workspace/help/article/data_export)
`,l=`---
title: What is RefBoard?
category: intro
tags: [overview, referee, match, FiveM, local]
related: [intro_setup, match_create_new]
shortcut: null
actionUrl: null
errorCode: null
---

# What is RefBoard?

## What you will learn

- What RefBoard is for (staff / referee match logging)
- Where data is stored in **v0.1.0 local mode**

## About RefBoard

RefBoard is an **NUI tool for FiveM** to **manage football matches** — scores, timeline events, and lineups.

In **v0.1.0**, data is **not sent to a game database**: it is kept in the browser’s **\`localStorage\`** only. There is no automatic sync across PCs — use **Data** exports for backups.

- **Framework-agnostic**: no ESX/QBCore dependency.
- **History**: manual score changes are kept in on-device history (see each task’s help article).

## After reading

Concepts only. Use **Matches**, **Teams**, and **Data** for real actions.

## FAQ

**Q. Offline?**  
A. It still runs as FiveM NUI, but **no external DB** is required; data stays on the device.

**Q. Moving to another PC**  
A. Use **Data** → **Full data backup (JSON)** and restore on the new machine.

## See also

- [Get started with RefBoard](#/workspace/help/article/intro_setup)
- [Create a new match](#/workspace/help/article/match_create_new)
`,c=`---
title: Record yellow and red cards
category: in_match
tags: [yellow, red, warning, send-off, card, YC, RC, stoppage, additional time, 45+2]
related: [match_substitute_player, match_record_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Record yellow and red cards

## What you will learn

- How to record a **yellow** (caution) or **red** (send-off)
- **Second yellow** → treated as red
- What changes after a send-off

## Prerequisites

- You are on the match detail screen.
- The player is **on the pitch** for this match (already sent-off players cannot receive another card).

## Yellow card

1. **Card** on the player row, or **event menu → Card**.
2. Choose **Yellow**.
3. Optional **match minute** and short **reason**. You can enter **\`45+2\`** (\`minute+stoppage\`). Leave blank and confirm to use the **current match clock**.
4. Confirm.

## Straight red

1. Open **Card**.
2. Choose **Red**.
3. Optional **match minute** and short **reason** (same **\`45+2\`** rules as yellow).
4. Confirm the **send-off** dialog.

## Second yellow → red

If a player already has one yellow and you issue **yellow** again, the UI explains that this becomes a **red**. Confirm to apply warning count and send-off together.

## After issuing

- Timeline rows show \`🟨\` / \`🟥\` (or combined notation for second yellow).
- Player row shows **caution** / **sent off**.
- **Sent-off players cannot return** via substitution (no “re-enter” flow).

## Tournament totals

RefBoard tracks **yellows in this match only**. Season suspensions are **out of scope**.

## FAQ

**Q. Wrong card**  
A. Use **Undo** on the timeline row when available; otherwise follow your staff policy and consider [manual score edit](#/workspace/help/article/match_manual_score_edit) if scores must align.

## See also

- [Substitute a player](#/workspace/help/article/match_substitute_player)
- [Record a goal](#/workspace/help/article/match_record_goal)
`,d=`---
title: Create a new match
category: match_prep
tags: [match, home, away, schedule, half, stoppage, additional time]
related: [match_finish, intro_setup, match_record_goal]
shortcut: null
actionUrl: "#/workspace/matches"
errorCode: null
---

# Create a new match

## What you will learn

- How to create a **new match** from the list
- What to expect when opening the match for editing

## Prerequisites

- **Home and away** teams are already registered under **Teams**.
- Creating matches requires the **\`refboard.referee\` ACE** (validated on the server).

## Steps

1. Open **Matches** from the sidebar.
2. Use **New** (or equivalent) to open \`CreateMatchDialog\`.
3. Choose **home**, **away**, and optionally **kickoff** time.
4. On success, a new row appears in the list.
5. Open **match detail**, acquire the edit lock, and start recording.

## After creating

- A \`matches\` row starts as **draft** with score 0–0 and no lineup until you add players.
- Fill **info, score, and players** from match detail.

**Half length** (e.g. 45 minutes) set here is separate from **stoppage time** on events (\`45+2\` = minute + added time). Enter stoppage in goal / card / substitution dialogs.

## FAQ

**Q. Teams do not appear in the list**  
A. Register teams first: [Register a new team](#/workspace/help/article/team_create).

**Q. I want to delete a match**  
A. Whether **Delete** is allowed depends on server rules and lock state. Follow your staff policy.

## See also

- [Finish or reopen a match](#/workspace/help/article/match_finish)
- [Record a goal](#/workspace/help/article/match_record_goal)
`,h=`---
title: Finish or reopen a match
category: in_match
tags: [finish, reopen, resume, final, half, stoppage, additional time]
related: [match_penalty_shootout, match_manual_score_edit, match_record_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Finish or reopen a match

## What you will learn

- Set match to **\`finished\`**
- UI/data changes after finish
- **Reopen** flow and caveats

## Prerequisites

- **Edit mode**.
- Play reached **end of second half** (or PK decided) — finishing early is possible but discouraged.

Each **half length** you set at match creation (e.g. 45×2) is separate from **stoppage time** on events: record it as **\`45+2\`** (\`minute+stoppage\`; timeline shows \`45+2'\`).

## Finish

1. **Finish match** from \`MatchStatusCard\` or header.
2. Confirm dialog shows score and breakdown.
3. Server runs \`Match.finish\`; \`refboard:match:finished\` switches clients to **view** mode.

## After finish

- \`status\` = **\`finished\`**, \`finished_at\` set.
- Timeline and roster **read-only**.
- Appears in Data history with final score.
- Edit lock released.
- Draft rows in \`match_drafts\` **kept** for reopen.

## Reopen

1. In **match list**, **[Reopen]** on the row.
2. Confirm: match returns **\`in_progress\`**; \`reopened_*\` logged.
3. Acquire edit lock as usual.

## Reopen — OK

- Undo/add goals, cards, subs.
- Manual score edit.
- Fix roster / minutes.

## Reopen — watch out

- **Exported CSV** may disagree with new finals — **re-export** summaries.
- **\`reopened_*\`** shows last reopen; full trail in \`edit_logs\`.
- **PK winner** can change if you undo PK events — avoid heavy PK edits unless necessary.

## Cancel / delete

- No dedicated **cancel** flow. Unused drafts: follow staff DB policy.

## FAQ

**Q. Match looks stuck after finish**  
A. The local build has **no edit locks**. Reload the page or reopen the match from the list.

**Q. Multiple reopens**  
A. Allowed; \`reopened_*\` stores **last** event only — use \`edit_logs\` for history.

## See also

- [Penalty shootout](#/workspace/help/article/match_penalty_shootout)
- [Manual score edit](#/workspace/help/article/match_manual_score_edit)
- [Wrong goal](#/workspace/help/article/trouble_undo_goal)
`,m=`---
title: Edit the score manually
category: in_match
tags: [manual, score, edit, reason]
related: [match_record_goal, trouble_undo_goal, match_finish]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: E2005
---

# Edit the score manually

## What you will learn

- Changing **numbers on the scoreboard** without a goal event
- Required **reason** (5+ chars) and audit trail
- When to prefer **Undo goal** instead

## When to use

**Prefer undoing/re-recording goals** when possible. Manual edit is for cases **hard to express as events**, e.g.:

- Corrections after server downtime
- Drift after restore/migration
- Deliberate reconciliation when \`match_events\` and \`home_score\`/\`away_score\` diverge

See [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal) first for normal mistakes.

## Prerequisites

- **Edit mode** with lock.
- \`refboard.referee\` ACE.

## Steps

1. Click the **score digits** or open **Manual score edit** from the menu.
2. Enter new **home / away** values in \`ScoreEditDialog\`.
3. **Reason — at least 5 characters** (otherwise **\`E2005 reason_too_short\`**).
4. Save.

## After save

- \`matches.home_score\` / \`away_score\` update.
- **\`match_score_history\`** gets a \`manual_edit\` row with the reason (view in \`ScoreHistoryDialog\`).
- **\`match_events\` unchanged** — events and aggregate score can **intentionally** differ.
- No scoreboard “flash” animation for manual edits.

## Errors

| Code | Meaning | Fix |
|------|---------|-----|
| \`E2005\` | reason too short | Use **5+ characters**. |
| \`E1002\` | not_editor | Reload or reopen the match detail screen. |
| \`E4003\` | tx_failed | Save failed — retry; if it persists check browser storage / extensions. |

## FAQ

**Q. Edit PK breakdown here?**  
A. **No** — regulation totals only. Fix PK rows on the timeline.

**Q. Delete history rows?**  
A. **Append-only**. Add another manual edit with reason “Correction: …” if you mistyped.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
`,p=`---
title: Run a penalty shootout
category: in_match
tags: [PK, penalty, shootout]
related: [match_record_goal, match_finish]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Run a penalty shootout

## What you will learn

- Moving the match into **PK** phase
- Using \`PenaltyShootoutPanel\` (make / miss)
- Auto winner detection and finishing

## Prerequisites

- Match in **edit mode**.
- Regulation (and extra time if used) **ended** with **tied score** (per your rules).
- Both sides agreed to PKs (house rules).

## Start PKs

1. In \`MatchStatusCard\`, switch half to **PK**.
2. Confirm **Start penalty shootout?** and pick **first team**.
3. \`current_half\` becomes **\`pk\`**; **PenaltyShootoutPanel** appears.
4. Score **breakdown** gains a \`pk\` column.

## Record each kick

1. Pick **kicker** from eligible players.
2. **Scored** or **Missed**.
3. Server records successes; alternation is guided by the UI.
4. \`evaluatePenaltyShootout\` decides the winner after 5 each and sudden death as implemented.

## Finish

1. When a winner is shown, use **Finish match** on the panel.
2. Main match score **stays tied**; winner is expressed via **PK breakdown** and metadata.

## Mistakes

- Wrong kicker: **Undo** that PK row, re-record.
- Wrong first team: **no cancel-PK UI** yet — contact admin or annotate per ops policy.
- Need to go back before PK: avoid starting PK until sure; there is **no** simple “rewind half” UI.

## FAQ

**Q. Edit PK score manually?**  
A. **Not** via manual score edit (that is for regulation goals). Use PK event undo/re-record.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)
`,u=`---
title: Record a penalty shootout (two-column UI)
category: match
tags: [PK, penalty, shootout, record, goal, miss, home, away, kicker, input, two-column]
related: [match_penalty_shootout, match_finish]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Record a penalty shootout (two-column UI)

## What this page covers

- **Home left / away right** columns during PK
- Only the **team whose turn it is** can submit
- How **PK score** updates

## Layout

- **Left**: home team name and that team’s kicks (top to bottom)
- **Right**: away team, same pattern
- Below: separate **home** and **away** player pickers and **Scored / Missed** buttons

Alternation is unchanged: the **active** side is highlighted and only that side’s controls work.

## Steps

1. Enter PK phase (from the match status card).
2. On the **highlighted** side, pick the kicker, then **Scored** or **Missed**.
3. Repeat when it becomes the other side’s turn.
4. When decided, you’ll see the winner overlay, then a prompt to finish the match.

Success shows **⚽**, miss shows **Miss** (or the localized label). For CSV columns, see the CSV format article.

## Compact dock

In **compact dock** mode, during PK the **full PK panel** is shown and the dock’s **recent events** list is **hidden**. After PK, when you return to a normal half, the list appears again in the dock.

## See also

- General PK flow: [#/workspace/help/article/match_penalty_shootout](#/workspace/help/article/match_penalty_shootout)
- Compact dock: [#/workspace/help/article/compact_dock_usage](#/workspace/help/article/compact_dock_usage)
`,_=`---
title: Record a goal
category: in_match
tags: [goal, score, shot, G, assist, record, stoppage, additional time, 45+2]
related: [match_manual_score_edit, trouble_undo_goal, match_card]
shortcut: G
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Record a goal

## What you will learn

- How to record a goal during a match
- How to attach an **assist**, and how to fix mistakes later
- What updates on screen (local build)

## Prerequisites

- You are on the **match detail** screen.
- The scorer is **on the match roster** for the scoring team.

## Steps

1. Under the scoreboard, open the **event menu** → **Goal** (shortcut **\`G\`**).
2. Pick **home or away**.
3. Select the **scorer** (on-pitch players only).
4. Optionally pick an **assist**, or leave **no assist**.
5. Set **match minute** if needed (\`45+2\` for stoppage; leave blank and confirm to use the **current match clock**). Half follows the match clock phase.
6. Confirm in the dialog.

## Assists

### During goal entry

After the scorer, pick an assist from the grid or choose **no assist**.

### After the goal (change assist)

There is **no “edit assist only” UI**. Use one of:

1. **Undo and re-record (recommended)**: timeline **Undo** on that goal → record again (net score unchanged).
2. **Manual totals only**: [Edit the score manually](#/workspace/help/article/match_manual_score_edit) with a **reason ≥ 5 characters** (timeline text may not match).

Only **one** assist is supported (no double assist).

## After recording

- Scoreboard **+1** with a highlight flash.
- Timeline row for the goal.
- Player table: scorer +1 goals; assist +1 if set.
- Data is saved to this device’s **\`localStorage\`**.

## If you made a mistake

- **Right after recording**: use timeline **Undo** when available — see [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal).
- **Wrong scorer**: undo and re-record is safest.
- **Numbers only**: [manual score edit](#/workspace/help/article/match_manual_score_edit).

## FAQ

**Q. Own goals**  
A. Record as the **opponent’s goal** and add a note.

**Q. Stoppage time**  
A. In the wizard’s **match minute** field, enter **\`45+2\`** style (\`minute+stoppage\`; \`+\` can be half-width or full-width). Leave it blank and confirm to use the **current match clock** minute. The timeline shows values like \`45+2'\`.

## See also

- [Yellow and red cards](#/workspace/help/article/match_card)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)

## Shortcuts

| Key | Action |
|-----|--------|
| \`G\` | Open goal wizard |
| \`Esc\` | Close wizard (discard unconfirmed) |
`,g=`---
title: Substitute a player
category: in_match
tags: [sub, substitution, bench, stoppage, additional time, 45+2]
related: [match_card, match_record_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Substitute a player

## What you will learn

- Substitution flow (\`SubstitutionDialog\`)
- Effects on timeline and player list
- Interaction with cards and send-offs

## Prerequisites

- You are on the **match detail** screen.
- **OUT** player is currently **active** on the pitch.
- **IN** player is on the team roster (or add them first) and not yet on the pitch.

## Steps

1. Use **Substitute** on a row in the player list, or **event menu → Substitution**.
2. Confirm **OUT** (player leaving).
3. Pick **IN** from roster / picker.
4. Set **match minute** and **half** if needed. Minutes support **\`45+2\`** (\`minute+stoppage\`). Leave blank and confirm to use the **current match clock**.
5. Confirm.

## After substitution

- OUT → **\`subbed_out\`**, IN → **\`active\`**.
- Timeline: \`🔁 OUT → IN\`.
- List order refreshes (on-pitch vs bench/subbed).

## Cards and send-offs

- **One yellow**: substitution still OK.
- **Second yellow / straight red**: player is **sent off**; you **cannot** bring them back as IN. See [Yellow and red cards](#/workspace/help/article/match_card).

## FAQ

**Q. Can a subbed player return to the pitch?**  
A. No dedicated **re-entry** flow; \`subbed_out\` → \`active\` is not offered in UI by design.

**Q. Add roster player mid-flow**  
A. Use **Add player** / roster flow first, then substitute.

## See also

- [Yellow and red cards](#/workspace/help/article/match_card)
- [Record a goal](#/workspace/help/article/match_record_goal)
`,f=`---
title: Add a member to the roster
category: team
tags: [roster, member, server id, number]
related: [team_create, match_record_goal]
shortcut: null
actionUrl: "#/workspace/teams"
errorCode: null
---

# Add a member to the roster

## What you will learn

- Add players to the team **roster** (match-day pool)
- **Server ID** vs picking existing roster entries

## Prerequisites

- **Teams** screen with a team selected.
- Player identifiable on FiveM when using server-ID mode.

## Steps

1. In roster section, **Add** → \`AddRosterMemberDialog\`.
2. Choose mode:
   - **From server ID**: enter session id, resolve name, set number/position.
   - **From existing list**: when UI offers roster picker.
3. If **duplicate license** warns, follow staff policy.
4. Save → \`team_roster\` updates.

## After adding

- Player appears in **pick from roster** during matches.
- Can be registered before any match starts.

## FAQ

**Q. Cannot resolve server ID**  
A. Player may be **offline** or not resolvable — retry when online.

**Q. Roster vs on-pitch**  
A. Roster = **eligible pool**; on-pitch is **\`active\`** in match detail — different state.

## See also

- [Register a new team](#/workspace/help/article/team_create)
- [Record a goal](#/workspace/help/article/match_record_goal)
`,w=`---
title: Register a new team
category: team
tags: [team, create team, register, abbreviation, color]
related: [team_add_roster_member, match_create_new]
shortcut: null
actionUrl: "#/workspace/teams"
errorCode: null
---

# Register a new team

## What you will learn

- Add one team from **Team management**
- How this ties to matches and roster

## Prerequisites

- **\`refboard.referee\` ACE**.
- Duplicate-name rules follow **your server**.

## Steps

1. Open **Teams** from the sidebar.
2. **Register team** → \`CreateTeamDialog\`.
3. Fill **full name**, **short name**, **colors** as prompted.
4. Save; list refreshes after ACK.

## After saving

- Row in \`teams\`; team appears in **Create match** immediately.
- **Roster** may be empty — add members: [Add roster member](#/workspace/help/article/team_add_roster_member).

## FAQ

**Q. Crest / logo image?**  
A. UI may use emoji-style icons; full image upload may be **unimplemented** — check README/DB columns.

**Q. Wrong data**  
A. Use team **edit/delete** when the server allows; FKs may block delete.

## See also

- [Add roster member](#/workspace/help/article/team_add_roster_member)
- [Create a new match](#/workspace/help/article/match_create_new)
`,y=`---
title: Player has timeline events (E3006)
category: trouble
tags: [player remove, timeline, events, E3006, player_has_events, draft]
related: [trouble_undo_goal, match_finish, match_manual_score_edit]
errorCode: E3006
errorKey: player_has_events
---

# Player has timeline events (E3006)

## What is happening

You tried to remove a player from the match roster, and the app returned **\`E3006\`** (\`player_has_events\`). The player is referenced by **at least one non-voided event** on the timeline.

The client checks timeline rows that are not voided and the player appears as any of:

- Scorer (\`player_id\`)
- Assist (\`assist_player_id\`)
- Substitute in (\`sub_in_player_id\`)
- Substitute out (\`sub_out_player_id\`)
- Card recipient (\`player_id\`)

This is a data-integrity guard so a player cannot vanish from the roster while still being credited with a goal.

## Prerequisites

- Match status must be **\`draft\`** (in-progress). Removing players from a finished match is rejected with **\`E3004\`** (\`bad_status\`).
- The player must not appear in any non-voided event (this article).

## How to fix

### 1. Void the related events first (recommended)

From the **Match progress** tab, void each event that mentions the player (\`voided_at\` will be set). Once all of them are voided, the **Remove** button on the roster will succeed.

1. Open the match → **Match progress** tab.  
2. Find every event row showing this player's name.  
3. Use the row menu → **Void**.  
4. Try **Remove** on the roster again.

### 2. Replace the player instead

If you noticed midway that "it was actually a different person," it is usually cleaner to **add the correct player and use a substitution event to swap them in**. If the wrong player has no real on-field events, voiding them and then removing also works.

### 3. Restore from JSON backup (last resort)

If you need to roll back a messy state, use **Data** → **Full data backup (JSON)** and restore from a snapshot.

## After resolution

- After step 1, the roster row is removed from **local storage** once all references are voided.
- After step 2, both players remain on the roster as part of history.
- After step 3, rely on your backup policy and keep regular exports.

**You cannot** remove a player while keeping their non-voided events.

## FAQ

**Q. Why don't voided events count toward E3006?**  
A. Only **non-voided** events count. Voided events are excluded.

**Q. The match is already finished and I want to remove a player.**  
A. Removal on a finished match is rejected with **\`E3004\`** (\`bad_status\`). **Reopen** the match to return it to \`draft\`, then follow step 1.

**Q. Why have a remove button at all if it is this strict?**  
A. Remove is intended for **undoing an accidental add right after it happens**. Once a player has on-field events, they belong to the history of the match.

## Still stuck?

- Re-scan the timeline top-to-bottom for any row that still names the player.  
- Take a **JSON backup** on the **Data** screen, restart the client, and try again.

## See also

- [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
- [Manually edit the score](#/workspace/help/article/match_manual_score_edit)
`,v=`---
title: I recorded the wrong goal
category: trouble
tags: [undo, mistake, G, wrong goal, take back]
related: [match_record_goal, match_manual_score_edit]
shortcut: G
---

# I recorded the wrong goal

Wrong scorer, wrong team, or accidental goal — **after** recording.

## Fix

### 1. Undo (preferred)

Use **Undo** near the scoreboard/timeline when it reverses the **last score change**. Audit still logs the undo.

### 2. Manual score edit

If undo is not enough:

1. Open **manual score edit**.  
2. Enter correct totals.  
3. **Reason ≥ 5 characters** (e.g. “Correcting mistaken goal”).  
4. Confirm.

### 3. Restore from backup

If many mistakes stack up, consider restoring from a recent **JSON backup** (**Data** screen).

## After fix

- **Undo**: score and UI roll back; history keeps entries.  
- **Manual edit**: totals update; reason stored in **score history**.

RefBoard does **not** erase audit trails — corrections are visible, not hidden.

## FAQ

**Q. After match finished?**  
A. **Reopen** the match, then undo or manual-edit as allowed.

**Q. Assist disappears with goal undo?**  
A. Depends how the goal was removed; manual number-only edit may leave old event rows.

## If still wrong

Use **Data** → **Full data backup (JSON)** to snapshot the current state, restart the client, and reopen the match. If it persists, restore from backup.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)

## Shortcuts

- \`G\` — goal wizard (match detail, when enabled)  
- \`Esc\` — close dialog
`,b=`---
title: Events missing or not visible
category: trouble
tags: [event, missing, display, reload, JSON, timeline, PK, troubleshooting, record]
related: [data_csv_format, match_pk_recording, trouble_undo_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Events missing or not visible

## What this page covers

- First checks when an event you recorded **does not show** in the UI
- Cases where **PK** or **compact dock** changes what you see

## Checklist

### 1. Reload

Press **F5** (or reload NUI). Sometimes the view lags behind the store.

### 2. Which list you are looking at

- **Match detail timeline** and the **PK two-column list** are different surfaces. PK shots still appear in the timeline as penalty rows; the PK panel shows structured rows.
- In **compact dock**, **recent events are hidden during PK**. Use the full PK UI instead.

### 3. Inspect raw data

1. Export **match JSON** and check the \`events\` array.
2. Or export **detailed CSV** and verify \`event_index\` / \`event_text\` increased.

If data exists in JSON/CSV but not on screen, suspect a **UI refresh** issue. If absent everywhere, the event may **not have been saved**.

### 4. Operator name

The CSV **operator** column does not control visibility, but setting **Settings → display name** helps auditing who exported or operated.

## Still wrong?

- Can you reproduce on **another match**?
- Did you **undo** or void events?

Note steps and tell the maintainer if it looks like a bug.

## See also

- PK UI: [#/workspace/help/article/match_pk_recording](#/workspace/help/article/match_pk_recording)
- CSV columns: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
`;export{b as _,v as a,y as b,w as c,f as d,g as e,_ as f,u as g,p as h,m as i,h as j,d as k,c as l,l as m,i as n,s as o,r as p,o as q,a as r,t as s,n as t,e as u};
