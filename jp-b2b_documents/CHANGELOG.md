# Changelog

All notable changes to **jp-b2b_documents** are documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning where applicable.

## [2.0.3-jp.10] — 2026-05-05

### Fixed

- **白紙スタック**: `createItem` フックに加え、配布時 **`Search(..., 'slots', paper_blank)`** で空メタの既存スロットを見つけたら **`AddItem(src, name, 1, nil, slot)`** で枚数を足す（`INV.TryStackBlankPaperOx` / `server.lua`）。
- **画像ありでロック失敗**: 挿入画像を **最大辺 1280px・JPEG 品質 0.82** に縮小してから埋め込み、NUI の `doAction` JSON が肥大化しすぎないようにした（`ui/script.js`）。

## [2.0.3-jp.9] — 2026-05-05

### Fixed

- **白紙スタック（ox_inventory）**: `Items.Metadata` が durability 等を付与するとスロット間でメタが一致しないことがあるため、**`registerHook('createItem')`** で `paper_blank` のメタを **`{}` に正規化**（`server.lua`）。
- **画像ボタンが無反応**: FiveM NUI では **`prompt` が使えない**ことが多い。ツールバー **画像**を **ファイル選択 → `readAsDataURL` → `insertEmbed`** に差し替え（`ui/script.js`）。
- **画像入りでロック保存が落ちる**: base64 等で **Delta JSON が巨大**になり NUI / DB で欠けることがあるため、**`JSON.stringify` 結果が約 900KB 超なら `__B2B_DOC_HTML_V1__` + innerHTML** で保存するフォールバックを追加。

## [2.0.3-jp.8] — 2026-05-05

### Fixed

- **ox_inventory 白紙がスタックしない**: `AddItem` に **`{}`（空テーブル）**を渡すと、一部環境で「メタあり」と扱われ **`stack = true` でも既存スロットに合流しない**。`INV.AddItem` で空テーブルを **`nil` に正規化**し、配布は **`nil` メタ**で付与するように変更（`inventory_bridge.lua` / `server.lua`）。

## [2.0.3-jp.7] — 2026-05-05

### Changed

- **ドキュメント**: ox_inventory の `paper_blank` 例を **`stack = true`** に変更（未使用同士がスタック可能）。`document` は **`stack = false` のまま**。[`config.lua`](./config.lua) に注意書きを追加。

## [2.0.3-jp.6] — 2026-05-05

### Fixed

- **Critical — ロック後に本文が消える**: Delta の `JSON.parse` 失敗時に **`setContents([])` でエディタを空にしていた**のをやめ、残り文字列を **HTML として再読込**するように変更。保存は **Delta 優先**のまま、**本文があるのに `ops` が空**・**`JSON.stringify` 例外**のときは **`__B2B_DOC_HTML_V1__` + `innerHTML`** に自動フォールバック。読込は BOM 除去、`HTML_V1` 分岐を追加。
- **Server**: `save` / `lock` / `duplicate` で **`content` が string でなければ保存しない**（nil や誤型で DB を壊さない）。

## [2.0.3-jp.5] — 2026-05-05

### Added

- Toolbar **font size** picker (`size`: 標準 / 小 / 大 / 見出しサイズ = `false`, `14px`, `24px`, `32px`) with `SizeStyle` whitelist aligned to existing i18n CSS.

### Changed

- **Enter / 改行**: Removed **`header`** from post-Enter reapply (headings stay “heading” semantics; Normal after Enter is OK). Reapply order is **inline first** (`font`, …, `size`) then **`align`**, so custom **Japanese fonts** are not cleared by block formatting.
- **Toolbar UI**: Quill snow toolbar controls scaled to **~2×** (buttons 64px, larger SVGs, picker label height/font, options padding). Editor `max-height` adjusted for the taller toolbar.

## [2.0.3-jp.4] — 2026-05-05

### Fixed

- **Lock / save / font**: Root cause was **HTML round-trip** — `clipboard.convert` when loading often normalizes away custom `font` (and similar) even when `innerHTML` had `ql-font-*`. **New saves** (save / lock / duplicate) now store **`__B2B_DOC_QV1__\n` + JSON Delta** (`ops` only) in `b2b_documents.content`. **Load** detects the prefix and uses `setContents(new Delta(ops))`; older rows stay **HTML** and still load via `convert`.
- **Enter / Heading**: Enter で `header` を再適用する変更は **2.0.3-jp.5 で撤回**（フォント継承と競合したため）。

## [2.0.3-jp.3] — 2026-05-05

### Fixed

