# MERIDIAN-9（jp-meridian9）正式方針

マスター承認済みの修正方針を、外部の指示書とリポ実装の両方で参照できるよう集約したもの。更新時は本ファイルと実装の差分を必ず確認すること。

---

## INSTRUCTION-005 補足：開発日記（MERIDIAN-9 専用例外）

**MERIDIAN-9 専用例外**：日記は `jp-meridian9/YYYY-MM-DD_開発日記.md` 形式で **MOD 直下** に配置する。リポジトリ既定の `dev-diary-required.mdc`（`<mod>/docs/*.html`）は **本 MOD では適用しない**。

理由：規模が大きく日記が頻繁に増えるため、ファイルブラウザで時系列を一覧しやすい直下配置が運用上有利。

---

## INSTRUCTION-001 補足：グローバル変数規約の例外

`.cursor/rules/fivem-lua.mdc` の「グローバル禁止」原則に対し、MERIDIAN-9 では以下のみグローバル化を許容する。

- `MRD9` … 名前空間テーブル（ユーティリティ・状態管理を内包）
- `Config` … 設定オブジェクト
- `Locales` / `_` … ロケール辞書とヘルパー関数

これら **以外** の関数・変数は **`local` 必須**。将来的にモジュール分割（`exports` ベース）への移行余地は残すが、現段階では開発速度を優先する。

---

## INSTRUCTION-001 補足：`fxmanifest.lua` ヘッダ

リポジトリ慣習に合わせ、次を含める（`version` はリリースに合わせて更新）。

```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'MERIDIAN-9 / Project JANUS - 次元探査エクストラクション型ミッション MOD'
version '0.1.0-jp'
license 'MIT'
repository 'https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja'
```

INSTRUCTION-006 以降: `dependencies { 'oxmysql', 'ox_lib', 'ox_target' }`（009 時点）を追加し、`server_scripts` の **先頭**に `'@oxmysql/lib/MySQL.lua'` を置く（`jp-tcgbook` 等のリポジトリ慣習に合わせる）。`@ox_lib/init.lua` は `shared_scripts` 先頭。

---

## INSTRUCTION-003：フレームワーク検出と Qbox

- **運用ルール**：実装で判明した API 誤りは **実装を正** とし、本ファイル・外部指示書を **事後更新** する。
- **Qbox**：`qb-core` とは API が異なるため分岐を分離する。プレイヤー取得は **`exports.qbx_core:GetPlayer(src)`** を用いる（`GetCoreObject().Functions.GetPlayer` に依存しない）。

指示書スニペット例（簡略。`paymentType` が `cash` / `bank` 以外のときは実装側で `custom` 等へ分岐すること）：

```lua
elseif fw == 'qbox' then
    local Player = exports.qbx_core:GetPlayer(src)
    if Player then
        Player.Functions.AddMoney(paymentType, amount, 'jp-meridian9 reward')
    end
```

---

## INSTRUCTION-003 補足：FW 検出行の `print`

完了判定（サーバーコンソールで FW 名を即確認）のため、フレームワーク検出直後の **`print` は `Config.Debug` 非依存**で残す。将来、開発フェーズが落ち着いたら `MRD9.Log` へ統一する可能性あり。**実装ファイルでは該当 `print` 直上にコメントで意図を明記**する。

---

## INSTRUCTION-004：画像アセット

- **ロゴが 1 枚しかない場合**：`logo_light.png` / `logo_dark.png` に **同一ファイルを複製してよい**。背景色によるバージョン分けは後工程で対応する。
- **拡張子のみ変更（JPEG → `.png`）の暫定対応**：本番で NUI 表示に問題が出た場合、画像編集ツールで **真の PNG 形式**に再エクスポートすること。**透過が必要な場合は必須**。

---

## INSTRUCTION-019 チェックリスト（事前メモ）

README 完成・運営者向けドキュメント整備（INSTRUCTION-019）の段階で、少なくとも以下を確認する。

