# INSTRUCTION-021 設計書：オープンワールド・サバイバル（Cayo Perico）

> マスター実機検証（INSTRUCTION-020 v3 採用後）の結果、アリーナ単体（3 ウェーブ完了 → 帰還）よりも「アリーナ序盤 + 自由探索 + 持続的脅威」のハイブリッド型がエクストラクション体験として優れていると判断。本書は INSTRUCTION-011（ゾンビアリーナ）の上に重ねる **自由探索フェーズ + 持続的ゾンビスポーン**機構を定義する。

---

## 0. 前提

- 採用 MAP: Cayo Perico（INSTRUCTION-020 v3 確定）
- 既存 INSTRUCTION-011（アリーナ・3 ウェーブ）は**無改変で残す**。Survival は **3 ウェーブクリア後**または **`Config.Arena.enabled=false` 時**に並列開始する独立機構
- 既存 INSTRUCTION-013（脱出）と独立。脱出は引き続き個別離脱（5 ヶ所のいずれかから）
- 採用ネイティブ: 既存 `MRD9.Arena.Spawn.RequestZombie` を流用（クライアント委譲スポーン）

---

## 1. ゲームデザイン

### 1-A. 任務フロー（v3 + 021 適用後）

```
ヴェガ依頼
  ↓
ゲート転送（Cayo Perico 住宅街 5 ヶ所からランダム選出）
  ↓
[Arena 有効時] 3 ウェーブ（INSTRUCTION-011 既存）
  ↓ クリア
[Survival 開始] ← 新規（本書）
  ↓
自由探索フェーズ（ルート回収・脱出ポイント選択）
  ・各メンバー周辺 30〜150m に 3 分ごとに 3 体スポーン
  ・サバイバル感を維持しながら、ルートと脱出ルート選択の自由度
  ↓
個別脱出（5 ヶ所のいずれか）or タイムアウト
```

### 1-B. アリーナ ON/OFF

`Config.Arena.enabled = false` の場合は **3 ウェーブをスキップして即 Survival 開始**。短時間プレイ・テスト・別ミッションタイプ展開に対応。

### 1-C. 「サバイバル感」の根拠

- **持続的脅威**：「敵を倒し切った」「もう安全」と思わせない。ルート回収中に背後からゾンビが湧く緊張感
- **拠点性の希薄化**：「ここに立てこもれば安全」を防ぐ。各メンバー周辺に湧くので、籠もるよりも移動推奨
- **脱出判断の重み**：早く脱出すれば持ち物が確定、長居して高レアを狙うほどリスク蓄積

---

## 2. スコープ

### 含む
- `Config.Survival` 設定
- `server/survival.lua` 新設（PeriodicSpawn ループ）
- Arena → Survival 接続フック（`_onWaveCleared` の `cleared` 分岐）
- TransferIn での Arena.enabled=false 時の Survival 直接開始
- Session.Destroy での Survival 停止
- `MRD9.Arena.Spawn.PickCoordsNearPlayer` に半径オーバーライド引数追加

### 含まない
- 新しいゾンビ AI（既存の `client/arena.lua` の `spawnZombie` を流用）
- ボス・特殊個体（将来 INSTRUCTION-022 で扱う）
- ロアロケーション固有のスポーン（El Rubio 邸宅地下の Subject-0 等）→ 別 INSTRUCTION

---

## 3. 確定事項

- **アリーナ並列ではなく逐次**: 3 ウェーブクリア後に Survival 開始。アリーナ中は Survival 起動しない
- **`MRD9.Survival.Start(sessionId)`** を **`_onWaveCleared` の cleared 分岐**と **`TransferIn` の Arena.enabled=false 分岐**から呼ぶ
- **`MRD9.Survival.Stop(sessionId)`** を **`Session.Destroy`** から呼ぶ
- 既存 `MRD9.Arena.Spawn.RequestZombie` の API は無変更（リーダー宛配信、波管理連携）
- **Survival は `RequestZombie` を直接呼ばず、独自に `spawnAroundPlayer` を実装**（各メンバー宛配信、半径オーバーライド、波管理に登録しない）
- **波管理（`arenaStates[sessionId]`）には登録しない**：Survival ゾンビはアリーナの kill count に貢献しない（純粋な脅威）

