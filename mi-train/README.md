# mi-train（jp-mi-train）

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![FiveM](https://img.shields.io/badge/FiveM-Resource-blueviolet)
![Version](https://img.shields.io/badge/Version-0.3.1-blue)

ミッション：インポッシブル風の**走行中列車ヘイスト**。freight ミッション列車の最後尾に **DBuz747** を attach し、ヘリから**車内へ直接飛び込む** FiveM リソース群です。

| パス（本リポジトリ） | サーバーへの配置 | 役割 |
|---|---|---|
| **`jp-mi-train/`** | `resources/.../jp-mi-train/` | ヘイスト脚本（Lua・設定） |
| **`DBuz747/`** | `resources/.../DBuz747/` | 客車モデル・meta（stream）— **本 repo に同梱** |

詳細な使い方・設定: [`jp-mi-train/README.md`](jp-mi-train/README.md)  
変更履歴: [`CHANGELOG.md`](CHANGELOG.md)

---

## 列車データの配置（サーバー側）

FiveM サーバーでは **リソースが 2 つ** 必要です。フォルダ名と `ensure` 名を揃えてください。

### 全体ツリー（推奨: `[jp-mods]` 配下）

```
<server>/resources/
└── [jp-mods]/
    ├── DBuz747/                    ← ① 列車モデル（mi-train/DBuz747/ をコピー）
    │   ├── fxmanifest.lua
    │   ├── stream/                   ← OpenIV から Export した単体ファイル
    │   │   ├── dbuz747.yft
    │   │   ├── dbuz747_hi.yft
    │   │   └── dbuz747.ytd
    │   └── data/
    │       └── vehicles.meta         ← handling 無し版は meta のみでも可
    │
    └── jp-mi-train/                  ← ② 本リポジトリの jp-mi-train/ をコピー
        ├── fxmanifest.lua
        ├── config.lua
        ├── client/
        │   ├── train.lua             … CreateMissionTrain（freight）
        │   ├── addon_carriage.lua    … DBuz747 attach
        │   ├── heli_board.lua        … ヘリ → 車内
        │   └── ...
        └── server/
            └── main.lua
```

### 何をどこに置くか

| 種類 | 置き場所 | 中身 | 入手元 |
|---|---|---|---|
| **客車メッシュ** | `DBuz747/stream/` | `.yft` / `.ytd` | **`mi-train/DBuz747/stream/`**（同梱済み） |
| **車両 meta** | `DBuz747/data/` | `vehicles.meta` | **`mi-train/DBuz747/data/`**（同梱済み） |
| **ヘイスト脚本** | `jp-mi-train/` | `.lua` / `config.lua` | **`mi-train/jp-mi-train/`** をそのままコピー |
| **走行用 freight** | （配置不要） | — | ゲーム標準。スクリプトが `CreateMissionTrain` で生成 |

**注意**

- `stream/` 直下に **ファイル 3 つ**（フォルダや `.yft.full` は不可）。
- リソース名は **`DBuz747`**（`jp-mi-train` の `dependencies` と `server.cfg` と一致）。
- spawn 名は **`dbuz747`**（`vehicles.meta` の `<modelName>` / `config.lua` の `Config.AddonCarriage.model`）。

### server.cfg（順序）

```cfg
ensure ox_lib
ensure ox_target          # 任意
ensure DBuz747            # ① 必ず jp-mi-train より前
ensure jp-mi-train        # ②
```

### 本リポジトリ ↔ サーバーの対応

| Git（`fivem-mods_ja`） | サーバーにコピーするもの |
|---|---|
| `mi-train/DBuz747/` 一式 | `resources/[jp-mods]/DBuz747/` |
| `mi-train/jp-mi-train/` 一式 | `resources/[jp-mods]/jp-mi-train/` |
| `mi-train/docs/03_dbuz747_setup.md` | 参照用（配置不要） |
| `mi-train/research/` | 参照用（**配置不要**） |

モデル再取得・OpenIV 手順: [`docs/03_dbuz747_setup.md`](docs/03_dbuz747_setup.md)。再配布は [`DBuz747/CREDITS.md`](DBuz747/CREDITS.md) の原作者規約に従うこと。

---

## クイックスタート

1. `mi-train/DBuz747/` と `mi-train/jp-mi-train/` を `resources/[jp-mods]/` にそれぞれコピー
3. `server.cfg` に `ensure` を追加
4. ゲーム内: 埠頭の依頼人 → ヘイスト開始 → ヘリで最後尾 → **`[E] 車内に飛び込む`**

---

## ドキュメント

| ファイル | 内容 |
|---|---|
| [`jp-mi-train/README.md`](jp-mi-train/README.md) | 機能・操作・設定・TS |
| [`docs/03_dbuz747_setup.md`](docs/03_dbuz747_setup.md) | DBuz747 OpenIV 手順（詳細） |
| [`docs/01_exp_trainheist_analysis.md`](docs/01_exp_trainheist_analysis.md) | 参考ヘイスト解析 |
| [`docs/02_existing_moving_train_implementations.md`](docs/02_existing_moving_train_implementations.md) | 既存列車 MOD 比較 |

---

## ライセンス

`jp-mi-train`: **MIT**（`jp-mi-train/README.md` のクレジット参照）  
DBuz747 モデル: 原作者 [MrGTAmodsgerman](https://www.gta5-mods.com/vehicles/german-double-stack-wagon-dbuz747-addon-enterable-interior-light-train-passenger-wagon) の利用規約に従うこと。
