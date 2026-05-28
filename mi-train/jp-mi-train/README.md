# jp-mi-train（FiveM リソース）

> **リポジトリ TOP・データ配置図**: 親ディレクトリの [`../README.md`](../README.md) を参照（`DBuz747` と `jp-mi-train` の置き場所）。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Version](https://img.shields.io/badge/Version-0.3.1-blue)

## 目次

- [機能一覧](#機能一覧)
- [動作要件](#動作要件)
- [インストール](#インストール)
- [使い方](#使い方)
- [設定](#設定)
- [トラブルシューティング](#トラブルシューティング)
- [今後の予定](#今後の予定)
- [クレジット](#クレジット)

## 機能一覧

| 機能 | 状態 |
|---|---|
| 受注 NPC（ox_target）+ **ヘイストリセット** | ✅ |
| freight ミッション列車スポーン・周回走行 | ✅ |
| ホスト管理（切断時再選出） | ✅ |
| MAP Blip（ホスト=エンティティ / 他=座標 relay） | ✅ |
| **DBuz747** 最後尾 attach（ハイブリッド） | ✅ |
| ヘリ `[E]` → **車内直行** | ✅ |
| 車内歩行・安全降車 | ✅ |
| `/mitrain start \| stop \| status` | ✅ |
| 警備兵・金庫・報酬 | ⏳ Phase 3 |

## 動作要件

| リソース | 必須 |
|---|---|
| [ox_lib](https://github.com/overextended/ox_lib) | ✅ |
| [ox_target](https://github.com/overextended/ox_target) | ⚪ 推奨 |
| **DBuz747**（`ensure DBuz747`） | ✅ |
| QBCore / ESX | ❌ 不要 |

## インストール

**配置の全体図は [`../README.md`](../README.md#列車データの配置サーバー側) を見てください。**

1. サーバーに **`DBuz747`**（stream + `data/vehicles.meta`）— [`docs/03_dbuz747_setup.md`](../docs/03_dbuz747_setup.md)
2. 本フォルダ **`jp-mi-train/`** を `resources/[jp-mods]/jp-mi-train/` にコピー
3. `server.cfg`:

```cfg
ensure ox_lib
ensure DBuz747
ensure jp-mi-train
```

## 使い方

1. 埠頭「謎の依頼人」でヘイスト開始
2. ヘリで最後尾へ → **`[E] 車内に飛び込む`**
3. 降車: **`[E] 列車から降りる`**（飛び降りしない）
4. 中断: 依頼人 **ヘイストをリセット（中断）**

| コマンド | 効果 |
|---|---|
| `/mitrain start` | 強制開始 |
| `/mitrain stop` | 強制終了 |
| `/mitrain status` | 状態表示 |

## 設定

`config.lua` の主な項目:

| キー | 内容 |
|---|---|
| `Config.AddonCarriage.attachOffset` | DBuz747 の attach（`z`＝貨車との重なり調整） |
| `Config.AddonCarriage.interiorEntry.offset` | 車内スポーン位置 |
| `Config.HeliBoard.exitOffset` | 安全降車位置 |
| `Config.Train.cruiseSpeed` | 走行速度 m/s |

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| モデル未読込 | `ensure DBuz747`、stream 3 ファイル確認 |
| 車内で freight に引っかかる | `attachOffset.z` を上げる（v0.3.1+） |
| 降車でクラッシュ | `[E] 列車から降りる` を使用 |

## 今後の予定

Phase 3: 警備兵・金庫・報酬

## クレジット

[TheNickoos/FiveM-Trains](https://github.com/TheNickoos/FiveM-Trains) / [Blumlaut/FiveM-Trains](https://github.com/Blumlaut/FiveM-Trains) / [VenomXNL/XNL-FiveM-Trains-U3](https://github.com/VenomXNL/XNL-FiveM-Trains-U3) / [exp_trainheist](https://github.com/GTA-EXPLORE/exp_trainheist) / [DBuz747](https://www.gta5-mods.com/vehicles/german-double-stack-wagon-dbuz747-addon-enterable-interior-light-train-passenger-wagon)

**License:** MIT
