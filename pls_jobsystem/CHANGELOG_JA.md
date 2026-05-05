# 変更履歴（日本語化版）

## [JA-1.0.0] - 2026-05-05

初版リリース。原作 [polisek/pls_jobsystem](https://github.com/polisek/pls_jobsystem) を基にした日本語化版。

### 追加

- `locales/ja.lua` を新設
- `config.lua` の既定言語を `ja` に変更
- 運営向けドキュメント `docs/INSTALL_JA.md` `docs/USAGE_JA.md` `docs/BOSSMENU_JA.md` `docs/DISPATCH_JA.md` `docs/TROUBLESHOOTING_JA.md` を整備
- NUI 翻訳マップ `docs/i18n/nui_replacements.json` と適用スクリプト `scripts/apply_nui_i18n.ps1`

### 変更

- `client/client.lua` `client/nui.lua` `server/server.lua` 内のハードコード英語/チェコ語をロケールキーに置換
- `server/server.lua` のリソース名チェックエラーログを日本語化
- `GetLocale()` を `config.lua`（shared）に集約

### 維持

- 原作の機能・コマンド `/open_jobs` はそのまま
- リソース名 `pls_jobsystem` は変更不可（互換性のため）
