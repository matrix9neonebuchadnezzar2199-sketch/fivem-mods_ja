# matkez_blackmarket 日本語版（マルチフレームワーク対応）

レベリングシステム付きブラックマーケットスクリプトの **完全日本語化版** です。
**ESX / QBox / QBCore** の3フレームワークに対応しています。

オリジナル: [MatkezZzz/matkez_blackmarket](https://github.com/MatkezZzz/matkez_blackmarket)（GPL-3.0）

---

## 本フォークでの変更点

- 🇯🇵 **完全日本語化** — UI、通知、設定ファイルのコメントすべて
- 🧩 **QBCore 対応を追加** — 既存の ESX / QBox に加えて QBCore でも動作
- 🪧 UI 内 `LEVEL` ラベルも localize に対応（`locales/*.json` の `level` キー）
- 🏷 `locales/JA.json` を新規追加、`locales/EN.json` に `level` キーを追加
- 📝 README を日本語化、設定例を拡充

---

## 機能

- 受け渡し場所方式の注文 → ピックアップフロー
- レベル / 経験値（XP）システム（マーケットごと、または全体共有）
- 価格のランダム化（最小〜最大の範囲で起動時に決定）
- 受け渡し場所のランダム化（注文ごとに変わる）
- ブラックマーケットごとに通貨アイテムを設定可能
- 管理者用 XP リセットコマンド
- Discord webhook / ox_lib logger によるログ出力

---

## 必要要件

- フレームワーク: **QBox** / **ESX** / **QBCore** のいずれか
- [ox_lib](https://github.com/CommunityOx/ox_lib)
- [ox_inventory](https://github.com/CommunityOx/ox_inventory) **（必須）**
- [ox_target](https://github.com/CommunityOx/ox_target) または [sleepless_interact](https://github.com/Sleepless-Development/sleepless_interact)
- oxmysql

> ⚠ **インベントリは ox_inventory 固定**です。`exports.ox_inventory:Search / AddItem / RemoveItem / CanCarryItem / CustomDrop / Items()` を直接使用しているため、QBCore でも `qb-inventory` ではなく `ox_inventory` を使う構成が前提となります。

---

## 元リポジトリへの質問とその回答

このフォークは以下の2点の要件で派生しています。

### Q1. ESX / QBX-Core / QBCore すべてで使えるようにできるか？

**A. できます。**
オリジナルは bridge パターンを採用しており、`bridge/{client,server}/<framework>.lua` をフレームワーク別に分離しています。本フォークではこれに `qbcore.lua` を追加することで QBCore に対応しました。`config/shared.lua` の `framework` を `'ESX'` / `'QBOX'` / `'QBCORE'` のいずれかに切り替えるだけで動作します。

ただし前述のとおり **インベントリは ox_inventory 固定** です。完全に「全構成」で動かすにはインベントリ層の bridge 化が別途必要です。本フォークではスコープ外としています。

### Q2. すべて日本語化したい

**A. しました。**
文字列の出処は次の場所にまとまっており、すべて localize 済みです。

- `locales/JA.json`（新規追加） — 通知文・UIラベル・ログテンプレート
- `ui/a.js` の `window.onload` で `locales.order / search / cart / level` を UI に流し込み
- `config/shared.lua` の `label` / `blip.label` / `pickupRoute.label` を日本語に
- README の日本語化

`config.shared.language = 'JA'` が既定です。英語に戻す場合は `'EN'` に変更してください。

---

## インストール手順

1. このリポジトリの `matkez_blackmarket_ja` ディレクトリを `resources/[local]/matkez_blackmarket_ja` などに配置します。
2. 同梱の `insrt.sql` をデータベースで実行します。

   ```sql
   CREATE TABLE `blackmarket_levels` (
       `identifier` VARCHAR(64) NOT NULL,
       `blackmarket` VARCHAR(64) NOT NULL,
       `xp` INTEGER DEFAULT 0,
       PRIMARY KEY (`identifier`, `blackmarket`)
   );
   ```

3. `config/shared.lua` を環境に合わせて編集します。
   - `framework` … `'ESX'` / `'QBOX'` / `'QBCORE'`
   - `language` … `'JA'`（既定） / `'EN'`
   - `interaction` … `'ox_target'` / `'sleepless_interact'`
   - `blackmarkets[*].currencyItem` … サーバの通貨アイテム名
     - ESX 既定: `black_money`
     - QBCore 既定: `markedbills`
     - 現金: `money`
   - `blackmarkets[*].ped.coords` … 売人 NPC の座標
   - `pickupLocations` … 受け渡し場所（最低1か所）

4. `config/server.lua` で管理者識別子とログ送信先を設定します。

   ```lua
   return {
       logging = {
           logType = 'discord',          -- 'discord' | 'ox_lib'
           webhook = 'https://discord.com/api/webhooks/xxx/yyy'
       },
       levelRestartCommand = 'resetplayerlevels',
       admins = {
           ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = true,
       }
   }
   ```

5. `server.cfg` に追記します。

   ```cfg
   ensure ox_lib
   ensure ox_inventory
   ensure ox_target            # または sleepless_interact
   ensure matkez_blackmarket_ja
   ```

---

## 管理者コマンド

- `/resetplayerlevels [対象プレイヤーID]`
  指定プレイヤーの全ブラックマーケット XP を 0 にリセット（`config/server.lua` の `admins` に登録された識別子のみ実行可能）。

---

## ファイル構成

```
matkez_blackmarket_ja/
├── bridge/
│   ├── client/
│   │   ├── esx.lua
│   │   ├── qbox.lua
│   │   └── qbcore.lua    ← 追加
│   ├── server/
│   │   ├── esx.lua
│   │   ├── qbox.lua
│   │   └── qbcore.lua    ← 追加
│   └── shared.lua
├── client/main.lua
├── config/
│   ├── server.lua
│   └── shared.lua        ← 日本語化
├── locales/
│   ├── EN.json           ← level キー追加
│   ├── JA.json           ← 追加
│   └── SR.json
├── server/main.lua
├── ui/
│   ├── a.html            ← lang="ja"
│   ├── a.js              ← LEVEL ラベル localize
│   ├── a.css
│   └── sounds/
├── fxmanifest.lua
├── insrt.sql
└── README.md             ← 本ファイル
```

`fxmanifest.lua` の `'bridge/client/*.lua'` / `'bridge/server/*.lua'` ワイルドカードにより、`qbcore.lua` は自動で読み込まれます。

---

## ライセンス

オリジナルと同じ **GPL-3.0** ライセンスで配布されます。

派生物・改変物を再配布する場合も GPL-3.0 を継承する必要があります。

## クレジット

- 原作: [MatkezZzz](https://github.com/MatkezZzz)
- 日本語化 / QBCore 対応: [matrix9neonebuchadnezzar2199-sketch](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja)
