# i18n 機構 — 設計（実装は次フェーズ）

## 採用方針

- **第一候補**: [ox_lib locale](https://overextended.dev/ox_lib/Modules/Locale/Shared) に合わせ、`lib.getLocaleKey` / locale JSON または Lua テーブルでキー解決するパターンに寄せる（Qbox サーバーと運用を揃える）。
- **代替案**: `shared/locale.lua` に `Locale(key, ...)` を実装し、`Config.Locale` に応じて `locales/*.lua` を読み込む薄いラッパー（ox_lib 非依存部分との切り分け用）。

## ファイル構成（案）

- `locales/en.lua` — 既存英語文字列のキー化・集約  
- `locales/ja.lua` — 日本語訳  
- `fxmanifest.lua` — `files { 'locales/*.lua' }` および `shared_script` でローダーを読み込み  

（拡張子はプロジェクトで `json` に統一する場合も可。その場合は ox_lib の locale 形式に合わせる。）

## スコープ

| 区分 | 扱い |
|------|------|
| **i18n 対象** | `client` / `server` の `lib.notify`・`lib.alertDialog`・`lib.registerContext` の表示文、コマンド説明、将来のテキスト UI |
| **i18n 対象外（方針）** | `shared/config.lua` の `Config.Furnitures` の各 `label`（件数が多くキー管理が煩雑）→ **テーブル内を直接日本語化** |
| **原則そのまま** | `Config.Apartments` / `Config.Shells` の `label` は**地名・プロパティ固有名詞**として英語のまま運用可（必要なら個別のみ和訳） |

## キー命名

`<scope>.<context>.<name>` 例:

- `menu.housing.title`  
- `notify.purchase.success`  
- `tooltip.furniture.add_to_cart`  

## 言語切替

- `shared/config.lua` 冒頭付近に `Config.Locale = 'ja'`（または `'en'`）を追加。  
- リソース起動時に `Config.Locale` に対応する locale データを読み込み、`Locale('notify.xxx')` 形式で参照。

## 次ステップ（実装タスク）

1. `locale.lua` ローダーと `fxmanifest` への配線  
2. `Notify` / `alertDialog` / `registerContext` から順にキー置換  
3. NUI は `ui/` ビルド後の `html/` に反映されるため、**Svelte 側**の文字列もキー化または辞書参照に寄せる（別タスク）
