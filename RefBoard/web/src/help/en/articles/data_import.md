---
title: Import a JSON backup
category: data
tags: [data, backup, import, json, restore, migration, 取り込み, partial merge, selective]
related: [data_export, data_view_history]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Import a JSON backup

## What this page covers

- How to restore a **full-data JSON** backup from **Data**
- The difference between **Replace** and **Merge**, and **selective merge** (pick teams / roster / matches)
- Why you must **reload the page** after importing
- **Import history** stays on this browser/device only

## Prerequisites

- The file must be a **RefBoard full backup** with `schemaVersion: 1`. Single-match JSON and CSV are not imported here.
- Invalid or truncated JSON is rejected during preview; **localStorage is not changed** until you confirm an import.

## Steps

1. Open **Data** and choose **Import from JSON**.
2. Pick the backup **.json** file. Review the counts and the **lists of teams, roster rows, and matches** from the file.
3. Understand **Replace** vs **Merge**:
   - **Replace**: **Deletes everything** locally, then writes the backup. There is **no per-entity selection** (full file only). A **two-step confirmation** reduces mistakes. Import history is preserved and merged with a new head entry.
   - **Merge**: Append teams, roster rows, and matches with **new IDs**. **Settings (display name, etc.) stay** on this device.
4. When **Merge** is selected, you can **check teams, roster rows, and matches individually** (v0.2.0). Use **Select all / Clear** per section.
5. **When a match is selected, also include related teams and roster** (default **on**): home/away teams for checked matches and any **rosterMemberId** referenced by those matches’ players are auto-checked. Turn it **off** only if you intend to select everything manually; validation blocks confirm until home/away teams and required roster rows are covered.
6. After success, click **Reload to apply** so the page reloads. Pinia stores must rehydrate from disk.

## After you import

- **Import history** (up to 20 rows) lists time, operator label, mode, and counts. **Partial merge** rows are labeled accordingly. Nothing is sent to a server.
- To move devices: export **Full data backup (JSON)** on the old device, then import on the new one.

## FAQ

**Q. “Unsupported schema”**  
A. This build only accepts the schema version it was built for (currently **1**). Update the app if backups use a newer schema.

**Q. I closed without reloading**  
A. Lists may stay stale. Reload the browser or revisit Data after a full refresh.
