---
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
- Deliberate reconciliation when `match_events` and `home_score`/`away_score` diverge

See [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal) first for normal mistakes.

## Prerequisites

- **Edit mode** with lock.
- `refboard.referee` ACE.

## Steps

1. Click the **score digits** or open **Manual score edit** from the menu.
2. Enter new **home / away** values in `ScoreEditDialog`.
3. **Reason — at least 5 characters** (otherwise **`E2005 reason_too_short`**).
4. Save.

## After save

- `matches.home_score` / `away_score` update.
- **`match_score_history`** gets a `manual_edit` row with the reason (view in `ScoreHistoryDialog`).
- **`match_events` unchanged** — events and aggregate score can **intentionally** differ.
- No scoreboard “flash” animation for manual edits.

## Errors

| Code | Meaning | Fix |
|------|---------|-----|
| `E2005` | reason too short | Use **5+ characters**. |
| `E1002` | not_editor | Reload or reopen the match detail screen. |
| `E4003` | tx_failed | Save failed — retry; if it persists check browser storage / extensions. |

## FAQ

**Q. Edit PK breakdown here?**  
A. **No** — regulation totals only. Fix PK rows on the timeline.

**Q. Delete history rows?**  
A. **Append-only**. Add another manual edit with reason “Correction: …” if you mistyped.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
