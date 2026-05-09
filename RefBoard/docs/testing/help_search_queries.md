# ヘルプ検索 評価クエリリスト

Fuse.js の設定変更時は、`RefBoard/web` で `node scripts/eval-help-fuse.mjs` を実行し、下表の **実測上位3（スクリプト）** 列を更新する。

**採用中の Fuse 設定**（`web/src/utils/helpSearch.ts`）:

- `threshold: 0.35`, `minMatchCharLength: 2`, `ignoreLocation: true`, `includeScore: true`
- `keys`: `title` 0.5 / `tags` 0.3 / `slug` 0.1 / `body` 0.1

**コーパス**: ja/en 各 **16 本**（intro 3／match 8／team 2／trouble 3）。v0.4.0 でデータ管理系 6 本を削除したため、**CSV／インポート／バックアップ／移行**専用の評価クエリは撤去した。

| クエリ | ロケール | 期待ヒット記事（主） | 実測上位3（`eval-help-fuse.mjs`） | 備考 |
|--------|----------|----------------------|-----------------------------------|------|
| ゴール | ja | match_record_goal | match_record_goal > trouble_undo_goal > intro_setup | |
| アシスト | ja | match_record_goal | match_record_goal > trouble_undo_goal > trouble_e3006_player_has_events | |
| カード | ja | match_card | match_card > compact_dock_usage > troubleshooting_event_disappears | data 記事削除後、短語は他記事に寄りやすい |
| 警告 | ja | match_card | match_card > team_add_roster_member | |
| 退場 | ja | match_card | match_card > match_substitute_player > match_penalty_shootout | |
| 交代 | ja | match_substitute_player | match_substitute_player > intro_setup > match_create_new | |
| PK | ja | match_penalty_shootout | match_penalty_shootout > match_pk_recording > troubleshooting_event_disappears | |
| ペナルティ | ja | match_penalty_shootout | match_penalty_shootout > match_pk_recording | |
| 試合作成 | ja | match_create_new | match_create_new > team_create > match_finish | |
| 終了 | ja | match_finish | match_finish > compact_dock_usage > match_pk_recording | |
| 再開 | ja | match_finish | match_finish | |
| チーム作成 | ja | team_create | team_create | |
| ロスター | ja | team_add_roster_member | team_add_roster_member > match_substitute_player > match_card | |
| 表示名 | ja | intro_setup | intro_setup > troubleshooting_event_disappears > compact_dock_usage | |
| はじめて | ja | intro_setup | intro_setup > intro_what_is_refboard | |
| ゴール取消 | ja | trouble_undo_goal | trouble_undo_goal > troubleshooting_event_disappears | |
| 削除できない | ja | trouble_e3006_player_has_events | trouble_e3006_player_has_events > team_create > match_create_new | |
| E3006 | ja | trouble_e3006_player_has_events | trouble_e3006_player_has_events | |
| ロスタイム | ja | match_card 等 | match_card > match_substitute_player > match_record_goal | |
| PK 入力 | ja | match_pk_recording | match_pk_recording | |
| ペナルティ 戦 | ja | match_pk_recording | match_pk_recording > match_penalty_shootout | |
| 小窓 モード | ja | compact_dock_usage | compact_dock_usage > troubleshooting_event_disappears > match_pk_recording | |
| compact dock | ja | compact_dock_usage | compact_dock_usage > match_pk_recording | |
| イベント 消えた | ja | troubleshooting_event_disappears | troubleshooting_event_disappears | |
| event missing | ja | troubleshooting_event_disappears | troubleshooting_event_disappears | |
| goal | en | match_record_goal | match_record_goal > trouble_undo_goal > intro_setup | |
| card | en | match_card | match_card > match_record_goal > intro_what_is_refboard | |
| substitute | en | match_substitute_player | match_substitute_player > match_card > trouble_e3006_player_has_events | |
| operator | en | intro_setup | intro_setup > compact_dock_usage > troubleshooting_event_disappears | |
| stoppage | en | match_record_goal 等 | match_record_goal > match_substitute_player > match_card | |
| PK input | en | match_pk_recording | match_pk_recording > compact_dock_usage | |
| penalty shootout | en | match_pk_recording | match_pk_recording > match_penalty_shootout > match_finish | |
| compact dock | en | compact_dock_usage | compact_dock_usage > match_pk_recording > troubleshooting_event_disappears | |
| event missing | en | troubleshooting_event_disappears | troubleshooting_event_disappears | |

## 旧設定（参考）

第九コミット前の `helpSearch.ts` は概ね次のとおりだった。

- `keys`: `title` 0.7 / `tags` 0.2 / `body` 0.1（**slug キーなし**）
- `threshold: 0.4`
