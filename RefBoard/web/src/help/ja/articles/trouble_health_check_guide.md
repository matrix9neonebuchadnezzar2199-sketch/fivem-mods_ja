---
title: ヘルスチェックの見方
category: trouble
tags: [ヘルスチェック, DB, 権限, ロック, 診断]
related: [trouble_autosave_failed, trouble_connection_lost, intro_setup]
shortcut: null
actionUrl: "#/workspace/health"
errorCode: null
---

# ヘルスチェックの見方

## このページでわかること

- **ヘルスチェック** 画面の見方（カテゴリ別の行）
- **再実行**・**Markdown コピー** で運営・開発に共有する流れ

## 前提条件

- サイドバーから **設定** を開き、**ヘルスチェック** へのリンク（または `#/workspace/health` に相当する遷移）から画面に入れること。

## 手順

1. **ヘルスチェック** を開く。
2. **再チェック** でサーバーに `refboard:health:check` 系のリクエストを送り、結果テーブルを更新する。
3. カテゴリ（**server / db / auth / presence / lock / config** など）ごとに行を確認する。
   - **DB**: 接続・スキーマ（テーブル数）・マイグレーション状態の行。
   - **auth**: ライセンス・審判 ACE。
   - **lock**: 編集ロックの異常残りがないか。
4. 障害調査するときは **レポートをコピー（Markdown）** でクリップボードにまとめ、管理者に送る。

## やった後どうなる？

- 各チェックは **その時点のスナップショット**です。サーバー設定を変えたあとは必ず **再チェック** してください。
- 失敗行がある場合、トーストや行の **detail** にヒントが出ることがあります。

## よくある質問

**Q. 全部 OK なのに試合が保存できない**  
A. ヘルスは **接続・スキーマ・権限の広い健全性** を見ます。個別の NetEvent 失敗は [オートセーブが失敗した時](#/workspace/help/article/trouble_autosave_failed) や F8 ログを参照してください。

**Q. 開発中ブラウザでも動く？**  
A. **NUI モック** がある場合は固定の正常レスポンスになることがあります。本番相当の確認は **FiveM 内**で行ってください。

## 関連項目

- [接続が切れた、データは大丈夫？](#/workspace/help/article/trouble_connection_lost)
- [オートセーブが失敗した時](#/workspace/help/article/trouble_autosave_failed)
- [はじめてのセットアップ（運営・審判向け）](#/workspace/help/article/intro_setup)
