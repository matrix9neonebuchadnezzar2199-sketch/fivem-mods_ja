---
title: Player has timeline events (E3006)
category: trouble
tags: [player remove, timeline, events, E3006, player_has_events, draft]
related: [trouble_undo_goal, match_finish, match_manual_score_edit]
errorCode: E3006
errorKey: player_has_events
---

# Player has timeline events (E3006)

## What is happening

You tried to remove a player from the match roster, and the server returned **`E3006`** (`player_has_events`). The player is referenced by **at least one non-voided event** on the timeline.

The server checks `match_events` rows where `voided_at IS NULL` and the player appears as any of:

- Scorer (`player_id`)
- Assist (`assist_player_id`)
- Substitute in (`sub_in_player_id`)
- Substitute out (`sub_out_player_id`)
- Card recipient (`player_id`)

This is a data-integrity guard so a player cannot vanish from the roster while still being credited with a goal.

## Prerequisites

- Match status must be **`draft`** (in-progress). Removing players from a finished match is rejected with **`E3004`** (`bad_status` — see `shared/error_codes.lua` / `MATCH_ALREADY_FINISHED`).
- You must hold the **edit lock**.
- The player must not appear in any non-voided event (this article).

## How to fix

### 1. Void the related events first (recommended)

From the **Match progress** tab, void each event that mentions the player (`voided_at` will be set). Once all of them are voided, the **Remove** button on the roster will succeed.

1. Open the match → **Match progress** tab.  
2. Find every event row showing this player's name.  
3. Use the row menu → **Void**.  
4. Try **Remove** on the roster again.

### 2. Replace the player instead

If you noticed midway that "it was actually a different person," it is usually cleaner to **add the correct player and use a substitution event to swap them in**. If the wrong player has no real on-field events, voiding them and then removing also works.

### 3. DB-side correction (last resort)

If voiding would falsify a public match record, an admin can set `match_events.voided_at` directly in the DB or write a corrective entry into `edit_logs`. **The UI does not expose this path.**

## After resolution

- After step 1, `match_players` is **physically DELETEd** and the action is recorded in `edit_logs`. The `E3006` warning itself is not logged.
- After step 2, both players remain in `match_players` as part of history.
- After step 3, leave a `note` in `edit_logs` explaining the correction.

**You cannot** remove a player while keeping their non-voided events.

## FAQ

**Q. Why don't voided events count toward E3006?**  
A. The server query only counts rows where `voided_at IS NULL` (see `server/player.lua`). Voided events are excluded.

**Q. The match is already finished and I want to remove a player.**  
A. Removal on a finished match is rejected with **`E3004`** (`bad_status`). **Reopen** the match to return it to `draft`, then follow step 1.

**Q. Why have a remove button at all if it is this strict?**  
A. Remove is intended for **undoing an accidental add right after it happens**. Once a player has on-field events, they belong to the history of the match.

## Still stuck?

- Run **Settings → Health check** to verify DB / edit lock state.
- Inspect `edit_logs` for add/void history of the player to see which events remain.

## See also

- [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
- [Manually edit the score](#/workspace/help/article/match_manual_score_edit)