- **Save / lock reopen**: `getSemanticHTML()` dropped presentation classes (`ql-font-*`), so fonts still vanished after lock. Save again uses `quill.root.innerHTML` only.
- **Enter / 改行**: Quill 2 does not carry inline formats across newlines (PR #3428). `keyboard.addBinding` with `return false` never ran (first matching handler stops the chain). Implemented **capture `keydown` on Enter** + **`text-change`** with a strict check that the delta is **Enter-only** (`insert` strings are only `'\n'`), then reapply font/size/color/etc. so paste with newlines does not reuse stale formats.

## [2.0.3-jp.2] — 2026-05-05

### Fixed

- Opening a document (including **locked** read-only) now loads HTML with `clipboard.convert({ html })` + `setContents`, so **font** (and other inline formats) round-trip from the DB. Previously `quill.root.innerHTML = …` did not sync Quill’s Delta, so fonts often reverted to default on reopen. (Save briefly used `getSemanticHTML`; removed in 2.0.3-jp.3 because it stripped `ql-font-*`.)

## [2.0.3-jp.1] — 2026-05-05

### Added

- Quill toolbar **font family picker** (`formats/font`) wired to bundled faces: Noto Sans/Serif JP, Shippori Mincho, Klee One, Yuji Mai, Zen Kurenaido + default. Picker labels i18n (`ui_font_*` keys). CSS classes `.ql-font-*` map to `@font-face` families.

## [2.0.2-jp.1] — 2026-05-05

### Added

- Japanese webfonts bundled under `ui/fonts/` (same families as jp-uv-books2: Noto Sans/Serif JP, Shippori Mincho, Klee One, Yuji*, Hina Mincho, Zen Kurenaido, Yusei Magic, Reggae One) with `OFL.txt`.
- Lock confirmation modal before signing; new locale keys `ui_modal_lock_title`, `ui_modal_lock_desc`, `ui_btn_lock_confirm`.

### Changed

- NUI: Google Fonts limited to Inter; Japanese text uses local `@font-face` (`fonts.css`).
- `style.css`: body uses `Noto Sans JP`, headings use `Noto Serif JP` / `Shippori Mincho`.

## [2.0.1-jp.1] — 2026-05-05

### Changed

- **データベース**: サーバー起動時に `b2b_documents` テーブルを `CREATE TABLE IF NOT EXISTS` で自動作成（手動の SQL インポートは原則不要）。`sql/b2b_documents.sql` は参照用として維持。
- **ドキュメント**: `INSTALLATION_JP.txt` の STEP 1 を上記に合わせて簡略化。

## [2.0.0-jp.1] — 2026-05-05

### Added

- Japanese locale `locales/ja.lua` and expanded keys in `locales/en.lua`, `locales/fr.lua` (UI sizes, untitled copy, signed/editable strings).
- `modules/framework_bridge.lua`: ESX / QB-Core / Qbox auto-detect, `FW.Notify`, `FW.GetPlayer`, `FW.RegisterUsableItem` (Qbox via `pcall`).
- `modules/inventory_bridge.lua`: inventory abstraction for `ox_inventory`, `qb-inventory`, and ESX default inventory with `b2b_documents_links` table (auto-created on ESX path).
- `INSTALLATION_JP.txt` and root-level install notes cross-link; `README.md` for this resource.
- NUI: Google Fonts (Noto Sans JP / Noto Serif JP / Inter) plus optional local `@font-face` in `ui/fonts/fonts.css`.
- Client fallbacks: `qb-target` (with `pcall`) and `[E]` distance interaction when ox_target / qb-target are unavailable.
- `Config.Items`, `Config.Inventory`, `Config.UseOxTarget` in `config.lua` (Japanese comments).

### Changed

- `fxmanifest.lua`: `lua54 'yes'`, modular scripts, `optional_dependencies` for inventories/frameworks; hard dependencies reduced to `ox_lib` and `oxmysql`.
- `server.lua` / `client.lua`: bridge-based paper grant, document save/lock/duplicate, `currentCtx` (`slot`, `instanceId`, `itemName`), NUI passes `itemName` for server validation.
- `sql/b2b_documents.sql`: default `title` set to `ドキュメント` (utf8mb4 unchanged).
- UI: default `lang="ja"`, i18n placeholders/titles, dynamic Quill size picker labels from locale in `script.js`.

### Notes

- ESX default inventory cannot attach per-item metadata; multiple documents per player may not resolve to a specific instance (see `INSTALLATION_JP.txt`). Prefer `ox_inventory` when strict per-item metadata is required.
- Resource folder name must match `ensure` name and `nui://...` paths in inventory item definitions.

### Credits

- Original: [alnd029/b2b_documents](https://github.com/alnd029/b2b_documents)
- Japanese localization and extensions: matrix9neonebuchadnezzar2199
