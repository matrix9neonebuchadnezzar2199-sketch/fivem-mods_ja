# FiveM Trading Card Game (jp-tcgbook) フェーズ1 実装指示書

## プロジェクト概要

FiveM上で動作するトレーディングカードゲームリソース。
ハンターハンターの「グリードアイランド」とFF8の「トリプルトライアド」を
ベースとした、PvP対応のカードバトルシステム。

## リポジトリ情報

- 親リポジトリ: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja
- 本リソースの位置: 親リポジトリ内の `jp-tcgbook/` サブフォルダ
- ローカルパス: `H:\CURSOR\Dev\jp-tcgbook`
- リソース名（FiveM上）: `jp-tcgbook`

### Git 運用方針

`jp-tcgbook` フォルダ単体での `git init` は **行わない**。
親リポジトリ `fivem-mods_ja` のサブディレクトリとして管理する。

```bash
# 親リポジトリのルートで作業する前提
cd <fivem-mods_ja のルート>
git add jp-tcgbook/
git commit -m "feat: jp-tcgbook フェーズ1基盤実装"
git push
```

将来的に独立リポジトリ化する場合は、その時点で git filter-repo 等で
切り出す方針とする。

## 技術スタック

- FiveM (cerulean fx_version)
- サーバーサイド: Lua
- クライアントサイド: Lua
- NUI: 素のHTML/CSS/JavaScript（ビルドツールなし）
- DB: MariaDB / MySQL

### 必須依存リソース

このリソースは以下を **必須** とする。`server.cfg` で先にensureすること。

```cfg
ensure oxmysql
ensure jp-tcgbook
```

`oxmysql` は事実上の標準であり、本リソースは内部的に
`@oxmysql/lib/MySQL.lua` を直接require する。
`fxmanifest.lua` の `server_scripts` 先頭で必ず読み込む。

### フレームワーク方針

本リソースは **スタンドアロン** を基本とし、ESX/QBCoreなど特定のフレームワークに
依存しない。ただしプレイヤー一意キーは「論理的に citizenid」と呼称する
（DB列名も `citizenid`）。実体は以下の優先順位で取得する：

```lua
-- shared/identity.lua として実装
function GetPlayerUid(source)
    return GetPlayerIdentifierByType(source, 'license')
        or GetPlayerIdentifierByType(source, 'discord')
        or GetPlayerIdentifierByType(source, 'fivem')
        or ('steam:' .. (GetPlayerIdentifierByType(source, 'steam') or 'unknown'))
end
```

将来 QBCore 連携を入れる場合は、この関数のみ差し替える設計にする。
README にも識別子方針を明記する。

## ディレクトリ構成

```
jp-tcgbook/
├── fxmanifest.lua
├── README.md
├── config.lua
├── shared/
│   ├── identity.lua                 # 識別子取得の共通関数
│   └── cards.lua                    # カードマスタ定義
├── server/
│   ├── main.lua
│   ├── database.lua
│   ├── deck.lua
│   ├── collection.lua
│   ├── debug.lua
│   └── sql/
│       └── install.sql
├── client/
│   ├── main.lua
│   └── nui_callbacks.lua
├── html/
│   ├── index.html
│   ├── css/
│   │   ├── common.css
│   │   ├── collection.css
│   │   └── deck.css
│   ├── js/
│   │   ├── app.js
│   │   ├── nui.js
│   │   ├── api.js
│   │   ├── card.js
│   │   ├── collection.js
│   │   ├── deck.js
│   │   └── mock_data.js
│   └── assets/
│       └── cards/
└── docs/
    ├── IMPLEMENTATION_PHASE1.md     # この指示書
    └── （フェーズ2以降の指示書）
```

### デザイン資産の所在

UIモックHTMLは `デザイン仕様/` フォルダ（プロジェクトルート直下）を **正** とする。
`docs/mocks/` への複製は行わず、参照は `デザイン仕様/` を正規パスとする。

```
jp-tcgbook/
├── デザイン仕様/                    # ★ デザインモックの正規置き場
│   ├── collection.html
│   ├── deck.html
│   └── （対戦・トレード・ランキングは後追加）
└── ...
```

実装時は `デザイン仕様/*.html` を参照しつつ、本実装の HTML/CSS は
`html/index.html` に統合する。

---

## 全体仕様

### カードランク体系

