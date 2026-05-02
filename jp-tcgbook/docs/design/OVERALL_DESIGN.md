# jp-tcgbook — 全体設計（マスター）

**役割**: 本ファイルは **設計ドキュメントの入口**。**詳細は各 PHASE・個別設計に譲り**、ここでは現在地・データの関係・**実装順の推奨**だけを一本化する。  
**文字コード**: UTF-8（BOM なし）

---

## 1. 読む順番（ドキュメントマップ）

| 優先 | ファイル | 内容 |
|------|----------|------|
| ★ | **本ファイル** | 全体像・ロードマップ |
| | `docs/design/PHASE_2d_defeat_reward.md` | 敗北コピー（実装済） |
| | `docs/design/PHASE_C_daily_counters.md` | 日次カウンタ `tcg_daily_counters` |
| | `docs/design/PHASE_E_ranking_season_ui.md` | ランキング UI・履歴・段位・EXP／連勝・徽章 **`html/assets/ranc/`** |
| | `docs/design/RANKING_SEASON_LEVEL_HISTORY.md` | ランキング補足メモ |

長期引継ぎ・過去の経緯: `2026-05-01 開発日記.md` §19。実務の現在地: `2026-05-02 開発日記.md`。

---

## 2. 現在地（実装済みの前提）

| 領域 | 状態 | メモ |
|------|------|------|
| **仮想ロビー・PvP コア** | 済（PHASE 2b） | `battle_lobby.lua` / `battle_pvp.lua` / `shared/battle_rule.lua` |
| **Wire ログ** | 済 | `Config.BattleWireLog`、`shared/battle_wire_log.lua` |
| **リアル PvP 終了フック** | 済 | `BattleStats.RecordFinish`（Elo・win/loss/draw）、`BattleRewards.GrantOnFinish`（2d） |
| **日次カウンタ** | **済（M1）** | `tcg_daily_counters`・`Database.IncrementDaily*`・`battle_stats` / `battle_rewards` 連携。再起動で `install.sql` がテーブル作成 |
| **試合履歴テーブル** | **済（M2）** | `tcg_match_history`・`Finish` 時 INSERT・`GrantOnFinish` の戻りでコピー列 |
| **ランキング／履歴タブ・EXP** | **未** | → **PHASE E2〜E5** |

**単独検証**: `tcg_debug_finish_hooks_dryrun`（`server/battle_finish_dryrun.lua`）で 2c/2d フックを疑似実行可能。

---

## 3. サーバー終了パイプライン（リアル PvP・normal）

確立済みの順序。**PHASE C / E** はこの列に **副作用として追加**する（順序の詳細は各 PHASE）。

```
BattlePvp.Finish
  → collectFinishContext（ctx）
  → TriggerClient ended …
  → BattleStats.RecordFinish(ctx)     ← Elo / winloss／【C】日次 counters／【E】EXP・連勝・将来ほか
  → BattleRewards.GrantOnFinish(ctx)  ← 2d コピー／【C】copies_received 日次
  → 【E1】`Database.InsertMatchHistory`（リアル PvP のみ）
  → destroySession …
```

- **solo / CPU**: `ctx.is_real_pvp == false` → Stats の一部・Rewards は早期 return（現状どおり）。
- **投了・切断**: `Finish` 非経由 → 本パイプラインは動かない（意図どおり）。

---

## 4. データモデル俯瞰

### 4.1 既存（概要）

- **`tcg_players`**: `citizenid`, `rating`, `wins`, `losses`, `draws`, …
- **`tcg_player_cards`**, **`tcg_decks`**, **`tcg_cards_master`**, …

### 4.2 これから追加・拡張（計画）

| 名前 | PHASE | 役割 |
|------|-------|------|
| **`tcg_daily_counters`** | **C** | JST 暦日ごとの battles/wins/losses/draws/copies_received |
| **`tcg_match_history`** | **E1 済** | 試合 1 行。一覧 API は **E2** |
| **`tcg_players` 列追加** | **E3** 目安 | `exp`, `level`, `win_streak_current` 等（列名は実装で確定） |
| **シーズンマスタ** | **E6（任意）** | 番号シーズン時のみ。通年は `season_id=0` 等で十分な場合あり |

インデックス・API の **`LIMIT`**・権限・XSS・除外リスト等は **PHASE E §8.1** に集約。

---

## 5. BOOK / NUI（完成イメージ）

| タブ（想定） | 状態 | PHASE |
|--------------|------|-------|
| コレクション／デッキ／対戦（既存） | 済 | — |
| **対戦履歴** | 未 | **E2** |
| **ランキング** | 未 | **E4〜E5**（段位徽章は `html/assets/ranc/*.png`） |

機能フラグで未完成タブを隠す運用は **PHASE E §8.1**。

---

## 6. 統一実装ロードマップ（推奨順）

「依存が少ないもの→プレイヤー見えやすいもの」の順。**C と E1 は並行開発も可能**。

| ステップ | 内容 | 主な成果物 |
|----------|------|------------|
| **M1** | ~~**PHASE C** 本実装~~ **済** | `tcg_daily_counters`、`Database.IncrementDaily*`、`battle_stats` / `battle_rewards` |
| **M2** | ~~**PHASE E1**~~ **済** | `tcg_match_history`、`Database.InsertMatchHistory`、`battle_pvp.Finish` |
| **M3** | **PHASE E2** | 履歴一覧 API + NUI **対戦履歴**タブ |
| **M4** | **PHASE E3** | EXP・連勝・連勝ボーナス（`RecordFinish`／関連 DB） |
| **M5** | **PHASE E4** | ランキングタブ骨格（通年ラベル・`rating` 順・自分順位） |
| **M6** | **PHASE E5** | **段位**（config 閾値 + `ranc` 画像 + フォールバック） |
| **M7** | **PHASE E6（任意）** | 番号シーズン・締め・ランクソフト降下 |

**検証**: 各マイルストーン後に dryrun または 2 クライアントで Wire・DB・BOOK を確認。

---

## 7. 設定・運営（共通）

- **`config.lua`**: 段位閾値・EXP・連勝倍率・リーダーボード除外 citizenid・UI フラグなどは **日本語コメント必須**（プロジェクト規約）。
- **本番**: `Config.BattleWireLog = false` 推奨。デバッグコマンドは ACE と `Config.DebugCommands`。

---

## 8. 変更しないもの（このロードマップの範囲外）

- ESX / QBCore 依存、他リソースのファイル参照
- 盤面全ログ・リプレイストレージ
- IP / ハードウェア ID の収集

---

## 9. 改訂履歴（人工メモ）

| 日付 | 内容 |
|------|------|
| 2026-05-02 | 初版（PHASE C / E 統合ロードマップ、`ranc` 徽章前提） |
| 2026-05-02 | M1 PHASE C 実装済を現在地に反映 |
| 2026-05-02 | M2 PHASE E1 `tcg_match_history`・Finish 時 INSERT |
