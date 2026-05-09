---
title: What is RefBoard?
category: intro
tags: [overview, referee, match, FiveM, local]
related: [intro_setup, match_create_new]
shortcut: null
actionUrl: null
errorCode: null
---

# What is RefBoard?

## What you will learn

- What RefBoard is for (staff / referee match logging)
- Where data is stored in **v0.1.0 local mode**

## About RefBoard

RefBoard is an **NUI tool for FiveM** to **manage football matches** — scores, timeline events, and lineups.

In **v0.1.0**, data is **not sent to a game database**: it is kept in the browser’s **`localStorage`** only. There is no automatic sync across PCs — use **Data** exports for backups.

- **Framework-agnostic**: no ESX/QBCore dependency.
- **History**: manual score changes are kept in on-device history (see each task’s help article).

## After reading

Concepts only. Use **Matches**, **Teams**, and **Data** for real actions.

## FAQ

**Q. Offline?**  
A. It still runs as FiveM NUI, but **no external DB** is required; data stays on the device.

**Q. Moving to another PC**  
A. Use **Data** → **Full data backup (JSON)** and restore on the new machine.

## See also

- [Get started with RefBoard](#/workspace/help/article/intro_setup)
- [Create a new match](#/workspace/help/article/match_create_new)
