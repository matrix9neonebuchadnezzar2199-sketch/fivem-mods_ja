---
title: Another referee is editing (E1003)
category: trouble
tags: [lock, edit, E1003, lock_held]
related: [trouble_undo_goal, trouble_connection_lost]
errorCode: E1003
errorKey: lock_held
---

# Another referee is editing (E1003)

## What is happening

Another referee holds the **edit lock** for this match. Only **one editor** per match is allowed. Others can use **view** mode.

Server `error` key: **`lock_held`**, code: **`E1003`**.

## How to fix

### 1. Contact the editor (recommended)

1. Check presence / lock UI for the name.  
2. Reach them on voice/Discord/in-game.  
3. When they release the lock, you can acquire it.

### 2. Wait for timeout

If heartbeats stop for **`Config.LockTimeoutSec`** (default **30s**), the lock auto-releases (disconnect, crash, etc.).

### 3. Open in view mode

If you only need to read, use **View** from the launcher.

## After resolution

- When the lock is free, try **edit** again.
- In view mode you still receive `refboard:match:state` updates.

**You cannot** force-take a lock from the UI.

## Still stuck?

- Run **Settings → Health check**.
- Admins may reset `editor_locks` on restart per policy.

## See also

- [I recorded the wrong goal](#/workspace/help/article/trouble_undo_goal)
- [Lost connection](#/workspace/help/article/trouble_connection_lost)

## Shortcuts

- `Esc` closes dialogs where applicable.