- [ ] NUI 用ロゴ・アイコンを **真の PNG** に再エクスポート済み（暫定 JPEG 流用を解消）
- [ ] Linux 本番での大文字小文字・`fxmanifest` `files` 列挙の再確認

---

## INSTRUCTION-006：DB スキーマ（実装済み・正本追記）

| 項目 | 確定・実装 |
|------|------------|
| DB ライブラリ | **oxmysql** 必須。`fxmanifest.lua` に `dependencies { 'oxmysql' }` と `@oxmysql/lib/MySQL.lua`（`server_scripts` 先頭） |
| 接続確認 | `server/main.lua` で起動後 `Wait(2000)` のあと `SELECT 1` および `INFORMATION_SCHEMA` で `mrd9_contracts` 存在確認（`MySQL.ready` は未使用） |
| スキーマ自動適用 | `mrd9_contracts` 不在時、`LoadResourceFile(... , 'sql/install.sql')` で SQL を読み、`--` 行コメントを除いた上で `;` 区切りに分割し、各文を `MySQL.query.await` で順次実行。**`sql/install.sql` を単一情報源**として保ち、Lua 側にスキーマを二重定義しない方針。実行後に再度存在チェックして結果を `print`。失敗時は手動適用にフォールバック（処理は継続）。**注意**: 将来 `COMMENT='--'` のような `--` を含む文字列リテラルを追加するなら、正規 SQL トークナイザーへ差し替える。 |
| スキーマ | `mrd9_contracts` / `mrd9_stats`（FK）/ `mrd9_mission_logs`。手動で `sql/install.sql` を適用 |
| 読み込み順 | `contract.lua` / `stats.lua` を **`main.lua` より先**に読み込み（`RegisterCommand` から `MRD9.Contract` を参照するため） |
| デバッグ | `Config.Debug` 時のみ `/m9_sign_me` `/m9_check_contract` `/m9_my_stats` |

契約判定は `mrd9_contracts.identifier`（`license:xxx`）を正とする。

## INSTRUCTION-007：セッション管理（実装済み・正本追記）

| 決定 | 内容 |
|------|------|
| D1 Multiverse | **(a) 機能のみ移植**（`server/session.lua` 独自実装。Multiverse 本体は非同梱）。クレジットは `docs/CREDITS.md`。 |
| D2 バケット | **(b) プール管理**（`bucketStart`〜`bucketEnd` をキュー化し、終了時に `ReleaseBucket`）。旧 `bucketMax` は `missionBucketEnd()` でフォールバック。 |
| D3 永続化 | **(a) メモリのみ**。`onResourceStop` で全セッション `Destroy(..., 'server_shutdown')`（キー配列にコピーしてからループ）。 |
| `SetPlayerRoutingBucket` | **整数 `playerSrc`**（公式 Cookbook 準拠）。旧指示書の `tostring(src)` は誤記。詳細は本ファイル「`SetPlayerRoutingBucket` の引数型」節。 |
| `MRD9.Session.GetAll` | **内部 `sessions` テーブル参照をそのまま返す**（デバッグ用途。改変は自己責任）。 |
| 離脱通知 | `RemovePlayer` では離脱プレイヤーへ必ず `jp-meridian9:onMissionEnd` を送る（最後の 1 人でも `Destroy` が空ループにならないよう）。 |

## リポジトリ `.gitignore` と `jp-meridian9/docs/`

ルート `.gitignore` は `docs/` を一律除外している。`jp-meridian9` の設計正本・マイルストーン等は **`jp-meridian9/docs/`** に置くため、**`!jp-meridian9/docs/` / `!jp-meridian9/docs/**` 例外**をルート `.gitignore` に追加し、Git 追跡対象とする（`jp-tcgbook` / `jp-cooktree` と同型）。

## `SetPlayerRoutingBucket` の引数型（公式準拠）

