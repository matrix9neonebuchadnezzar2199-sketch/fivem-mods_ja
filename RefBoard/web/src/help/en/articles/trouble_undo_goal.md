---
title: I recorded the wrong goal
category: trouble
tags: [undo, mistake, G, wrong goal, take back]
related: [match_record_goal, match_manual_score_edit]
shortcut: G
---

# I recorded the wrong goal

Wrong scorer, wrong team, or accidental goal — **after** recording.

## Fix

### 1. Undo (preferred)

Use **Undo** near the scoreboard/timeline when it reverses the **last score change**. Audit still logs the undo.

### 2. Manual score edit

If undo is not enough:

1. Open **manual score edit**.  
2. Enter correct totals.  
3. **Reason ≥ 5 characters** (e.g. “Correcting mistaken goal”).  
4. Confirm.

### 3. Restore from backup

If many mistakes stack up, consider restoring from a recent **JSON backup** (**Data** screen).

## After fix

- **Undo**: score and UI roll back; history keeps entries.  
- **Manual edit**: totals update; reason stored in **score history**.

RefBoard does **not** erase audit trails — corrections are visible, not hidden.

## FAQ

**Q. After match finished?**  
A. **Reopen** the match, then undo or manual-edit as allowed.

**Q. Assist disappears with goal undo?**  
A. Depends how the goal was removed; manual number-only edit may leave old event rows.

## If still wrong

Use **Data** → **Full data backup (JSON)** to snapshot the current state, restart the client, and reopen the match. If it persists, restore from backup.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [Edit the score manually](#/workspace/help/article/match_manual_score_edit)

## Shortcuts

- `G` — goal wizard (match detail, when enabled)  
- `Esc` — close dialog
