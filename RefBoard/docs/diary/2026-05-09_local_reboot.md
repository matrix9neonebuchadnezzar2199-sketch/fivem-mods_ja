# 2026‑05‑09 — RefBoard ローカル版リブート（v0.1.0）

旧 RefBoard（v0.8.6 までサーバ連動版）を `RefBoard_old/` に退避し、`RefBoard/` をローカル単体版として作り直した。1 日で 4 連コミットを通し、ブラウザ単体・FiveM の双方で実データ駆動が成立する状態まで引き上げた。

## 第 1 コミット — Lua 最小化と旧資産退避

`fxmanifest.lua` から `server_scripts` と `oxmysql` 依存を全削除し、`shared_scripts` を `config.lua`／`shared/constants.lua` のみに絞った。`client/main.lua` は F6 トグルと `RegisterNUICallback('close')` だけの最小実装。`server/`、`sql/`、`shared/error_codes.lua`、`locales/`、旧 `docs/` を一括削除。`RefBoard_old/` をルート `.gitignore` に追加し、GitHub 側は `git rm -r --cached` で切り離した。サーバを完全に外したことで、編集ロック・プレゼンス・オートセーブ・ヘルスチェックという旧設計の主要ドメインがそのまま不要になった点が大きい。

## 第 2 コミット — web 側のサーバ依存撤去（`571cfdd`）

`stores/{session,presence,autosave}`、`composables/{useHeartbeat,useFocusTracker,useRefboardClose,refboardCloseLua}`、`utils/{lockAcquireErrors,mapMatchFromServer}`、`views/HealthCheck.vue`、`components/{PresenceBadge,UserAvatar,AutosaveIndicator}.vue`、`mocks/` を一括削除。`useNui.ts` を全面書き換えし、FiveM 環境では `close` と小窓関連だけ Lua へ POST、その他は dev で `console.warn` ＋ `{ ok: true }` を返すスタブに落とした。`on()` は `refboard:compact_input_mode` のみ `window.message` 経由で購読する形に簡略化。`utils/localPersist.ts`（`refboard_local_` プレフィックス、スキーマ v=1）と `utils/localId.ts`（match/team/player/rosterMember/event/scoreHistory 用カウンタ）を新設し、ローカル永続化の土台を置いた。`MatchList`／`MatchDetail`／`Settings`／`CreateMatchDialog` はビルドが通る最小限のローカル仮実装に置換し、ストア接続は次コミットへ繰り越した。

## 第 3 コミット — ストア新設と全画面の本接続（`767dd35`）

`types/local.ts` で `Match`/`Team`/`MatchPlayer`/`MatchEvent`/`ScoreHistoryEntry` を定義し、`stores/teams.ts` と `stores/matches.ts` を新設。試合作成・時計（`clockStartedAt` ＋ `clockAccumulatedMs` 合算方式）・ゴール／カード／交代／PK／手動スコア／終了／再開・選手追加・削除（`E3006` 相当の使用中チェック含む）をローカルで完結させた。`MatchDetail.vue` は `localMatchAdapter.ts` を介して既存の `MatchDetailModel` に橋渡しする形にし、UI 側の改修量を最小化。`settings.selfName` を追加してランチャーと設定画面で入力可能にし、`exporters.ts` に `exportFullBackup()`（`refboard_backup_*.json`）を実装してデータ画面から呼べるようにした。`errorCodeMapper.ts` は `E2001 (bad_payload)` / `E3004 (bad_status)` / `E3006 (player_has_events)` のみに縮小。子コンポーネントは `MatchStatusCard @set-half`、`PenaltyShootoutPanel @pk-shot/@finish-match` などイベント駆動に整理し、`AddPlayerDialog` はロスター選択と手入力の両対応にした。

## 第 4 コミット — 掃除（`c89256a`）

`matchServerMapping.ts` を削除（参照ゼロ確認後）。i18n から `presence`／`autosave`／`health` のトップレベル、`toast.local_feature_pending`、`shell.online`、`settings.health_link` を抜き、`help.error_article_missing` のヘルス言及も除去。ヘルプは案 A を採用し **15 本**構成（intro 2／match 7／team 2／data 2／trouble 2。案 A で統合した assist・黄・赤は goal／card に吸収）。`match_record_assist` は `match_record_goal` のアシスト章に統合、`match_yellow_card` と `match_red_card` は `match_card` に統合、トラブル系は `trouble_undo_goal` と `trouble_e3006_player_has_events` の 2 本に絞った。`reverse_index` から 🆘 と 🩺 を畳み 🔧 のみ残す形に整理。`context_map.json` も同期した。`npm run build` の CSS 警告 `Expected identifier but found "-"` は、Tailwind が `exporters.ts` のタイムスタンプ用正規表現 `/[-:T]/g` を任意ユーティリティ `[-:T]` として拾い `index.css` に `.\[-\:T\]{-: T}` を吐いていたのが原因。タイムスタンプ生成を `slice(0,19).replace(/\D/g,'').slice(0,13)` に変更して解消した。

## 検証

`npx vue-tsc --noEmit` と `npm run build` がいずれも緑。`npm run dev` でランチャー → 表示名入力 → チーム 2 つ作成 → 試合作成 → ゴール 2 点と警告 1 枚記録 → 試合終了 → CSV／JSON バックアップ取得 → リロード後の永続化確認まで通った。

## 所感と次の一手

サーバ連動を外した瞬間に、設計の主要ドメインの半分（編集ロック・プレゼンス・オートセーブ・ヘルスチェック）が「そもそも要らない」に変わったのが象徴的だった。コードの削減量よりも、ヘルプとエラーコード体系の縮小幅が大きく、`E1xxx`／`E4xxx` 系の記事を畳めたことで運用ドキュメントが大幅に軽くなった。次に着手するのは JSON インポート UI（端末移行で必須）と、`selfName` を試合詳細ヘッダに表示する小改修。ロスタイム表記の許容は v0.2.0 で集計改修と合わせて入れる方が筋がよさそう。
