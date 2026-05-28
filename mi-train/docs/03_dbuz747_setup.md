# DBuz747 導入ガイド（マスター向け・詳細）

jp-mi-train Phase 2 は **freight ミッション列車 + DBuz747 を最後尾に attach** します。  
この文書は **FiveM サーバー運営者（マスター）** が環境を揃える手順です。

---

## 0. 全体像

```
[server.cfg]
   ensure ox_lib
   ensure dbuz747          ← add-on 車両ストリーム（新規作成）
   ensure jp-mi-train      ← ヘイスト本体（既存）

[ヘイスト開始時・ホストクライアントのみ]
   CreateMissionTrain (freight 編成) → 走行
        ↓
   CreateVehicle('dbuz747') → 最後尾 freight に AttachEntityToEntity
        ↓
   Blip / ヘリ侵入 / 屋根着地 は DBuz747 側を「最後尾」として扱う
```

| 誰が何を見るか | 内容 |
|---|---|
| **ホスト** | freight 列車 + DBuz747 メッシュ（attach 済み） |
| **他プレイヤー** | 列車実体は見えないことが多い。**MAP Blip** は全員で追える |
| **モデル未導入** | `failIfMissingModel = false` なら **freight 最後尾のみ**で Phase 1 同様に動作 |

---

## 1. 必要なもの

