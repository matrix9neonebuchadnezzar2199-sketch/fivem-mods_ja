# i18n ユニークキー一覧（正規化済み）

- **`locales/en.lua`**: **114** キー（検証: `node tools/verify-locale-keys.mjs`）
- **`locales/ja.lua`**: **101** キー（`_test.fallback` 意図的欠落 + **`log.*` は en のみ**）
- **`log.*`（12 キー）**: Discord / 管理ログ用。**`ja.lua` には無し**。コードでは **`LocaleEn('log.*', ...)`** のみ使用。

## カテゴリ別（目安）

| プレフィックス | 備考 |
|----------------|------|
| `_test` | 3（ブートストラップ） |
| `dialog` / `menu` / `radial` / `target` / `ui` | クライアント UI |
| `notify` | 通知（`notify.framework.property_title` は ox 通知タイトル兼用） |
| `property` | `property.description.apartment` — DB 保存の物件説明（プレイヤー向け、`Locale()`） |
| `log` | **en のみ**。`LocaleEn()` 専用 |

## 代表マッピング

- **Notify（プレイヤー向け）**: `Locale('notify.*', ...)` — `server/server.lua`, `server/sv_property.lua`, `client/*`
- **SendLog**: `LocaleEn('log.*', ...)` — `server/server.lua`, `server/sv_property.lua`
- **ox_target / qb-target ラベル**: `Locale('target.*')` — `shared/framework.lua`
- **家具タイプ target**: `Locale('target.furniture.storage'|'clothing')` — `shared/config.lua` の `Config.FurnitureTypes` のみ
- **デバッグ `print` / `Debug`**: ロケールキー**なし**（英語ベタ。`i18n-extraction.md` 除外リスト）

## 関連

- 抽出・行番号の履歴: [i18n-extraction.md](i18n-extraction.md)
- 機構: [i18n-design.md](i18n-design.md)
