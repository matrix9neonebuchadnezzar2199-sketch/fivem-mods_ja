# jp-mi-train

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![FiveM](https://img.shields.io/badge/FiveM-Resource-blueviolet)
![Version](https://img.shields.io/badge/Version-0.3.1-blue)
![Framework](https://img.shields.io/badge/Framework-Standalone-success)
![Dependency](https://img.shields.io/badge/Requires-ox__lib-blue)
![Dependency](https://img.shields.io/badge/Requires-DBuz747-orange)

ミッション：インポッシブル風の**走行中列車ヘイスト**。`CreateMissionTrain`（freight 編成）に **DBuz747** 客車を最後尾 attach し、ヘリから**車内へ直接飛び込む** Phase 2 まで実装済み。

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
| ヘリ `[E]` → **車内直行**（屋根経由なし） | ✅ |
| 車内歩行（freight 無衝突・客車床のみ当たり） | ✅ |
| 安全降車（`[E]` / 範囲外 / リセット時） | ✅ |
| `/mitrain start \| stop \| status` | ✅ |
| 警備兵・金庫・報酬 | ⏳ Phase 3 |

## 動作要件

| リソース | 必須 |
|---|---|
| [ox_lib](https://github.com/overextended/ox_lib) | ✅ |
| [ox_target](https://github.com/overextended/ox_target) | ⚪ 推奨（無しでも E フォールバック） |
| **DBuz747**（add-on ストリーム、`ensure DBuz747`） | ✅ Phase 2 |
| QBCore / ESX | ❌ 不要 |

## インストール

### 1. 配置

```
resources/[jp-mods]/jp-mi-train/
resources/[jp-mods]/DBuz747/    # 別リソース（stream + vehicles.meta）
```

DBuz747 の FiveM 化手順: [`docs/03_dbuz747_setup.md`](../docs/03_dbuz747_setup.md)

### 2. server.cfg

```cfg
ensure ox_lib
ensure ox_target          # 任意
ensure DBuz747            # jp-mi-train より前
ensure jp-mi-train
```

### 3. 起動確認

クライアント F8:

```
[jp-mi-train/main] jp-mi-train client initialized
```

サーバー:

```
[jp-mi-train] jp-mi-train server started
```

## 使い方

### プレイヤー

1. 埠頭の「謎の依頼人」で **ヘイストの依頼を受ける**
2. ヘリで最後尾（DBuz747）付近へ接近
3. **`[E] 車内に飛び込む`**（ヘリから降下して車内へテレポート）
4. 車内を移動（屋根歩行はなし）
5. 降りるときは **`[E] 列車から降りる`**（列車横の安全位置へ。いきなり飛び降りない）
6. 中断するときは依頼人の **ヘイストをリセット（中断）**

### 管理者

| コマンド | 効果 |
|---|---|
| `/mitrain start` | 強制開始 |
| `/mitrain stop` | 強制終了 |
| `/mitrain status` | 状態表示 |

## 設定

`config.lua` の主な項目:

| キー | 内容 |
|---|---|
| `Config.HeliBoard.boardDirectToInterior` | ヘリから車内直行（既定 `true`） |
| `Config.AddonCarriage.attachOffset` | DBuz747 の attach 位置（`z` で高さ調整） |
| `Config.AddonCarriage.interiorEntry.offset` | 車内スポーン位置（ローカル座標） |
| `Config.HeliBoard.exitOffset` | 安全降車位置（客車横） |
| `Config.Heist.resetAllowAnyone` | 進行中、誰でも NPC からリセット可（lab 向け） |
| `Config.Train.cruiseSpeed` | 走行速度 m/s（既定 20） |

変更履歴: リポジトリ直下 [`CHANGELOG.md`](../CHANGELOG.md)

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| `addon skipped (model missing)` | `ensure DBuz747` → F8: `HasModelLoaded(joaat('dbuz747'))` |
| `HideHelp` 等の script error | v0.3.1 以降に更新 |
| 車内で freight に引っかかる | v0.3.1+: freight 無衝突。`attachOffset.z` を上げる |
| 降車でクラッシュ | **`[E] 列車から降りる`** を使う（コリジョン OFF 後にテレポート） |
| 列車が見えない（非ホスト） | ホストのみ実車描画。Blip で追跡 |
| リセット後も列車が残る | 依頼人からリセット → `prepareReset` 後に削除 |

## 今後の予定

| Phase | 内容 |
|---|---|
| **Phase 3** | 警備兵・金庫・報酬・警察通報 |
| **Phase 4** | MI 風演出（ロープ降下、スクリプテッドシーン） |

## クレジット

| 参考 | 要素 |
|---|---|
| [TheNickoos/FiveM-Trains](https://github.com/TheNickoos/FiveM-Trains) | CreateMissionTrain / ホスト再選出 |
| [Blumlaut/FiveM-Trains](https://github.com/Blumlaut/FiveM-Trains) | variation / mission entity |
| [VenomXNL/XNL-FiveM-Trains-U3](https://github.com/VenomXNL/XNL-FiveM-Trains-U3) | トラック制御 |
| [GTA-EXPLORE/exp_trainheist](https://github.com/GTA-EXPLORE/exp_trainheist) | ヘイストフロー設計 |
| [DBuz747 by MrGTAmodsgerman](https://www.gta5-mods.com/vehicles/german-double-stack-wagon-dbuz747-addon-enterable-interior-light-train-passenger-wagon) | 客車モデル（別リソースでストリーム） |

**License:** MIT

設計ドキュメント: `mi-train/docs/`
