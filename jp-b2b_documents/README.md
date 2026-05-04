# jp-b2b_documents

FiveM 向けのドキュメント／メモエディター（**日本語版**）。Quill ベースの NUI です。

原作: [alnd029/b2b_documents](https://github.com/alnd029/b2b_documents)

## 概要

日本語 UI・Noto 系フォント（CDN + 任意ローカル）、ESX / QB-Core / Qbox 自動検出、
`ox_inventory` / `qb-inventory` / ESX 標準インベントリ向けの抽象化レイヤーを含みます。

## 依存関係

- **必須**: ox_lib, oxmysql
- **インベントリ**: 上記のいずれか（`Config.Inventory = "auto"` 推奨）
- **ターゲット**: ox_target / qb-target または [E] 距離フォールバック

## インストール

[INSTALLATION_JP.txt](./INSTALLATION_JP.txt) を参照してください。

## ライセンス・クレジット

- 原作: [alnd029](https://github.com/alnd029/b2b_documents)
- 日本語化・改修: matrix9neonebuchadnezzar2199
- 個別の `LICENSE` に従います
