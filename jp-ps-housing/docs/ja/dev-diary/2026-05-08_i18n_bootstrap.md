# 開発日記 — 2026-05-08 Lua i18n 基盤

## 実装

- `shared/locale.lua`: グローバル `Locales`、`Locale(key, ...)`、en フォールバック、`[missing: key]`。
- `shared/config.lua`: `Config.Locale` 既定 `'ja'`。
- `locales/en.lua`, `locales/ja.lua`: テスト用キー `_test.*` のみ（本番文言は次バッチ）。
- `fxmanifest.lua`: `shared_script` に `locale.lua` → `en` → `ja` → `framework.lua` の順で追加。
- `server/server.lua`: 検証用 `print(Locale(...))` ブロックを**コメントアウト**で配置（確認後削除予定）。

## ドキュメント

- `docs/ja/i18n-keys.md` — キー命名規約。
- `docs/ja/i18n-extraction.md` — 置換前の英語文字列と推奨キー（client/server/shared）。
- `docs/ja/i18n-design.md` — 実装に合わせて更新。

## 次タスク（予定）

1. **8A-next**: `i18n-extraction.md` に沿って `Locale()` 実置換 + `locales/*.lua` 本番キー投入。  
2. **8B**: `ui/src` の Svelte i18n。  
3. **8C**: Noto Sans JP + `ui` 再ビルド。  
4. **8D**: 家具 CSV 和訳（並行可）。

## メモ

- `server/server.lua` L381–382 は同一 `targetSrc` に対し異なる文言を出しており、上流バグの可能性あり。置換時に仕様確認推奨。
