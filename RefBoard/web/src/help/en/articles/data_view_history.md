---
title: View history in Data
category: data
tags: [data, match history, stats, log]
related: [data_export, match_finish]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# View history in Data

## What you will learn

- **Data** tabs: matches, teams, players, logs
- Filters and opening a match from the table

## Prerequisites

- **`refboard.referee` ACE** (server enforces access).

## Steps

1. Open **Data** from the sidebar.
2. Pick a tab:
   - **Matches**: filters by date, team, status, etc.
   - **Teams / Players**: aggregate rows (columns per build).
   - **Logs**: audit `edit_logs` excerpts when available.
3. From **Matches**, use **Open** (or equivalent) to jump to match detail.

## Behavior

- Tabs are **read-heavy**; editing happens in match detail, not here.
- Changing filters **re-queries** the server.

## FAQ

**Q. Numbers differ from match detail**  
A. Filters or **reopen** state may differ — open the match and compare timeline.

**Q. Live updates**  
A. View reflects **last load**; switch tabs or reopen to refresh (auto-poll may be absent).

## See also

- [Export to CSV](#/workspace/help/article/data_export)
- [Finish or reopen a match](#/workspace/help/article/match_finish)