| 項目 | 内容 |
|---|---|
| MOD 本体 | [German Double Stack Wagon (DBuz747)](https://www.gta5-mods.com/vehicles/german-double-stack-wagon-dbuz747-addon-enterable-interior-light-train-passenger-wagon)（MrGTAmodsgerman） |
| spawn 名 | **`dbuz747`**（`vehicles.meta` の `<gameName>`。変更した場合は `config.lua` も合わせる） |
| jp-mi-train | `v0.2.0` 以降（`client/addon_carriage.lua` あり） |
| ox_lib | 既存どおり必須 |

**任意（原作 MOD の機能をそのまま使う場合）**

- `trains.xml` を差し替えてワールドに DBuz747 列車を出す設定（**jp-mi-train では不要**。ヘイスト列車はスクリプトが生成する）

---

## 2. FiveM 用リソース `dbuz747` の作成

現状、サーバー `resources/` 下に `dbuz747` は **まだ無い** 想定です。SP 用 OpenIV パッケージを **FiveM stream リソース**に変換します。

### 2.1 MOD をダウンロード・展開

1. 上記 GTA5-Mods ページから **Add-On** 版をダウンロード
2. ZIP を展開（例: `German Double Stack Wagon...` フォルダ）
3. 中身の典型構造:
   - `Automatic Installation`（OIV）… FiveM では使わないか、中身だけ参照
   - `mods/update/x64/dlcpacks/dbuz747/...` または `dlcpacks/dbuz747/`
   - `Add To Railroads`（`trains.xml`）… jp-mi-train 単体では不要

### 2.2 stream 用ファイルの取り出し

OpenIV または展開済み `dlcpacks/dbuz747/dlc.rpf` から、車両モデルを取り出します。

**`stream/` に入れるファイル（名前は MOD 版により多少異なる）:**

| ファイル | 役割 |
|---|---|
| `dbuz747.yft` | 本体モデル |
| `dbuz747_hi.yft` | 高 LOD |
| `dbuz747.ytd` | テクスチャ |
| `dbuz747+hi.ytd` 等 | あれば同梱 |

`vehicles.meta` / `handling.meta` / `carvariations.meta` は **`data/`** 側に置き、`fxmanifest` から `data_file` で登録します（MOD 付属の meta をそのまま流用）。

### 2.3 リソースフォルダ構成（推奨）

マスターのサーバー例:

```
H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources\
  [vehicles]\dbuz747\          ← 新規（[jp-mods] でも可）
    fxmanifest.lua
    stream\
      dbuz747.yft
      dbuz747_hi.yft
      dbuz747.ytd
      ...
    data\
      vehicles.meta
      handling.meta
      carvariations.meta
```

### 2.4 `fxmanifest.lua` 例

```lua
fx_version 'cerulean'
game 'gta5'

files {
    'data/vehicles.meta',
    'data/carvariations.meta',
    'data/handling.meta',
}

data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
```

`stream/` 内の `.yft` / `.ytd` は **ファイル名を書かなくてよい**（自動ストリーム）。

### 2.5 `vehicles.meta` の確認

`<modelName>dbuz747</modelName>` および `<gameName>dbuz747</gameName>` になっていることを確認。  
ここが `dbuz747` でない場合、`jp-mi-train/config.lua` の `Config.AddonCarriage.model` を **同じ文字列**に変更する。

---

## 3. `server.cfg` の設定

### 3.1 ensure 順序

**ox_lib → dbuz747 → jp-mi-train** の順が安全です。

```cfg
ensure ox_lib
# ensure ox_target    # 任意

ensure dbuz747        # リソースフォルダ名と一致させる
ensure jp-mi-train
```

マスター環境（抜粋）では `jp-mi-train` は既に 118 行付近にあります。**その直前に** `ensure dbuz747` を追加してください。

### 3.2 リソース名の一致

| 場所 | 値 |
|---|---|
| フォルダ名 | 例: `resources/[vehicles]/dbuz747` |
| `server.cfg` | `ensure dbuz747` |
| `config.lua` の `requiredResource` | 同じ名前を入れると未起動を検知できる（任意） |

```lua
requiredResource = 'dbuz747',
```

---

## 4. `jp-mi-train` の配置と更新

### 4.1 開発版（正本）

```
H:\CURSOR\Dev\fivem-mods_ja\mi-train\jp-mi-train\
```

### 4.2 テストサーバーへコピー

```
H:\CURSOR\FiveMServer\txData\...\resources\[jp-mods]\jp-mi-train\
```

**Phase 2 で増えた主なファイル:**

- `client/addon_carriage.lua`
- `config.lua` の `Config.AddonCarriage` ブロック
- `fxmanifest.lua` に `addon_carriage.lua` の行

コピー後は必ず **`ensure jp-mi-train`**（またはサーバー再起動）。

---

## 5. `config.lua` の設定（jp-mi-train）

パス: `jp-mi-train/config.lua`

```lua
Config.AddonCarriage = {
    enabled = true,              -- false = Phase 1 のみ（freight 最後尾）
    model = 'dbuz747',           -- vehicles.meta の gameName
    requiredResource = 'dbuz747', -- 任意: 未 ensure なら F8 に warn
    failIfMissingModel = false,    -- true = モデル無しでヘイスト失敗
    notifyOnAttach = true,
    attachOffset = vec3(0.0, -12.5, 0.35),
    attachRotation = vec3(0.0, 0.0, 0.0),
    roofOffset = vec3(0.0, 0.0, 3.1),
}
```

| キー | 推奨（初回） | 説明 |
|---|---|---|
| `enabled` | `true` | DBuz747 attach を使う |
| `failIfMissingModel` | `false` | まだ MOD 導入中でもヘイストテスト可能 |
| `failIfMissingModel` | `true` | 本番で MOD 必須にしたいとき |
| `attachOffset` | 実機調整 | 最後尾 freight からの相対位置。ずれは **Y を ±0.5** |
| `roofOffset` | `3.0`〜`3.5` | ヘリから E で降りたときの高さ |

---

## 6. 動作確認手順

### 6.1 サーバー起動時

txAdmin / コンソールでエラーが無いこと。

```
ensure dbuz747
ensure jp-mi-train
```

### 6.2 モデルがクライアントに載っているか（任意）

F8（クライアント）で一時的に:

```lua
/local model = joaat('dbuz747'); print(IsModelInCdimage(model), IsModelValid(model))
```

`true true` なら stream 成功。

### 6.3 ヘイストフロー

1. `/mitrain start` または埠頭 NPC で受注
2. F8 フィルタ `[jp-mi-train/`
3. 期待ログ（ホスト）:

```
[jp-mi-train/train] train spawned: N wagons ...
[jp-mi-train/addon] addon carriage attached: model=dbuz747 entity=... parent=...
[jp-mi-train/blip] host train entity blip ...
```

4. 通知: 「DBuz747 客車を編成末尾に接続した。」（`notifyOnAttach = true` 時）
5. MAP で Blip が列車と一緒に動く
6. ヘリで最後尾（**二階建て客車**）に接近 → E → 屋根着地

### 6.4 addon が付かないとき

| 症状 | 確認 |
|---|---|
| `model not found in cdimage` | `dbuz747` リソース未 ensure / stream 欠落 |
| freight のみ走る | `enabled = false` または attach 失敗（ログ確認） |
| 編成が離れて見える | `attachOffset` の Y/Z を調整 |
| 地面に落ちてクラッシュ | 原作 MOD の既知問題。attach 前に freeze 済みかログで確認 |

---

## 7. トラブルシューティング

### Q. DBuz747 が見えない（freight だけ走っている）

- ホスト以外のクライアント → **仕様**（実車はホストのみ）。Blip で追う
- ホストでも不可 → `dbuz747` 未導入。§6.2 を確認

### Q. `addon skipped (model missing)`

- `failIfMissingModel = false` ならヘイストは続行（freight 最後尾）
- MOD 導入後に `ensure dbuz747` → `ensure jp-mi-train`

### Q. 二重に客車が見える

- 最後尾 freight と DBuz747 が重なっている → `attachOffset` の **Y を負の方向に**（例: `-13.0` → `-14.5`）

### Q. 屋根着地が低い / 高い

- `Config.AddonCarriage.roofOffset` の **Z** を変更（例: `2.8` / `3.4`）

### Q. Phase 1 に戻したい

```lua
Config.AddonCarriage.enabled = false
```

---

## 8. 車内（enterable）について

DBuz747 は **車内に入れる MOD** ですが、jp-mi-train Phase 2 は **attach と屋根着地まで**です。

屋根に乗ったあと:

- 通常の GTA **乗車キー（F）** で入れるかは実機確認
- 専用ドア target / シーンは **Phase 3** 予定

---

## 9. チェックリスト（印刷用）

- [ ] DBuz747 MOD をダウンロードした
- [ ] `resources/.../dbuz747/stream/` に yft/ytd を置いた
- [ ] `data/*.meta` を置き `fxmanifest.lua` で data_file 登録した
- [ ] `vehicles.meta` の gameName が `dbuz747`
- [ ] `server.cfg` に `ensure dbuz747` を **jp-mi-train より前**に追加した
- [ ] `jp-mi-train` を v0.2.0 相当に更新した
- [ ] `Config.AddonCarriage.enabled = true`
- [ ] サーバー再起動後 `/mitrain start` で F8 に `addon carriage attached` が出た
- [ ] ヘリ → E → 屋根着地まで確認した

---

## 10. 関連パス（マスター環境）

| 用途 | パス |
|---|---|
| 開発正本 | `H:\CURSOR\Dev\fivem-mods_ja\mi-train\jp-mi-train\` |
| テストサーバー | `H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources\[jp-mods]\jp-mi-train\` |
| 本ガイド | `H:\CURSOR\Dev\fivem-mods_ja\mi-train\docs\03_dbuz747_setup.md` |
