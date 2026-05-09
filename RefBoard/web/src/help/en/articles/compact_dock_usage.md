---
title: Compact dock mode
category: intro
tags: [compact, dock, stadium, F6, clock, score, operator, recent events, small window]
related: [intro_setup, match_pk_recording]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Compact dock mode

## What this page covers

- How to enter **compact dock** from match detail
- What appears (clock, score, status, operator, recent events)
- Behaviour **during PK** and how **F6** fits in

## How to open

1. Open **match detail** (editor view)
2. Tap **Compact mode** in the header

Main cards hide; a **bottom dock** shows the scoreboard (embedded), match status, and **restore full UI**. Hints may mention **Ctrl+B** to favour game input (per NUI behaviour).

## What you see

- **Clock / remaining time** (inside the scoreboard)
- **Match status** (half changes, etc.)
- **Operator** line (Settings display name, or “unset”)
- **Recent events** (newest first, scrollable; **hidden during PK**)

Modal overlays can use **transparent** chrome so the game stays visible behind dialogs.

## During PK

In PK phase the dock **does not show**; use the **full PK panel** instead. To use the dock again, leave PK (change half) and re-enable compact mode if needed.

## F6

**F6** toggles the RefBoard UI (default **OpenKey** in `config.lua`). It is not dock-specific, but is the usual way to close the UI while playing.

## See also

- First-time setup: [#/workspace/help/article/intro_setup](#/workspace/help/article/intro_setup)
- PK recording: [#/workspace/help/article/match_pk_recording](#/workspace/help/article/match_pk_recording)
