# jp-b2b_documents

FiveM 向けのドキュメント／メモエディター（**日本語版**）。Quill ベースの NUI です。

原作: [alnd029/b2b_documents](https://github.com/alnd029/b2b_documents)

## 概要

日本語 UI・和文 Web フォント同梱（jp-uv-books2 と同系の .woff2 + OFL）、欧文は Inter（Google）、ESX / QB-Core / Qbox 自動検出、
`ox_inventory` / `qb-inventory` / ESX 標準インベントリ向けの抽象化レイヤーを含みます。

## 依存関係

- **必須**: ox_lib, oxmysql
- **インベントリ**: 上記のいずれか（`Config.Inventory = "auto"` 推奨）
- **ターゲット**: ox_target / qb-target または [E] 距離フォールバック

## インストール

[INSTALLATION_JP.txt](./INSTALLATION_JP.txt) を参照してください。

## 変更履歴

[CHANGELOG.md](./CHANGELOG.md) を参照してください。

## 開発日記（本 MOD の作業記録）

日付ごとのメモは本フォルダ直下に置きます（リポジトリ全体の日記と混同しないため）。

- [2026-05-05 開発日記.md](./2026-05-05%20開発日記.md)

## ライセンス・クレジット

- 原作: [alnd029](https://github.com/alnd029/b2b_documents)
- 日本語化・改修: matrix9neonebuchadnezzar2199
- 個別の `LICENSE` に従います