---

## 4. データモデル

### 4-A. `Config.Survival`

```lua
Config.Survival = {
    enabled = true,
    intervalMs = 180 * 1000,            -- 3 分ごと
    countPerPlayer = 3,                 -- 1 サイクルで各メンバー周辺に出現する体数
    radiusMin = 30.0,                   -- スポーン半径下限（m）
    radiusMax = 150.0,                  -- スポーン半径上限（m）
    zombieHealth = 100,                 -- 1 体あたり HP
    zombieModels = { 'u_m_y_zombie_01' },
}
```

### 4-B. `survivalStates[sessionId]`

```lua
{
    running = true,
    startedAt = GetGameTimer(),
    cycleCount = 0,                     -- スポーン周期回数（デバッグ・統計用）
}
```

### 4-C. クライアント側挙動

既存の `RegisterNetEvent('jp-meridian9:client:spawnZombie', ...)` で受信。`data.source = 'survival'` で区別可能（クライアント側は無視可、将来の演出差別化に余地）。

---

## 5. アルゴリズム

### 5-A. PeriodicSpawn ループ

```lua
CreateThread(function()
    while running do
        Wait(intervalMs)
        if not session or session.state ~= 'IN_MISSION' then break end
        if countAliveMembers(session) <= 0 then
            -- 全員ダウン中はスポーン抑制
            goto continue
        end
        for _, src in ipairs(session.members) do
            if alive(src) then
                spawnAroundPlayer(sessionId, src, countPerPlayer, radiusMin, radiusMax, ...)
            end
        end
        cycleCount += 1
        ::continue::
    end
end)
```

### 5-B. 同時並列セッション数

- セッション独立: 各 `sessionId` に独立した `CreateThread` が走る
- 20 セッション並列でも 20 スレッド（FiveM Lua スケジューラは数百スレッドを問題なく扱う）
- スポーン処理は 3 分に 1 回、各セッション 5 人 ×3 体 = 15 個 `TriggerClientEvent` のみ
- サーバー負荷: ほぼ無視できる

### 5-C. 半径制御

- `radiusMin = 30.0`：「視界に入って湧く」を防ぐ最小距離
- `radiusMax = 150.0`：プレイヤーから一定範囲内、ストリーミング距離内
- 半径は `Config.Arena.spawnRadiusMin/Max` とは独立（オーバーライド引数で渡す）

---

## 6. ファイル変更

| ファイル | 変更 |
|---------|------|
| `jp-meridian9/config.lua` | `Config.Survival` 設定追加、`Config.Mission.spawnPoints` 配列化（5 ヶ所） |
| `jp-meridian9/server/survival.lua` | **新規**：`MRD9.Survival.Start/Stop/IsActive` 実装 |
| `jp-meridian9/server/arena/spawn.lua` | `PickCoordsNearPlayer` に `minROverride` / `maxROverride` 引数追加（後方互換） |
| `jp-meridian9/server/arena/arena.lua` | `_onWaveCleared` の cleared 分岐で `MRD9.Survival.Start(sessionId)` を呼ぶ |
| `jp-meridian9/server/session.lua` | `TransferIn` で spawnPoints からランダム選出。Arena.enabled=false 時に Survival.Start 直接呼出。Destroy で Survival.Stop |
| `jp-meridian9/fxmanifest.lua` | `server_scripts` に `'server/survival.lua'` を `server/arena/arena.lua` の直後に追加 |

---

## 7. 既存実装との関係

| 既存 | 関係 |
|------|------|
| INSTRUCTION-011 アリーナ | 無変更。3 ウェーブクリアで Survival にバトンタッチ |
| INSTRUCTION-013 脱出 | 無変更。Survival 中も 5 ヶ所の `ExtractPoints` から個別離脱 |
| INSTRUCTION-014 HUD | 無変更。`MRD9.Arena.GetHudSnapshot` は cleared 後 `active=false` を返すため、ウェーブバナーは消える |
| INSTRUCTION-012 ルート | 無変更。`Config.LootSpawns` 15 ヶ所が島内に配置済み |

---

