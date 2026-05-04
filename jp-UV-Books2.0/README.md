# jp-uv-books 2.0（日本語版）

FiveM 用 本の執筆／閲覧 MOD `uv-books 2.0`（[CocoDeee](https://github.com/CocoDeee/uv-books2.0) 氏作）の日本語ローカライズ版です。

## 主な変更点

- **ESX (Legacy) 対応を追加**（QBCore / QBox に加えて）
- UI・通知・ジャンル名をすべて日本語化
- 日本語フォントを11種類同梱（**達筆（佑字 舞）**・**教科書体（Klee One）** を含む）
- 文字数上限を日本語向けに調整（タイトル30 / 著者20 / 本文600文字）
- ロケール切替対応（`config.lua` の `Config.Locale = 'ja'` / `'en'`）

## 対応フレームワーク

| Framework | 対応 |
|---|---|
| ESX (Legacy 1.9+) | ✅ |
| QBCore | ✅ |
| QBox (qbx_core) | ✅ |

## 対応インベントリ

| Inventory | メタデータ | ドラフト保存 | ジャンル表示 |
|---|---|---|---|
| ox_inventory | ✅ | ✅ | ✅（自動） |
| jaksam_inventory | ✅ | ✅ | ✅ |
| qb-inventory / qs / ps / lj | ✅ | ✅ | パッチ要 |
| ESX 標準インベントリ | ❌ | ❌ | ❌ |

> ESX 標準インベントリはアイテムメタデータ非対応のため、ドラフト保存・ジャンル・カスタムフォントは保存されません。**ox_inventory との併用を強く推奨**します。

## 原作との同時起動について

本リソースは原作 [uv-books 2.0](https://github.com/CocoDeee/uv-books2.0)（CocoDeee 氏作）の日本語ローカライズ版で、内部の **ネットイベント名** および **アイテム名**（既定 `book`）は原作踏襲です。**原作の `uv-books` リソースと同じサーバーで同時に起動することはできません**（イベント・アイテムの衝突）。どちらか一方のみ `ensure` してください。

## インストール

1. リソースフォルダを `resources/` に配置（フォルダ名は **`jp-uv-books2.0` など小文字＋ハイフン**を推奨。Linux サーバーでは `ensure` 名とディレクトリ名の大小文字が一致する必要があります）
2. `server.cfg` に追記（フォルダ名に合わせる）：

   ```
   ensure jp-uv-books2.0
   ```

3. アイテム定義を追加：

   **QBCore**（`qb-core/shared/items.lua`）

   ```lua
   ['book'] = {['name']='book', ['label']='本', ['weight']=250, ['type']='item',
              ['image']='book.png', ['unique']=true, ['useable']=true,
              ['shouldClose']=true, ['description']='まだ何も書かれていない本。'},
   ```

   **QBox / ox_inventory**（`ox_inventory/data/items.lua`）

   ```lua
   ['book'] = {
       label = '本', weight = 200, stack = false, close = true, consume = 0,
       server = { export = 'jp-uv-books2.0.book' }
   },
   ```

   （`export` は **リソース名（フォルダ名）** + `.book`。フォルダ名を変えた場合はそれに合わせて書き換え。）

   **ESX**

   ```sql
   INSERT INTO items (name, label, weight) VALUES ('book', '本', 1);
   ```

4. `images/book.png` を各インベントリの画像フォルダにコピー
5. `patches/` の tooltip パッチを使用中のインベントリに適用（任意）

## 設定

`config.lua` で以下を変更可能：

- `Config.Locale` — `'ja'` または `'en'`
- `Config.MaxPages` / `Config.MaxCharsPerPage` 等の上限値
- `Config.ForceFramework` / `Config.ForceInventory` — 自動検出を上書き

## 同梱フォント

11種類の和文フォントを同梱（すべて SIL Open Font License 1.1）：

| 内部キー | 表示名 | 用途 |
|---|---|---|
| `jp-noto-serif` | Noto Serif JP | 標準明朝 |
| `jp-noto-sans` | Noto Sans JP | 標準ゴシック |
| `jp-shippori` | しっぽり明朝 | エレガントな明朝 |
| `jp-klee` | **Klee One（教科書体）** | やわらかい教科書体 |
| `jp-yuji-syuku` | 佑字 肅（楷書） | 端正な楷書 |
| `jp-yuji-mai` | **佑字 舞（達筆）** | 自由で情緒的な行書 |
| `jp-yuji-boku` | 佑字 朴（筆文字） | 朴訥な筆文字 |
| `jp-hina` | ひな明朝 | 古風で可愛らしい明朝 |
| `jp-zen-kurenaido` | Zen 紅道 | 個性的な手書き |
| `jp-yusei` | Yusei Magic | ラフな手書き |
| `jp-reggae` | Reggae One | 勘亭風の太字 |

## クレジット・ライセンス

- 原作：[CocoDeee / uv-books 2.0](https://github.com/CocoDeee/uv-books2.0)（Uncanny Valley RP）
- 日本語化・ESX対応：matrix9
- 同梱フォントは SIL Open Font License 1.1（`html/fonts/OFL.txt` 参照）
- 原作ライセンスは `LICENSE-ORIGINAL` を参照

原作者の名前・クレジットは保持しています。再販売は禁止です。
