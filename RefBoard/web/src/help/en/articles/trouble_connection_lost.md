---
title: Lost connection — is my data OK?
category: urgent
tags: [connection, disconnect, autosave]
related: [trouble_autosave_failed]
---

# Lost connection — is my data OK?

**Short answer:** the server’s **MySQL** is the source of truth. **What the server accepted is saved.** The client is for display and input.

## Why

- Actions go over NetEvents; on success the DB updates.  
- **Autosave** (`match_drafts`) backs up in-progress UI state.  
- After disconnect, data remains **as of the last successful server commit**.

## Scenarios

### FiveM client crashed

- Lock **times out** and releases.  
- Reconnect, reopen the match, re-acquire lock if needed.

### Brief network blip

- Retry the action; check toasts.  
- For traces: `localStorage.refboard_trace = '1'`, reload, watch F8 (see internal sprint docs).

### Server or DB down

- Use **Health check** after recovery.

## Recovery

1. Reconnect.  
2. Open the match from the list.  
3. Re-acquire edit lock if editing.  
4. Run **Health check** if unsure.

## After recovery

- You should see everything **committed before** the drop.  
- **Unsent** client-only input may be **lost** — confirm success toasts after important actions.

## FAQ

**Q. Autosave checkmark before crash**  
A. If the server never ACK’d, the action may not exist server-side — **repeat** it.

## See also

- [When autosave fails](#/workspace/help/article/trouble_autosave_failed)
