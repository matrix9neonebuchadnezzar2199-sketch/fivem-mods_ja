# jp-tcgbook

FiveM 上で動作するトレーディングカードゲームリソース（フェーズ1は BOOK・コレクション・デッキ編成が対象）。

## 親リポジトリでの管理

このフォルダは **単体では `git init` しません**。親リポジトリ（例: [fivem-mods_ja](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja)）のサブディレクトリとして追加・コミットしてください。

```bash
cd <親リポジトリのルート>
git add jp-tcgbook/
git commit -m "docs: jp-tcgbook フェーズ1指示書・README"
git push
```

詳細は [docs/IMPLEMENTATION_PHASE1.md](docs/IMPLEMENTATION_PHASE1.md) の「Git 運用方針」を参照。

## セットアップ（実装後の想定）

1. MariaDB / MySQL を用意する。
2. [oxmysql](https://github.com/overextended/oxmysql) を導入する。
3. `server.cfg` に以下を追加する。

   ```cfg
   ensure oxmysql
   ensure jp-tcgbook
   ```

4. `set mysql_connection_string "mysql://..."` を設定する。
5. サーバー起動時にテーブル作成・カードマスタ投入（実装フェーズで `database.lua` 等から実行）。

## 必須リソース

- **oxmysql** — `fxmanifest.lua` で `@oxmysql/lib/MySQL.lua` を読み込む前提。

## 識別子方針

DB の列名は `citizenid` とするが、**フレームワーク非依存**のため実体は識別子の優先順位で決める（`license` → `discord` → `fivem` → `steam` のフォールバック）。実装時は `shared/identity.lua` の `GetPlayerUid(source)` に集約する。詳細はフェーズ1指示書の「フレームワーク方針」を参照。

## デバッグ方針

- `config.lua` の `Config.DebugCommands` が有効でも、デバッグ用 `/tcg_*` コマンドは **ACE 権限 `command.tcg_debug`** がないプレイヤーでは実行できない実装とする。
- コンソール（source `0`）は常に許可する想定。
- `server.cfg` の例: `add_ace group.admin command.tcg_debug allow`
- 本番では `Config.Debug = false` / `Config.DebugCommands = false` を推奨。

## デザイン資産

UI の HTML モックは **`デザイン仕様/` を正** とする。

| ファイル | 内容 |
|----------|------|
| `デザイン仕様/collection.html` | コレクション画面モック |
| `デザイン仕様/deck.html` | デッキ編成モック |

`docs/mocks/` への複製は行わない。本番 NUI は `html/index.html` に統合する。

## フェーズ1の実装仕様

[docs/IMPLEMENTATION_PHASE1.md](docs/IMPLEMENTATION_PHASE1.md) を参照。

## 全体設計（対戦・日次・ランキング）

対戦タブ以降の PHASE・DB・実装順の **入口**は **[docs/design/OVERALL_DESIGN.md](docs/design/OVERALL_DESIGN.md)**。

## ライセンス

未定。
