# インストール（Qbox 想定）

## 前提

- [dependencies.md](dependencies.md) の **必須** リソースがサーバーに入っていること（ox_lib, oxmysql, ox_target, qbx_core 等）。
- データベースに SQL を流す（Qbox 用ファイルは同梱ディレクトリを参照）。

## SQL

`README - INSTALL INSTRUCTIONS/QBOX/properties.sql` を DB に適用する。  
（環境に合わせてバックアップを取ってから実行。）

## リソース配置

1. 本フォルダ `jp-ps-housing` をサーバーの `resources` 配下に置く（例: `[housing]/jp-ps-housing`）。  
2. `server.cfg` で依存リソースの **起動順** を上流 README に従って整える。  
3. `ensure jp-ps-housing`（フォルダ名に合わせる）。

## 設定

- `shared/config.lua` の `Config.Target` / `Config.Notify` / `Config.Inventory` を **ox** 系に合わせる（Qbox では `ox` が一般的）。  
- `shared/framework.lua` は QBCore 互換ブリッジ経由で動作する想定。

## NUI の再ビルド（翻訳・フォント変更後）

```text
cd ui
pnpm install   # または npm install
pnpm build     # 成果物が html/ に出力される想定（package.json の scripts を確認）
```

初回のみ上流 `ui/README.md` も参照。