## 8. テスト観点

- [ ] `restart jp-meridian9` で `survival.lua` が起動エラーなく読み込まれる
- [ ] `Config.Arena.enabled = true` で開始 → 3 ウェーブクリア → 通知「自由探索フェーズ開始」→ 3 分後にゾンビ出現
- [ ] `Config.Arena.enabled = false` で開始 → 即「自由探索フェーズ開始」→ 3 分後にゾンビ出現
- [ ] スポーン位置がプレイヤー周辺 30〜150m にあり、視界外で湧くこと
- [ ] 全員ダウン中はスポーンしない（`countAliveMembers <= 0`）
- [ ] 脱出 → 個別離脱で Survival スレッドは継続（他メンバーには湧き続ける）
- [ ] 最後の 1 人脱出 → `Session.Destroy` → `MRD9.Survival.Stop` → スレッド終了
- [ ] タイムアウト（20 分）→ `Session.Destroy` → 同上
- [ ] `restart jp-meridian9` でゾンビが残らない（既存の `Arena.Cleanup` がエンティティ削除）

---

## 9. パフォーマンス目標

- サーバー定常：< 0.1 ms（3 分に 1 度の `TriggerClientEvent` ループのみ）
- クライアント定常：既存と同等（スポーンするゾンビ数の合計が増えるだけ、AI は `client/arena.lua` の既存実装）
- 20 セッション並列：問題なし（独立スレッド）

---

## 10. リスク・既知の罠

| リスク | 対策 |
|---|---|
| プレイヤーが島外（海上飛行など）に居る時のスポーン | `PickCoordsNearPlayer` がプレイヤー周辺座標を返すため、海上にゾンビが湧く可能性。許容（プレイヤーが意図的に島外に出た場合の自業自得） |
| スポーンサイクル中の `Session.Destroy` 競合 | `Wait(intervalMs)` 後の `MRD9.Session.Get` チェックで早期 return。Destroy 側で `running = false` セット |
| クライアントが OneSync 同期遅延でゾンビを認識しない | 既存の `client/arena.lua` の zombie monitor で対応済み（INSTRUCTION-011 範囲） |
| `intervalMs` を極端に短くするとゾンビ氾濫 | 運営者責任。`Config.Arena.maxConcurrentZombies` がアリーナ側、Survival 側は無制限なので別途上限を持たせるか検討（将来課題） |

---

## 11. 着手順序

1. ✅ マスター承認（座標とゲームデザイン）
2. `Config.Mission.spawnPoints` 配列化（5 ヶ所）
3. `Config.ExtractPoints` を 5 ヶ所新名称で書き換え
4. `Config.Survival` 設定追加
5. `server/survival.lua` 新規実装
6. `server/arena/spawn.lua` に半径オーバーライド引数
7. `server/arena/arena.lua` の `_onWaveCleared` で `Survival.Start` フック
8. `server/session.lua` の `TransferIn` で spawnPoints ランダム選出 + Arena.enabled=false 時 Survival 直接開始、`Destroy` で `Survival.Stop`
9. `fxmanifest.lua` に `'server/survival.lua'` 追加
10. 実機テスト
11. ドキュメント整備（FORMAL_POLICIES / milestones / design）
12. 開発日記 + コミット + push

---

## 12. 完了条件

1. 3 ウェーブクリア後に Survival が自動開始する
2. `Config.Arena.enabled = false` で Survival が直接開始する
3. 3 分ごとに各メンバー周辺 30〜150m にゾンビが 3 体スポーン
4. 脱出・タイムアウト・全滅で Survival が停止する
5. `restart jp-meridian9` でゾンビが残らない
6. ドキュメント更新済み

---

## 13. 死亡・タイムアウト・クラッシュの初期化処理（マスター質問対応）

### 13-A. 個別死亡（任務中）

- `client/arena.lua` の死亡監視ループが `IsPedDeadOrDying(ped, true)` を検出
- `TriggerServerEvent('jp-meridian9:server:playerDowned')` を 1 回だけ送信
- サーバー `MRD9.Arena.OnPlayerDowned(sessionId, src)` で **`Session.RemovePlayer(src, 'died')`** を呼ぶ
- `RemovePlayer` 内で:
  - `setPlayerBucket(src, 0)`（任務 bucket から退出）
  - `session.inventory[src] = {}`（インベントリ全ロスト）
  - `session.members` から除外
  - `TriggerClientEvent('jp-meridian9:onMissionEnd', src, { reason='died', returnPoint })`