| 区分 | ランク | 同名カード上限/デッキ | 編成枠 |
|------|--------|---------------------|---------|
| 指定カード | UR | 1枚 | 指定枠（合計2枚まで） |
| 指定カード | SS | 1枚 | 指定枠（合計2枚まで） |
| フリーカード | S | 2枚 | フリー枠（残り8枚） |
| フリーカード | A | 2枚 | フリー枠（残り8枚） |
| フリーカード | B | 2枚 | フリー枠（残り8枚） |
| フリーカード | C | 2枚 | フリー枠（残り8枚） |

### カードのステータス

各カードは4方向（上・右・下・左）に1〜10の数値を持つ。
バトル時、隣接マスのカードと辺の数値を比較して大きい方が勝ち、相手カードを奪取。

### デッキ仕様

- 1デッキ10枚編成
- 1プレイヤー最大10デッキ保有
- 指定カード合計2枚まで、残り8枚はフリーカード
- 同じ指定カードはデッキ内1枚まで、同じフリーカードは2枚まで
- デッキ間でカードの重複利用可能

### バトル時の挙動（フェーズ2で詳細化）

- デッキ10枚から5枚を初期手札としてランダム抽選
- ターン終了時、手札が5枚未満なら山札から1枚ドロー
- 3×3のフィールドにカードを配置、隣接辺の数値比較で奪取

### 初回プレイ時

- `/book` 初回実行時にフリーカード10枚をランダム配布
- 配布内容はフリーカードのみで「組める10枚」を保証（同名最大2枚制約）
- 自動でデフォルトデッキ「マイデッキ」を作成し、配布カードを編成

---

## DB スキーマ

### `tcg_players`

```sql
CREATE TABLE IF NOT EXISTS tcg_players (
    citizenid VARCHAR(64) PRIMARY KEY,
    initialized BOOLEAN DEFAULT FALSE,
    rating INT DEFAULT 1500,
    wins INT DEFAULT 0,
    losses INT DEFAULT 0,
    draws INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### `tcg_cards_master`

```sql
CREATE TABLE IF NOT EXISTS tcg_cards_master (
    card_id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    rank ENUM('UR','SS','S','A','B','C') NOT NULL,
    type ENUM('shitei','free') NOT NULL,
    stat_top TINYINT NOT NULL,
    stat_right TINYINT NOT NULL,
    stat_bottom TINYINT NOT NULL,
    stat_left TINYINT NOT NULL,
    image_path VARCHAR(128),
    description TEXT,
    no INT
);
```

### `tcg_player_cards`

```sql
CREATE TABLE IF NOT EXISTS tcg_player_cards (
    instance_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(64) NOT NULL,
    card_id VARCHAR(32) NOT NULL,
    obtained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    locked BOOLEAN DEFAULT FALSE,
    INDEX idx_owner (citizenid),
    INDEX idx_card (card_id),
    FOREIGN KEY (card_id) REFERENCES tcg_cards_master(card_id)
);
```

### `tcg_decks`

```sql
CREATE TABLE IF NOT EXISTS tcg_decks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(64) NOT NULL,
    name VARCHAR(64) NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_owner (citizenid),
    UNIQUE KEY uniq_owner_name (citizenid, name)
);
```

`UNIQUE KEY uniq_owner_name` を追加。同一プレイヤー内のデッキ名重複を
DB側でも防止する。

### `tcg_deck_cards`

```sql
CREATE TABLE IF NOT EXISTS tcg_deck_cards (
    deck_id BIGINT NOT NULL,
    slot_index TINYINT NOT NULL,
    card_id VARCHAR(32) NOT NULL,
    PRIMARY KEY (deck_id, slot_index),
    FOREIGN KEY (deck_id) REFERENCES tcg_decks(id) ON DELETE CASCADE,
    FOREIGN KEY (card_id) REFERENCES tcg_cards_master(card_id)
);
```

`deck_cards` は instance_id ではなく card_id で管理する。

### カードマスタ投入方針

`shared/cards.lua` の内容は起動時に `tcg_cards_master` へ投入する。
方針は **UPSERT（INSERT ... ON DUPLICATE KEY UPDATE）**。

```sql
INSERT INTO tcg_cards_master
    (card_id, name, rank, type, stat_top, stat_right, stat_bottom, stat_left, image_path, description, no)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    rank = VALUES(rank),
    type = VALUES(type),
    stat_top = VALUES(stat_top),
    stat_right = VALUES(stat_right),
    stat_bottom = VALUES(stat_bottom),
    stat_left = VALUES(stat_left),
    image_path = VALUES(image_path),
    description = VALUES(description),
    no = VALUES(no);
