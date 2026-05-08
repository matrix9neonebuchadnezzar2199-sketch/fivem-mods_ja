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
- Wrong first team: **no cancel-PK UI** yet — contact admin or annotate per ops policy.
- Need to go back before PK: avoid starting PK until sure; there is **no** simple “rewind half” UI.

## FAQ

**Q. Edit PK score manually?**  
A. **Not** via manual score edit (that is for regulation goals). Use PK event undo/re-record.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)
