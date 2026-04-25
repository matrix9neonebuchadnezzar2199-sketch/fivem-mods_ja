# fivem-mods（JP-Mods）

日本語 FiveM RP 向けの**スタンドアロン**リソース用開発リポジトリです。

## ドキュメント

- [AGENTS.md](./AGENTS.md) — プロジェクト方針・MOD 配置・命名規則
- [`.cursor/rules/fivem-lua.mdc`](.cursor/rules/fivem-lua.mdc) — FiveM / Lua コーディングルール

## デプロイ（開発 PC → ローカルFXServer）

テスト用サーバーの展開先は [AGENTS.md](./AGENTS.md) のパス（既定: `C:\FiveMServer\server-data\resources\[jp-mods]\`）と合わせてください。

- 1 つだけ同期: `scripts\deploy.bat jp-<mod名>`
- すべての `jp-*` を一括: `scripts\deploy-all.bat`

## MOD の形

各 MOD は本リポジトリ直下の `jp-<名前>/` に `fxmanifest.lua`・`config.lua`・`client` / `server` など（[AGENTS.md](./AGENTS.md) 参照）を置きます。
