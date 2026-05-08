---
title: Add or change an assist
category: in_match
tags: [assist, score, edit]
related: [match_record_goal, trouble_undo_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Add or change an assist

## What you will learn

- How to attach an assist when recording a goal
- How to fix assist **after** the goal (current limitations)
- When player **A** stats update

## Prerequisites

- Match in **edit mode**.
- Assist candidate is on the **same team** as the scorer and on the pitch.

## During goal recording

1. After picking the scorer, use **`PlayerSelectGrid`** for the assist.
2. Or choose **no assist** and confirm.

## After the goal (change assist)

There is **no dedicated “edit assist only” UI** yet. Use one of:

1. **Undo and re-record (recommended)**: timeline → **Undo** on that goal → record goal again (net score unchanged).
2. **Ops note**: if you must log a correction without re-recording, follow your staff policy (e.g. `edit_logs` / admin).

## After a successful assist

- Player **A** column +1.
- Timeline text includes assist when applicable.
- Data views aggregate assists in real time.

## FAQ

**Q. Double assist?**  
A. Only **one** assist is supported today.

## See also

- [Record a goal](#/workspace/help/article/match_record_goal)
- [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal)
