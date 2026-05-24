# インストールガイド (日本語)

jp-lunar_fishing を FiveM サーバーに導入する手順です。

---

## 1. 前提条件

### 1-1. サーバー環境

- FiveM サーバー（artifacts は最新の推奨版）
- MySQL / MariaDB が稼働中
- 以下のフレームワーク・リソースが導入済み

### 1-2. 必須依存リソース

導入順に記載します。すべて `server.cfg` の `ensure lunar_fishing` より
**前**に `ensure` されている必要があります。

| リソース | バージョン目安 | 入手先 |
|---|---|---|
| `oxmysql` | 最新 | https://github.com/overextended/oxmysql |
| `ox_lib` | 最新 | https://github.com/overextended/ox_lib |
| `ox_target` または `qb-target` / `qtarget` | 最新 | https://github.com/overextended/ox_target |
| `ox_inventory` または `qb-inventory` | 最新 | https://github.com/overextended/ox_inventory |
| `es_extended` または `qb-core` | 最新 | https://github.com/esx-framework / https://github.com/qbcore-framework |

---

## 2. リソースのインストール

### 2-1. ファイル配置

`lunar_fishing/` ディレクトリ全体を、サーバーの `resources/` 配下にコピー
します。配置例：

```
[your-server]/
└─ resources/
   └─ [fishing]/
      └─ lunar_fishing/        ← ここにコピー
         ├─ fxmanifest.lua
         ├─ locales/
         ├─ config/
         ├─ client/
         ├─ server/
         ├─ framework/
         ├─ utils/
         └─ install/
```

ディレクトリ名は `lunar_fishing` のままにしてください（変更すると
`ensure` 行も合わせる必要があります）。

### 2-2. server.cfg への追記

`server.cfg` の依存リソース読み込みの**後**に以下を追加します。

```cfg
# ox_lib のロケールを日本語に設定
setr ox:locale ja

# jp-lunar_fishing を起動
ensure lunar_fishing
```

`setr ox:locale ja` を入れないと、UI 文字列は英語（`en.json`）のまま表示されます。

---

## 3. インベントリへのアイテム登録

### 3-1. ox_inventory を使用する場合

`lunar_fishing/install/items_ox_ja.lua` の中身（`return { ... }` の内側）を、
`ox_inventory/data/items.lua` の `return { ... }` ブロックの末尾に追記します。

例（`ox_inventory/data/items.lua` の最後の方）：

```lua
return {
    -- ... 既存アイテム ...

    -- ▼ jp-lunar_fishing 追加分（ここから）
    ['iwashi'] = {
        label  = 'イワシ',
        weight = 100,
        stack  = true,
        close  = true,
        description = '日本近海で最も馴染み深い小魚。安価だが数が稼げる。',
    },
    -- ... 残り 14 アイテム ...
    -- ▲ jp-lunar_fishing 追加分（ここまで）
}
```

**衝突回避**：既存アイテムと同じキー名が存在する場合（例：`worms`）、
キーをリネームし、`config.lua` の対応箇所も同じ名前に書き換えてください。

### 3-2. QBCore を使用する場合

`lunar_fishing/install/items_qb_ja.lua` の中身（フラグメント）を、
`qb-core/shared/items.lua` の `QBShared.Items = { ... }` ブロックの末尾に
追記します。

例：

```lua
QBShared.Items = {
    -- ... 既存アイテム ...

    -- ▼ jp-lunar_fishing 追加分（ここから）
    ['iwashi'] = {
        ['name']        = 'iwashi',
        ['label']       = 'イワシ',
        ['weight']      = 100,
        ['type']        = 'item',
        ['image']       = 'iwashi.png',
        ['unique']      = false,
        ['useable']     = false,
        ['shouldClose'] = true,
        ['combinable']  = nil,
        ['description'] = '日本近海で最も馴染み深い小魚。安価だが数が稼げる。',
    },
    -- ... 残り 14 アイテム ...
    -- ▲ jp-lunar_fishing 追加分（ここまで）
}
```

**`useable` の調整**：釣り竿（`basic_rod` / `graphite_rod` / `titanium_rod`）が
ゲーム内で起動しない場合、`useable = true ↔ false` を切り替えて再起動して
ください。lunar_fishing の動作仕様により挙動が変わります。

