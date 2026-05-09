---
title: CSV でエクスポートする
category: data
tags: [CSV, エクスポート, BOM, Excel, バックアップ, csv エクスポート]
related: [data_view_history, data_csv_format, data_csv_excel_open]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# CSV でエクスポートする

## このページでわかること

- **データ管理** や **試合詳細** から CSV を落とすときの流れ
- **UTF-8 BOM** 付きで Excel を想定している点

## 前提条件

- ブラウザ／NUI が **ダウンロード（blob）** を許可していること。
- 対象データへのアクセス権（審判 ACE）。

## 手順 — データ管理

1. **データ管理** の各タブで、画面に **CSV 出力** または同等のボタンがある場合に押す。
2. ファイル名は `refboard_filename` ユーティリティ等で **日付・種別** が付与されたものになります（実装に準拠）。

## 手順 — 試合詳細（イベント CSV）

1. 試合詳細ヘッダで **CSV 形式**（標準 / 詳細）を選び、**CSV** 操作で **サマリ** と **イベント** の **2 ファイル**が、約 0.2 秒間隔で連続ダウンロードされます（v0.3.0〜）。列の意味は [CSV 出力の形式](#/workspace/help/article/data_csv_format) を参照。
2. **JSON** ボタンは別形式（1 ファイル）です。

## やった後どうなる？

- ローカルに `.csv` が保存されます。**先頭 BOM** により、Excel で文字化けしにくい構成です。Excel での注意は [Excel で CSV を開く](#/workspace/help/article/data_csv_excel_open) を参照。
- DB 上のデータは **変わりません**（エクスポートは読み取りのコピー）。

## よくある質問

**Q. Google スプレッドシートにそのまま貼りたい**  
A. **ファイル → インポート** でアップロードするか、BOM 付き UTF-8 として扱われるようインポート設定を確認してください。

**Q. PK 内訳まで CSV に全部入る？**  
A. **詳細**形式なら PK 成否・`pk_shot_index` などが列に出ます。列一覧は [CSV 出力の形式](#/workspace/help/article/data_csv_format) を参照。さらに生データが必要なら **試合詳細の JSON エクスポート** も併用してください。

## 関連項目

- [データ管理で履歴を見る](#/workspace/help/article/data_view_history)
- [試合を終了する／再編集する](#/workspace/help/article/match_finish)（再編集後の履歴とエクスポートのズレに関する注意）
