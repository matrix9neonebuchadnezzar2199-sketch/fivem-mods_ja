# RefBoard 開発日記 — 2026-05-09（v0.1.0 準備・第一コミット / Lua 最小化）

**記録日時**: 2026-05-09（セッション記録）

## 背景

- RefBoard を **ローカル専用 v0.1.0** へリブートする計画のうち、**第一コミット**として Lua 側のみを整理。
- `RefBoard_old/` はローカル素材庫として残し、GitHub には載せない方針。リポジトリ上はもともと未追跡のため `git rm` は不要。`.gitignore` に `RefBoard_old/` を追加して誤 add を防止。

## 実施内容

### fxmanifest / 設定

- `fxmanifest.lua`: `dependencies`・`server_scripts`・`sql` の `files` 参照を削除。`shared_scripts` は `config.lua` と `shared/constants.lua` のみ。`version` を `0.1.0` に。
- `config.lua`: `OpenKey`（F6）と `DefaultLocale` のみに縮小（旧のパスワード・ロック・オートセーブ等は削除）。

### クライアント

- `client/main.lua`: サーバー通信（`TriggerServerEvent` / `RegisterNetEvent`）をすべて削除。`RegisterCommand` / `RegisterKeyMapping` で開閉、`RegisterNUICallback('refboard:close')` で閉じる。
- **第一コミットでは `web/` を変更しない**ため、現行 NUI との互換を維持:
  - 小窓モード用の `compact_dock_state` / `compact_toggle_input` / `refboard:nui_focus_cursor` および `SetNuiFocus` の切り替えロジックを残置。
  - `refboard:setOpen` は `payload.open`（現行 `main.ts`）とトップレベル `open`（将来の NUI 想定）の両方を送信。
- `client/nui_callback.lua` は削除（サーバーへの NUI 転送は不要になったため）。

### 共有・削除

- `shared/constants.lua`: `Config.RefBoard.Version = '0.1.0'` のみ（旧の EventPrefix 等は削除）。
- `shared/error_codes.lua` 削除。
- `server/`・`sql/`・`locales/` をリポジトリから削除。
- `docs/` から通信・DB 前提の文書・スプリント記録・テスト計画・スクリーンショット等を削除（`editor_lock_release_flows.md` / `mock_audit.md` / `logo.svg` は今回のリスト外のため残存）。

## この時点の注意

- `web/dist` は旧ビルドのまま。サーバーが無いため **アプリとしてはまだ正常動作しない**想定。第二コミット以降で `useNui`・ストア・画面を localStorage 駆動に切り替える。

## 検証

- `git push origin main` 成功（記録時点）。

## Git

- コミット: `90efe92` — `chore(RefBoard): Lua を NUI 開閉のみに最小化し旧 server/sql/docs を撤去（v0.1.0 準備）`
- `origin/main` へ push 済み。

## 次の予定（引き継ぎ）

- 第二コミット: `useNui.ts` の書き換え、不要コンポーネント・ストア・`mocks/` 等の削除、`localPersist.ts` / `localId.ts` 新設。
