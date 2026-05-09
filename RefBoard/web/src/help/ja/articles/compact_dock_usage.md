---
title: 小窓（コンパクト）モード
category: intro
tags: [小窓, コンパクト, compact, dock, スタジアム, F6, 時計, スコア, 操作者, 直近イベント, transparentChrome]
related: [intro_setup, match_pk_recording]
shortcut: null
actionUrl: "#/workspace/matches/:matchId"
errorCode: null
---

# 小窓（コンパクト）モード

## このページでわかること

- 試合詳細から **小窓モード**に入る方法
- 画面に出る要素（時計・スコア・ステータス・操作者・直近イベント）
- **PK 中**の挙動と **F6** の位置づけ

## 入り方

1. **試合詳細**（編集画面）を開く
2. ヘッダ付近の **小窓モード** ボタンを押す

メインのカード類は隠れ、画面下に **スコアボード（埋め込み）**・**試合ステータス**・**通常画面に戻る** などが並びます。ゲーム側の操作との切り替えは、環境によって **Ctrl+B**（歩行優先）などの案内が表示されます（NUI の実装に準拠）。

## 表示されるもの

- **残り時間・時計操作**（スコアボード内）
- **試合ステータス**（ハーフ変更など）
- **操作者**（設定の表示名。未設定のときは「未設定」）
- **直近のイベント**（新しい順、スクロール可能。**PK 中は非表示**）

モーダル背面は **透過**設定により、ゲーム画面が見えるようにできます（`transparentChrome`）。

## PK 中

PK フェーズに入ると、小窓ドックは **表示されず**、**通常の全画面レイアウト**で PK パネルが使えます。終了後に再び小窓へ戻る場合は、ハーフを PK 以外にしてから **小窓モード**を選び直してください。

## F6 について

**F6** は RefBoard の UI 自体を開閉するキーです（`config.lua` の `OpenKey` で変更可能）。小窓モード専用のキーではありませんが、試合中に UI を閉じてプレイに集中する動線として使われます。

## 関連

- 初回セットアップ: [#/workspace/help/article/intro_setup](#/workspace/help/article/intro_setup)
- PK 記録: [#/workspace/help/article/match_pk_recording](#/workspace/help/article/match_pk_recording)
