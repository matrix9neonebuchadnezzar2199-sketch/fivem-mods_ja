# fivem-mods_ja 共通ツール

このディレクトリには、リポジトリ内の各 MOD で共通利用する自動化スクリプトを置きます。

## `apply_nui_i18n.ps1` — 汎用 NUI 日本語化適用ツール

ビルド済み React/Vue NUI (`web/dist/assets/index.js`) を翻訳マップ JSON に従って一括置換するためのツールです。

### 規約 (Convention)

各 MOD は次のファイル配置を満たすことで、本ツールから自動的に対象になります。

| 役割 | パス (相対) |
|---|---|
| NUI バンドル | `<MOD>/web/dist/assets/index.js` |
| NUI HTML | `<MOD>/web/dist/index.html`（任意。あれば `lang="ja"` に書き換え） |
| 翻訳マップ (推奨) | `<MOD>/docs/i18n/<MOD>_replacements.json` |
| 翻訳マップ (旧式・MOD 固有1本) | `<MOD>/docs/i18n/nui_replacements.json` |

ツールは推奨パス → 旧式パスの順に解決します。明示的に指定するときは `-MapPath` を使います。

### 翻訳マップの形式

```json
{
  "_meta": {
    "description": "NUI 文字列置換マップ。キーは原文、値は日本語訳。",
    "match_mode": "exact-quoted"
  },
  "translations": {
    "Save": "保存",
    "Cancel": "キャンセル"
  }
}
```

`_` で始まるキー (`_meta` 等) は無視されます。

**注意:** Windows PowerShell の `ConvertFrom-Json` は JSON キーの大文字小文字を区別しないため、`Animation Name` と `Animation name` のように同一扱いになるキーを並べないでください。

### 使い方

リポジトリ直下で実行してください。

```powershell
# プレビュー (書き込みなし)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode preview

# 適用 (バックアップ *.orig を作成)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode apply

# 復元 (*.orig から戻す)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode restore
```

### バックアップ

`apply` 時に `index.js.orig` / `index.html.orig` を生成します。リポジトリ直下の `.gitignore` で `*.orig` 等をコミット対象外にしてください。

### 既存 MOD 専用スクリプトとの関係

`pls_jobsystem/scripts/apply_nui_i18n.ps1` のような MOD 専用版は互換のため残しています。新しい MOD では本汎用版を使う運用を推奨します。

### 新規 MOD の追加手順

1. `<MOD>/web/dist/` を配置
2. `<MOD>/docs/i18n/<MOD>_replacements.json` を作成
3. `tools/apply_nui_i18n.ps1 -ModName <MOD> -Mode preview` でヒット数を確認
4. ヒットが妥当なら `-Mode apply`
5. 残った英文は `_replacements.json` に追記して再実行
