---
title: Events missing or not visible
category: trouble
tags: [event, missing, display, reload, timeline, PK, troubleshooting, record]
related: [match_pk_recording, trouble_undo_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Events missing or not visible

## What this page covers

- First checks when an event you recorded **does not show** in the UI
- Cases where **PK** or **compact dock** changes what you see

## Checklist

### 1. Reload

Press **F5** (or reload NUI). Sometimes the view lags behind the store.

### 2. Which list you are looking at

- **Match detail timeline** and the **PK panel** are different surfaces. PK shots still appear in the timeline as penalty rows; the PK UI shows structured rows.
- In **compact dock**, **recent events are hidden during PK**. Use the full PK UI instead.

### 3. Tell saved vs display

The app **does not offer export/backup UI**. If you can inspect **`localStorage`** with devtools, check whether the match blob’s `events` array contains the row. Missing there means it likely **never saved**; present there but not on screen points to a **UI refresh** issue.

### 4. Operator name

Setting **Settings → display name** helps auditing who operated, even though it does not control visibility.

## Still wrong?

- Can you reproduce on **another match**?
- Did you **undo** or void events?

Note steps and tell the maintainer if it looks like a bug.

## See also

- PK UI: [#/workspace/help/article/match_pk_recording](#/workspace/help/article/match_pk_recording)
