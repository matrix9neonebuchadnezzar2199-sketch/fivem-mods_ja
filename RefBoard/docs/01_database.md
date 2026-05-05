# RefBoard 設計書 1/3：データモデル設計書（DB Schema Specification）

## 1.1 概要

FiveM サッカー試合管理ツール **RefBoard** のデータ永続化層。`oxmysql`（MySQL/MariaDB）。全テーブル InnoDB、`utf8mb4`。

## 1.2 設計原則

- **append-only 履歴**: スコア等の重要操作は UPDATE せず INSERT のみ（改ざん防止）。
- **論理削除**: チーム・選手は `deleted_at` で論理削除。物理削除は禁止。
- **真実の源はサーバー DB**: クライアント state はキャッシュ。
- **タイムスタンプは UTC**: 表示時に JST 等へ変換。

## 1.3 テーブル一覧

| テーブル | 役割 |
|----------|------|
| `teams` | チームマスタ |
| `matches` | 試合（スコアキャッシュ列あり） |
| `match_players` | 試合参加選手 |
| `match_events` | ゴール・交代・カード等（void は論理） |
| `match_score_history` | スコア履歴（INSERT のみ） |
| `match_drafts` | オートセーブ JSON |
| `editor_locks` | 単一行ロック |
| `tournaments` | 将来用（v1.0 は作成のみ） |
| `tournament_matches` | 将来用 |

カラム詳細・インデックス・ENUM 定義は実装の参照元として **`../sql/install.sql`** を正とする（コピペインストール用 DDL 同梱）。

## 1.4 インストール

```sql
SOURCE sql/install.sql;
```

または MySQL クライアントで `RefBoard/sql/install.sql` を実行。

## 1.5 スコア整合

`matches.team1_score` / `team2_score` は表示用キャッシュ。真の系列は `match_score_history` で再現。アプリ層でトランザクション整合を担保する。

## 1.6 試合メタ（UI 基本情報パネル用）

`matches` に以下を保持する（`sql/install.sql` に含む。既存 DB は `sql/migration_001_match_meta.sql` を一度だけ適用）。

| カラム | 型 | 説明 |
|--------|-----|------|
| `match_name` | `VARCHAR(128) NULL` | 試合名（自由入力） |
| `venue` | `VARCHAR(128) NULL` | 会場名 |
| `kickoff_time` | `TIME NULL` | 開始時刻（日付は `match_date`） |

ハーフ別スコア内訳は `match_score_history` から集計可能（`half` + スコア列）。
