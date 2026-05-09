---
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

- Set match to **`finished`**
- UI/data changes after finish
- **Reopen** flow and caveats

## Prerequisites

- **Edit mode**.
- Play reached **end of second half** (or PK decided) — finishing early is possible but discouraged.

## Finish

1. **Finish match** from `MatchStatusCard` or header.
2. Confirm dialog shows score and breakdown.
3. Server runs `Match.finish`; `refboard:match:finished` switches clients to **view** mode.

## After finish

- `status` = **`finished`**, `finished_at` set.
- Timeline and roster **read-only**.
- Appears in Data history with final score.
- Edit lock released.
- Draft rows in `match_drafts` **kept** for reopen.

## Reopen

1. In **match list**, **[Reopen]** on the row.
2. Confirm: match returns **`in_progress`**; `reopened_*` logged.
3. Acquire edit lock as usual.

## Reopen — OK

- Undo/add goals, cards, subs.
- Manual score edit.
- Fix roster / minutes.

## Reopen — watch out

- **Exported CSV** may disagree with new finals — **re-export** summaries.
- **`reopened_*`** shows last reopen; full trail in `edit_logs`.
- **PK winner** can change if you undo PK events — avoid heavy PK edits unless necessary.

## Cancel / delete

- No dedicated **cancel** flow. Unused drafts: follow staff DB policy.

## FAQ

**Q. Match looks stuck after finish**  
A. The local build has **no edit locks**. Reload the page or reopen the match from the list.

**Q. Multiple reopens**  
A. Allowed; `reopened_*` stores **last** event only — use `edit_logs` for history.

## See also

- [Penalty shootout](#/workspace/help/article/match_penalty_shootout)
- [Manual score edit](#/workspace/help/article/match_manual_score_edit)
- [Wrong goal](#/workspace/help/article/trouble_undo_goal)