FiveM 公式（ルーティングバケット Cookbook）では **`SetPlayerRoutingBucket(playerSrc, bucketId)` とし、`playerSrc` はサーバー側プレイヤー ID（整数）** を渡す。過去指示書にあった `tostring(src)` は誤記扱いとし、実装は **整数のまま** とする。

## INSTRUCTION-008：契約キャッシュと運営コマンド（実装済み・正本追記）

| ID | 決定 |
|----|------|
| D4 | **サーバー側キャッシュ** `contractCache`。`playerJoining`（遅延 `LoadCache`）、`playerDropped`（`UnloadCache`）、リソース起動後に既接続プレイヤーへ一括 `LoadCache`。`Sign` / `Suspend` / `Terminate` / `IsContracted` の DB フォールバックで整合。 |
| D5 | ACE 名 **`jp-meridian9.admin`**（`Config.Admin.aceName` で変更可）。 |
| D6 | 運営コマンド `/m9_admin_sign` `/m9_admin_suspend` `/m9_admin_terminate` `/m9_admin_check` `/m9_admin_list`（`RegisterCommand(..., true)` と `HasAdminAce` の二重ガード）。 |

| 実装メモ |
|----------|
| `IsContracted` はキャッシュ優先、未ロード時は DB 読み取り後にキャッシュへ書き戻し。 |
| `MRD9.Contract.Get` は運営確認用のため **DB 直読みのまま**（キャッシュとズレないよう運用側で `Sign` 等の後に必要なら再 `LoadCache`）。 |

## INSTRUCTION-009：ヴェガ NPC・対話（実装済み・正本追記）

| ID | 決定 |
|----|------|
| D7 | **ox_lib** の `lib.registerContext` / `lib.showContext` と `lib.notify` で対話。NUI は INSTRUCTION-014/015 で本格化。 |
| D8 | **ox_target** の `addLocalEntity` で「ヴェガと話す」。 |
| D9 | NPC 座標は **暫定** `vector4(427.5, -979.3, 30.7, 90.0)`（Mission Row 警察署付近）。路地裏オフィス MLO は別フェーズで `config.lua` 差し替え。 |

| 依存 | 内容 |
|------|------|
| **ox_lib** | `shared_scripts` 先頭に `@ox_lib/init.lua`。`dependencies` に明記。フレームワーク（ESX/QB）ではなく **UI/コールバック基盤**として採用。 |
| **ox_target** | NPC インタラクション。`dependencies` に明記。 |

| 実装メモ |
|----------|
| NPC 対話時の `IsContracted` は **キャッシュ＋DB フォールバック**の既存実装のまま。NPC 側から明示 `LoadCache` は不要（INSTRUCTION-008 方針）。 |
| `client/npc.lua` でスポーン・`onResourceStop` で `removeLocalEntity`＋`DeleteEntity`・ブリップ削除。 |
| `client/dialogue.lua` で初回／リピート分岐・署名コールバック・チュートリアル。ゲートは「ソロ／パーティ」分岐（`openGateSubmenu`）。パーティ UI は `client/party.lua` の `jp-meridian9:client:openPartyMenu`。 |

## INSTRUCTION-010：パーティ編成（実装済み・正本追記）

| 項目 | 内容 |
|------|------|
| 永続化 | **メモリのみ**。`server/party.lua` の `parties` / `playerToParty` / `globalPendingInvite`。リソース再起動で消滅。 |
| メンバー規約 | `members[1]` = リーダー。離脱・譲渡後も先頭をリーダーに同期。 |
| 招待 | 距離 `Config.Party.inviteRange`、タイムアウトは `CreateThread` + `Wait`（トークンで無効化）。同一被招待者へのグローバル排他 `globalPendingInvite`。 |
| 確定 | `MRD9.Session.Create({ leader, members })` → 成功後のみ `party.sessionId` 代入 → `Session.TransferIn`。失敗時は `forming` にロールバック。未処理招待がある間は `Confirm` 拒否（`err_pending_invites`）。 |
| 切断 | `server/session.lua` の `playerDropped` **先頭**で `MRD9.Party.HandleDisconnect`（`dispatched` は no-op）。 |
| セッション終了 | `Session.Destroy` 末尾で `MRD9.Party.NotifySessionDestroyed` により `dispatched` パーティを掃除。 |
| クライアント | `lib.registerContext` メイン UI、招待受信のみ `lib.alertDialog`。 |
| 逸脱 | 指示書の `server/main.lua` の `playerDropped` 追記ではなく **`session.lua` に統合**（切断処理の順序を一本化）。 |

