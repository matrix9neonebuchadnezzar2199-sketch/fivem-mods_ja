---
title: Record yellow and red cards
category: in_match
tags: [yellow, red, warning, send-off, card]
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
3. Optional **minute** and short **reason**.
4. Confirm.

## Straight red

1. Open **Card**.
2. Choose **Red**.
3. Optional minute / reason.
4. Confirm the **send-off** dialog.

## Second yellow → red

If a player already has one yellow and you issue **yellow** again, the UI explains that this becomes a **red**. Confirm to apply warning count and send-off together.

## After issuing

- Timeline rows show `🟨` / `🟥` (or combined notation for second yellow).
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
