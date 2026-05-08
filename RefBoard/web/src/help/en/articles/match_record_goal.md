---
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

1. From the **event menu** under the scoreboard, choose **Goal** (shortcut **`G`**).
2. Pick **home or away**.
3. Select the **scorer** from `PlayerSelectGrid` (on-pitch players only).
4. Optionally select an **assist**, or leave **no assist**.
5. Adjust **minute** and **half** if needed (defaults match current play).
6. Confirm in the dialog.

## After recording

- Scoreboard **+1** with a score flash (increment only).
- Timeline shows `⚽ Scorer (Assist)`.
- Player table: **G** +1 for scorer, **A** +1 if assist set.
- Other referees receive updates via `refboard:match:state`.
- DB updates `match_events`, `match_score_history`, and `matches` in **one transaction** (rollback on failure).

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
A. Use an **integer minute** (e.g. `47`), not `45+2` text.

## See also

- [Add or change an assist](#/workspace/help/article/match_record_assist)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)

## Shortcuts

| Key | Action        |
|-----|---------------|
| `G` | Open goal wizard |
| `Esc` | Close wizard (discard unconfirmed) |
