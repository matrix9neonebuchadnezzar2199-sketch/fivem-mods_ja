---
title: スコアを手で直す（手動編集）
category: in_match
tags: [手動, スコア, 修正, 理由, manual]
related: [match_record_goal, trouble_undo_goal, match_finish]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: E2005
---

# スコアを手で直す（手動編集）

## このページでわかること

- イベント記録ではなく、**スコアの数字だけ**を直接書き換える手順
- 必須の「理由」（5 文字以上）と監査ログへの残り方
- ゴール記録の取消との使い分け

## いつ使う？

**原則として、ゴールイベントの取消・記録し直しを優先してください**。手動編集は次のような **イベント単位で表現できないケース** のための非常口です。

- 過去のサーバー停止中に発生したスコアを、後追いで反映したい。
- データ移行・バックアップ復元後の数字ずれを修正したい。
- 何らかの理由で `match_events` と `matches.home_score` / `away_score` が乖離している。

通常のゴール訂正は [間違えてゴールを記録してしまった](#/workspace/help/article/trouble_undo_goal) を先に検討してください。

## 前提条件

- 対象の試合が **編集モード**で開かれている。
- 編集する人が `refboard.referee` ACE 権限を持っている。

## 手順

1. スコアボードの **スコア数字をクリック**、または右上のメニューから「**スコアを手動編集**」。
2. `ScoreEditDialog` で **新しいホーム / アウェイの数値**を入力。
3. **理由（5 文字以上）** を必ず入力。空欄や 5 文字未満は **`E2005 reason_too_short`** で拒否されます。
4. 「保存」で確定。

## やった後どうなる？

- `matches.home_score` / `away_score` が新しい値に更新されます。
- **`match_score_history`** に `manual_edit` 種別で **理由付き**の履歴が 1 行追加。`ScoreHistoryDialog` から確認できます。
- **`match_events` は変化しません**。これは **イベント単位の真実**（誰が何分に決めた）と **集計値**（現在のスコア）を分離して扱う設計のためです。
- 他の審判の画面にも `refboard:match:state` でブロードキャストされます。
- スコアフラッシュは **手動編集では発生しません**（増分でも減分でも）。ゴール演出は本物のゴール記録のときだけ。

## 注意

- `match_events` のゴール件数と `home_score` / `away_score` が **意図的にズレた状態**になります。データ管理での集計時に「イベント数 ≠ スコア」になることを許容してください。
- 監査ログとして必ず残るので、**「なぜそうしたか」が後から追えるよう理由を具体的に**書いてください（例: 「2026-05-07 サーバー再起動中に発生した 1 点を後追い反映」）。

## エラー対応

| code | 意味 | 対処 |
|------|------|------|
| `E2005` | `reason_too_short` | 理由を **5 文字以上**で入力し直す。 |
| `E1002` | `not_editor` | 編集ロックを取得していない。閲覧モードでは編集不可。 |
| `E4003` | `tx_failed` | DB トランザクション失敗。再試行しても繰り返すなら [オートセーブが失敗した時](#/workspace/help/article/trouble_autosave_failed) を参照。 |

## よくある質問

**Q. PK 内訳も手動編集できますか？**  
A. **できません**。手動編集は本戦スコア（`home_score` / `away_score`）専用です。PK の数字を直したい場合は該当 PK イベントの取消・再記録で対応してください。

**Q. 履歴を消すことはできますか？**  
A. **できません**。`match_score_history` は append-only です。誤った理由を書いてしまった場合は、続けて訂正の手動編集（同じ値で「理由訂正: ...」と書く）を入れてください。

## 関連項目

- [ゴールを記録する](#/workspace/help/article/match_record_goal)
- [間違えてゴールを記録してしまった](#/workspace/help/article/trouble_undo_goal)
- [試合を終了する／再編集する](#/workspace/help/article/match_finish)
