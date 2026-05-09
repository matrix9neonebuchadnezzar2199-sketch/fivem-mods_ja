# 編集ロック（`editor_locks`）解放フロー整理

同じ「DB の 1 行を空にする」結果でも、**経路は複数**ある。Close と強制終了は**同じ処理ではない**（後述）。

## サーバ側：ロック行を空にする処理

| 経路 | ファイル | トリガ | 備考 |
|------|----------|--------|------|
| `refboard:session:leave` | `server/main.lua` | NUI `session_leave` またはクライアント Lua `TriggerServerEvent` | `RefboardLockReleaseIfHeldBy(src)`。**保持者の `holder_server_id` が `src` と一致するときだけ**行クリア。あわせて `presence:remove`・編集パスワード承認解除。 |
| `refboard:lock:release` | `server/lock.lua` | NUI `lock_release` またはクライアント Lua | 保持者が **`src` 一致**または **`license` 一致**（再接続幽霊対策）なら `clearRow`。`presence:setMode(view)`。 |
| `playerDropped`（ロック） | `server/lock.lua` | プレイヤー切断 | `holder_server_id == source` なら `clearRow` またはフォールバック `UPDATE … WHERE holder_server_id = ?`。 |
| ハートビート失効 | `server/lock.lua`（スレッド） | `last_heartbeat` が `Config.LockTimeoutSec` 超過 | `clearRow` + 通知。 |
| リソース起動 | `server/lock.lua` `onResourceStart` | `ensure RefBoard` 等 | 行をクリア（再起動後のゾンビ ID 防止）。 |
| 試合削除 | `server/match.lua` | 削除成功時 | ロック行をクリアして `lock:update` ブロードキャスト。 |

### Close（意図的閉じ）と強制終了の比較

- **Close / F6 で閉じる（同一クライアント）**  
  - `client/main.lua` の `setOpen(false)` が **`refboard:session:leave` と `refboard:lock:release` の両方**を `TriggerServerEvent` する。  
  - 通常は `session:leave` だけで保持者一致なら行は空く。続く `lock:release` は空行に対して冪等 OK。  
  - **`lock:release` だけが同 license 不一致 ID の幽霊に効く**ため、両方残している。

- **ゲーム落ち・Alt+F4（強制終了）**  
  - NUI の `session_leave` / `lock_release` は**呼ばれない**。  
  - サーバは **`playerDropped`**（`lock.lua`）と **`presence.lua` の `playerDropped`**（セッション一覧から削除）が別ハンドラで動く。  
  - ロックは `lock.lua` 側で `holder_server_id == 落ちた source` ならクリア。**Close と同一の Lua 関数ではない**が、結果は「保持者が消えたらロックを外す」で揃える設計。

## クライアント側：NUI を閉じるとき

| 経路 | 動き |
|------|------|
| F6 / `refboard` コマンド | `setOpen(false)` → 上記サーバ 2 イベント + `refboard:setOpen` |
| NUI `refboard:close`（fetch） | 同上（`RegisterNUICallback('refboard:close')`） |
| `onClientResourceStart` | `setOpen(false)` で CEF がログイン画面を覆わないよう同期 |

## Web（Vue）：Close ボタンとランチャー「ゲームへ戻る」

- **`fetchRefboardCloseNui()`**（`composables/refboardCloseLua.ts`）で **必ず先に** `refboard:close` を呼ぶ。NUI 経由の `session_leave` が遅れても、**Lua が先にサーバ解放する**。
- 続けて **`session.leave()`** で `session_leave` + `lock_release` を送り、Pinia とサーバを二重に冪等同期する。
- `session.leave()` 先頭で `pendingRelockMatchId` を消さない（`App.vue` の `refboard:setOpen(false)` ウォッチが試合詳細上の編集者向けに `pendingRelock` を立てるため）。

## 再発調査のチェックリスト

1. `editor_locks` 1 行目: `holder_server_id` / `holder_license` / `last_heartbeat`  
2. サーバログ: `net:lock:release` / `net:session:leave` / `playerDropped`  
3. NUI: Close が `useRefboardClose` を通っているか、単独 `router.push` していないか  
4. 別審判が掴んでいないか（別 `license` では reclaim 不可）
