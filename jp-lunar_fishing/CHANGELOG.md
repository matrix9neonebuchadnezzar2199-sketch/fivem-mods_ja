# Changelog

本ファイルは GNU GPL-3.0 §5(a) に基づき、改変の日付・改変者・改変内容を記録します。

形式は [Keep a Changelog](https://keepachangelog.com/) に準拠します。

---

## [1.0.1-ja1] - 2026-05-24

### Modified by
matrix9neonebuchadnezzar2199-sketch
（https://github.com/matrix9neonebuchadnezzar2199-sketch）

### Based on
Lunar-Scripts/lunar_fishing v1.0.1
（https://github.com/Lunar-Scripts/lunar_fishing）

### Added
- 日本語ロケールファイル `locales/ja.json`（UI 文字列 42 キー全て翻訳）
- インベントリ用アイテム定義 `install/items_ox_ja.lua`（ox_inventory 向け）
- インベントリ用アイテム定義 `install/items_qb_ja.lua`（QBCore 向け）
- 日本語インストールガイド `docs/INSTALL_JA.md`
- 画像生成プロンプト集 `docs/IMAGE_PROMPTS.md`
- 開発作業指示書 `docs/WORK_INSTRUCTIONS.md`
- プロジェクト README（日本語）
- 改変履歴ファイル（本ファイル）
- 原作者クレジットファイル `CREDITS.md`

### Changed
- `config/config.lua` の魚種を日本魚 10 種へ置換
  （イワシ／アジ／サバ／マダイ／ヒラメ／ウナギ／ブリ／カツオ／クロマグロ／リュウグウノツカイ）
- `config/config.lua` のゾーン名・NPC 名・通知メッセージを日本語化
  （サンゴ礁／深海域／沼地／シートレード商会／ボートレンタル）
- `fxmanifest.lua` の `version` を `'1.0.1'` から `'1.0.1-ja1'` に変更
- `fxmanifest.lua` の `description` に "(Japanese Localization)" を追記

### Preserved
- ベース MOD のすべてのゲームロジックコード（client/server/framework/utils）
- 元のロケールファイル `locales/en.json` / `locales/de.json`
- 元のライセンス `LICENSE`（GNU GPL-3.0）
- 元のゾーン座標・出現確率・スキルチェック難易度の数値バランス

### Not Yet Implemented
- AI 生成魚アイコン画像（`assets/fish_images/`）— STEP 7 で実施予定

---

## [Original 1.0.1] - Lunar Scripts

ベース MOD のオリジナルバージョン。
詳細は https://github.com/Lunar-Scripts/lunar_fishing/releases を参照。
