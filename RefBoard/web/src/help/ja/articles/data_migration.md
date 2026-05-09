---
title: 別の PC へデータを移す（JSON）
category: data
tags: [移行, migration, バックアップ, JSON, 取り込み, replace, merge, 別PC, 端末, selfName, 部分マージ]
related: [data_import, data_export, intro_setup]
shortcut: null
actionUrl: "#/workspace/data"
errorCode: null
---

# 別の PC へデータを移す（JSON）

## このページでわかること

- **全データ JSON バックアップ**でチーム・試合を丸ごと持ち出す流れ
- **置換（replace）** と **追記（merge）** の使い分け
- **表示名（selfName）** は端末ごとに独立している点

## 手順の概要

### 1. 旧 PC でバックアップを作る

1. **データ管理** を開く
2. **全データのバックアップ (JSON)** を実行
3. ダウンロードされた `refboard_backup_*.json` を USB やクラウドで新 PC にコピー

### 2. 新 PC で取り込む

1. RefBoard を開き、**データ管理** → **JSON から取り込む**
2. モードを選ぶ  
   - **置換**: この端末の既存データを消して、バックアップの内容だけにする（**初回移行向け**）  
   - **追記**: 既存データを残しつつ ID を振り直してマージ（**別端末のデータを足したい**とき）
3. 部分マージでは、チーム／ロスター／試合を個別に選べます。試合だけ取り込むと、関連チームは自動で同伴するオプションがあります。

### 3. 取り込み後

- 画面の指示どおり **ページを再読み込み** して Pinia を再読み込みします。
- **表示名**は `refboard_settings` 側のため、新 PC では **設定**で再度入力が必要なことがあります（CSV の `operator` 列とは別レイヤーです）。

## よくある質問

**Q. CSV だけでは足りない？**  
A. 列構造が決まっている CSV と、階層そのままの JSON では用途が違います。**丸ごと移行は JSON**、表計算用は **CSV（サマリ＋イベント）** を使うとよいです。

## 関連

- 取り込み UI の詳細: [#/workspace/help/article/data_import](#/workspace/help/article/data_import)
- CSV の列: [#/workspace/help/article/data_csv_format](#/workspace/help/article/data_csv_format)
