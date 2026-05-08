const e=`---
title: Export to CSV
category: data
tags: [CSV, export, BOM, Excel]
related: [data_view_history, match_finish]
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

1. Header **CSV** downloads the **event list** for that match (JSON is separate).

## After export

- File saved locally; **BOM** helps Excel decode UTF-8.
- **No change** to database (read-only copy).

## FAQ

**Q. Google Sheets**  
A. Use **Import** or ensure UTF-8 with BOM in import settings.

**Q. Every column including PK?**  
A. Depends on exporter version; use **JSON export** from match detail if columns are missing.

## See also

- [View history in Data](#/workspace/help/article/data_view_history)
- [Finish or reopen a match](#/workspace/help/article/match_finish) (reopen vs exported snapshots)
`,n=`---
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
`,t=`---
title: First-time setup (admins & referees)
category: intro
tags: [install, ACE, password, oxmysql, SQL]
related: [intro_what_is_refboard, trouble_health_check_guide]
shortcut: null
actionUrl: null
errorCode: null
---

# First-time setup (admins & referees)

## What you will learn

- One-time **server admin** tasks (DB, resource, permissions)
- **Referee** tasks in-game (open tool, edit mode)

## Prerequisites

- **MySQL** and **oxmysql** on the server, with a chosen database.

## Steps — server admin

1. Run **\`sql/install.sql\`** against the **same database oxmysql uses** (running it on another DB causes \`Table doesn't exist\`).
2. Apply **\`sql/migration_*.sql\`** as needed for your environment.
3. In \`server.cfg\`, **\`ensure oxmysql\`** then **\`ensure RefBoard\`** (match the folder name).
4. Grant ACE to referees, e.g.  
   \`add_ace identifier.license:xxxxxxxx refboard.referee allow\`
5. Share **\`Config.EditPassword\`** from **\`config.lua\`** with staff (used when entering edit mode from the launcher).

## Steps — referee (in-game)

1. Open NUI with **\`/refboard\`** or **\`F6\`** (\`Config.OpenKey\` in \`config.lua\`).
2. On first launch, pick **View** or **Edit** in the launcher; **Edit** requires the password above.
3. Use the sidebar to open **Matches**, **Teams**, etc.

## After setup

- After SQL succeeds, team/match/lock tables are available and APIs work from NUI.
- After ACE is granted, only players with \`refboard.referee\` can access protected actions.

## FAQ

**Q. \`Table '….teams' doesn't exist\`**  
A. **install.sql** was not run on the connected DB. Check the README install section.

**Q. I cannot get the edit lock (E1003)**  
A. Another referee is editing that match. See [Another referee is editing (E1003)](#/workspace/help/article/trouble_e1003_lock_held).

## See also

- [What is RefBoard?](#/workspace/help/article/intro_what_is_refboard)
- [How to read the health check](#/workspace/help/article/trouble_health_check_guide)
`,a=`---
title: What is RefBoard?
category: intro
tags: [overview, referee, match, FiveM, MySQL]
related: [intro_setup, match_create_new]
shortcut: null
actionUrl: null
errorCode: null
---

# What is RefBoard?

## What you will learn

- What RefBoard is for, and how server vs client roles differ
- Why edit locks, history, and autosave exist

## About RefBoard

RefBoard is an **NUI tool for FiveM** for **managing football matches**. Referees (staff) record **scores, timeline events, and lineups**; **MySQL is the single source of truth** shared across clients.

- **Framework-agnostic**: no ESX/QBCore dependency. Players with the \`refboard.referee\` ACE can use it.
- **Single edit lock**: only **one person** can edit a given match at a time. Others can open in view mode.
- **History**: manual score edits are stored **with reasons** in \`match_score_history\` (see each action’s help).

## Prerequisites (users)

- The **RefBoard resource**, **oxmysql**, and **initial SQL (\`sql/install.sql\`)** are applied on the server.
- Your identifier has the **\`refboard.referee\` ACE** (view-only usage depends on your server rules).

## After reading

This article explains concepts only. Use **Matches**, **Teams**, and **Data** screens for real actions.

## FAQ

**Q. Can every player use it?**  
A. Normally it is **for staff/referees**. Players without the ACE are rejected on the server.

**Q. Does it work offline?**  
A. **No**. It runs as NUI on a FiveM client connected to the server and DB.

## See also

- [First-time setup](#/workspace/help/article/intro_setup)
- [Create a new match](#/workspace/help/article/match_create_new)
`,r=`---
title: Create a new match
category: match_prep
tags: [match, home, away, schedule]
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

## FAQ

**Q. Teams do not appear in the list**  
A. Register teams first: [Register a new team](#/workspace/help/article/team_create).

**Q. I want to delete a match**  
A. Whether **Delete** is allowed depends on server rules and lock state. Follow your staff policy.

## See also

- [Finish or reopen a match](#/workspace/help/article/match_finish)
- [Record a goal](#/workspace/help/article/match_record_goal)
`,o=`---
title: Finish or reopen a match
category: in_match
tags: [finish, reopen, final]
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

**Q. Lock stuck after finish**  
A. Locks should clear; if not, see [E1003](#/workspace/help/article/trouble_e1003_lock_held).

**Q. Multiple reopens**  
A. Allowed; \`reopened_*\` stores **last** event only — use \`edit_logs\` for history.

## See also

- [Penalty shootout](#/workspace/help/article/match_penalty_shootout)
- [Manual score edit](#/workspace/help/article/match_manual_score_edit)
- [Wrong goal](#/workspace/help/article/trouble_undo_goal)
`,s=`---
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
| \`E1002\` | not_editor | Acquire edit lock. |
| \`E4003\` | tx_failed | Retry; if persistent see [Autosave failed](#/workspace/help/article/trouble_autosave_failed). |

## FAQ

**Q. Edit PK breakdown here?**  
A. **No** — regulation totals only. Fix PK rows on the timeline.

**Q. Delete history rows?**  
A. **Append-only**. Add another manual edit with reason “Correction: …” if you mistyped.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
`,i=`---
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
`,l=`---
title: Add or change an assist
category: in_match
tags: [assist, score, edit]
related: [match_record_goal, trouble_undo_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Add or change an assist

## What you will learn

- How to attach an assist when recording a goal
- How to fix assist **after** the goal (current limitations)
- When player **A** stats update

## Prerequisites

- Match in **edit mode**.
- Assist candidate is on the **same team** as the scorer and on the pitch.

## During goal recording

1. After picking the scorer, use **\`PlayerSelectGrid\`** for the assist.
2. Or choose **no assist** and confirm.

## After the goal (change assist)

There is **no dedicated “edit assist only” UI** yet. Use one of:

1. **Undo and re-record (recommended)**: timeline → **Undo** on that goal → record goal again (net score unchanged).
2. **Ops note**: if you must log a correction without re-recording, follow your staff policy (e.g. \`edit_logs\` / admin).

## After a successful assist

- Player **A** column +1.
- Timeline text includes assist when applicable.
- Data views aggregate assists in real time.

## FAQ

**Q. Double assist?**  
A. Only **one** assist is supported today.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal)
`,c=`---
title: Record a goal
category: in_match
tags: [goal, score, shot, G]
related: [match_record_assist, match_manual_score_edit, trouble_undo_goal]
shortcut: G
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Record a goal

## What you will learn

- How to record a goal during a match
- How to pick scorer and assist, and where to fix mistakes
- What updates on screen and in the database

## Prerequisites

- The match is open in **edit mode** (you hold the lock). View-only referees cannot record.
- The scorer is **registered on the scoring team** for this match. Add the player from the event menu if needed.

## Steps

1. From the **event menu** under the scoreboard, choose **Goal** (shortcut **\`G\`**).
2. Pick **home or away**.
3. Select the **scorer** from \`PlayerSelectGrid\` (on-pitch players only).
4. Optionally select an **assist**, or leave **no assist**.
5. Adjust **minute** and **half** if needed (defaults match current play).
6. Confirm in the dialog.

## After recording

- Scoreboard **+1** with a score flash (increment only).
- Timeline shows \`⚽ Scorer (Assist)\`.
- Player table: **G** +1 for scorer, **A** +1 if assist set.
- Other referees receive updates via \`refboard:match:state\`.
- DB updates \`match_events\`, \`match_score_history\`, and \`matches\` in **one transaction** (rollback on failure).

## If you made a mistake

- **Right after recording**: use **Undo** on the timeline row when available. See [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal).
- **Wrong scorer**: undo and re-record is safest.
- **Change numbers only**: [Edit the score manually](#/workspace/help/article/match_manual_score_edit) — **reason must be 5+ characters**.

## FAQ

**Q. A player not on the pitch is missing from the list**  
A. Add them to the pitch or substitute them in first.

**Q. Own goals**  
A. Record as the **opponent’s goal** and add a note in comments/timeline. No dedicated own-goal flow yet.

**Q. Stoppage time**  
A. Use an **integer minute** (e.g. \`47\`), not \`45+2\` text.

## See also

- [Add or change an assist](#/workspace/help/article/match_record_assist)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)

## Shortcuts

| Key | Action        |
|-----|---------------|
| \`G\` | Open goal wizard |
| \`Esc\` | Close wizard (discard unconfirmed) |
`,d=`---
title: Issue a red card (send-off)
category: in_match
tags: [red, send-off, card, ejected]
related: [match_yellow_card, match_substitute_player]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Issue a red card (send-off)

## What you will learn

- Straight red flow
- Second yellow → red
- What you cannot do after send-off

## Prerequisites

- Match in **edit mode**.
- Player is **active**. Already sent-off players cannot receive another red.

## Straight red

1. **Card** → **Red**.
2. Optional minute / reason.
3. Confirm the **warning dialog** (send-off is high impact).

## Second yellow → red

1. Issue **yellow** to a player who already has one yellow.
2. UI explains **second yellow = red**.
3. Confirm: **\`yellow_cards\` +1** and **\`ejected_*\`** apply in **one transaction**.

## After send-off

- State **sent off**; timeline \`🟥\` (or combined notation for 2× yellow).
- Team “available players” count may drop.
- Player **cannot** return as a sub IN.
- Stats: \`red_cards\` increments.

## Undo mistakes

- Timeline **Undo** restores flags and returns player to **active** when applicable.
- Undoing a **second-yellow red** removes **both** the second yellow and the send-off; **first yellow remains**.

## FAQ

**Q. Staff/coach send-off**  
A. RefBoard models **players only** — note bench staff in comments if needed.

**Q. Forfeit / abandoned**  
A. You can still **finish** the match in RefBoard; document in Data if required.

## See also

- [Yellow card](#/workspace/help/article/match_yellow_card)
- [Substitute a player](#/workspace/help/article/match_substitute_player)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
`,h=`---
title: Substitute a player
category: in_match
tags: [sub, substitution, bench]
related: [match_yellow_card, match_red_card, match_record_goal]
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

- Match in **edit mode**.
- **OUT** player is currently **active** on the pitch.
- **IN** player is on the team roster (or add them first) and not yet on the pitch.

## Steps

1. Use **Substitute** on a row in the player list, or **event menu → Substitution**.
2. Confirm **OUT** (player leaving).
3. Pick **IN** from roster / picker.
4. Set **minute** and **half** if needed.
5. Confirm.

## After substitution

- OUT → **\`subbed_out\`**, IN → **\`active\`**.
- Timeline: \`🔁 OUT → IN\`.
- List order refreshes (on-pitch vs bench/subbed).

## Cards and send-offs

- **One yellow**: substitution still OK.
- **Second yellow / straight red**: player is **sent off**; you **cannot** bring them back as IN. See [Red card](#/workspace/help/article/match_red_card).

## FAQ

**Q. Can a subbed player return to the pitch?**  
A. No dedicated **re-entry** flow; \`subbed_out\` → \`active\` is not offered in UI by design.

**Q. Add roster player mid-flow**  
A. Use **Add player** / roster flow first, then substitute.

## See also

- [Yellow card](#/workspace/help/article/match_yellow_card)
- [Red card](#/workspace/help/article/match_red_card)
`,u=`---
title: Issue a yellow card
category: in_match
tags: [yellow, warning, card]
related: [match_red_card, match_substitute_player]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Issue a yellow card

## What you will learn

- How to record a yellow card
- **Second yellow** → treated as red
- What is tracked across matches vs one match only

## Prerequisites

- Match in **edit mode**.
- Player is **on the pitch** for this match (\`active\` or similar).

## Steps

1. **Card** on the player row, or **event menu → Card**.
2. Choose **Yellow**.
3. Optional **minute** and **short reason**.
4. Confirm.

## After issuing

- Player **\`yellow_cards\`** +1.
- Timeline: \`🟨 Name (reason)\`.
- Badge shows warning count.
- **Second yellow** on the same player triggers a confirmation, then **auto red** / send-off. See [Red card](#/workspace/help/article/match_red_card).

## Tournament totals

- RefBoard tracks **yellows in this match only**. Season suspensions are **out of scope** — use Data stats + your house rules.

## FAQ

**Q. Wrong yellow**  
A. **Undo** on the timeline row reverses the count (audit log remains).

**Q. Card after send-off**  
A. Recording may still be allowed as a factual note; competitive effect is already applied.

## See also

- [Red card](#/workspace/help/article/match_red_card)
- [Substitute a player](#/workspace/help/article/match_substitute_player)
`,m=`---
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
`,p=`---
title: Register a new team
category: team
tags: [team, register, abbreviation, color]
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
`,f=`---
title: When autosave fails
category: urgent
tags: [autosave, save, DB, error]
related: [trouble_connection_lost]
errorCode: E4003
errorKey: tx_failed
---

# When autosave fails

Autosave shows an error, or the ACK includes \`error: 'tx_failed'\` / **\`E4003\`** (also used for some main score transaction failures).

## What happened

A recent **DB write** (draft save, score update, etc.) failed. Common causes:

- MySQL glitch  
- Deadlock / timeout  
- Validation / integrity error  

## What to do

### Step 1 — Retry

Use **Retry** if shown; otherwise **repeat** the action.

### Step 2 — Pause and retry

If it keeps failing, wait **seconds to tens of seconds**, then try again.

### Step 3 — Health check

**Settings → Health check** for DB and schema.

### Step 4 — Logs

Give admins **Logger ERROR** lines and, if possible, NUI trace (\`refboard_trace\`).

## After retry

- **Success**: indicator returns to saved.  
- **Still failing**: treat as **unsaved** — do not assume progress; fix infra first.

## FAQ

**Q. UI shows new score but server disagrees**  
A. Could be optimistic UI — **reload** and trust server state.

**Q. \`tx_failed\` vs \`db_query_failed\`**  
A. Both are DB-layer failures — diagnose via health + logs.

## See also

- [Lost connection](#/workspace/help/article/trouble_connection_lost)
`,_=`---
title: Lost connection — is my data OK?
category: urgent
tags: [connection, disconnect, autosave]
related: [trouble_autosave_failed]
---

# Lost connection — is my data OK?

**Short answer:** the server’s **MySQL** is the source of truth. **What the server accepted is saved.** The client is for display and input.

## Why

- Actions go over NetEvents; on success the DB updates.  
- **Autosave** (\`match_drafts\`) backs up in-progress UI state.  
- After disconnect, data remains **as of the last successful server commit**.

## Scenarios

### FiveM client crashed

- Lock **times out** and releases.  
- Reconnect, reopen the match, re-acquire lock if needed.

### Brief network blip

- Retry the action; check toasts.  
- For traces: \`localStorage.refboard_trace = '1'\`, reload, watch F8 (see internal sprint docs).

### Server or DB down

- Use **Health check** after recovery.

## Recovery

1. Reconnect.  
2. Open the match from the list.  
3. Re-acquire edit lock if editing.  
4. Run **Health check** if unsure.

## After recovery

- You should see everything **committed before** the drop.  
- **Unsent** client-only input may be **lost** — confirm success toasts after important actions.

## FAQ

**Q. Autosave checkmark before crash**  
A. If the server never ACK’d, the action may not exist server-side — **repeat** it.

## See also

- [When autosave fails](#/workspace/help/article/trouble_autosave_failed)
`,g=`---
title: Another referee is editing (E1003)
category: trouble
tags: [lock, edit, E1003, lock_held]
related: [trouble_undo_goal, trouble_connection_lost]
errorCode: E1003
errorKey: lock_held
---

# Another referee is editing (E1003)

## What is happening

Another referee holds the **edit lock** for this match. Only **one editor** per match is allowed. Others can use **view** mode.

Server \`error\` key: **\`lock_held\`**, code: **\`E1003\`**.

## How to fix

### 1. Contact the editor (recommended)

1. Check presence / lock UI for the name.  
2. Reach them on voice/Discord/in-game.  
3. When they release the lock, you can acquire it.

### 2. Wait for timeout

If heartbeats stop for **\`Config.LockTimeoutSec\`** (default **30s**), the lock auto-releases (disconnect, crash, etc.).

### 3. Open in view mode

If you only need to read, use **View** from the launcher.

## After resolution

- When the lock is free, try **edit** again.
- In view mode you still receive \`refboard:match:state\` updates.

**You cannot** force-take a lock from the UI.

## Still stuck?

- Run **Settings → Health check**.
- Admins may reset \`editor_locks\` on restart per policy.

## See also

- [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal)
- [Lost connection](#/workspace/help/article/trouble_connection_lost)

## Shortcuts

- \`Esc\` closes dialogs where applicable.
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

You tried to remove a player from the match roster, and the server returned **\`E3006\`** (\`player_has_events\`). The player is referenced by **at least one non-voided event** on the timeline.

The server checks \`match_events\` rows where \`voided_at IS NULL\` and the player appears as any of:

- Scorer (\`player_id\`)
- Assist (\`assist_player_id\`)
- Substitute in (\`sub_in_player_id\`)
- Substitute out (\`sub_out_player_id\`)
- Card recipient (\`player_id\`)

This is a data-integrity guard so a player cannot vanish from the roster while still being credited with a goal.

## Prerequisites

- Match status must be **\`draft\`** (in-progress). Removing players from a finished match is rejected with **\`E3004\`** (\`bad_status\` — see \`shared/error_codes.lua\` / \`MATCH_ALREADY_FINISHED\`).
- You must hold the **edit lock**.
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

### 3. DB-side correction (last resort)

If voiding would falsify a public match record, an admin can set \`match_events.voided_at\` directly in the DB or write a corrective entry into \`edit_logs\`. **The UI does not expose this path.**

## After resolution

- After step 1, \`match_players\` is **physically DELETEd** and the action is recorded in \`edit_logs\`. The \`E3006\` warning itself is not logged.
- After step 2, both players remain in \`match_players\` as part of history.
- After step 3, leave a \`note\` in \`edit_logs\` explaining the correction.

**You cannot** remove a player while keeping their non-voided events.

## FAQ

**Q. Why don't voided events count toward E3006?**  
A. The server query only counts rows where \`voided_at IS NULL\` (see \`server/player.lua\`). Voided events are excluded.

**Q. The match is already finished and I want to remove a player.**  
A. Removal on a finished match is rejected with **\`E3004\`** (\`bad_status\`). **Reopen** the match to return it to \`draft\`, then follow step 1.

**Q. Why have a remove button at all if it is this strict?**  
A. Remove is intended for **undoing an accidental add right after it happens**. Once a player has on-field events, they belong to the history of the match.

## Still stuck?

- Run **Settings → Health check** to verify DB / edit lock state.
- Inspect \`edit_logs\` for add/void history of the player to see which events remain.

## See also

- [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
- [Manually edit the score](#/workspace/help/article/match_manual_score_edit)
`,w=`---
title: How to read the health check
category: trouble
tags: [health, DB, permission, lock, diagnostics]
related: [trouble_autosave_failed, trouble_connection_lost, intro_setup]
shortcut: null
actionUrl: "#/workspace/health"
errorCode: null
---

# How to read the health check

## What you will learn

- How rows are grouped (**server / db / auth / presence / lock / config**)
- **Re-run** and **Copy Markdown** for sharing with staff

## Prerequisites

- Open **Settings** and follow the **Health check** link (or \`#/workspace/health\`).

## Steps

1. Open **Health check**.
2. **Re-check** sends \`refboard:health:check\` (or equivalent) and refreshes the table.
3. Review rows:
   - **DB**: connectivity, schema/table counts, migration hints.
   - **auth**: license + referee ACE.
   - **lock**: stray \`editor_locks\` rows.
4. For incidents, **Copy report (Markdown)** and send to admins.

## After reading

- Snapshot is **point in time** — re-run after config changes.
- Failed rows may show hints in **detail** / toasts.

## FAQ

**Q. All green but save still fails**  
A. Health is broad; per-event errors need toasts/F8 and [Autosave failed](#/workspace/help/article/trouble_autosave_failed).

**Q. Browser dev without FiveM**  
A. NUI mock may return canned OK — verify **inside FiveM** for production-like checks.

## See also

- [Lost connection](#/workspace/help/article/trouble_connection_lost)
- [When autosave fails](#/workspace/help/article/trouble_autosave_failed)
- [First-time setup](#/workspace/help/article/intro_setup)
`,v=`---
title: I recorded the wrong goal
category: urgent
tags: [goal, undo, mistake, G]
related: [trouble_e1003_lock_held]
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

### 3. Admin / policy

Complex cases may need server-side fixes per your rules.

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

Run **Health check** and share server logs with admins.

## See also

- [Another referee is editing (E1003)](#/workspace/help/article/trouble_e1003_lock_held)

## Shortcuts

- \`G\` — goal wizard (match detail, when enabled)  
- \`Esc\` — close dialog
`;export{v as _,w as a,y as b,g as c,_ as d,f as e,p as f,m as g,u as h,h as i,d as j,c as k,l,i as m,s as n,o,r as p,a as q,t as r,n as s,e as t};
