---
title: CSV 出力の形式（v0.3.0）
category: data
tags: [CSV, エクスポート, 形式, 標準, 詳細, サマリ, イベント, BOM, UTF-8, csv形式, 13列, 26列]
related: [data_export, data_import, data_csv_excel_open]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# CSV 出力の形式（v0.3.0）

## このページでわかること

- **サマリ** と **イベント** の **2 ファイル** が一度にダウンロードされること
- **標準 13 列** と **詳細 26 列** の違い
- ファイル名の付き方

## 2 ファイル構成

試合ごとに、約 0.2 秒間隔で次の 2 つが保存されます。

1. **`refboard_m{試合ID}_{YYYY-MM-DD}_summary.csv`** … 試合メタ 1 行（**9 列**）
2. **`refboard_m{試合ID}_{YYYY-MM-DD}_events.csv`** … イベント 1 行ずつ（**13 列 or 26 列**）

**データ管理**（終了試合の行）または **試合詳細** ヘッダで、ドロップダウンから **標準** / **詳細** を選んでから CSV 操作を行います。

## サマリ CSV（9 列）

`match_id`, `match_title`, `match_date`, `home_team`, `away_team`, `final_score`, `match_status`, `operator`, `exported_at`

- `match_id` は `m_42` のように **m\_** 接頭辞付き
- `final_score` は PK がある場合 `1-1 (PK 2-2)` のように併記
- `operator` は設定の **表示名**（未設定なら空に近い値）

## イベント CSV — 標準（13 列）

`match_id`, `match_title`, `match_date`, `home_team`, `away_team`, `final_score`, `event_index`, `event_kind`, `event_team`, `minute_label`, `event_minute`, `event_text`, `recorded_at_iso`

- `event_kind` は `goal`, `substitution`, `pk_goal`, `pk_miss`, `yellow`, `red` など
- `minute_label` は `45+2'` や `PK`（PK シュートは分欄は空）
- `sub_in` だけの行は出さず、**交代は `sub_out` 1 行**にまとまります

## イベント CSV — 詳細（26 列）

標準 13 列に加え、`event_stoppage`, 選手名・背番号、アシスト、カード色、交代 in/out、PK 成否・**チーム内** `pk_shot_index`, `event_text`, `operator`（各行）などが付きます。

## 関連

- 概要の流れ: [#/workspace/help/article/data_export](#/workspace/help/article/data_export)
- Excel での注意: [#/workspace/help/article/data_csv_excel_open](#/workspace/help/article/data_csv_excel_open)
