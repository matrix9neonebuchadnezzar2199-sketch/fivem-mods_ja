---
title: CSV export format (v0.3.0)
category: data
tags: [CSV, export, format, standard, detailed, summary, events, BOM, UTF-8, columns]
related: [data_export, data_import, data_csv_excel_open]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# CSV export format (v0.3.0)

## What this page covers

- **Summary** and **events** delivered as **two files**
- **Standard (13 columns)** vs **detailed (26 columns)**
- How filenames are built

## Two files per export

For each match, two downloads run about **0.2 s** apart:

1. **`refboard_m{id}_{YYYY-MM-DD}_summary.csv`** — one metadata row (**9 columns**)
2. **`refboard_m{id}_{YYYY-MM-DD}_events.csv`** — one row per event (**13 or 26 columns**)

In **Data** (finished match row) or **Match detail** header, choose **Standard** / **Detailed** in the dropdown, then export.

## Summary CSV (9 columns)

`match_id`, `match_title`, `match_date`, `home_team`, `away_team`, `final_score`, `match_status`, `operator`, `exported_at`

- `match_id` uses an **`m_`** prefix (e.g. `m_42`)
- `final_score` can include PK, e.g. `1-1 (PK 2-2)`
- `operator` is **Settings display name** (may be empty if unset)

## Events CSV — standard (13 columns)

`match_id`, `match_title`, `match_date`, `home_team`, `away_team`, `final_score`, `event_index`, `event_kind`, `event_team`, `minute_label`, `event_minute`, `event_text`, `recorded_at_iso`

- `event_kind` values include `goal`, `substitution`, `pk_goal`, `pk_miss`, `yellow`, `red`, …
- `minute_label` uses display form e.g. `45+2'` or `PK` for shootout kicks
- Substitutions use a **single `sub_out` row** (no separate `sub_in` row)

## Events CSV — detailed (26 columns)

Adds stoppage, player/assist numbers and names, card colour, sub in/out, PK result and per-team `pk_shot_index`, `operator` on each row, etc.

## See also

- Flow overview: [#/workspace/help/article/data_export](#/workspace/help/article/data_export)
- Excel tips: [#/workspace/help/article/data_csv_excel_open](#/workspace/help/article/data_csv_excel_open)
