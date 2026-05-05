# スプリント 4（v0.4.0）指示書 — 記録要素完備・複数審判 UX

**ゴール**: 交代・警告/退場・PK・ハーフ別内訳・編集フォーカス追従を実装し、サッカー試合運営に必要な記録と複数審判の協調 UX を揃える。

## 着手順序（推奨）

4-3 → 4-1 → 4-2 → 4-4 → 4-5 → 4-6

## タスク概要

| ID | 内容 |
|----|------|
| 4-3 | `Match.getScoreBreakdown` / `breakdown` を `match:get`・broadcast に含める。`MatchStatusCard` で表示（延長・PK は該当フェーズのみ）。 |
| 4-1 | `SubstitutionDialog`（Wizard）、`Event.substitute`、タイムライン・選手一覧の交代表示。 |
| 4-2 | `CardIssueDialog`、黄/赤、`issue_card`、2 枚目黄→赤の確認、選手状態表示。 |
| 4-4 | PK フェーズ遷移・`PenaltyShootoutPanel`、`record_penalty`、サドンデス対応の UI 判定。 |
| 4-5 | `useFocusTracker`、`presence:focus`、各カードのバッジを `editorFocus` と連動。 |
| 4-6 | `docs/testing/transaction_test.md`、必要に応じ `refboard_test_transaction`（本番は無効化）。 |

## 受け入れ基準（v0.4.0）

1. 交代が記録され `is_active` / UI 状態が整合する。  
2. 黄 2 枚相当のフローで退場（赤）として記録できる。  
3. スコア内訳が `match_events` 集計と一致する。  
4. PK が本戦スコアと別カウントで記録される。  
5. 編集者のフォーカスが閲覧側バッジに反映される。  
6. トランザクション検証手順が文書化されている。  
7. CHANGELOG / バージョンバンプ / 開発日記 / 本指示書の保存 / git（RefBoard のみ）。
