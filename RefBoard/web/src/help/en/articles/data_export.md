---
title: Export to CSV
category: data
tags: [CSV, export, BOM, Excel, csv export]
related: [data_view_history, data_csv_format, data_csv_excel_open]
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

1. Pick **CSV format** (standard / detailed), then use **CSV** to download **summary** and **events** as **two files** ~200ms apart (v0.3.0+). See [CSV format](#/workspace/help/article/data_csv_format).
2. **JSON** is a separate one-file export.

## After export

- Files saved locally; **BOM** helps Excel decode UTF-8. For Excel quirks see [Open CSV in Excel](#/workspace/help/article/data_csv_excel_open).
- **No change** to database (read-only copy).

## FAQ

**Q. Google Sheets**  
A. Use **Import** or ensure UTF-8 with BOM in import settings.

**Q. Every column including PK?**  
A. **Detailed** mode includes PK result and `pk_shot_index`. See [CSV format](#/workspace/help/article/data_csv_format). Use **JSON export** if you need raw data.

## See also

- [View history in Data](#/workspace/help/article/data_view_history)
- [Finish or reopen a match](#/workspace/help/article/match_finish) (reopen vs exported snapshots)