## INSTRUCTION-011：ゾンビアリーナ（実装済み・正本追記）

| 項目 | 内容 |
|------|------|
| 移植スコープ | **(a) AI コア相当 + スポーン制御のみ**（`server/arena/spawn.lua` は TP-Advanced-Zombies 派生・Apache 2.0）。ウェーブ定義は `server/arena/wave.lua` + `Config.Arena.waves`（MERIDIAN-9 独自）。 |
| サーバー | `server/arena/arena.lua` が状態管理。`TransferIn` 完了後に `MRD9.Arena.Start`、`Session.Destroy` 冒頭で `MRD9.Arena.Cleanup`（ゾンビ掃除イベント後にバケット 0 送還）。 |
| クライアント | リーダーのみ `jp-meridian9:client:spawnZombie` で生成→`jp-meridian9:server:zombieSpawned` で登録。撃破は `jp-meridian9:server:zombieKilled`。全滅は `jp-meridian9:server:playerDowned` 集約後 `Session.Destroy(..., 'arena_wiped')`。 |
| 失敗演出順 | **`jp-meridian9:client:arenaMissionFailed`**（`lib.notify`）→ **`Session.Destroy`** → **`jp-meridian9:onMissionEnd`**（`reason == 'arena_wiped'`）で `SetEntityHealth` + `SetPedToRagdoll`（送還直後の ped）。 |
| 設定 | `Config.Arena`（`enabled` / `ragdollDurationMs` / `knockdownHealth` / ウェーブ等）。`Config.Zombies` は従来プレースホルダのまま残置。 |

### INSTRUCTION-011 残課題メモ（蘇生・脱出 UI 連携）

- `knockdownHealth = 1` + `SetPedToRagdoll` は「ダウン演出 + 救急動線」の最小構成。
- INSTRUCTION-014（任務中 HUD）または INSTRUCTION-016（蘇生システム）実装時に以下を再確認すること:
  - HP 1 状態で救急隊呼び出しトリガーが発火するか
  - ragdoll 中の他プレイヤーからの蘇生操作が可能か
  - `returnAlive = true` 時の挙動との一貫性

## INSTRUCTION-012：ルート取得（実装済み・正本追記）
| 項目 | 内容 |
|------|------|
| 権威 | 取得は **`lib.callback` `jp-meridian9:loot:pickup`**。`source` 退避・距離・セッション・クールダウン・`lootId` 検証。加算は **`session.inventory[src][itemId]`** のみ。 |
| 配置 | `Config.LootSpawns` が **空でない** かつ `[1].coords` がある場合はそこからランダム座標。それ以外は **`spawnPoint` 中心 `spawnAreaRadius` 内**＋`minDistanceBetween`。 |
| レアリティ | 各スロットで `Config.LootSpawns` 要素の `weight` があれば使用、なければ **`Config.LootRarityWeight`**。アイテムは `Config.Items` から該当 `rarity` をプール抽選。 |
| プロップ | リーダーのみ **`jp-meridian9:client:lootSpawnBatch`** で `CreateObject` → **`jp-meridian9:server:lootSpawnAck`** → 全員 **`client:lootRegister`** で **`exports.ox_target:addEntity(netId, …)`**。 |
| 掃除 | `Session.Destroy` 冒頭で **`MRD9.Loot.Cleanup`**（`client:lootClearAll` のあと `session.loot = nil`）。`TransferIn` 末尾は **`Arena.Start` の次に `Loot.Spawn`**。 |
| 表示 | 取得成功は **`lib.notify`**（HUD 連携は INSTRUCTION-014）。 |
| 無効化 | `Config.Loot.enabled = false` でスポーン抑止。 |