```

これにより `cards.lua` を編集して再起動するだけでマスタが最新化される。
削除されたカードはDBから自動削除はしない（孤立行は手動メンテとする）。

---

## config.lua の内容

```lua
Config = {}

-- デッキ関連
Config.MaxDecksPerPlayer = 10
Config.DeckSize = 10
Config.HandSize = 5
Config.MaxShiteiPerDeck = 2

Config.CardLimit = {
    shitei = 1,
    free = 2
}

-- 初回配布
Config.InitialCards = 10
Config.InitialCardRanks = { 'B', 'B', 'B', 'C', 'C', 'C', 'A', 'A', 'B', 'C' }

-- レーティング
Config.InitialRating = 1500
Config.EloKFactor = 32

-- デバッグ
Config.Debug = true               -- 本番では false
Config.DebugCommands = true       -- /tcg_* デバッグコマンド有効化

-- 自動保存
Config.AutoSaveDebounceMs = 500   -- NUI側のデバウンス時間
```

---

## デバッグ機能と権限制御

### 権限制御方針

デバッグコマンドは **ACE権限** で保護する。
`Config.DebugCommands` がtrueでも、ACE許可がなければ実行不可。

`server.cfg` 例：

```cfg
add_ace group.admin command.tcg_debug allow
```

実装テンプレート：

```lua
local function isDebugAllowed(source)
    if not Config.DebugCommands then return false end
    if source == 0 then return true end  -- コンソールは常に許可
    return IsPlayerAceAllowed(source, 'command.tcg_debug')
end

RegisterCommand('tcg_give', function(source, args)
    if not isDebugAllowed(source) then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '[tcg]', '権限がありません' }
        })
        return
    end
    -- 本処理
end, false)
```

本番運用では `Config.DebugCommands = false` を推奨するが、
ACE未設定でも誤って一般プレイヤーに使われない多重防御とする。

### 実装するデバッグコマンド

```
/tcg_give <card_id> [count]   自分にカードを付与
/tcg_giveall                  全カード1枚ずつ付与
/tcg_reset                    自分のTCGデータを完全リセット
/tcg_clearcards               所持カードを全削除
/tcg_dumpdeck                 アクティブデッキをコンソール出力
/tcg_setrating <value>        レート設定
/tcg_listdecks                デッキ一覧をコンソール出力
```

### `/tcg_reset` の削除順序

外部キー制約があるため、以下の順で削除する：

```lua
-- 1. tcg_deck_cards（tcg_decksにFK） ※decks削除時にCASCADEで消えるが念のため明示
MySQL.query.await('DELETE FROM tcg_deck_cards WHERE deck_id IN (SELECT id FROM tcg_decks WHERE citizenid = ?)', { uid })

-- 2. tcg_decks（CASCADEで deck_cards も消える）
MySQL.query.await('DELETE FROM tcg_decks WHERE citizenid = ?', { uid })

-- 3. tcg_player_cards
MySQL.query.await('DELETE FROM tcg_player_cards WHERE citizenid = ?', { uid })

-- 4. tcg_players（initialized フラグも初期化）
MySQL.query.await('DELETE FROM tcg_players WHERE citizenid = ?', { uid })
```

`tcg_decks` の ON DELETE CASCADE が効くため `tcg_deck_cards` の明示削除は
冗長だが、CASCADE設定を将来変更する事故への保険として明示する。

---

## ブラウザ単体テスト機能

### NUI環境判定とフォールバック

`html/js/nui.js` で FiveM 環境を判定する。
ブラウザでは `GetParentResourceName` が未定義のため、固定値 `jp-tcgbook` で
フォールバックする。

```javascript
const RESOURCE_NAME = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName()
    : 'jp-tcgbook';

const IS_FIVEM = (typeof GetParentResourceName === 'function')
    || navigator.userAgent.includes('CitizenFX');

