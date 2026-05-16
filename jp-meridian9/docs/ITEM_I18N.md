# 回収アイテムの名称と i18n（MERIDIAN-9）

## 方針

- **ゲーム内 ID**（`Config.Items[].id`）は ASCII の `snake_case`。ルート在庫・ログ・`item-icon-map.js` のキーと一致させる。
- **英語の正式名**（運営・ログ・NUI フォールバック用）は `Config.Items[].name` に置く。
- **プレイヤー向け表示**は `Config.Items[].nameKey`（例: `m9_item_energy_cell`）をキーに、`locales/ja.lua` / `locales/en.lua` の `_('m9_item_*')` で解決する。**和名は `ja.lua` にのみ書く**（`en.lua` には英語のみ）。
- **素材 PNG** は本番 Linux の大文字小文字・パス互換のため **`image/item/<id>.png`**（英語ファイル名）に統一する。

## 追加・改名するとき

1. `config.lua` の `Config.Items` に `{ id, nameKey, name, rarity, value, fictionTag? }` を追加。
2. `locales/ja.lua` に `['nameKey'] = '和名'` を追加。
3. `locales/en.lua` に同じキーで英語を追加。
4. `html/item-icon-map.js` に `id: 'image/item/<id>.png'` を追加。
5. `image/item/<id>.png` を配置（`fxmanifest` は `image/item/*.png` で列挙済み）。

## Fiction（Subject-0）

- `fictionTag = 'subject_zero'` は現状 **`data_chip`**（レジェンダリー）に付与している。表示名は通常アイテムと同じ i18n キーでよい（没収 UI は `confiscated` フラグ側）。

---

## 実運用で複数件（例: 24 件）を一括追加する

### 方法 A: JSON シード + 生成スクリプト（推奨）

1. `jp-meridian9/docs/item-bulk-seed.example.json` をコピーして運用用 `item-bulk-seed.json`（リポに載せないなら `.gitignore` 配下でも可）を作る。
2. 配列にオブジェクトを並べる。各要素のフィールド:

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `id` | ○ | ASCII `snake_case`。画像ファイル名・`item-icon-map` のキーになる。 |
| `nameEn` | ○ | 英語正式名（`Config.Items[].name` と `en` ロケール）。 |
| `nameJa` | ○ | 和名（`ja` ロケールのみ）。 |
| `rarity` | 任意 | `common` / `uncommon` / `rare` / `legendary`（省略時 `common`）。 |
| `value` | ○ | 数値（売却・スコア用の基準値）。 |
| `fictionTag` | 任意 | 例: `"subject_zero"`。不要なら省略。 |
| `nameKey` | 任意 | 省略時は `m9_item_<id>` を自動採用。既存キー体系とずらす場合のみ指定。 |

3. リソースルートで実行（パスは環境に合わせる）:

```bash
cd jp-meridian9
node scripts/emit-item-snippets.mjs path/to/item-bulk-seed.json > _item_snippets_out.txt
```

4. `_item_snippets_out.txt` を開き、表示順どおりに `config.lua` の `Config.Items`、`locales/ja.lua`、`locales/en.lua`、`html/item-icon-map.js` へ貼る。**直前の行の末尾カンマ**を忘れない。
5. 各 `id` について `image/item/<id>.png` を配置。`fxmanifest` の `image/item/*.png` は変更不要。

スクリプト本体: `jp-meridian9/scripts/emit-item-snippets.mjs`

### 方法 B: 1 件だけ手で足す（コピペ用テンプレ）

`id` を `my_new_item` に置き換えて 4 箇所に反映する例（`nameKey` は `m9_item_<id>` に合わせる）。

**`config.lua` → `Config.Items` 内**

```lua
    { id = 'my_new_item', nameKey = 'm9_item_my_new_item', name = 'My New Item', rarity = 'common', value = 1000 },
```

**`locales/ja.lua` → `Locales['ja']` 内**

```lua
    ['m9_item_my_new_item'] = 'マイニューアイテム',
```

**`locales/en.lua` → `Locales['en']` 内**

```lua
    ['m9_item_my_new_item'] = 'My New Item',
```

**`html/item-icon-map.js` → `MRD9_ITEM_ICON_MAP` 内**

```js
        my_new_item: 'image/item/my_new_item.png',
```

**画像**: `image/item/my_new_item.png`

Fiction を付ける場合は `config` 行末に `, fictionTag = 'subject_zero'` を追加（`data_chip` 以外に付ける場合は運用方針に合わせる）。

### 現行 24 件をシード化したい場合

`config.lua` の `Config.Items` ブロックを手で JSON に落とすか、スプレッドシートから `id,nameEn,nameJa,rarity,value,fictionTag` をエクスポートして JSON に変換してから **方法 A** に渡す。リポ内の現行定義は `config.lua` の `Config.Items` が正（二重管理を避けるため、全件のミラー JSON はリポに置かない）。