## INSTRUCTION-013：脱出（実装済み・正本追記）

| 項目 | 内容 |
|------|------|
| 個別離脱 | パーティ全員揃わなくても **個別に脱出可**（死亡＝全ロストとの二重リスク回避） |
| 進行 | **`lib.progressCircle`**（5 秒既定）。`disable.move/car/combat/sprint`、`canCancel = true`。アニメ `random@arrests / idle_2_hands_up` |
| キャンセル | **被ダメージ（`HasEntityBeenDamagedByAnyPed`）**・エリア外・気絶。判定スレッドは `Wait(150)` |
| サーバー権威 | **`lib.callback.register('jp-meridian9:extract:request')`**。`source` 退避・state=IN_MISSION・メンバー判定・`pointIdx` ホワイトリスト・距離検証・クールダウン |
| スナップショット | 成功時 `session.extractedInventory[identifier] = { items, src, extractedAt, sessionId }`。**メモリ保持**（DB は `mrd9_mission_logs` のみ） |
| ログ | 成功時 `mrd9_mission_logs.outcome = 'extracted'` ＋ `items_recovered_json`。`Stats.Update` は `extracted=true, extractSeconds=elapsed` |
| Destroy 連携 | `Session.Destroy` 冒頭で **`MRD9.Extract.OnSessionDestroy`** → 未脱出メンバーに `outcome` を割り当てログ（`timeout`/`died`/`aborted`） |
| ブリップ | 任務中のみ表示（`Config.Extract.showBlipsDuringMission`）。`onMissionStart`/`onMissionEnd` で生成・破棄 |
| 配置 | `Config.ExtractPoints` を **3 箇所暫定**（`spawnPoint` 周辺）。差し替えは config 末尾 |

## INSTRUCTION-014：任務中 HUD / NUI（実装済み・正本追記）

| 項目 | 内容 |
|------|------|
| Q1 パーティ HP | **サーバー集約**。`server/hud.lua` が `Config.HUD.tickServerMs`（未指定時は `updateInterval`）周期で `state == 'IN_MISSION'` のセッションのみ処理し、メンバー各員へ `jp-meridian9:client:hud:state` で DTO 配信。HP/Armor はサーバー側 `GetPlayerPed` + `GetEntityHealth` 等。 |
| Q2 インベントリ | **`total` + `byRarity`（common/uncommon/rare/legendary）**。`Config.Items[].rarity` で集計。 |
| Q3 自分 HP | **パーティ一覧先頭が自分**（`isSelf`）。専用自機パネルは置かない。 |
| Q4 ウェーブ | **画面上部中央バナー**。`MRD9.Arena.GetHudSnapshot(sessionId)` の `wave` / `totalWaves` / `zombiesAlive` / `active` を DTO に同梱。`Config.HUD.showWaveBanner = false` で非表示。 |
| Q5 脱出 | **`lib.showTextUI` のみ**（013 踏襲）。HUD に脱出バッジは出さない。 |
| Q6 周期 | 既定の **`tickServerMs=500` / `tickClientMs=250`**。 |
| クライアント | `client/hud.lua` が `MRD9.HUD.OnMissionStart` / `OnMissionEnd`、`RegisterNetEvent('jp-meridian9:client:hud:state')`、ローカルタイマー補間と自機行の上書き、`SendNUIMessage`（`m9_hud_show` / `m9_hud_hide` / `m9_hud_locale` / `m9_hud_state` / `m9_hud_event`）。`onResourceStop` で hide + `SetNuiFocus(false,false)` 保険。 |
| アリーナ連携 | `client/arena.lua` が `MRD9.HUD.PushEvent` でウェーブ系トースト（`lib.notify` と併用）。 |
| NUI | `html/index.html` / `style.css` / `app.js`。`#m9-toasts` は `#app` 外に配置し、任務終了後も短時間トーストを表示可能。 |
| fxmanifest | **`server/hud.lua` は `server/arena/arena.lua` の直後**（`GetHudSnapshot` 依存）。**`client/hud.lua` は `client/main.lua` より前**。 |

