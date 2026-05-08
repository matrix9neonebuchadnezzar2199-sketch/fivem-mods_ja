---
title: What is RefBoard?
category: intro
tags: [overview, referee, match, FiveM, MySQL]
related: [intro_setup, match_create_new]
shortcut: null
actionUrl: null
errorCode: null
---

# What is RefBoard?

## What you will learn

- What RefBoard is for, and how server vs client roles differ
- Why edit locks, history, and autosave exist

## About RefBoard

RefBoard is an **NUI tool for FiveM** for **managing football matches**. Referees (staff) record **scores, timeline events, and lineups**; **MySQL is the single source of truth** shared across clients.

- **Framework-agnostic**: no ESX/QBCore dependency. Players with the `refboard.referee` ACE can use it.
- **Single edit lock**: only **one person** can edit a given match at a time. Others can open in view mode.
- **History**: manual score edits are stored **with reasons** in `match_score_history` (see each action’s help).

## Prerequisites (users)

- The **RefBoard resource**, **oxmysql**, and **initial SQL (`sql/install.sql`)** are applied on the server.
- Your identifier has the **`refboard.referee` ACE** (view-only usage depends on your server rules).

## After reading

This article explains concepts only. Use **Matches**, **Teams**, and **Data** screens for real actions.

## FAQ

**Q. Can every player use it?**  
A. Normally it is **for staff/referees**. Players without the ACE are rejected on the server.

**Q. Does it work offline?**  
A. **No**. It runs as NUI on a FiveM client connected to the server and DB.

## See also

- [First-time setup](#/workspace/help/article/intro_setup)
- [Create a new match](#/workspace/help/article/match_create_new)
