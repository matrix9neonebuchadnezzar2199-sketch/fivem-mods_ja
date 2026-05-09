---
title: Excel で CSV を開く
category: data
tags: [Excel, CSV, 文字化け, BOM, UTF-8, 日付, アポストロフィ, 45+2, データの取り込み]
related: [data_export, data_csv_format]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# Excel で CSV を開く

## このページでわかること

- RefBoard の CSV は **UTF-8 BOM 付き**で、通常は Excel で**文字化けしにくい**こと
- **`45+2'`** のような分表記が **日付に化ける**ときの回避策

## 文字化けしないように開く

RefBoard v0.3.0 の試合 CSV は先頭に **BOM** があります。Windows の Excel では **ダブルクリックで開いても日本語が正しく表示される**ことが多いです。

もし文字化けする場合:

1. Excel で **データ** タブ → **テキストまたは CSV から** を選ぶ
2. ファイルを指定し、文字コードを **65001: Unicode (UTF-8)** にする
3. 区切り記号を **カンマ** に合わせて完了

## `45+2'` が日付になる問題

`minute_label` 列に **`10'`** や **`45+2'`** が入っていると、Excel が **日付や時刻**と誤認することがあります。

**対処の例**

- 列の書式を **文字列** に設定してからファイルを開き直す
- **データの取り込み**で列の型を **テキスト** に指定する
- 集計に使う列は **`event_minute`** / **`event_stoppage`**（数値列）を使う（詳細形式）

## 関連

- 列の意味全体: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
