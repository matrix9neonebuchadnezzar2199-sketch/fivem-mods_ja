---
title: Open CSV in Excel
category: data
tags: [Excel, CSV, encoding, BOM, UTF-8, date, apostrophe, import, garbled]
related: [data_export, data_csv_format]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Open CSV in Excel

## What this page covers

- RefBoard CSV is **UTF-8 with BOM**, which Excel usually reads correctly
- When values like **`45+2'`** are mistaken for **dates**

## Avoiding mojibake

Match CSV files include a **BOM**. Double-clicking in Excel often shows Japanese text correctly.

If characters are wrong:

1. In Excel: **Data** → **From Text/CSV**
2. Pick the file and set encoding to **65001: Unicode (UTF-8)**
3. Use **comma** as the delimiter and finish

## `45+2'` turning into a date

Excel may auto-convert **`10'`** or **`45+2'`** in `minute_label` to a date/time.

**Mitigations**

- Set the column format to **Text** before or after import
- In **Get Data**, set the column type to **Text**
- For analysis, prefer numeric **`event_minute`** / **`event_stoppage`** (detailed export)

## See also

- Column reference: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
