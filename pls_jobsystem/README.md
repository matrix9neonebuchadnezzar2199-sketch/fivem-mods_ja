# pls_jobsystem (日本語化版)

> 原作: [polisek/pls_jobsystem](https://github.com/polisek/pls_jobsystem) (MIT License)  
> 本リポジトリは原作を日本語化し、運営向けの導入手順を整備した派生版です。

クラフト台・ショップ・ブリップ・スタッシュ・NPC・レジ・アラーム・ボスメニュー連携などをゲーム内 UI から作成・編集できる、汎用ジョブシステムです。React 製の管理 UI を備え、レストラン・密造所・整備工場など、あらゆる「会社系ジョブ」を運営者が自由に組み立てられます。

## 主な特徴

- 対応フレームワーク: ESX / QBCore / OX
- 対応インベントリ: ox_inventory / qb-inventory / quasar_inventory
- 対応ターゲット: ox_target / qb-target（マーカー運用も可）
- ゲーム内 UI（React）でクラフト台・ショップ・スタッシュ・ブリップ・NPC・プロップ・レジ・アラームを作成
- バックアップ & インゲーム復元
- ボスメニュー / 通報処理は外部 export を `config.lua` で接続
- **完全日本語化**（Lua ロケール `ja` + NUI 文字列置換）

## 必要環境

- ox_lib（[overextended/ox_lib](https://github.com/overextended/ox_lib)）
- ESX / QBCore / OX のいずれか
- ox_inventory / qb-inventory / quasar_inventory のいずれか

## クイックスタート

1. 本フォルダ全体を `resources/[local]/pls_jobsystem/` に配置（**フォルダ名は必ず `pls_jobsystem`**）
2. `BRIDGE/config.lua` でフレームワーク・インベントリ・ターゲットを選択
3. `config.lua` の `Config.Locale = "ja"` を確認（既定で日本語）
4. `server.cfg` に `ensure pls_jobsystem` を追加
5. インゲームで `/open_jobs` を実行して動作確認

詳細は [`docs/INSTALL_JA.md`](./docs/INSTALL_JA.md) を参照してください。

## ドキュメント

- [導入手順 (INSTALL_JA)](./docs/INSTALL_JA.md)
- [使い方 (USAGE_JA)](./docs/USAGE_JA.md)
- [ボスメニュー連携 (BOSSMENU_JA)](./docs/BOSSMENU_JA.md)
- [通報連携 (DISPATCH_JA)](./docs/DISPATCH_JA.md)
- [トラブルシューティング (TROUBLESHOOTING_JA)](./docs/TROUBLESHOOTING_JA.md)
- [変更履歴 (CHANGELOG_JA)](./CHANGELOG_JA.md)

## コマンド

| コマンド | 説明 |
|---|---|
| `/open_jobs` | ジョブ管理メニューを開く（権限のあるユーザーのみ） |

## ライセンス

原作と同様 MIT。日本語化の追加分も MIT で提供します。詳細は [`LICENSE`](./LICENSE) と [`NOTICE_JA.md`](./NOTICE_JA.md)。

## クレジット

- 原作: [polisek](https://github.com/polisek) / [polisek.io](https://polisek.io)
- 日本語化: matrix9neonebuchadnezzar2199-sketch
