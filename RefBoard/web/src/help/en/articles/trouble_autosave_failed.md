---
title: When autosave fails
category: urgent
tags: [autosave, save, DB, error]
related: [trouble_connection_lost]
errorCode: E4003
errorKey: tx_failed
---

# When autosave fails

Autosave shows an error, or the ACK includes `error: 'tx_failed'` / **`E4003`** (also used for some main score transaction failures).

## What happened

A recent **DB write** (draft save, score update, etc.) failed. Common causes:

- MySQL glitch  
- Deadlock / timeout  
- Validation / integrity error  

## What to do

### Step 1 — Retry

Use **Retry** if shown; otherwise **repeat** the action.

### Step 2 — Pause and retry

If it keeps failing, wait **seconds to tens of seconds**, then try again.

### Step 3 — Health check

**Settings → Health check** for DB and schema.

### Step 4 — Logs

Give admins **Logger ERROR** lines and, if possible, NUI trace (`refboard_trace`).

## After retry

- **Success**: indicator returns to saved.  
- **Still failing**: treat as **unsaved** — do not assume progress; fix infra first.

## FAQ

**Q. UI shows new score but server disagrees**  
A. Could be optimistic UI — **reload** and trust server state.

**Q. `tx_failed` vs `db_query_failed`**  
A. Both are DB-layer failures — diagnose via health + logs.

## See also

- [Lost connection](#/workspace/help/article/trouble_connection_lost)
