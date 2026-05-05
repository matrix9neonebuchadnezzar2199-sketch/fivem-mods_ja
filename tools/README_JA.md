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

## FAQ

### Q. apply 後に preview を実行するとヒット数がほぼ 0 になります

A. 正常です。`apply` 後の `index.js` は英語リテラルが日本語に置換済みのため、同じマップで再度 preview しても英語キーは見つかりません。これはツールが冪等に動作している証拠です。

英語バンドルに戻して検証したい場合は `restore` を実行してください。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode restore
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode preview
```

### Q. preview で少数のヒットが残るのはなぜですか

A. 次のいずれかが原因です。

1. **意図的に英語のまま残しているキー**（クレジット表記 `by PLS SCRIPTS` 等）。マップの値が英語のままなら置換しても見た目が変わらず、ヒットが残り続けます。問題ありません。
2. **minify 後の重複参照**。同じ文字列がコードパス上で複数箇所から参照されているケース。これも問題ありません。
3. **未訳のキーが追加されている**。マップの値が日本語訳になっているのに残っているなら、`apply` を実行し忘れている可能性があります。

### Q. 新しい MOD を追加するときの最短手順は

A. 次の3ステップです。

1. `<MOD>/web/dist/` を配置
2. `<MOD>/docs/i18n/<MOD>_replacements.json` を作成
3. `tools\apply_nui_i18n.ps1 -ModName <MOD> -Mode preview` → 妥当なら `-Mode apply`

### Q. 翻訳マップを編集してもUIに反映されません

A. `apply` を再実行する必要があります。マップの編集は自動反映ではありません。
また、FiveM サーバー側で `restart <MOD>` (またはクライアント再接続) が必要です。

### Q. 置換先の日本語に "$" や "\" を含めても大丈夫ですか

A. 大丈夫です。本ツールは正規表現置換ではなく `.Replace()` によるリテラル置換を採用しているため、置換先の文字列に正規表現メタ文字や後方参照記号が含まれても安全に動作します。
