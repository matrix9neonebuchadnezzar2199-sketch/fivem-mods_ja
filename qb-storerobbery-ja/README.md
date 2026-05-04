# qb-storerobbery
Store Robberies For QB-Core

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>

## 修正したバグの詳細

### 🐛 連続コンビニ強盗ができないバグ（最重要）

**症状**: 1件目のコンビニ強盗は正常に完了するが、2件目以降のレジで強盗を開始できなくなる。サーバ/ゲームを再起動するまで復旧しない。

**原因**: `server/main.lua` のレジクールダウン解除通知で、ペイロードが配列形式（`toSend[#toSend+1] = register`）で送られていた。クライアント側は受信したテーブルのキーをレジIDとして扱うため、配列インデックス（1, 2, …）が誤ってレジIDに上書きされ、`Config.Registers` が破壊されていた。

**修正**: ペイロードを `toSend[registerId] = register` 形式（IDキー）に変更し、ループも `ipairs` から `pairs` に変更。これにより非連続IDでも正しく同期され、クライアント側 Config が破壊されなくなった。

### その他の修正
- 金庫クールダウンのサーバ再起動消失問題（KVP永続化）
- 40分ごとの全金庫コード強制リセット問題（強奪時のみ再生成に変更）
- `copsCalled` フラグのリセット漏れ（中断/失敗時にも `false` に戻す）
- `currentRegister` / `currentSafe` のグローバル状態汚染（キャンセル時に統一リセット）

## 対応店舗

本MODは Los Santos 各地の **コンビニ32店舗（レジ）** と **金庫19箇所** に対応しています。

レジと金庫はそれぞれ独立したクールダウン管理で、レジAを強盗中でもレジB・C・D…は即強盗可能です。同じ店舗のレジ→金庫の連続強盗もできます（レジから10%の確率で金庫コードのメモが入手可能）。

**対象店舗の種類**:
- 24/7 コンビニ（マップ全域）
- LTD ガソリンスタンド
- Robs Liquor / Rob's Liquor

**カウント**:
- レジ: 32箇所（`Config.Registers` ID 1〜32）
- 金庫: 19箇所（`Config.Safes` ID 1〜19）

## 動作要件

- 警官オンライン人数: `Config.MinimumStoreRobberyPolice = 2`（デフォルト）
  - 日本サーバ向けには 0 や 1 への変更を推奨
- レジクールダウン: `Config.resetTime = 30分`（変更可）
- 金庫クールダウン: 40〜80分のランダム（KVP永続化済み）

## インベントリ対応

報酬・ロックピック削除は **`server/bridge/inventory.lua`** が次を **起動済みリソースから自動検出**します。

| 優先順（先に見つかったものを使用） | 備考 |
|-------------------------------------|------|
| `ox_inventory` | **`markedbills` / `stickynote` が未登録だと報酬は一切入りません。** 定義例はリポジトリの [`optional/ox_inventory_items_snippet.lua`](./optional/ox_inventory_items_snippet.lua) を `ox_inventory` の `data/items.lua` に追記。失敗時はサーバコンソールに `ox_inventory:AddItem failed | ... invalid_item` 等が出ます。 |
| `qb-inventory` | 本家前提。ItemBox 通知あり。 |
| `qs-inventory` | 簡易対応。 |

いずれも起動していない場合、コンソールに警告が出てアイテム処理は失敗します。

## 開発記録

日々の作業ログは [DEVLOG.md](./DEVLOG.md) を参照してください。
