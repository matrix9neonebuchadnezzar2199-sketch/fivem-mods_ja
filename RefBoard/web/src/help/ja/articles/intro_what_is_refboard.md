---
title: RefBoard とは
category: intro
tags: [概要, 審判, 試合管理, FiveM, ローカル]
related: [intro_setup, match_create_new]
shortcut: null
actionUrl: null
errorCode: null
---

# RefBoard とは

## このページでわかること

- RefBoard の用途（審判・運営向けの試合記録）
- **v0.1.0 ローカル版**でデータがどこに保存されるか

## RefBoard について

RefBoard は **FiveM 上で動く NUI** の **サッカー試合管理ツール**です。スコア・イベント・出場メンバーを画面から記録します。

**この版（v0.1.0）**では、データは **サーバーや DB には送らず**、ブラウザ（CEF）の **`localStorage`** にだけ保存されます。複数端末での自動同期はありません。バックアップは **データ**画面のエクスポートを利用してください。

- **フレームワーク非依存**: ESX / QBCore などには依存しません。
- **履歴**: 手動スコア変更などは画面内の履歴として残る設計です（各操作のヘルプを参照）。

## やった後どうなる？

概念の説明のみです。実際の操作は **試合管理**・**チーム管理**・**データ** から行います。

## よくある質問

**Q. オフラインでも動きますか？**  
A. FiveM の NUI として動く必要がありますが、**外部 DB 接続は不要**です。データは端末内に閉じます。

**Q. 別の PC に移したい。**  
A. **データ**→**全データのバックアップ (JSON)** で書き出し、移行先でインポートする運用を想定しています。

## 関連項目

- [RefBoard をはじめて使う](#/workspace/help/article/intro_setup)
- [新しい試合を作る](#/workspace/help/article/match_create_new)
