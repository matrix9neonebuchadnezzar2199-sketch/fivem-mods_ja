---
title: イベントが画面に出ない／消えたように見える
category: trouble
tags: [イベント, 表示, 消えた, missing, リロード, JSON, タイムライン, PK, 記録, 確認, トラブル]
related: [data_csv_format, match_pk_recording, trouble_undo_goal]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# イベントが画面に出ない／消えたように見える

## このページでわかること

- 記録したはずのイベントが **一覧に出ない**ときに最初に確認すること
- **PK** や **小窓モード** で見え方が変わるケース

## チェックリスト

### 1. ページを再読み込みする

ブラウザや FiveM NUI の表示更新の遅れで、**リロード（F5）**すると直ることがあります。

### 2. どの一覧を見ているか

- **試合詳細のタイムライン** と **PK パネルの 2 列** は別物です。PK シュートは `penalty` としてタイムラインにも出ますが、**PK 専用列**では `text` 付きで表示されます。
- **小窓モード**の「直近イベント」は **PK 中は非表示**です。PK 中は全画面の PK UI を確認してください。

### 3. 生データで確認する

1. 試合詳細から **JSON エクスポート** を取得し、`events` 配列に該当イベントがあるか見る
2. または **CSV（詳細）** を出力し、`event_index` と `event_text` が増えているか確認する

JSON / CSV にあって画面にだけ無いなら **表示バグの可能性**、どちらにも無いなら **保存されていない**可能性が高いです。

### 4. 操作者名（表示名）

CSV の **operator** 列は記録の有無とは無関係ですが、運用上だれが操作したか追うときに **設定の表示名**を入れておくと後から調べやすくなります。

## それでもおかしいとき

- 同じ操作を **別の試合**で再現できるか
- **ゴール取消**や **void** 系の操作をしていないか

改善が必要な挙動だと分かったら、再現手順をメモして開発者へ伝えてください。

## 関連

- PK の見え方: [#/workspace/help/article/match_pk_recording](#/workspace/help/article/match_pk_recording)
- CSV の列: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
