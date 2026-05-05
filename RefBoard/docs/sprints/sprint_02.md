# Sprint 02 — Match UI, create flow, lock wiring, autosave

## Goal (v0.2.0)

「1試合分を UI から触れる」状態: 試合一覧・作成、`MatchDetail` フルモック、編集ロックの NUI 配線、オートセーブ表示。

## Delivered

- `MatchDetail.vue` + `components/match/*` + `mocks/matchDetail.ts` + `types/match.ts`
- `MatchList.vue`, `CreateMatchDialog.vue`, ルート `/workspace/matches`, `/workspace/matches/:id`
- サーバー: `lock.lua`（DB + タイムアウト）、`team.lua` / `match.lua`（list/create）、`autosave.lua`（draft + `refboard:autosave:saved`）
- クライアント: `lock:acquire:result`, `team/match` acks, `autosave:saved` → NUI
- `session.enterEdit`（session → lock）、`Launcher` ロック失敗ダイアログ
- i18n: `autosave`, `match_list`, `create_match`, `launcher.*`, `shell`
- `sql/seed_dev_teams.sql`

## Notes

- ブラウザ単体ではロック RPC がタイムアウトし得る（`GetParentResourceName` 無し）。FiveM 内で検証すること。
- 本番は `teams` を運営データで管理し、seed は開発専用とする。
