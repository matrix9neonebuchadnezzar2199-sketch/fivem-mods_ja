---
title: I recorded the wrong goal
category: urgent
tags: [goal, undo, mistake, G]
related: [trouble_e1003_lock_held]
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

### 3. Admin / policy

Complex cases may need server-side fixes per your rules.

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

Run **Health check** and share server logs with admins.

## See also

- [Another referee is editing (E1003)](#/workspace/help/article/trouble_e1003_lock_held)

## Shortcuts

- `G` — goal wizard (match detail, when enabled)  
- `Esc` — close dialog