## INSTRUCTION-020：サイト・ナイン MAP 導入（北ヤンクトン版 v2・実装済み・正本追記）

| 項目 | 内容 |
|------|------|
| 採用 MAP | **GTA V バニラ同梱の North Yankton**（Prologue「Ludendorff」ステージ）。LS 南西海上の独立 region、座標基準 `(3217.697, -4834.826, 111.815)` |
| IPL ローダー | **[Bob74/bob74_ipl](https://github.com/Bob74/bob74_ipl)**（MIT）。`fxmanifest.lua` の `dependencies` に追加し、`server.cfg` で `ensure bob74_ipl` を `jp-meridian9` の前に置く |
| 同梱方針 | **本リポには同梱しない**。運営者が GitHub から `git clone https://github.com/Bob74/bob74_ipl.git` で取得 |
| 分離方式 | **クライアントローカル IPL × routing bucket** の組み合わせ。`NorthYankton.Enable(true)` はクライアントローカルネイティブのため、任務 bucket 内のメンバーだけが個別に Enable することで「**bucket 内クライアントだけ別空間が見える**」が成立。bucket 0 のプレイヤーには **海面のまま**（既存 LS の見た目を一切壊さない） |
| 実装 | `client/transition.lua` に `applyNorthYankton` / `clearNorthYankton`。`Transition.Enter` で IPL ロード→`Config.SiteNine.iplLoadWaitMs`（既定 2000ms）待機→既存演出（雪・寒色・街灯消灯・時間固定）。`Transition.Leave` で逆順解除＋IPL 無効化 |
| サーバー側テレポート | `Session.TransferIn` で **クライアントへ `onMissionStart` 送信→`Config.Mission.siteNineLoadWaitMs`（既定 2000ms）待機→`SetEntityCoords`** の 2 段。IPL ロード完了前のテレポートで地形貫通する事故を防止 |
| 起動チェック | `server/main.lua` で起動後 `Wait(3000)` のあと `GetResourceState('bob74_ipl')` を確認。未起動なら `[WARN] bob74_ipl 未起動` を出して通常起動継続（演出のみ動作） |
| 座標 | `Config.Mission.spawnPoint = vector4(3217.697, -4834.826, 113.0, 90.0)`（Ludendorff 中心、東向き）。`Config.ExtractPoints` を **教会前広場 / 駅プラットフォーム / 墓地裏門** の 3 箇所、`Config.LootSpawns` を 15 箇所程度（**墓地と銀行はレア寄り**） |
| RP 整合 | 「**サイト・ナイン＝北ヤンクトンの隔離区域**」「APERTURE-J ゲートは座標を北ヤンクトン中心へワープ」「LS と北ヤンクトンは海と次元の歪みで隔たれている」と再定義。`ストーリー.txt` のヴェガ事務所・APERTURE・インシデント・ゼロ・Subject-0 と整合 |
| Cayo Perico との関係 | バニラ仕様で North Yankton と Cayo Perico は **同座標重複配置**。`Enable(true)` を呼んだクライアントは Cayo Perico が消えて North Yankton が見える。jp-meridian9 では Cayo は使わないので問題なし |
| 撤回案 | **The Apocalypse Project** 採用案（INSTRUCTION-020 v1）は撤回。LS 内 ymap 直配置で bucket 単位分離ができず、「車・ヘリで地続きで行ける」問題が解消できなかったため。詳細は `docs/INSTRUCTION-020（サイト・ナイン MAP 導入）.md` §15 |
| 既知の罠 | バニラ North Yankton は穴・broken model あり（Prologue 専用未完成エリア）。`ExtractPoints` / `LootSpawns` で穴を避ける運用 |