---

## 4. 画像アセットの配置

### 4-1. 配置場所

| 使用インベントリ | 配置先ディレクトリ |
|---|---|
| `ox_inventory` | `ox_inventory/web/images/` |
| `qb-inventory` | `qb-inventory/html/images/` |
| その他 | 各インベントリの画像ディレクトリ |

ファイル名はアイテムキーと完全一致させてください（例：`maguro.png`）。

### 4-2. 画像が未生成の場合

STEP 7（画像生成）が完了するまでは、`assets/fish_images/` ディレクトリは
空または不完全です。この状態でサーバーを起動すると、インベントリ画面で
魚アイコンが「未表示（空白枠）」になります。**機能自体は動作します**。

暫定対応として、以下のいずれかが可能です：

- 元 MOD のオリジナル画像を流用（lunar_fishing v1.0.1 の `install/` 配下）
- 任意のフリー素材で代用
- STEP 7 完了まで未配置のまま運用

---

## 5. 動作確認

### 5-1. 起動チェック

サーバー起動後、コンソールに以下のようなログが出れば成功です。

```
[script:lunar_fishing] Started resource lunar_fishing
```

エラーが出る場合は次の節を参照してください。

### 5-2. ゲーム内チェック

1. プレイヤーキャラクターを以下の座標付近にスポーン

   - NPC（魚屋）：`-2081.38, 2614.32, 3.08`（北東のサンディショアズ近郊）
   - NPC（魚屋）：`-1492.36, -939.25, 10.21`（ロックフォードヒルズ）
   - ボートレンタル：`-1434.48, -1512.27, 2.14`（パシフィックブラフ）

2. マップ上に以下のブリップが表示されているか確認

   - シートレード商会（緑）
   - ボートレンタル（緑）
   - サンゴ礁（青）／深海域（紫）／沼地（黄）

3. NPC に話しかけて「釣り竿を購入」「ミミズを購入」が日本語で表示されるか確認
4. 釣り竿と餌を購入し、水辺で釣りができるか確認
5. 釣った魚（例：「イワシ」「アジ」）がインベントリに日本語ラベルで入るか確認
6. NPC に話しかけて「魚を売る」を選択し、売却できるか確認

---

## 6. トラブルシューティング

### 6-1. UI が英語のまま

- `setr ox:locale ja` が `server.cfg` に記載されているか
- `ox_lib` のバージョンが古くないか（locale 機能対応版か）
- `lunar_fishing/locales/ja.json` がファイル存在し UTF-8 BOM なしか

### 6-2. アイテム名が「IWASHI」などキー名のまま表示される

- 該当インベントリ（ox_inventory / qb-core）にアイテム定義を追記済みか
- インベントリリソースを再起動したか（`restart ox_inventory`）

### 6-3. 魚アイコンが空白枠

- 画像ファイル名がアイテムキー名と完全一致しているか（大文字小文字、拡張子）
- 配置ディレクトリが正しいか（ox_inventory なら `web/images/`）
- ブラウザキャッシュをクリア（F5 ではなく Ctrl+F5）

### 6-4. 釣り竿を使っても何も起きない

- `ox_target` / `qb-target` が起動しているか
- QBCore の場合、`items_qb_ja.lua` で `useable = true` になっているか
- 水辺に立っているか（陸上では釣り開始しません）

### 6-5. ゾーンに入ってもメッセージが出ない

- `config.lua` の `Config.fishingZones[].message` が正しく設定されているか
- ブリップが地図に表示されているか（表示されていれば座標は正しい）

---

## 7. アンインストール

1. `server.cfg` から `ensure lunar_fishing` 行を削除
2. `resources/[fishing]/lunar_fishing/` ディレクトリを削除
3. ox_inventory / qb-core のアイテム定義から該当 15 アイテムを削除
4. プレイヤーインベントリに残った魚アイテムは、削除前に手動で除去するか
   そのまま放置（無害ですが「Unknown Item」表示になります）
5. サーバー再起動

---

## 8. サポート

- バグ報告：https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/issues
- 原作の質問：https://discord.gg/zDK4CHQ56N