- クライアント `onMissionEnd` ハンドラで:
  - `MRD9.HUD.OnMissionEnd` で HUD 非表示
  - `MRD9.Transition.TeleportToLosSantos(rp)` でフェード＋安全帰還
  - 帰還後 `SetEntityHealth(ped, 1)` + `SetPedToRagdoll` で気絶演出
- 残メンバー 0 なら `Session.Destroy(sessionId, 'all_lost')` 自動発火

### 13-B. アリーナ全滅（同時に全員ダウン）

INSTRUCTION-021 適用後は **個別死亡で即除外**するため、`arena_wiped` のフローはほぼ理論上のケースのみ。`Session.RemovePlayer` で `#members == 0` 検知 → `Destroy(sessionId, 'all_lost')` で代替成立。

### 13-C. タイムアウト（制限時間切れ）

- `server/session.lua` の cleanup ループ（`Wait(cleanupIntervalSeconds * 1000)`）
- `s.state == 'IN_MISSION' and now >= s.endsAt` を検出
- `Session.Destroy(sessionId, 'timeout')`
- 各メンバーに `onMissionEnd { reason='timeout', returnPoint }` → クライアント側で `TeleportToLosSantos`
- `mrd9_mission_logs.outcome = 'timeout'` 記録（`Extract.OnSessionDestroy` 経由）

### 13-D. クライアントクラッシュ・切断

- `AddEventHandler('playerDropped', ...)` で `Session.RemovePlayer(src, 'disconnect')`
- bucket 0 復帰・インベントリ消去（既ログイン時無効、再ログイン時に bucket 0 で LS スポーン）
- 残メンバー 0 なら `Session.Destroy(sessionId, 'all_lost')`

### 13-E. リソース restart（サーバー側）

- `server/session.lua` の `onResourceStop` で全 `sessions` を `Destroy(..., 'server_shutdown')`
- 各メンバーに `onMissionEnd` 送信 → クライアントが `TeleportToLosSantos` で帰還
- `MRD9.Arena.Cleanup` でゾンビエンティティ削除、`MRD9.Survival.Stop` で Survival スレッド停止

### 13-F. リソース restart（クライアント側 / Cayo Perico 残留対策）

- `client/transition.lua` の `onResourceStop` で:
  - `State.active`（任務中）なら **`returnPoint` へ瞬間テレポート**（フェードなしの強制）
  - `Transition.Leave()` で `SetIslandEnabled(false)` + 演出解除
- これでクライアントの restart 直後、海面に取り残されずヴェガ事務所前で立っている

### 13-G. テスト観点

- [ ] 任務中に個別死亡 → 自分だけ帰還＋ロスト、他メンバー継続
- [ ] 任務中に全員順次死亡 → 最後の死亡で `all_lost` → 自動 Destroy
- [ ] タイムアウト → 全員帰還、`mrd9_mission_logs.outcome='timeout'`
- [ ] クライアントクラッシュ → 残メンバーに継続通知、`outcome='aborted'` または `died`
- [ ] `restart jp-meridian9`（サーバー側）→ 全員ヴェガ事務所へフェード帰還
- [ ] `restart jp-meridian9`（クライアント側、`/restart` 等）→ 自分だけ瞬時帰還（フェードなしだが安全）

---

## 14. 将来拡張余地（本書範囲外）

- **Survival ボス**: 一定周期で特殊個体（HP 高・ダメージ大）をスポーン
- **環境イベント**: ヘリ追撃・嵐の到来・霧の発生など、定期的な脅威イベント
- **ロアロケーション**: El Rubio 邸宅地下の Subject-0 室、コミュニケーションタワー、地下サブマリン基地などで特殊スポーン
- **難易度別 Config.Survival**: Easy/Normal/Hard で `intervalMs` / `countPerPlayer` / `zombieHealth` を切替
