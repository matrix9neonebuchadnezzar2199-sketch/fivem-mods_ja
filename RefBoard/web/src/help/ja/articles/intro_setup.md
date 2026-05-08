---
title: はじめてのセットアップ（運営・審判向け）
category: intro
tags: [インストール, ACE, パスワード, oxmysql, SQL]
related: [intro_what_is_refboard, trouble_health_check_guide]
shortcut: null
actionUrl: null
errorCode: null
---

# はじめてのセットアップ（運営・審判向け）

## このページでわかること

- **サーバー管理者**が一度行う作業（DB・リソース・権限）
- **審判**がゲーム内で行う作業（ツールを開く・編集モード）

## 前提条件

- サーバーに **MySQL** と **oxmysql** があり、接続先データベースが決まっていること。

## 手順 — サーバー管理者

1. リポジトリの **`sql/install.sql`** を、**oxmysql が実際に接続している DB** に対して実行する（別名 DB にだけ流すと `Table doesn't exist` になります）。
2. 必要に応じて **`sql/migration_*.sql`** を既存環境の手順どおり適用する。
3. `server.cfg` で **`ensure oxmysql`** のあとに **`ensure RefBoard`**（フォルダ名に合わせる）。
4. 審判用プレイヤーに ACE を付与する例:  
   `add_ace identifier.license:xxxxxxxx refboard.referee allow`
5. **`config.lua`** の **`Config.EditPassword`** を運営で共有する（ランチャーで編集モードに入るときに使用）。

## 手順 — 審判（ゲーム内）

1. **`/refboard`** または **`F6`**（`config.lua` の `Config.OpenKey`）で NUI を開く。
2. 初回は **ランチャー**で **閲覧** か **編集** を選ぶ。編集では **上記パスワード** を入力。
3. サイドバーから **試合管理** / **チーム管理** などへ移動する。

## やった後どうなる？

- SQL 成功後: チーム・試合・ロック用テーブルが利用可能になり、NUI から API が通ります。
- ACE 付与後: `refboard.referee` 権限のあるプレイヤーだけがツールの保護された操作に入れます。

## よくある質問

**Q. `Table '…​.teams' doesn't exist` と出る**  
A. **install.sql を接続先 DB で未実行**のことがほとんどです。README のインストール節を確認してください。

**Q. 編集ロックが取れない（E1003）**  
A. 他の審判が同じ試合を編集中です。[他の審判が編集中（E1003）](#/workspace/help/article/trouble_e1003_lock_held) を参照してください。

## 関連項目

- [RefBoard とは](#/workspace/help/article/intro_what_is_refboard)
- [ヘルスチェックの見方](#/workspace/help/article/trouble_health_check_guide)
