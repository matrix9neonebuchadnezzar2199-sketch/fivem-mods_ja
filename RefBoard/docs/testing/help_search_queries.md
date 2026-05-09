# ヘルプ検索 評価クエリリスト

Fuse.js の設定変更時は、`RefBoard/web` で `node scripts/eval-help-fuse.mjs` を実行し、下表の **実測上位3（スクリプト）** 列を更新する。ブラウザ手動評価（`npm run dev` → `#/workspace/help`）では同順位になることを確認する。

**採用中の Fuse 設定**（`web/src/utils/helpSearch.ts`）:

- `threshold: 0.35`, `minMatchCharLength: 2`, `ignoreLocation: true`, `includeScore: true`
- `keys`: `title` 0.5 / `tags` 0.3 / `slug` 0.1 / `body` 0.1
- `useExtendedSearch`: 未使用

インデックスのタイトル・タグは **`reverse_index.json`（ja/en）** 由来。本文は各 `articles/*.md` を frontmatter 除去後に正規化したテキスト。

| クエリ | ロケール | 期待ヒット記事（主） | 実測上位3（スクリプト `eval-help-fuse.mjs`） | 備考 |
|--------|----------|----------------------|---------------------------------------------|------|
| ゴール | ja | match_record_goal（1位） | match_record_goal > trouble_undo_goal > intro_setup | |
| アシスト | ja | match_record_goal | match_record_goal > trouble_undo_goal > trouble_e3006_player_has_events | goal 記事に統合 |
| カード | ja | match_card（1位） | match_card > data_export > intro_setup | |
| 警告 | ja | match_card | match_card > team_add_roster_member | |
| 退場 | ja | match_card, match_substitute_player | match_card > match_substitute_player > match_penalty_shootout | 順不同可 |
| 交代 | ja | match_substitute_player（1位） | match_substitute_player > intro_setup > match_card | |
| PK | ja | match_penalty_shootout（1位） | match_penalty_shootout > data_export > match_manual_score_edit | |
| ペナルティ | ja | match_penalty_shootout | match_penalty_shootout | |
| 試合作成 | ja | match_create_new（1位） | match_create_new > team_create > intro_setup | |
| 終了 | ja | match_finish（1位） | match_finish > match_create_new > data_view_history | |
| 再開 | ja | match_finish | match_finish | `reverse_index` に「再開」タグ |
| インポート | ja | data_import（1位） | data_import > intro_what_is_refboard > data_export | |
| 取り込み | ja | data_import | data_import | |
| バックアップ | ja | data_export, data_import | data_import > data_export > intro_setup | 上位3に両方 |
| CSV | ja | data_export（1位） | data_export > intro_setup > data_view_history | |
| 履歴 | ja | data_view_history（1位） | data_view_history > intro_what_is_refboard > trouble_undo_goal | |
| チーム作成 | ja | team_create | team_create | `reverse_index` に「チーム作成」 |
| ロスター | ja | team_add_roster_member（1位） | team_add_roster_member > team_create > match_substitute_player | |
| 表示名 | ja | intro_setup（1位） | intro_setup > data_import > data_view_history | |
| はじめて | ja | intro_setup, intro_what_is_refboard | intro_setup > intro_what_is_refboard | 順不同可 |
| ゴール取消 | ja | trouble_undo_goal | trouble_undo_goal | undo 側タグから単独「ゴール」を外し「ゴール取消」を付与 |
| 削除できない | ja | trouble_e3006_player_has_events | trouble_e3006_player_has_events > team_create > match_create_new | |
| E3006 | ja | trouble_e3006_player_has_events | trouble_e3006_player_has_events | |
| ロスタイム | ja | match_record_goal, match_card, match_substitute_player（順不同で上位3） | match_card > match_substitute_player > match_record_goal | `reverse_index` の試合中記事タグに `ロスタイム` / `stoppage` / `45+2` を付与 |
| goal | en | match_record_goal | match_record_goal > trouble_undo_goal > intro_setup | |
| card | en | match_card | match_card > match_record_goal > intro_what_is_refboard | |
| import | en | data_import | data_import > data_export > intro_setup | |
| substitute | en | match_substitute_player | match_substitute_player > match_card > trouble_e3006_player_has_events | `substitute` を tags に追加 |
| operator | en | intro_setup | intro_setup > data_import | `operator` を intro tags に追加 |
| stoppage | en | match_record_goal, match_card, match_substitute_player（順不同） | match_substitute_player > match_card > match_record_goal | `match_create_new` / `match_finish` の `reverse_index` から `stoppage` タグを外し本文マッチに寄せない |
| 部分マージ | ja | data_import（1位必須） | data_import | |
| 選択取り込み | ja | data_import（1位必須） | data_import | |
| partial | en | data_import（1位必須） | data_import > intro_what_is_refboard > trouble_e3006_player_has_events | |
| selective | en | data_import（1位必須） | data_import > team_add_roster_member > match_record_goal | |

## 旧設定（参考）

第九コミット前の `helpSearch.ts` は概ね次のとおりだった。

- `keys`: `title` 0.7 / `tags` 0.2 / `body` 0.1（**slug キーなし**）
- `threshold: 0.4`
- `ignoreLocation: true`（変更なし）
- `minMatchCharLength: 2`（変更なし）
