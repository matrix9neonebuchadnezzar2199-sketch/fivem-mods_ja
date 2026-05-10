---
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
- Using `PenaltyShootoutPanel` (make / miss)
- Auto winner detection and finishing

## Prerequisites

- Match in **edit mode**.
- Regulation (and extra time if used) **ended** with **tied score** (per your rules).
- Both sides agreed to PKs (house rules).

## Before Starting

Both teams must have at least **one player** registered to start the penalty shootout. If either team has zero players, the shootout cannot be started (a warning will be displayed).

## Start PKs

1. In `MatchStatusCard`, switch half to **PK**.
2. Confirm **Start penalty shootout?** and pick **first team**.
3. `current_half` becomes **`pk`**; **PenaltyShootoutPanel** appears.
4. Score **breakdown** gains a `pk` column.

## Record each kick

1. Pick **kicker** from eligible players.
2. **Scored** or **Missed**.
3. Server records successes; alternation is guided by the UI.
4. `evaluatePenaltyShootout` decides the winner after 5 each and sudden death as implemented.

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
