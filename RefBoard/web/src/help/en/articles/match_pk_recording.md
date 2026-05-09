---
title: Record a penalty shootout (two-column UI)
category: match
tags: [PK, penalty, shootout, record, goal, miss, home, away, kicker, input, two-column]
related: [match_penalty_shootout, match_finish]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# Record a penalty shootout (two-column UI)

## What this page covers

- **Home left / away right** columns during PK
- Only the **team whose turn it is** can submit
- How **PK score** updates

## Layout

- **Left**: home team name and that team’s kicks (top to bottom)
- **Right**: away team, same pattern
- Below: separate **home** and **away** player pickers and **Scored / Missed** buttons

Alternation is unchanged: the **active** side is highlighted and only that side’s controls work.

## Steps

1. Enter PK phase (from the match status card).
2. On the **highlighted** side, pick the kicker, then **Scored** or **Missed**.
3. Repeat when it becomes the other side’s turn.
4. When decided, you’ll see the winner overlay, then a prompt to finish the match.

Success shows **⚽**, miss shows **Miss** (or the localized label). For CSV columns, see the CSV format article.

## Compact dock

In **compact dock** mode, during PK the **full PK panel** is shown and the dock’s **recent events** list is **hidden**. After PK, when you return to a normal half, the list appears again in the dock.

## See also

- General PK flow: [#/workspace/help/article/match_penalty_shootout](#/workspace/help/article/match_penalty_shootout)
- Compact dock: [#/workspace/help/article/compact_dock_usage](#/workspace/help/article/compact_dock_usage)
