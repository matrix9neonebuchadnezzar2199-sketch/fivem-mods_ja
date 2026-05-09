---
title: Move data to another PC (JSON)
category: data
tags: [migration, backup, JSON, import, replace, merge, device, selfName, partial]
related: [data_import, data_export, intro_setup]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Move data to another PC (JSON)

## What this page covers

- Exporting **full JSON backup** and restoring on another machine
- **Replace** vs **merge**
- **Display name (selfName)** is per-device

## Overview

### 1. Export on the old PC

1. Open **Data**
2. Run **Full data backup (JSON)**
3. Copy `refboard_backup_*.json` to the new PC (USB, cloud, etc.)

### 2. Import on the new PC

1. Open **Data** → **Import from JSON**
2. Choose mode  
   - **Replace**: wipe this device and use only the backup (**first-time migration**)  
   - **Merge**: keep existing data and reassign IDs (**add** another device’s data)
3. Partial merge lets you pick teams / rosters / matches. Importing matches can auto-include related teams.

### 3. After import

- **Reload the page** as prompted so Pinia reloads.
- **Display name** lives in `refboard_settings`; you may need to set it again in **Settings** (separate from CSV `operator`).

## FAQ

**Q. Isn’t CSV enough?**  
A. CSV is flat columns; JSON keeps the full structure. Use **JSON for full moves**, **CSV (summary + events)** for spreadsheets.

## See also

- Import UI: [#/workspace/help/article/data_import](#/workspace/help/article/data_import)
- CSV columns: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
