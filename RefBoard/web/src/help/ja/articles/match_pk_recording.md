---
title: PK 戦を記録する（2 列 UI）
category: match
tags: [PK, ペナルティ, シュートアウト, 入力, 記録, 成功, 失敗, ホーム, アウェイ, 2列, pk入力, キッカー]
related: [match_penalty_shootout, match_finish]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# PK 戦を記録する（2 列 UI）

## このページでわかること

- PK フェーズでの **ホーム左・アウェイ右** の 2 列表示
- **今の番**のチームだけが操作できること
- 成功・失敗と **PK スコア**の関係

## 画面の構成

- **左列**: ホームチーム名と、そのチームのキック履歴（上から順）
- **右列**: アウェイチーム名と同様
- 列の下に、**ホーム用**と**アウェイ用**の選手選択と **成功 / 失敗** ボタンがあります

交互に蹴るルールはそのままなので、**今キックする側の行だけ**がハイライトされ、そちらだけボタンが有効になります。

## 操作手順

1. PK フェーズに入る（試合ステータスカードから PK 開始）
2. **ハイライトされている側**でキッカーを選び、**成功** または **失敗** を押す
3. もう一方の列に順番が回るまで待ち、同様に繰り返す
4. 決着がつくと勝者表示のあと、試合終了の確認が出ます

成功は **⚽**、失敗は **失敗**（英語 UI では **Miss**）として列に表示されます。詳しい列定義は CSV ヘルプも参照してください。

## 小窓モードについて

**小窓モード**中は PK のとき **全画面の PK パネル**が優先され、下部ドックの「直近イベント」は **非表示**になります。PK が終わり通常ハーフに戻れば、小窓でもイベント一覧が再び使えます。

## 関連

- PK の流れ全般: [#/workspace/help/article/match_penalty_shootout](#/workspace/help/article/match_penalty_shootout)
- 小窓: [#/workspace/help/article/compact_dock_usage](#/workspace/help/article/compact_dock_usage)
