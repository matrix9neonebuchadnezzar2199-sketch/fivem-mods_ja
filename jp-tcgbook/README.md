# jp-tcgbook

FiveM 上で動作する **スタンドアロン** TCG リソース（BOOK: コレクション・デッキ編成・CPU 対戦・疑似／実プレイヤー PvP・Elo・対戦履歴・ランキング／段位徽章・JA/EN UI とカード名 `name_en`）。パック入手・経済連携は将来拡張。

**English**: [README.en.md](README.en.md)

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

## カード画像の置き場所と差し替え方

BOOK のカード画像は **NUI のルート（`html/`）からの相対パス**で参照される。実体は次のディレクトリに置く。

| 種別 | ディレクトリ（リソース内） | ファイル名の規則 |
|------|------------------------------|------------------|
| キャラ枠 | `html/assets/cards/character/` | **`tcg_<card_id>.jpg`** とマスタの `card_id` を一致させる |
| モンスター枠 | `html/assets/cards/monster/` | 同上 |

例: `card_id` が `tcg_ur_antares` なら、ファイルは `html/assets/cards/character/tcg_ur_antares.jpg`。`shared/cards.lua` の **`image_path`** は `assets/cards/character/tcg_ur_antares.jpg` のように **`html/` からの相対**で書く。

### 既存カードの画像だけ差し替えるとき

1. **同名ファイルを上書き**する（パス・ファイル名は変えない）。推奨フォーマットは **横長の JPG**（コレクション・デッキは CSS で `object-fit: cover` により枠内に収める）。
2. クライアントキャッシュを避けたい場合は、運営ポリシーに応じて **クエリ付き URL やファイル更新時刻**の運用を検討（現状の実装はシンプルな相対パス参照）。
3. **`restart jp-tcgbook`**（またはサーバー再起動）で NUI が再読込される。
4. **重要**: **画像だけ変えてもカード名・説明は自動では変わらない。** 絵のキャラに合わせて **`shared/cards.lua` の `name` / `name_en` / `description` / `description_en` を手で直す。** 後述の **DB シード**で MySQL 側も揃えられる。

### 文字コード

Lua・HTML・JSON は **UTF-8（BOM なし）** で保存する（BOM 付きだと Lua の読み込みが失敗することがある）。

## カードマスタと DB（追加・更新のやり方）

カード定義の **正本は `shared/cards.lua` の `TcgCardsMaster`**。テーブル `tcg_cards_master` はこれをミラーする。

### 新規カードを追加するとき（概要）

1. **`html/assets/cards/...`** に **`tcg_<card_id>.jpg`** を配置する。
2. **`shared/cards.lua`** に 1 枚分のエントリを追加する（`card_id`, `name`, `name_en`, `rank`, `type`, 四方向ステ, `image_path`, `description`, `description_en`, `no` など。既存行と同じ形に合わせる）。
3. **`no`** は運用上の並び用。既存と重複しない値にする。
4. サーバー起動処理で **`Database.InitializeTables`** が走り、`tcg_cards_master` へ **INSERT / UPSERT** される（後述の **`Config.SeedCardsFromLua`** に依存）。

**注意**: `tcg_player_cards` などは **`card_id` が `tcg_cards_master` に存在する**ことが前提（外部キー）なので、**先にマスタが DB に入っている**必要がある。

### MySQL に Lua の内容を反映させる（運営向け）

`config.lua` の **`Config.SeedCardsFromLua`** が効く。

- **`true` にした状態でサーバー（またはリソース）を再起動**すると、`TcgCardsMaster` 全件について **`tcg_cards_master` が UPSERT** される（既存の `card_id` も **名前・画像パス・ステ・説明などが Lua で上書き**される）。
- **`false`** のときは、**すでにテーブルに 1 行でもある場合**、通常は **起動時の Lua シードをスキップ**する（DB を勝手に書き換えない運用）。**初回インストールで `tcg_cards_master` が空**なら、設定に関わらず **一度だけ Lua から投入**される仕様になっている。

**推奨フロー（本番でマスタを更新した直後）**

1. メンテまたはテスト鯖で **`Config.SeedCardsFromLua = true`** にする。
2. **`refresh` → `restart jp-tcgbook`**（またはサーバー再起動）。
3. DB の `tcg_cards_master` と実機 BOOK を確認する。
4. 問題なければ **`Config.SeedCardsFromLua = false`** に戻してコミット・再起動する。

開発中は **`true` のまま**にしておくと、Lua を編集するたびに DB が追従しやすい。

### BOOK の表示と DB の関係（参考）

BOOK は **`openBook` で Lua マスタを NUI に渡す**ため、**画面上の名前・画像パスは Lua と整合**させるのが基本である。デッキ詳細の一部は DB JOIN の結果も混ざるが、**Lua にある `card_id` は表示寄せで Lua を優先する**実装があり、DB が古くても表示が崩れにくいようにしてある。**ランキングや外部ツールが DB のみ参照する場合は、`SeedCardsFromLua` で DB を最新にしておく**と安全。

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

**MIT License** — 詳細は [LICENSE](LICENSE) を参照。

カード画像（`html/assets/cards/`）および段位徽章（`html/assets/ranc/`）は本リソース用オリジナル素材として同梱している。第三者素材に差し替える場合は独自のライセンス整理と必要なら `docs/CREDITS.md` で出典を記載すること。
