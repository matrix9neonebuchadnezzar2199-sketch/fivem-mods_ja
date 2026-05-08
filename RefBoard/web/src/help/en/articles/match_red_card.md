---
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
3. Confirm: **`yellow_cards` +1** and **`ejected_*`** apply in **one transaction**.

## After send-off

- State **sent off**; timeline `🟥` (or combined notation for 2× yellow).
- Team “available players” count may drop.
- Player **cannot** return as a sub IN.
- Stats: `red_cards` increments.

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