export function sendToServer(event, data) {
    if (IS_FIVEM) {
        return fetch(`https://${RESOURCE_NAME}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        }).then(r => r.json());
    } else {
        // ブラウザテストモード：mock_data.js のハンドラに委譲
        console.log('[MOCK]', event, data);
        if (window.MOCK_HANDLERS && window.MOCK_HANDLERS[event]) {
            return Promise.resolve(window.MOCK_HANDLERS[event](data));
        }
        return Promise.resolve({ success: true, data: {} });
    }
}
```

### モックデータ件数

`html/js/mock_data.js` には **47枚以上のダミーカード** を含める。
（コレクション画面の表示確認に十分な件数）

`shared/cards.lua` の本実装マスタは初期 **20枚程度** から開始（UR×2、SS×2、
S×4、A×4、B×4、C×4）。マスタは段階的に拡張していく。

両者の件数差は意図的なもので、混乱を避けるため `mock_data.js` 冒頭に
コメントで明記する：

```javascript
/**
 * ブラウザ単体テスト用ダミーデータ。
 * 本実装の shared/cards.lua とは別物で、UI表示確認用に件数多め。
 * FiveM環境で本リソースを起動した場合はこのファイルは使われない。
 */
```

---

## 実装フェーズ

### フェーズ1: 基盤構築 [今回の指示範囲]

#### 1-1. プロジェクト初期化

- `fxmanifest.lua` 作成
- `config.lua` 作成
- `shared/identity.lua` 作成（識別子取得関数）
- `shared/cards.lua` にダミーカードマスタ20枚程度作成
- `server/sql/install.sql` 作成
- `README.md` 作成（後述「README記載事項」参照）
- `.gitignore` 作成

#### 1-2. データベース層

`server/database.lua` に以下の関数を実装：

- `Database.InitializeTables()` 起動時にテーブル作成、カードマスタUPSERT
- `Database.GetPlayer(citizenid)`
- `Database.CreatePlayer(citizenid)`
- `Database.GetPlayerCards(citizenid)`
- `Database.AddCardToPlayer(citizenid, card_id)`
- `Database.GetPlayerDecks(citizenid)`
- `Database.GetDeckById(deck_id)`
- `Database.GetDeckNames(citizenid)`
- `Database.CreateDeck(citizenid, name)`
- `Database.UpdateDeckName(deck_id, name)` 重複時はエラー返却
- `Database.DeleteDeck(deck_id)`
- `Database.SetDeckCard(deck_id, slot, card_id)`
- `Database.RemoveDeckCard(deck_id, slot)`
- `Database.SetActiveDeck(citizenid, deck_id)`
- `Database.CountDecks(citizenid)`
- `Database.ResetPlayer(citizenid)` デバッグ用

#### 1-3. 所持カード管理

`server/collection.lua`:

- 初回 `/book` 時の10枚配布ロジック
- フリーカードのみで「組める10枚」を保証
- 配布後に自動でデフォルトデッキ「マイデッキ」を作成

#### 1-4. デッキ編成ロジック

`server/deck.lua`:

- バリデーション（10枚、指定2枚まで、同名上限）
- カード追加可否判定 `CanAddCardToDeck(deck_id, card_id)`
- 空きスロットへの自動投入 `AddCardToDeck(deck_id, card_id)`
- スロット解除 `RemoveCardFromDeck(deck_id, slot)`
- デッキコピー `DuplicateDeck(deck_id)` （命名: `元名 - Copy`、連番付与）
- デッキ名重複チェック（手動編集時はエラー、コピー時は連番自動付与）
- **`DeleteDeck`**: アクティブだったデッキを削除した場合、残デッキのうち **`tcg_deck_cards` の件数が `Config.DeckSize` と一致する**（ちょうど10枚完成）ものの **最も古い `id`** を `Database.SetActiveDeck` でアクティブ化する。該当が1つも無いときは **`UPDATE tcg_decks SET is_active = FALSE WHERE citizenid = ?`** でアクティブなしを許容する（未完成デッキだけが残るデッドロックを防ぐ。NUI はフェーズ1-6で「使用デッキ未設定」を表示する）。

#### 1-5. クライアント・NUI連携

`client/main.lua`:

- `/book` コマンド登録
- NUI開閉制御（SetNuiFocus、ESCで閉じる）

`client/nui_callbacks.lua`:

実装するコールバック：

- `openBook` `closeBook`
- `selectDeck` `addCardToDeck` `removeDeckCard`
- `createDeck` `duplicateDeck` `deleteDeck` `renameDeck`
- `setActiveDeck`

#### 1-6. NUI実装

`html/index.html` に5タブ構造を作成。
コレクション・デッキ編成のみ実装、他は「準備中」プレースホルダ。

デザインは `デザイン仕様/collection.html` および `デザイン仕様/deck.html` を
正として参照する。

##### コレクションタブ実装要点

- 3ペイン（左フィルタ／中央カードグリッド／右詳細）
- 上部ツールバー（完成度プログレスバー＋ソートボタン）
- カードの四方向数値表示、最大値は赤強調
- 右詳細はカード絵の四方向に円形バッジで数値配置
- 種別/ランクフィルタ、検索、ソート（ランク/入手日/名前）

##### デッキ編成タブ実装要点

- 3ペイン（左デッキ一覧／中央エディタ／右所持カード）
- サイドバー：保有数バッジ、鉛筆アイコンによる名前インライン編集
- エディタ：自動保存ステータス、枚数/指定カウンタ、5×2スロット、統計
- 右ペイン：残数バッジ、ホバー時「＋」ボタン、ルールに応じた無効化表示
- 操作: 「使用デッキに設定」「コピーして新規追加」「シャッフルテスト」「削除」
- ヘルプモーダル（タイトル横📖アイコン）

##### シャッフルテストの定義

「シャッフルテスト」ボタンの動作：

- **クライアント側のみで動作する表示シミュレーション**
- デッキ10枚からランダム5枚を抽出し、初期手札として表示するモーダル
- DBへの保存は行わない（自動保存とは無関係）
- 「もう一度シャッフル」ボタンで再抽選
- バトル時に実際どんな手札になるかの感覚を掴むための機能

##### 自動保存の競合制御

- NUI側で `Config.AutoSaveDebounceMs`（500ms）のデバウンス
- 連続操作時は最後の操作のみサーバー送信
- サーバー応答が success: false ならステータスを「赤●エラー」表示し、
  クリックで再送信
- ロールバック表示の例：「保存失敗：所持していないカードです（操作を取り消しました）」
- エラー時はクライアント側のUI状態をサーバーから取得した正値で再描画

#### 1-7. デバッグ機能

`server/debug.lua` に前述のコマンドを実装。ACE権限で保護。

#### 1-8. ブラウザ単体テスト

`html/js/mock_data.js` に47枚以上のダミーカードと操作ハンドラを実装。
ブラウザで `index.html` を開けばモックデータでUIが動作する状態にする。

---

## 開発ルール

### コミット粒度

機能単位で細かくコミット。1コミット1機能。
プレフィックス：`feat:` `fix:` `style:` `refactor:` `docs:` `chore:`

### サーバー権威

カード所持・デッキ内容・バリデーションは全てサーバーで判定。
NUIから受け取ったデータは絶対に信用しない。
クライアント側のチェックはUX用（即座のフィードバック）のみ。

### NUI応答形式

```javascript
{
  success: true | false,
  data: { ... },
  error: 'エラー内容'
}
```

---

## このフェーズの完成条件

1. `/book` で BOOK UI が開く
2. 初回プレイヤーに10枚のフリーカードが配布される
3. デフォルトデッキ「マイデッキ」が自動作成される
4. コレクションタブで所持カード一覧が表示される（フィルタ・ソート動作）
5. デッキ編成タブでカードの追加・削除が動作する
6. デッキの新規作成・コピー・削除・名前変更ができる
7. 自動保存ステータスが正しく表示される（デバウンス・エラー時ロールバック含む）
8. デッキ保有数10件で新規・コピーが無効化される
9. 編成ルール違反時に追加できない（残0/指定上限/デッキ満杯）
10. デバッグコマンドが ACE権限保護下で動作する
11. ブラウザ単体で `index.html` を開いてもモックデータでUIが動く
12. `/tcg_reset` 後に再度 `/book` で初回配布が走る

## このフェーズで実装しないもの

- 対戦タブ・バトル盤面
- マッチング機能
- トレード機能
- ランキングタブ
- カード画像アセット（プレースホルダ絵文字でOK）
- レーティング更新ロジック

## 次フェーズ予告

フェーズ2では「対戦」タブとバトル盤面の設計から始める。
HTMLモックを開発者と確認しながら進めるため、
本フェーズでは「対戦」「トレード」「ランキング」は
プレースホルダ表示のみ用意する。
