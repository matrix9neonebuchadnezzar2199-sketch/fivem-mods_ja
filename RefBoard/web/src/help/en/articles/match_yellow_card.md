---
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
- Player is **on the pitch** for this match (`active` or similar).

## Steps

1. **Card** on the player row, or **event menu → Card**.
2. Choose **Yellow**.
3. Optional **minute** and **short reason**.
4. Confirm.

## After issuing

- Player **`yellow_cards`** +1.
- Timeline: `🟨 Name (reason)`.
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
