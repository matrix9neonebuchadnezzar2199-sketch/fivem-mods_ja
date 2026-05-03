# jp-sentinel（JP-Sentinel）

警察職向けの自律追尾ドローン「Sentinel Ball」リソースです。スタンドアロン設計で、`Config.Framework` により ESX / QBCore / Qbox / ACE（standalone）に対応します。

## 必要環境

- FiveM（Cerulean / Lua 5.4）
- （任意）`oxmysql`：`Config.Cooldown.Persist = true` のときのみ。`false`（既定）では不要

## インストール

1. 本フォルダを `resources/[jp-mods]/jp-sentinel` などに配置する
2. `server.cfg` に `ensure jp-sentinel` を追加する
3. `config.lua` で `Config.Framework`・`Config.PoliceJobs`・`Config.StandalonePoliceAce` を環境に合わせる
4. インベントリに `Config.ItemName`（既定 `sentinel_ball`）を定義する（フレームワーク側のアイテム定義が必要）
5. standalone のときはアイテムフックは無効のため、`Config.EnableCommand = true` の `/sentinel` 運用またはインベントリ側の独自フックが必要

## クールダウン永続化（任意）

`Config.Cooldown.Persist = true` にした場合:

- `oxmysql` を開始済みにする
- `sql/jp_sentinel_cooldowns.sql` をデータベースに適用する

## ライセンス

MIT（本文はリポジトリルート `LICENSE` に準拠）

## 作者

[@eiho_tsukuyomi](https://x.com/eiho_tsukuyomi)
