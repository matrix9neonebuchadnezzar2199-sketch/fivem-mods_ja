# RefBoard 設計書 2/3：サーバー側設計書（FiveM Lua Server Specification）

## 2.1 ディレクトリ構成

```
RefBoard/
├── fxmanifest.lua
├── config.lua
├── sql/install.sql
├── server/
│   ├── main.lua
│   ├── db.lua
│   ├── lock.lua
│   ├── autosave.lua
│   ├── match.lua
│   ├── team.lua
│   ├── player.lua
│   ├── score.lua
│   ├── clock.lua
│   ├── event.lua
│   ├── permission.lua
│   └── util.lua
├── client/
│   ├── main.lua
│   └── nui_callback.lua
├── shared/constants.lua
├── locales/ja.lua, en.lua
└── web/dist/   # NUI ビルド成果物
```

## 2.2 依存関係

- `oxmysql`（必須）
- イベントプレフィックス: **`refboard:`**
- ACE: **`refboard.referee`**（`Config.RefereePermission` と一致）

## 2.3 設定（config.lua）

`Config.RefereePermission`, `Config.HeartbeatIntervalMs`, `Config.LockTimeoutSec`, `Config.AutosaveDebounceMs`, `Config.ClockSyncIntervalMs`, `Config.OpenKey`, `Config.DefaultLocale`, `Config.HalfDurationMs` — 実ファイル参照。

## 2.4 イベント設計（プロトコル）

設計当初の `soccer:` は **`refboard:`** に統一。

### セッション・ロック

| 方向 | イベント名 | 説明 |
|------|-------------|------|
| C2S | `refboard:session:enter` | ツール起動 `{ mode: 'edit' \| 'view' }` |
| C2S | `refboard:session:leave` | 終了 |
| C2S | `refboard:lock:acquire` | `{ matchId? }` |
| C2S | `refboard:lock:release` | |
| C2S | `refboard:lock:heartbeat` | 定期 |
| S2C | `refboard:lock:update` | broadcast |

### チーム / 試合 / 選手 / スコア / 時計

| C2S | 概要 |
|-----|------|
| `refboard:team:list` / `create` / `update` / `delete` | チーム CRUD |
| `refboard:match:create` / `list` / `get` / `finish` / `cancel` / `checkResume` | 試合 |
| `refboard:player:resolve` / `add` / `remove` / `onlineList` | 選手 |
| `refboard:score:goal` / `edit` / `undo` | スコア |
| `refboard:event:substitute` / `void` | イベント |
| `refboard:clock:start` / `stop` / `set` / `half` | 時計 |
| S2C | `refboard:match:state` | 状態 broadcast |
| S2C | `refboard:notify` | トースト用（任意） |

## 2.5 モジュール責務

- **lock.lua**: `editor_locks` 単一行、ハートビート超過で解放、`playerDropped` / `onResourceStart` でリセット。
- **autosave.lua**: `match_drafts` デバウンス、`checkResume`。
- **score.lua**: `MySQL.transaction` で履歴 + `matches` 更新、broadcast。
- **clock.lua**: `clock_started_at` / `clock_accumulated_ms` / `clock_running`。
- **permission.lua**: `IsPlayerAceAllowed(src, Config.RefereePermission)`。

## 2.6 切断・復帰

編集者 drop → ロック解放 + broadcast、ドラフトは DB 残存。再起動 → `editor_locks` 初期化。再接続 → `checkResume` で再開 UI。

## 2.7 locales

ゲーム内通知用 `Locales['ja']` / `Locales['en']` — `locales/ja.lua`, `locales/en.lua`。
