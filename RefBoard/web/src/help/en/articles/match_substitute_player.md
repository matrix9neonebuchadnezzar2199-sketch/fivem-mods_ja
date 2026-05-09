---
title: Substitute a player
category: in_match
tags: [sub, substitution, bench]
related: [match_card, match_record_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Substitute a player

## What you will learn

- Substitution flow (`SubstitutionDialog`)
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
4. Set **minute** and **half** if needed.
5. Confirm.

## After substitution

- OUT → **`subbed_out`**, IN → **`active`**.
- Timeline: `🔁 OUT → IN`.
- List order refreshes (on-pitch vs bench/subbed).

## Cards and send-offs

- **One yellow**: substitution still OK.
- **Second yellow / straight red**: player is **sent off**; you **cannot** bring them back as IN. See [Yellow and red cards](#/workspace/help/article/match_card).

## FAQ

**Q. Can a subbed player return to the pitch?**  
A. No dedicated **re-entry** flow; `subbed_out` → `active` is not offered in UI by design.

**Q. Add roster player mid-flow**  
A. Use **Add player** / roster flow first, then substitute.

## See also

- [Yellow and red cards](#/workspace/help/article/match_card)
- [Record a goal](#/workspace/help/article/match_record_goal)
