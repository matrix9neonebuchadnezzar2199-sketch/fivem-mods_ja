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

---

## 一般的な「ログアウト」管理との対応（参考スキーム）

Web アプリやデスクトップツールでよくあるパターンと、RefBoard（FiveM + NUI + 単一 DB 行ロック）の対応関係である。**そのまま OAuth や Cookie セッションを持ち込む必要はない**が、**思想は既に一部取り込んでいる**。

| 一般的な考え方 | 典型実装 | RefBoard での相当 | 備考 |
|----------------|----------|-------------------|------|
| **サーバ権威** | ログアウト API がトークン／セッション行を無効化 | `editor_locks` をサーバだけが更新。`session:leave` / `lock:release` / `playerDropped` が真実 | クライアントの Pinia は表示用。閉じる経路では Lua を先に呼ぶ（`refboardCloseLua.ts`）。 |
| **明示的ログアウト** | POST `/logout` を必ず一度 | `refboard:session:leave` + `lock:release`（意図的閉じ） | 冪等に近い（空ロックでも OK）。 |
| **接続切断＝セッション終了** | WebSocket close / TCP 切断でサーバが掃除 | `playerDropped` + ハートビート TTL | ブラウザの「タブを閉じる」と同種。NUI はクライアント終了で消える。 |
| **セッション ID** | 不推測なランダム ID を Cookie や Authorization に載せる | 実質 **`source`（server id）+ `license`** が接続単位の識別子 | `source` は再接続で変わるため **license で reclaim**（`lock:acquire` / `lock:release`）を併用。 |
| **単一デバイス／排他** | 「どこかでログインしたら前を蹴る」ポリシー | **編集ロック 1 行**で排他（＋奪い返しは同一 license のみ） | 複数審判は「同時編集は不可」という製品前提に合致。 |
| **Refresh / ローテーション** | アクセストークン短期 + リフレッシュ | **ハートビート**が「生存証明」に近い | TTL で幽霊を切る。JWT のような多段トークンは過剰。 |
| **サーバ側失効リスト** | logout 後に `jti` を denylist | 現状なし（行クリアで十分） | 将来、監査や「強制ログアウト」だけ別テーブルに記録する余地はある。 |

### そのまま使いにくいもの（制約）

- **HTTP Only Cookie ベースのセッション**: NUI は `fetch` でゲーム内リソース URL を叩く形であり、ブラウザの通常ログイン Cookie モデルとは別物である。
- **同一タブ内の localStorage だけでログアウト**: サーバのロックは解放されない。RefBoard は **必ず NetEvent でサーバに届ける**設計にしている。
- **OAuth2 / OpenID Connect フルセット**: 審判用パスワード＋DB ロックの規模には不釣り合いである。

### 取り込むとしたら次の延長線（任意・未実装）

1. **`session_epoch`（整数）**を `editor_locks` か別テーブルに持ち、ログイン成功のたびにインクリメント。各操作で「自分の epoch と一致するか」を見ると、**強制ログアウト**やデバッグ時の一括失効がしやすい（一般的な「セッションバージョン」に近い）。  
2. **`refboard:logout` の単一名前**で `session:leave` + `lock:release` を内部からまとめて呼ぶ（クライアントは今の 2 イベントを意識しなくてよい）。挙動は現状と同じでよい。

現状の **session leave + lock release + dropped + TTL** は、スケールを抑えた **「サーバ権威の明示ログアウト + 切断掃除 + 生存ハートビート」** に相当する。
