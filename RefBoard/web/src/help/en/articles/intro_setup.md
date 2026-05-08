---
title: First-time setup (admins & referees)
category: intro
tags: [install, ACE, password, oxmysql, SQL]
related: [intro_what_is_refboard, trouble_health_check_guide]
shortcut: null
actionUrl: null
errorCode: null
---

# First-time setup (admins & referees)

## What you will learn

- One-time **server admin** tasks (DB, resource, permissions)
- **Referee** tasks in-game (open tool, edit mode)

## Prerequisites

- **MySQL** and **oxmysql** on the server, with a chosen database.

## Steps — server admin

1. Run **`sql/install.sql`** against the **same database oxmysql uses** (running it on another DB causes `Table doesn't exist`).
2. Apply **`sql/migration_*.sql`** as needed for your environment.
3. In `server.cfg`, **`ensure oxmysql`** then **`ensure RefBoard`** (match the folder name).
4. Grant ACE to referees, e.g.  
   `add_ace identifier.license:xxxxxxxx refboard.referee allow`
5. Share **`Config.EditPassword`** from **`config.lua`** with staff (used when entering edit mode from the launcher).

## Steps — referee (in-game)

1. Open NUI with **`/refboard`** or **`F6`** (`Config.OpenKey` in `config.lua`).
2. On first launch, pick **View** or **Edit** in the launcher; **Edit** requires the password above.
3. Use the sidebar to open **Matches**, **Teams**, etc.

## After setup

- After SQL succeeds, team/match/lock tables are available and APIs work from NUI.
- After ACE is granted, only players with `refboard.referee` can access protected actions.

## FAQ

**Q. `Table '….teams' doesn't exist`**  
A. **install.sql** was not run on the connected DB. Check the README install section.

**Q. I cannot get the edit lock (E1003)**  
A. Another referee is editing that match. See [Another referee is editing (E1003)](#/workspace/help/article/trouble_e1003_lock_held).

## See also

- [What is RefBoard?](#/workspace/help/article/intro_what_is_refboard)
- [How to read the health check](#/workspace/help/article/trouble_health_check_guide)
