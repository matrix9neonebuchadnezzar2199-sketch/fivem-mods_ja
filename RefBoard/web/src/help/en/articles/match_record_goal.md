---
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

1. Under the scoreboard, open the **event menu** → **Goal** (shortcut **`G`**).
2. Pick **home or away**.
3. Select the **scorer** (on-pitch players only).
4. Optionally pick an **assist**, or leave **no assist**.
5. Set **match minute** if needed (`45+2` for stoppage; leave blank and confirm to use the **current match clock**). Half follows the match clock phase.
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
- Data is saved to this device’s **`localStorage`**.

## If you made a mistake

- **Right after recording**: use timeline **Undo** when available — see [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal).
- **Wrong scorer**: undo and re-record is safest.
- **Numbers only**: [manual score edit](#/workspace/help/article/match_manual_score_edit).

## FAQ

**Q. Own goals**  
A. Record as the **opponent’s goal** and add a note.

**Q. Stoppage time**  
A. In the wizard’s **match minute** field, enter **`45+2`** style (`minute+stoppage`; `+` can be half-width or full-width). Leave it blank and confirm to use the **current match clock** minute. The timeline shows values like `45+2'`.

## See also

- [Yellow and red cards](#/workspace/help/article/match_card)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)

## Shortcuts

| Key | Action |
|-----|--------|
| `G` | Open goal wizard |
| `Esc` | Close wizard (discard unconfirmed) |
