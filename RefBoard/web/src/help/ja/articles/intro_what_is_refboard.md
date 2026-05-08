---
title: RefBoard とは
category: intro
tags: [概要, 審判, 試合管理, FiveM, MySQL]
related: [intro_setup, match_create_new]
shortcut: null
actionUrl: null
errorCode: null
---

# RefBoard とは

## このページでわかること

- RefBoard が向いている用途と、サーバー側・クライアント側の役割の分かれ
- 「編集ロック」「履歴」「オートセーブ」が何のためか

## RefBoard について

RefBoard は **FiveM 上で動く NUI** の **サッカー試合管理ツール**です。審判（運営）が **スコア・経過イベント・出場メンバー** などを記録し、**MySQL 上のデータを正（単一の真実）** として複数のクライアントで共有します。

- **フレームワーク非依存**: ESX / QBCore などには依存しません。`refboard.referee` ACE を持つプレイヤーが利用します。
- **単一編集ロック**: 同一試合を **同時に編集できるのは 1 人**（取得中の審判）に限られます。他は閲覧モードで開けます。
- **履歴**: スコアの手動編集などは **`match_score_history`** に理由付きで残る設計です（詳細は各操作のヘルプへ）。

## 前提条件（利用者側）

- サーバーに **RefBoard リソース** と **oxmysql**、**初期 SQL（`sql/install.sql`）** が適用済みであること。
- あなたの識別子に **`refboard.referee` の ACE** が付いていること（閲覧のみでよい場合は運用次第）。

## やった後どうなる？

この記事は概念の説明のみです。実際の操作は **試合管理**・**チーム管理**・**データ管理** の各画面から行います。

## よくある質問

**Q. プレイヤー全員が使えますか？**  
A. 通常は **運営・審判向け**です。ACE 未付与のプレイヤーはサーバー側で拒否されます。

**Q. オフラインでも動きますか？**  
A. **いいえ**。サーバーと DB に接続した FiveM クライアント上で NUI として動作します。

## 関連項目

- [はじめてのセットアップ（運営・審判向け）](#/workspace/help/article/intro_setup)
- [新しい試合を作る](#/workspace/help/article/match_create_new)
