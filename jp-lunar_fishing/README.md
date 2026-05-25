# jp-lunar_fishing

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![FiveM Resource](https://img.shields.io/badge/FiveM-Resource-111111?logo=fivem)](https://fivem.net/)
[![Version](https://img.shields.io/badge/version-1.0.1--ja1-orange)](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/releases/tag/v1.0.1-ja1)
[![Based on](https://img.shields.io/badge/Based%20on-lunar__fishing%20v1.0.1-lightgrey)](https://github.com/Lunar-Scripts/lunar_fishing)
[![Framework](https://img.shields.io/badge/Framework-ESX%20%7C%20QBCore-green)](https://github.com/overextended/ox_lib)
[![i18n](https://img.shields.io/badge/i18n-Japanese-red)](lunar_fishing/locales/ja.json)
[![Maintained](https://img.shields.io/badge/status-Beta%20(pre--release)-yellow)](CHANGELOG.md)

[Lunar-Scripts/lunar_fishing](https://github.com/Lunar-Scripts/lunar_fishing) v1.0.1 の **日本語化 + 日本魚種対応** フォークです。FiveM RP サーバー向けに、UI・魚種・ゾーン名・NPC を日本向けに差し替え、Stable Diffusion 生成のアイコン 15 枚（CC0 1.0）を同梱しています。

| 読者 | 最初に読む場所 |
|---|---|
| **サーバー管理者** | [インストール手順](#インストール手順) · [`docs/INSTALL_JA.md`](docs/INSTALL_JA.md) |
| **プレイヤー向け運営** | [機能一覧](#機能一覧) · [魚種一覧](#魚種一覧) |
| **開発者 / フォーク派生** | [リポジトリ構成](#リポジトリ構成) · [`CHANGELOG.md`](CHANGELOG.md) · [`docs/WORK_INSTRUCTIONS.md`](docs/WORK_INSTRUCTIONS.md) |
| **最新版の入手** | [Releases / タグ](#releases--タグ) |

---

## 目次

- [概要](#概要)
- [Releases / タグ](#releases--タグ)
- [本家からの変更点](#本家からの変更点)
- [機能一覧](#機能一覧)
- [魚種一覧](#魚種一覧)
- [リポジトリ構成](#リポジトリ構成)
- [必要条件 / 依存関係](#必要条件--依存関係)
- [インストール手順](#インストール手順)
- [設定リファレンス](#設定リファレンス)
- [開発・カスタマイズ](#開発カスタマイズ)
- [トラブルシューティング](#トラブルシューティング)
- [ドキュメント索引](#ドキュメント索引)
- [既知の残課題](#既知の残課題)
- [クレジット・ライセンス](#クレジットライセンス)
- [GitHub Topics（推奨タグ）](#github-topics推奨タグ)

---

## 概要

| 項目 | 内容 |
|---|---|
| **プロジェクト名** | jp-lunar_fishing |
| **FiveM リソース名** | `lunar_fishing`（`ensure lunar_fishing`） |
| **バージョン** | `1.0.1-ja1`（[`fxmanifest.lua`](lunar_fishing/fxmanifest.lua)） |
| **ベース（upstream）** | [Lunar-Scripts/lunar_fishing](https://github.com/Lunar-Scripts/lunar_fishing) v1.0.1 |
| **フレームワーク** | ESX / QBCore（`ox_lib` 必須） |
| **言語** | UI 日本語（`locales/ja.json` + `setr ox:locale ja`） |
| **コードライセンス** | GNU GPL-3.0（ベース継承） |
| **画像アセット** | CC0 1.0（[`assets/fish_images/LICENSE_IMAGES.md`](assets/fish_images/LICENSE_IMAGES.md)） |
| **配布形態** | 非商用・無償（GPL-3.0 ソース公開義務あり） |
| **親リポジトリ** | [fivem-mods_ja](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja) |

---

## Releases / タグ

| 種別 | URL |
|---|---|
| **最新タグ** | [`v1.0.1-ja1`](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/releases/tag/v1.0.1-ja1) |
| **Releases ページ** | https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/releases |
| **ZIP 同梱物** | `lunar_fishing/` ディレクトリのみ（FiveM `resources/` へ直接配置） |
| **リリースノート** | [`docs/RELEASE_NOTES_v1.0.1-ja1.md`](docs/RELEASE_NOTES_v1.0.1-ja1.md) · [`CHANGELOG.md`](CHANGELOG.md) |

> **Note**: タグ `v1.0.1-ja1` は push 済みです。Release ページに ZIP が未掲載の場合は、Releases から手動アップロードするか [`_release/publish-release.ps1`](_release/publish-release.ps1) を実行してください。

---

## 本家からの変更点

| ID | カテゴリ | 本家 v1.0.1 | 本フォーク v1.0.1-ja1 | 状態 |
|---|---|---|---|---|
| JA-01 | ロケール | 英語 / ドイツ語 UI | `locales/ja.json`（42 キー完全翻訳） | ✅ 対応済 |
| JA-02 | 魚種 | 西洋系魚名・設定 | 日本魚 10 種（イワシ〜リュウグウノツカイ） | ✅ 対応済 |
| JA-03 | ワールド | 英語ゾーン名・NPC | サンゴ礁 / 深海域 / 沼地 / シートレード商会 等 | ✅ 対応済 |
| JA-04 | インベントリ | 英語ラベル定義 | `items_ox_ja.lua` / `items_qb_ja.lua` | ✅ 対応済 |
| JA-05 | アイコン | 原作画像 or 未配置 | Stable Diffusion 生成 15 枚（100×100 PNG） | ✅ 対応済 |
| JA-06 | ドキュメント | 英語 README のみ | 日本語 INSTALL / 作業指示書 / CHANGELOG | ✅ 対応済 |

**ゲームロジック**（XP・スキルチェック・ゾーン座標・確率）は本家バランスを **維持** しています。詳細は [`CHANGELOG.md`](CHANGELOG.md) を参照してください。

---

## 機能一覧

本家 `lunar_fishing` の機能を継承し、日本語 UI と日本魚種で RP 向けに調整しています。

| カテゴリ | 機能 | 説明 |
|---|---|---|
| **釣り** | ゾーン釣り / 全域釣り | 複数ゾーン（サンゴ礁・深海域・沼地）+ 沿岸全域 |
| **進行** | レベル & XP | 釣果に応じた成長、竿・餌の解禁 |
| **経済** | 魚売却 / 道具購入 | NPC（シートレード商会）経由 |
| **ジョブ** | フリーランス | 本家同等の副業フロー |
| **移動** | ボートレンタル | ゾーンへのアクセス支援 |
| **UI** | ox_lib ベース | 通知・入力・スキルチェック（日本語） |
| **ターゲット** | ox_target / qb-target | NPC・水面インタラクション |
| **性能** | 低 resmon | アイドル時 0.0ms 目安（本家同等） |

原作プレビュー: https://youtu.be/XUfPRGEm9_I

---

## 魚種一覧

| アイテムキー | 表示名 | 価格（$） | 主な出現ゾーン | レア度 |
|---|---|---|---|---|
| `iwashi` | イワシ | 25–50 | 沿岸全域 | ★☆☆☆☆ |
| `aji` | アジ | 50–100 | 沿岸全域 | ★☆☆☆☆ |
| `saba` | サバ | 150–200 | 沿岸全域 | ★★☆☆☆ |
| `tai` | マダイ | 200–250 | 沿岸全域 | ★★☆☆☆ |
| `hirame` | ヒラメ | 300–350 | サンゴ礁 | ★★★☆☆ |
| `unagi` | ウナギ | 350–450 | 沼地 | ★★★☆☆ |
| `buri` | ブリ | 400–450 | サンゴ礁 | ★★★☆☆ |
| `katsuo` | カツオ | 450–500 | 深海域 | ★★★★☆ |
| `maguro` | クロマグロ | 1250–1500 | 深海域 | ★★★★☆ |
| `ryugu` | リュウグウノツカイ | 2250–2750 | 深海域 | ★★★★★ |

釣り竿・餌: `basic_rod` / `graphite_rod` / `titanium_rod` / `worms` / `artificial_bait`  
数値の正本: [`lunar_fishing/config/config.lua`](lunar_fishing/config/config.lua)

---

## リポジトリ構成

```
jp-lunar_fishing/
├─ README.md                         ← このファイル（プロジェクト概要）
├─ LICENSE                           ← GNU GPL-3.0 全文
├─ CHANGELOG.md                      ← 改変履歴（GPL §5a）
├─ CREDITS.md                        ← 原作者・依存クレジット
├─ docs/
│  ├─ INSTALL_JA.md                  ← インストール正本
│  ├─ RELEASE_NOTES_v1.0.1-ja1.md    ← リリースノート
│  ├─ IMAGE_PROMPTS.md               ← アイコン生成プロンプト
│  └─ WORK_INSTRUCTIONS.md           ← 開発作業指示書
├─ assets/
│  └─ fish_images/                   ← 100×100 透過 PNG（15 枚 + extras）
└─ lunar_fishing/                    ← ★ FiveM リソース本体（resources/ へ配置）
   ├─ fxmanifest.lua
   ├─ locales/ja.json
   ├─ config/config.lua
   ├─ client/ · server/ · framework/ · utils/
   └─ install/
      ├─ items_ox_ja.lua
      └─ items_qb_ja.lua
```

---

## 必要条件 / 依存関係

`ensure lunar_fishing` より **前** に起動している必要があります。

| リソース | 必須 | 役割 |
|---|---|---|
| [`oxmysql`](https://github.com/overextended/oxmysql) | ✅ | DB（レベル保存） |
| [`ox_lib`](https://github.com/overextended/ox_lib) | ✅ | UI・ロケール・ユーティリティ |
| [`ox_target`](https://github.com/overextended/ox_target) または `qb-target` / `qtarget` | ✅ | NPC・水面インタラクション |
| `es_extended` または [`qb-core`](https://github.com/qbcore-framework/qb-core) | ✅ | フレームワーク |
| [`ox_inventory`](https://github.com/overextended/ox_inventory) または `qb-inventory` | 推奨 | アイテム・魚・竿・餌 |

MySQL / MariaDB が稼働していること。詳細バージョン目安は [`docs/INSTALL_JA.md`](docs/INSTALL_JA.md) §1 を参照。

---

## インストール手順

### 1. リソースの取得と配置

**方法 A — Git（monorepo から）**

```powershell
git clone https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja.git
# jp-lunar_fishing/lunar_fishing/ を server/resources/ 配下へコピー
```

**方法 B — Release ZIP**

1. [Releases `v1.0.1-ja1`](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/releases/tag/v1.0.1-ja1) から ZIP を取得
2. 展開した `lunar_fishing/` を `resources/[fishing]/lunar_fishing/` 等に配置

> リソース名は **`lunar_fishing` のまま** にしてください（フォルダ名 = `ensure` 名）。

### 2. server.cfg

依存リソースの **後** に追記:

```cfg
setr ox:locale ja
ensure lunar_fishing
```

### 3. インベントリアイテム

- **ox_inventory**: [`lunar_fishing/install/items_ox_ja.lua`](lunar_fishing/install/items_ox_ja.lua) を `ox_inventory/data/items.lua` に追記
- **QBCore**: [`lunar_fishing/install/items_qb_ja.lua`](lunar_fishing/install/items_qb_ja.lua) を `qb-core/shared/items.lua` に追記

### 4. 魚アイコン PNG

[`assets/fish_images/`](assets/fish_images/) 内の 15 枚をコピー:

| 用途 | 配置先 |
|---|---|
| ox_inventory | `ox_inventory/web/images/<key>.png` |
| qb-inventory | `qb-inventory/html/images/<key>.png` |

### 5. 再起動

```text
refresh
ensure lunar_fishing
```

手順の詳細・SQL・トラブル時の確認項目: **[`docs/INSTALL_JA.md`](docs/INSTALL_JA.md)**

---

## 設定リファレンス

| ファイル | 内容 |
|---|---|
| [`lunar_fishing/config/config.lua`](lunar_fishing/config/config.lua) | 魚種・価格・ゾーン・竿・餌・NPC 設定（日本語コメント付き） |
| [`lunar_fishing/config/cl_edit.lua`](lunar_fishing/config/cl_edit.lua) | クライアント側カスタム（必要時） |
| [`lunar_fishing/config/sv_config.lua`](lunar_fishing/config/sv_config.lua) | Webhook 等（任意・**URL は server.cfg / convar で設定**） |
| [`lunar_fishing/locales/ja.json`](lunar_fishing/locales/ja.json) | UI 文言（42 キー） |

---

## 開発・カスタマイズ

| 作業 | 参照 |
|---|---|
| 魚種追加 | `config.lua` + `items_ox_ja.lua` / `items_qb_ja.lua` + PNG |
| アイコン再生成 | [`docs/IMAGE_PROMPTS.md`](docs/IMAGE_PROMPTS.md) |
| 改変履歴の記録 | [`CHANGELOG.md`](CHANGELOG.md)（GPL §5a 必須） |
| 作業フロー全体 | [`docs/WORK_INSTRUCTIONS.md`](docs/WORK_INSTRUCTIONS.md) |

**GPL-3.0 派生物として配布する場合**、改変箇所・日付・改変者を CHANGELOG に記載し、ソースを公開してください。

---

## トラブルシューティング

| 症状 | 確認すること |
|---|---|
| UI が英語のまま | `setr ox:locale ja` が `server.cfg` にあるか |
| リソースが起動しない | `ox_lib` / `oxmysql` / フレームワークが先に `ensure` されているか |
| インベントリに魚が出ない | `items_ox_ja.lua` / `items_qb_ja.lua` の追記漏れ |
| アイコンが空白 | PNG を `web/images/` にコピーしたか（15 ファイル） |
| Lua エラー（変な先頭文字） | ファイルが UTF-8 **BOM なし** か |

---

## ドキュメント索引

| ドキュメント | 内容 |
|---|---|
| [`docs/INSTALL_JA.md`](docs/INSTALL_JA.md) | インストール正本 |
| [`docs/RELEASE_NOTES_v1.0.1-ja1.md`](docs/RELEASE_NOTES_v1.0.1-ja1.md) | v1.0.1-ja1 リリースノート |
| [`docs/IMAGE_PROMPTS.md`](docs/IMAGE_PROMPTS.md) | Stable Diffusion プロンプト集 |
| [`docs/WORK_INSTRUCTIONS.md`](docs/WORK_INSTRUCTIONS.md) | 開発作業指示書 |
| [`assets/fish_images/LICENSE_IMAGES.md`](assets/fish_images/LICENSE_IMAGES.md) | 画像 CC0 1.0 |
| [`CREDITS.md`](CREDITS.md) | クレジット |
| [`CHANGELOG.md`](CHANGELOG.md) | 改変履歴 |

---

## 既知の残課題

| 項目 | 状態 | メモ |
|---|---|---|
| GitHub Release ZIP | ⚠️ 要確認 | タグ `v1.0.1-ja1` は存在。Release ページへの ZIP 掲載は未完了の可能性あり |
| 実サーバー E2E テスト | 📋 未実施 | ベータ版 — フィードバック歓迎 |
| `extras/` 魚種（サーモン・タラ） | 📦 予備 | 将来拡張用 — [`assets/fish_images/extras/README.md`](assets/fish_images/extras/README.md) |

---

## クレジット・ライセンス

### 原作

- **[Lunar Scripts](https://github.com/Lunar-Scripts/lunar_fishing)** — `lunar_fishing` v1.0.1（GPL-3.0）
- プレビュー: https://youtu.be/XUfPRGEm9_I
- Discord: https://discord.gg/zDK4CHQ56N

### 日本語化・データ・画像

- **matrix9neonebuchadnezzar2199-sketch** — 翻訳、魚種選定、ドキュメント、画像プロンプト設計

### ライセンス

| 対象 | ライセンス |
|---|---|
| ソースコード（`lunar_fishing/` 等） | [GNU GPL-3.0](LICENSE) |
| 魚アイコン PNG | [CC0 1.0](assets/fish_images/LICENSE_IMAGES.md) |

---

## GitHub Topics（推奨タグ）

リポジトリ **Settings → Topics** に以下を設定すると検索性が向上します（`fivem-mods_ja` リポジトリまたは将来の独立リポ向け）。

```
fivem
fivem-resource
fivem-script
gta5
roleplay
esx
qbcore
ox_lib
ox_inventory
ox_target
fishing
japanese
i18n
localization
jp-mods
lua
opensource
gpl-3.0
lunar-scripts
```

---

## 関連リンク

- 本プロジェクト: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/tree/main/jp-lunar_fishing
- Issues: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/issues
- 原作: https://github.com/Lunar-Scripts/lunar_fishing
