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
title: Get started with RefBoard
category: intro
tags: [setup, display name, teams, match, localStorage]
related: [intro_what_is_refboard, match_create_new]
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

## Important

RefBoard **does not talk to a game server** for storage. Data lives in this browser’s **\`localStorage\`**. **Clearing site data** or using **Clear all data** in settings removes everything with **no recovery**. Keep any records you need elsewhere (notes, screenshots, etc.).

## See also

- [What is RefBoard?](#/workspace/help/article/intro_what_is_refboard)
- [Create a new match](#/workspace/help/article/match_create_new)
`,t=`---
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
`,a=`---
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
`,o=`---
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
`,r=`---
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

## Before Starting

Both teams must have at least **one player** registered to start the penalty shootout. If either team has zero players, the shootout cannot be started (a warning will be displayed).

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
- Wrong first team: with **zero** kicks recorded, use **Re-select First Team** at the bottom of the panel. After any kick, undo kicks until none remain, then re-select—or use **Cancel Penalty Shootout** below to return to the second half.
- Entered PK by mistake: use **Cancel Penalty Shootout** (returns to second half, 2H).

## FAQ

**Q. Edit PK score manually?**  
A. **Not** via manual score edit (that is for regulation goals). Use PK event undo/re-record.

## Selecting the First Kicker Team

When transitioning to penalty shootout, a dialog appears to select the first kicking team. Choose home or away based on the coin toss result. Once set, the first team cannot be changed after any PK kick has been recorded (to maintain record consistency).

## Undoing the Last Kick

Use the "↶ Undo Last Kick" button at the bottom of the PK panel to void the most recently recorded kick. A confirmation dialog appears before execution. Voided kicks remain in the timeline as "voided".

## Re-selecting the First Team

The "Re-select First Team" button is shown only when no PK kicks have been recorded. Use it after undoing all kicks via "Undo Last Kick", or right after the PK transition if you set the wrong team. To re-select after recording any kick, you must undo all kicks first.

## Cancelling the Penalty Shootout

Use the "Cancel Penalty Shootout" button at the bottom-right of the PK panel to abort the shootout and return to the second half (2H). Use this if you accidentally entered the PK phase or noticed that players are missing. A confirmation dialog shows the number of recorded events; confirming voids all PK events. They remain in the timeline as voided.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)
`,l=`---
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
`,c=`---
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
`,h=`---
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
`,d=`---
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
`,m=`---
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
`,u=`---
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
`,p=`---
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
`,g=`---
title: Events missing or not visible
category: trouble
tags: [event, missing, display, reload, timeline, PK, troubleshooting, record]
related: [match_pk_recording, trouble_undo_goal]
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

- **Match detail timeline** and the **PK panel** are different surfaces. PK shots still appear in the timeline as penalty rows; the PK UI shows structured rows.
- In **compact dock**, **recent events are hidden during PK**. Use the full PK UI instead.

### 3. Tell saved vs display

The app **does not offer export/backup UI**. If you can inspect **\`localStorage\`** with devtools, check whether the match blob’s \`events\` array contains the row. Missing there means it likely **never saved**; present there but not on screen points to a **UI refresh** issue.

### 4. Operator name

Setting **Settings → display name** helps auditing who operated, even though it does not control visibility.

## Still wrong?

- Can you reproduce on **another match**?
- Did you **undo** or void events?

Note steps and tell the maintainer if it looks like a bug.

## See also

- PK UI: [#/workspace/help/article/match_pk_recording](#/workspace/help/article/match_pk_recording)
`;export{g as _,p as a,u as b,m as c,d,h as e,c as f,l as g,i as h,s as i,r as j,o as k,a as l,t as m,n,e as o};
