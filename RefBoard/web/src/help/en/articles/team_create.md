---
title: Register a new team
category: team
tags: [team, create team, register, abbreviation, color]
related: [team_add_roster_member, match_create_new]
shortcut: null
actionUrl: "#/workspace/teams"
errorCode: null
---

# Register a new team

## What you will learn

- Add one team from **Team management**
- How this ties to matches and roster

## Prerequisites

- **`refboard.referee` ACE**.
- Duplicate-name rules follow **your server**.

## Steps

1. Open **Teams** from the sidebar.
2. **Register team** → `CreateTeamDialog`.
3. Fill **full name**, **short name**, **colors** as prompted.
4. Save; list refreshes after ACK.

## After saving

- Row in `teams`; team appears in **Create match** immediately.
- **Roster** may be empty — add members: [Add roster member](#/workspace/help/article/team_add_roster_member).

## FAQ

**Q. Crest / logo image?**  
A. UI may use emoji-style icons; full image upload may be **unimplemented** — check README/DB columns.

**Q. Wrong data**  
A. Use team **edit/delete** when the server allows; FKs may block delete.

## See also

- [Add roster member](#/workspace/help/article/team_add_roster_member)
- [Create a new match](#/workspace/help/article/match_create_new)
