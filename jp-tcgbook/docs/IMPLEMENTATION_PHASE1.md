# jp-tcgbook — フェーズ1 実装メモ

FiveM 向け BOOK（コレクション・デッキ編成）リソースのフェーズ1実装概要とデバッグ手順。

## Git 運用方針

`jp-tcgbook/` は親リポジトリのサブディレクトリとして管理する（単体で `git init` しない）。変更は親ルートから `git add jp-tcgbook/` → commit → push。

## フレームワーク方針

- ESX / QBCore 非依存。プレイヤーキーは `citizenid` 列に保存し、実体は `shared/identity.lua` の `GetPlayerUid(source)`（license → discord → fivem → steam）。

## フェーズ1-7: デバッグコマンド

開発・検証用の `/tcg_*` コマンド。本番では **ACE で無効化**できる。

### 権限（ACE）

- すべてのコマンドに共通: **`command.tcg_debug`**
- **コンソール（source = 0）** は常に許可（監査・緊急運用向け）
- 権限のないプレイヤーが実行した場合: **実行はされず**、`print('[tcg-debug] DENY: ...')` と **チャットにエラー1行**（`[tcg-debug] 権限がありません (ACE: command.tcg_debug)`）を返す

### server.cfg 設定例

```cfg
add_ace group.admin command.tcg_debug allow
# 運営スタッフを group.admin に載せる例（識別子は環境に合わせて変更）
# add_principal identifier.license:xxxxxxxxxxxxxxxx group.admin
```

### コマンド一覧

| コマンド | 構文 | 説明 |
|----------|------|------|
| `tcg_give` | `/tcg_give <card_id> [target_server_id]` | 指定マスタを **1枚** 付与。省略時は実行者。`target` は **オンライン server ID**。 |
| `tcg_giveall` | `/tcg_giveall [target_server_id]` | `TcgCardsMaster` を **1周（各1枚）** 付与（完成度テスト用）。 |
| `tcg_givepack` | `/tcg_givepack <count> [target_server_id]` | `Config.InitialCardRanks` のランクからランダムにフリーカードを選び **N 枚** 付与。**同名は所持が `Config.CardLimit.free` 未満のときのみ**。全体で最大 **50 試行**で打ち切り。 |
| `tcg_reset` | `/tcg_reset [target_server_id]` | `deck_cards → decks → player_cards → players` の順で **全削除**（確認なし）。監査用に `[tcg-debug] AUDIT tcg_reset ...` を `print`。対象クライアントは **BOOK 強制クローズ** + チャット通知。 |
| `tcg_clearcards` | `/tcg_clearcards [target_server_id]` | **所持インスタンス**と **全デッキの tcg_deck_cards** を削除。**デッキ行は残る**（空デッキ）。 |
| `tcg_dumpdeck` | `/tcg_dumpdeck [target_server_id]` | **アクティブデッキ**を `Deck.GetDeck` で取得し、`json.encode` を **サーバーコンソールに print**。アクティブが無い場合は警告と一覧の簡易出力。 |
| `tcg_setrating` | `/tcg_setrating <rating> [target_server_id]` | `tcg_players.rating` を **0〜9999** で更新（整数）。プレイヤー行が無い場合はエラー。 |
| `tcg_listplayers` | `/tcg_listplayers` | `tcg_players` を **citizenid, rating, wins, losses, initialized** でサーバーコンソールに列挙（フェーズ2対戦テスト用）。 |

共通: `RegisterCommand` の `restricted` は **false**（ACE のみで制御）。失敗時もサーバーを止めない。

### 典型的な開発フロー（1台 PC）

1. ゲーム内で `/book` を開き UI を確認する  
2. `/tcg_giveall`（または `/tcg_give`）でコレクション状態を作る  
3. `/book` を閉じて再度 `/book` で **完成度・デッキ** を確認する  
4. `/tcg_reset` で初期化テスト（データ消失に注意）

**注意**: FiveM は同一 PC でクライアントを2インスタンスにしにくいため、**マルチプレイ検証はデバッグコマンドで片側の状態を整え、対戦まわりだけ別 PC / ボット（フェーズ2以降）** とする想定。

## 関連ファイル

| ファイル | 内容 |
|----------|------|
| `server/debug.lua` | デバッグコマンド本体 |
| `server/database.lua` | `ResetPlayer` / `ClearPlayerCardsAndDeckSlots` / `UpdatePlayerRating` / `ListAllPlayers` |
| `client/main.lua` | `jp-tcgbook:client:debugForceCloseBook` |
| `html/js/app.js` | NUI `forceClose` |

## `fxmanifest.lua` の server_scripts 順序

`@oxmysql/lib/MySQL.lua` のあと、依存順に:

1. `server/database.lua`
2. `server/collection.lua`
3. `server/deck.lua`
4. **`server/debug.lua`**（`main.lua` より前）
5. `server/main.lua`

---

更新履歴（メモ）: フェーズ1-7 でデバッグコマンド・ACE 記載を追加。
