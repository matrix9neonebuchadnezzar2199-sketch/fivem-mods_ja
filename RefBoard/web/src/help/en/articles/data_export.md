---
title: Export to CSV
category: data
tags: [CSV, export, BOM, Excel]
related: [data_view_history, match_finish]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Export to CSV

## What you will learn

- Export from **Data** and **match detail**
- **UTF-8 BOM** for Excel-friendly open

## Prerequisites

- NUI allows **blob download**.
- Referee permissions for the dataset.

## From Data

1. On a tab, use **Export CSV** when shown.
2. Filename usually includes date/type (per `refboard_filename` helper).

## From match detail (events)

1. Header **CSV** downloads the **event list** for that match (JSON is separate).

## After export

- File saved locally; **BOM** helps Excel decode UTF-8.
- **No change** to database (read-only copy).

## FAQ

**Q. Google Sheets**  
A. Use **Import** or ensure UTF-8 with BOM in import settings.

**Q. Every column including PK?**  
A. Depends on exporter version; use **JSON export** from match detail if columns are missing.

## See also

- [View history in Data](#/workspace/help/article/data_view_history)
- [Finish or reopen a match](#/workspace/help/article/match_finish) (reopen vs exported snapshots)
