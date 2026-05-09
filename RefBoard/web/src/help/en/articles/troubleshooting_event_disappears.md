---
title: Events missing or not visible
category: trouble
tags: [event, missing, display, reload, JSON, timeline, PK, troubleshooting, record]
related: [data_csv_format, match_pk_recording, trouble_undo_goal]
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

- **Match detail timeline** and the **PK two-column list** are different surfaces. PK shots still appear in the timeline as penalty rows; the PK panel shows structured rows.
- In **compact dock**, **recent events are hidden during PK**. Use the full PK UI instead.

### 3. Inspect raw data

1. Export **match JSON** and check the `events` array.
2. Or export **detailed CSV** and verify `event_index` / `event_text` increased.

If data exists in JSON/CSV but not on screen, suspect a **UI refresh** issue. If absent everywhere, the event may **not have been saved**.

### 4. Operator name

The CSV **operator** column does not control visibility, but setting **Settings → display name** helps auditing who exported or operated.

## Still wrong?

- Can you reproduce on **another match**?
- Did you **undo** or void events?

Note steps and tell the maintainer if it looks like a bug.

## See also

- PK UI: [#/workspace/help/article/match_pk_recording](#/workspace/help/article/match_pk_recording)
- CSV columns: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
