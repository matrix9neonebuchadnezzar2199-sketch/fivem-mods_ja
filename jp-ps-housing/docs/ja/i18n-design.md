# i18n 機構 — 実装（Lua 側）

## 採用済み方針

- **ox_lib `lib.locale()` は使わない**。理由: JSON 自動ロード前提で柔軟性が低く、`[missing: key]` による欠落検知を統一しにくいため。
- 代わりに **`shared/locale.lua`** のグローバル関数 **`Locale(key, ...)`** を使用する。
- 言語データは **`locales/en.lua`** / **`locales/ja.lua`** で `Locales['en']` / `Locales['ja']` にテーブル代入（`ox_lib` 非依存）。

## ロード順（`fxmanifest.lua`）

1. `@ox_lib/init.lua`  
2. `shared/config.lua` — `Config.Locale`（既定 `'ja'`）  
3. `shared/locale.lua` — `Locales = {}`、`function Locale`  
4. `locales/en.lua` / `locales/ja.lua` — キー定義  
5. `shared/framework.lua` — 以降の共有ロジック  

## `Locale(key, ...)` の挙動

- 第1引数 `key` で `Locales[Config.Locale][key]` を参照。  
- 無ければ **`Locales['en'][key]`** にフォールバック。  
- それも無ければ **`[missing: key]`** を返す。  
- 追加引数がある場合は **`string.format`** で展開（失敗時は未整形文字列を返す）。

## 言語切替

- `shared/config.lua` の **`Config.Locale = 'ja'`** または **`'en'`** を変更してリソース再起動。

## スコープ（変更なし）

| 区分 | 扱い |
|------|------|
| **i18n 対象** | client/server/shared のユーザー向け文字列（通知・メニュー・ダイアログ・ターゲット） |
| **対象外** | `Config.Furnitures` の各 `label`（直接和訳） |
| **原則そのまま** | `Config.Apartments` / `Config.Shells` の `label`（固有名詞） |

## NUI（Svelte）

- **本リソースの Lua i18n とは別タスク**（`svelte-i18n` 等）。`Locale()` はクライアント Lua からも呼べるが、NUI 内の文言は別辞書で管理する想定。

## 関連ドキュメント

- キー規約: [i18n-keys.md](i18n-keys.md)  
- 抽出一覧: [i18n-extraction.md](i18n-extraction.md)  
