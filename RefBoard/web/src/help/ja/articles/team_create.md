---
title: チームを新規登録する
category: team
tags: [チーム, 登録, 略称, カラー]
related: [team_add_roster_member, match_create_new]
shortcut: null
actionUrl: "#/workspace/teams"
errorCode: null
---

# チームを新規登録する

## このページでわかること

- **チーム管理** 画面からチームを 1 件追加する手順
- 試合作成やロスター登録との関係

## 前提条件

- **`refboard.referee` ACE** を持っていること。
- チーム名の **重複ポリシー** は運用で決める（サーバー側の制約に従う）。

## 手順

1. サイドバー **チーム管理** を開く。
2. 一覧付近の **チームを登録**（または同等）で `CreateTeamDialog` を開く。
3. **正式名**・**略称**・**カラー**（UI で求められる項目）を入力する。
4. 保存するとサーバーへ送信され、ACK 後に一覧が更新される。

## やった後どうなる？

- `teams` テーブルに行が追加され、**試合作成** のチーム候補に即座に現れます。
- この時点では **ロスター（登録メンバー表）** は空のことが多いです。必要に応じて [ロスターにメンバーを追加する](#/workspace/help/article/team_add_roster_member) を続けてください。

## よくある質問

**Q. エンブレム画像は？**  
A. 現行 UI は **絵文字アイコン等の簡易表現**が中心です。画像アップロードの専用フローは **未実装**の場合があります（`teams.emblem_emoji` 等の DB 項目は README・マイグレーションを参照）。

**Q. 登録を間違えた**  
A. チーム詳細から **編集・削除** が可能な場合はそこから修正してください。権限や参照整合性で削除できないこともあります。

## 関連項目

- [ロスターにメンバーを追加する](#/workspace/help/article/team_add_roster_member)
- [新しい試合を作る](#/workspace/help/article/match_create_new)
