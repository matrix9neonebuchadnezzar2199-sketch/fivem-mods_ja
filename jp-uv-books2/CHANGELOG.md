# Changelog

## [2.0.0-ja.1] - 2026-05-04

### Added

- ESX (Legacy 1.9+) 対応
- 日本語ロケール（`locales/ja.lua`）と i18n 仕組み
- 和文フォント11種を同梱（達筆系・教科書体含む）
- `config.lua` による設定外部化
- `Config.ForceFramework` / `Config.ForceInventory` による自動検出の上書き
- UTF-8 安全な文字数判定／トリミング

### Changed

- 文字数上限の既定値を日本語向けに調整
  - タイトル 20 → 30 / 著者 15 → 20 / ページ 800 → 600
- フォント指定を直接指定からクラス切替方式へ変更（予定：`html/index.html`）
- フォントセレクタ値を内部キー化（予定）
- インベントリツールチップ用パッチを日本語化

### Notes

- ESX 標準インベントリ使用時はメタデータ機能が制限される
- `html/index.html` の NUI 全面 i18n・和文 `@font-face` は次コミットで対応予定
- イベント名は原作踏襲の `uv-books:` を維持（原作との差分マージのため）
- 原作 `uv-books` リソースとの同時起動は不可（イベント・アイテム名衝突）
- リソースフォルダ名を **`jp-uv-books2`** に統一（`ox_inventory` の `server.export` が **`resource.export` を先頭の `.` のみで分割**するため、`jp-uv-books2.0.book` は誤解釈され USE が効かない）。旧名からの移行は `RENAME_TO_LOWERCASE.md` を参照
