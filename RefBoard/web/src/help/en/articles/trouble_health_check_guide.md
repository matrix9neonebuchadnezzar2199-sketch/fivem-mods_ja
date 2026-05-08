---
title: How to read the health check
category: trouble
tags: [health, DB, permission, lock, diagnostics]
related: [trouble_autosave_failed, trouble_connection_lost, intro_setup]
shortcut: null
actionUrl: "#/workspace/health"
errorCode: null
---

# How to read the health check

## What you will learn

- How rows are grouped (**server / db / auth / presence / lock / config**)
- **Re-run** and **Copy Markdown** for sharing with staff

## Prerequisites

- Open **Settings** and follow the **Health check** link (or `#/workspace/health`).

## Steps

1. Open **Health check**.
2. **Re-check** sends `refboard:health:check` (or equivalent) and refreshes the table.
3. Review rows:
   - **DB**: connectivity, schema/table counts, migration hints.
   - **auth**: license + referee ACE.
   - **lock**: stray `editor_locks` rows.
4. For incidents, **Copy report (Markdown)** and send to admins.

## After reading

- Snapshot is **point in time** — re-run after config changes.
- Failed rows may show hints in **detail** / toasts.

## FAQ

**Q. All green but save still fails**  
A. Health is broad; per-event errors need toasts/F8 and [Autosave failed](#/workspace/help/article/trouble_autosave_failed).

**Q. Browser dev without FiveM**  
A. NUI mock may return canned OK — verify **inside FiveM** for production-like checks.

## See also

- [Lost connection](#/workspace/help/article/trouble_connection_lost)
- [When autosave fails](#/workspace/help/article/trouble_autosave_failed)
- [First-time setup](#/workspace/help/article/intro_setup)
