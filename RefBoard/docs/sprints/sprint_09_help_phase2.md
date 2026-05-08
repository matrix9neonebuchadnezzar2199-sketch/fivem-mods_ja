# Sprint 09 — v0.6.5 〜 v0.7.0（ヘルプ Phase 2 — Sprint 07 残タスク消化）

## 位置付け

Sprint 07（v0.6.0）で着地した「ヘルプ骨組み＋日本語記事 4 本」の続き。CHANGELOG v0.6.0 で明示した未完了タスク（**記事 16 本追加・英語版・Fuse.js 検索・主要 4 画面の `?` パネル**）を、5 つの小バージョンに刻んで段階リリースする。

設計の正は **[docs/help_system_design.md](../help_system_design.md)** のままで、本ファイルはスプリント境界・受け入れ基準・PR 分割を記録する。

## ロードマップ

| 版 | フェーズ | 内容 |
|----|---------|------|
| **v0.6.5** | **Phase A — 試合中記事 8 本** | `match_record_goal` / `match_record_assist` / `match_substitute_player` / `match_yellow_card` / `match_red_card` / `match_penalty_shootout` / `match_manual_score_edit` / `match_finish`。`index.json` / `reverse_index.json` に「試合中」カテゴリを追加。 |
| **v0.6.6** | Phase B — Fuse.js 検索 | `fuse.js` 依存追加。タイトル / tags / 本文の重み付き検索。結果に「項目ごと / 逆引き」バッジ。検索バーは Help ヘッダ。初回マウント時に lazy 構築。 |
| **v0.6.7** | Phase C — コンテキストヘルプ | `web/src/help/context_map.json` を新設（画面 ID → 記事 slug 配列）。`HelpTriggerButton` / `ContextHelpPanel` を実装し、`MatchDetail` / `TeamManage` / `DataManage` / `Settings` のヘッダ右上に `?` を配置。スライドインで関連記事一覧→クリックで Help 画面に遷移。 |
| **v0.6.8** | Phase D — 準備＋周辺記事 8 本 | `intro_what_is_refboard` / `intro_setup` / `match_create_new` / `team_create` / `team_add_roster_member` / `data_view_history` / `data_export` / `trouble_health_check_guide`。これで日本語 20 本完成。 |
| **v0.7.0** | Phase E — 英語版＋仕上げ | `en/articles/*.md` 20 本、`en/index.json` / `en/reverse_index.json`、`HelpView` の locale 切替。USER_GUIDE 更新、デモ GIF（任意）。**Sprint 07 受け入れ基準を全項満たして v0.7.0 リリース**。 |

## アーキテクチャ決定（Phase A 着手時に確定）

1. **両ロケール eager 取り込み**: `HelpView.vue` の `import.meta.glob` を `ja` / `en` 両方に対し eager で走らせ、`useI18n` の `locale` で実行時に切替。`index.json` / `reverse_index.json` も両方を import し computed で切替。
2. **Fuse.js は lazy 構築**: 初回 Help マウント時に 1 度だけ構築。locale 切替時に再構築。
3. **コンテキストマップは別ファイル**: `reverse_index.json` に持たせず `context_map.json` に分離（画面ヘッダーの変更で記事リストがブレないように）。
4. **`actionUrl` の `:matchId` 置換**: 実行時に `route.params.id` で置換。未選択時は試合一覧へ＋トースト。記事フッターは `ArticleFooter.vue` として共通化（Phase A の記事は frontmatter で `actionUrl` を持つが、ボタン UI 自体は Phase B 以降で実装してよい — 記事側は先に書いておく）。
5. **ハッシュルータ規則**: `#/workspace/help/article/:slug` / `#/workspace/help/error/:code` / `#/workspace/matches/:matchId` を踏襲。

## 受け入れ基準（v0.6.5 — Phase A）

1. `web/src/help/ja/articles/` に Phase A の記事 8 本（計 12 本）が揃い、すべて実用レベル本文（lorem 禁止）。
2. 各記事に **「やった後どうなる？」** 節があり、エラー誘発フロー（Undo・誤判定）には **取消手順** が明記されている。
3. `index.json` に「試合管理」カテゴリが追加され、Phase A 記事 8 本が登録されている。
4. `reverse_index.json` に「試合中」カテゴリが追加され、Phase A 記事のうち適切なものが逆引きから到達できる。
5. `npm run build` 成功。
6. CHANGELOG v0.6.5 セクション追加。
7. `sprint_07_uiux_findings.md` に執筆中の気づきが 1 件以上追記されている（無ければ「特記事項なし」と 1 行でよい）。

## Phase A 進捗

- 2026-05-08: スプリント開始。設計書作成、Phase A 着手。
- 2026-05-08: Phase A 前半（試合中記事 4 本: ゴール・アシスト・交代・黄カード）完了。コミット `987dfd7`。
- 2026-05-08: **Phase A 完了**（試合中記事 8/8 本: 上記＋赤カード・PK・手動スコア編集・試合終了/再編集）。受け入れ基準 1〜4 を満たす。`npm run build` 緑。**v0.6.5 リリース可能**。

## Phase B 進捗

- 2026-05-08: Phase B 着手。`fuse.js` 7.3 導入、`helpSearch.ts`（インデックス構築・検索）と `HelpView.vue` の検索バー実装、i18n 拡張。`reverse_index.json` 12 件をインデックス化。
- 2026-05-08: **Phase B 完了**。`npm run build` 緑、検索動作確認（タイトル一致・タグ一致・本文一致いずれもヒットすることを `npm run dev` で確認）。**v0.6.6 リリース可能**。

## Phase C 進捗

- 2026-05-08: Phase C 着手。`HelpTriggerButton` / `ContextHelpPanel` / `contextHelp` store を新設、`context_map.json` を作成、4 画面に `?` を配置。
- 2026-05-08: **Phase C 完了**。`npm run build` 緑、4 画面で `?` クリック → スライドイン → 記事クリック → Help 画面遷移を確認。**v0.6.7 リリース可能**。

## Phase D 進捗

- 2026-05-08: Phase D 着手。準備・周辺ヘルプ記事 8 本、`index.json` / `reverse_index.json` 拡張、`context_map.json` の `team_manage` / `data_manage` / `settings` / `match_detail` 更新。
- 2026-05-08: **Phase D 完了**。日本語記事 **20 本**そろい、`npm run build` 緑。**v0.6.8 リリース可能**。項目ごとツリー（`index.json`）の HelpView 配線は Phase E。

---

**改版履歴**

- 2026-05-08: 初版（v0.6.5 〜 v0.7.0 の 5 フェーズ計画と Phase A 受け入れ基準）。
- 2026-05-08: Phase A 完了（進捗節更新）。
- 2026-05-08: Phase B 完了（進捗節追加）。
- 2026-05-08: Phase C 完了（進捗節追加）。
- 2026-05-08: Phase D 完了（進捗節追加）。
