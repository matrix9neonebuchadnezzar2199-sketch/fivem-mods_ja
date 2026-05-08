# 翻訳・文字列棚卸し（チェックリスト）

生成・集計: 2026-05-08。実装フェーズでは本リストと `furniture-labels-todo.csv` を同期させる。

---

## 件数サマリ

| セクション | 内容 | 件数概算 | 優先度 |
|------------|------|----------|--------|
| **A** | `Config.Furnitures`（カテゴリ + object + label） | **886** 行（CSV） | **Mid**（バッチ作業） |
| **B** | `Config.Apartments` / `Config.Shells` の `label` | **約 89** 行（方針: 固有名詞は英語のまま可） | **Lo** |
| **C** | `client/*.lua` の UI 系文字列 | **抽出詳細: [i18n-extraction.md](i18n-extraction.md)**（クライアント部 **約 48** 行アイテム。ダイアログ1つで複数キー） | **Hi** |
| **D** | `server/*.lua` の通知・ログ用英文 | **同上**（サーバ部 **約 62** 行アイテム。`print` / `SendLog` 含む） | **Hi** |
| **E** | NUI（`html/` + `ui/src`） | 静的文言 **約 35〜45**（Svelte）。`html/index.js` **約 3350 行**（ビルド済み・**ソースは `ui/` を編集**） | **Hi** |
| **F** | コマンド | **2**（`migratehouses` / `migrateapartments`、help 文字列なし） | **Lo** |

---

## A. 家具ラベル（`Config.Furnitures`）

- **カテゴリ数**: 16（例: Prerequisites, Couches, Chairs, …）
- **アイテム総数（`label`）**: **886**
- **マスタ CSV**（`カテゴリ,object,label_en,label_ja(空欄)`）: `docs/ja/furniture-labels-todo.csv`  
- 再生成: `node tools/extract-furniture-labels.mjs`

**方針（i18n-design と整合）**: キー化せず **`config.lua` 内を直接日本語化**する想定。

---

## B. アパート／シェル名

- `shared/config.lua` の `Config.Apartments` / `Config.Shells` 内 `label`（および画像キャプション）。
- **優先度 Lo**: 地名・施設名は**英語のまま**でも可。UI 上だけ和訳する場合は個別判断。

---

## C. クライアント側 UI 文字列（`client/`）

**マスター一覧**: [i18n-extraction.md](i18n-extraction.md)（ファイル別・行番号・推奨キー）。

- 旧概算「約 40」は **Notify + 主要 grep のみ**の目安。抽出ドキュメントではダイアログ・ラジアル等を含め **約 48 行アイテム**。

**優先度 Hi**。

---

## D. サーバ側メッセージ（`server/`）

**マスター一覧**: [i18n-extraction.md](i18n-extraction.md)。

- 旧概算「約 55+」は **Notify 中心**。抽出では `print` / `SendLog` を含め **約 62 行アイテム**。

**優先度 Hi**。

---

## E. NUI 文字列

### `html/`（FiveM が読み込む成果物）

| ファイル | 行数（参考） | 備考 |
|----------|--------------|------|
| `index.html` | 26 | `<title>ps-housing</title>` など |
| `index.css` | 1 | ミニファイ済み。`font-family` は Tailwind プリフライト由来 |
| `index.js` | **3350** | **Vite バンドル**。人間が直接編集しない |

**フレームワーク**: ソースは **`ui/` の Svelte + TypeScript + Vite**。出荷物はバニラ JS（**React/Vue ではない**）。

### `ui/src/`（編集対象）

- `Header.svelte`, `Cart.svelte`, `ItemList.svelte`, `OwnedItems.svelte`, `VisibilityProvider.svelte`, `Modeler.svelte` 等に英語 UI が集中。

**優先度 Hi**（フォント方針は `font-policy.md`）。

---

## F. コマンド説明

| コマンド | ファイル | restricted | help 文字列 |
|----------|----------|------------|-------------|
| `migratehouses` | `client/migrate.lua` | いいえ | **なし** |
| `migrateapartments` | `server/migrate.lua` | **true** | **なし** |

**優先度 Lo**: 将来 `RegisterCommand(..., false)` の第4引数または `lib.addCommand` に help を追加する場合にキー化。

---

## 翻訳優先度（まとめ）

- **Hi**: NUI（`ui/src`）+ Lua 通知（client/server）  
- **Mid**: `Config.Furnitures` 886 件（CSV バッチ）  
- **Lo**: コマンド help、Apartments/Shells 固有名詞
