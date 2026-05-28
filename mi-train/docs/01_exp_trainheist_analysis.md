# exp_trainheist ソース解析レポート

- 対象: `GTA-EXPLORE/exp_trainheist` v2.0.0 (`b61a68b`)
- ライセンス: GPL-3.0
- 依存: `sd_lib`（必須、`fxmanifest.lua` の `dependencies`）、`ox_lib`（通知用、コメント外せばオプション）、`oxmysql`（server）、`ox_target` / `qb-target`（インタラクション）、`skinchanger`（アニメ中のバッグ差替え）、`xsound`（任意、グラインダー音）
- 解析目的: MI 風「走行中ヘイスト」へ改造する上での**変更必須箇所**と**そのまま流用できる箇所**を切り分ける

---

## 1. 結論サマリー

**結論**: 本体は「**停止した編成貨物列車**」前提で作られており、列車生成部分は **そのままでは MI 風に使えない**。ただし「警備兵 AI」「コンテナ・金庫インタラクション」「グラインダーアニメ」「金塊獲得アニメ」「報酬納品フロー」は**ほぼ流用可能**。

書き換える層と維持する層の境界が綺麗に切れているので、列車生成部だけ MI 風（CreateMissionTrain + Track ID 0 + Cruise Speed）に差し替えれば短期間で MI 化できる。

| 階層 | ファイル | MI 改造での扱い |
|---|---|---|
| 列車生成 | `client/train.lua::BuildTrain / SpawnWagon` | **全面書き換え** |
| 警備兵 | `client/_main.lua::SpawnGuards` | 流用（アタッチロジック追加） |
| インタラクション | `client/hitboxes.lua` | 流用（hitbox を wagon に追随） |
| アニメ | `client/animations.lua` | 流用（ただし synchronised scene の座標は走行中追随が必要） |
| 報酬・サーバー権威 | `server/main.lua`, `server/functions.lua` | 流用 |
| 開始 NPC / Discord ログ | `client/_main.lua` 冒頭, `server/main.lua` | 流用 |
| ヘリ侵入 | **未実装** | **新規追加** |

---

## 2. アーキテクチャ全体像

### 2.1 ファイル構成

```
exp_trainheist/
├── fxmanifest.lua          -- ox_lib / sd_lib / oxmysql 依存。lua54 yes
├── config.lua              -- 全グローバル定数（LANGUAGE/TRAIN/GUARDS/LOOT/...）
├── client/
│   ├── _main.lua           -- StartTrainHeist フロー、警備兵スポーン、Reset
│   ├── train.lua           -- BuildTrain（列車編成）、SpawnWagon、SetupContainers、SetupLoot
│   ├── hitboxes.lua        -- 不可視 hitbox object 経由の ox_target インタラクション
│   ├── animations.lua      -- AnimateContainerOpening、AnimateGoldGrabbing（synchronised scene）
│   ├── functions.lua       -- ヘルパー（_RequestModel, AddEntityMenuItem, SpawnNPC, SetBlip 等）
│   └── editables.lua       -- ShowNotification / DoesPedHaveAnyBag（差し替え用）
├── server/
│   ├── main.lua            -- CanPlayerStartHeist, GiveGold, DeliverGold, SD.Callback 登録
│   └── functions.lua       -- GetPoliceCount, DiscordLog
└── locales/                -- 多言語 JSON（en/de/es/fr/it/nl/no/pt/ru/se）
```

### 2.2 起動時シーケンス（クライアント）

`client/_main.lua` 先頭で:

1. `SD.Locale.LoadLocale(LANGUAGE)` — sd_lib のロケール初期化
2. グローバル変数初期化: `Entities, Hitboxes, StartNPC, HeistBlip, HitboxRegister, HasGold = {}, {}, nil, nil, {}, false`
3. `CreateThread` で開始 NPC スポーン（`START_SCENE.ped.model`, デフォルトは `s_m_m_highsec_01` @ `-687.82, -2417.1, 12.9445`）
4. NPC に `WORLD_HUMAN_SMOKING` シナリオ + `ox_target` メニュー「Start Train Heist」を貼り付け

**重要**: グローバル変数を使っている（`60-fivem-lua.mdc` §1 違反）。改造時は `local State = { entities = {}, ... }` にまとめ直すのが望ましい。

---

## 3. ステートマシン（ヘイスト進行フロー）

```
[Idle: NPC が世界にいる]
     │ プレイヤーが NPC を ox_target
     ▼
[Server: CanPlayerStartHeist callback]
     │  - IsHeistActive チェック（クールダウン中なら拒否）
     │  - GetPoliceCount() >= POLICE_REQUIRED チェック
     │  - 通過したら IsHeistActive = true、ROBBERY_INTERVAL(2h) 後に自動 Reset
     ▼
[Client: 通知「現場へ向かえ」+ HeistBlip 設置 (TRAIN.position)]
     │
     ▼
[Client: プレイヤーが TRAIN.position から 400m 以内に近づくのを待機]
     │  while #(coords - TRAIN.position) > 400.0 do Wait(500) end
     ▼
[Client→Server: SendPoliceAlert イベント送信（警察通報）]
     │
     ▼
[Client: BuildTrain() — 列車スポーン]
     │  - Wagons[1] = "freight" 機関車
     │  - 残り TRAIN.length 両ぶん貨車スポーン（うちランダム 1 両が "freightcar"）
     │  - 各 "freightcar" に前後 2 個のコンテナ + 鍵 + hitbox 設置
     │  - 2 個のコンテナにランダムで金塊台座を仕込む
     ▼
[Client: SpawnGuards(train_data) — 警備兵を中心点周囲 30m に 15 体]
     │  - GUARDS 関係グループを敵対化（5 = Hate）
     │  - TaskGuardCurrentPosition で警戒待機
     ▼
[Player Interactions（任意順序）]
     │  ├─ 警備兵を倒す（戦闘）
     │  ├─ コンテナドアを CutDoor（要 grinder + bag）
     │  │   - グラインダーアニメ（synchronised scene, 約 10〜15 秒）
     │  │   - hitbox 削除、コンテナ開放
     │  └─ 金塊を GrabGold
     │      - 取得アニメ → サーバーが inventory に gold_ingot ×25 付与
     │      - StartNPC に「Deliver Gold」メニュー追加
     ▼
[Player: StartNPC へ戻って DeliverGold]
     │  - サーバー: gold 回収 → MONEY_TYPE で price × count 付与
     │
     ▼
[2 時間経過後: Server から ResetAndWipe を全クライアントへ broadcast]
        - Entities 全削除、HeistBlip 削除
```

---

## 4. 列車生成部の詳細解析（**走行中ヘイストへの最大の壁**）

### 4.1 現実装の構造（`client/train.lua::BuildTrain`）

```lua
Wagons[1] = SpawnWagon(GetHashKey("freight"), TRAIN.position, TRAIN.heading)
-- 以降、TRAIN.length 両ぶん貨車を「前方ベクトル × 車両長」でオフセット配置
```

そして `SpawnWagon()` は:

```lua
function SpawnWagon(model, position, heading)
    _RequestModel(model)
    local vehicle = CreateVehicle(model, position, heading, true, true)
    FreezeEntityPosition(vehicle, true)              -- ★ ここが致命的
    SetEntityRotation(vehicle, TRAIN.angle, 0.0, heading)
    RequestCollisionAtCoord(position)
    while not HasCollisionLoadedAroundEntity(vehicle) do Wait(1) end
    return vehicle
end
```

**致命的な所見**:

1. `CreateVehicle` を使っている（**`CreateMissionTrain` ではない**）。GTA V のレールシステムを使わない、**ただの停止車両として配置している**。
2. `FreezeEntityPosition(vehicle, true)` で完全に固定。動く余地ゼロ。
3. ロケール `heistblip_name = "Train stopped"` も**停車前提**であることを明示している。
4. 編成は単に「前方ベクトルにオフセットして並べた `freight` + `freightcar` + `freightcont1` 等の組み合わせ」。実車両としての結合（couplings）はない。

### 4.2 設定パラメータ

```lua
TRAIN = {
    position = vector3(-3.21, 3441.62, 49.58),   -- Paleto 北東の貨物ヤード付近
    heading = 59.28,
    length = 5,                                  -- 機関車含めず後続貨車の両数
    angle = 1.0                                  -- ピッチ角（線路の傾斜に合わせる）
}
TRAIN_PARTS = {"freightcar", "freightcont1", "freightcont2", "freightgrain", "tankercar"}
```

`length` が編成長、`angle` が線路の物理角度。これも走行中だと無意味（角度はレールに従属する）。

### 4.3 MI 改造での書き換え方針

走行中列車に差し替えるには `BuildTrain` を以下のように再設計する必要がある:

```lua
-- 擬似コード
function BuildMovingTrain()
    -- 1. 既存のランダム列車を一掃
    DeleteAllTrains()
    SetRandomTrains(false)
    SwitchTrainTrack(0, false)  -- Track 0 のデフォルトスポーン無効化

    -- 2. CreateMissionTrain で生成（variation で編成型を選ぶ）
    --    variation 24 = freight（"freight" + "freightcar" + ...）
    local train = CreateMissionTrain(24, spawnX, spawnY, spawnZ, true)
    SetTrainCruiseSpeed(train, 20.0)  -- m/s = 約 72km/h

    -- 3. ★ 重要: GetTrainCarriage で各車両ハンドルを取り出す
    --    （これが現実装に欠けている。BuildTrain は自前で並べた静止車両を Wagons に保持しているが、
    --     CreateMissionTrain は GTA V 側がレール上で並べてくれる）
    local wagons = {}
    for i = 0, length - 1 do
        wagons[i + 1] = GetTrainCarriage(train, i)
    end

    -- 4. コンテナ・鍵・hitbox は wagon に「追随」させる必要がある
    --    現実装は FreezeEntityPosition + 絶対座標。
    --    MI 化では AttachEntityToEntity で wagon に貼り付けるか、
    --    毎フレーム GetOffsetFromEntityInWorldCoords で位置更新する。
    return wagons
end
```

**ハマりどころ**:

- `GetTrainCarriage(train, 0)` は機関車。`1` から後続貨車。
- `freightcar`（金庫貨車）が編成に含まれていない variation だと、コンテナを置く貨車がない。variation 表（DurtyFree/gta-v-data-dumps）で `freightcar` を含むものを選ぶ必要がある。または **コンテナ生成側で「金庫役の wagon は固定で index 2 番目」のように明示**してしまうのが簡単。
- ネットワーク制御: `NetworkRequestControlOfEntity(train)` を定期的に呼ぶ（オーナー固定）。

---

## 5. 警備兵 AI（`client/_main.lua::SpawnGuards`）

### 5.1 現実装

```lua
AddRelationshipGroup('GUARDS')
SetPedRelationshipGroupHash(ped, GetHashKey('PLAYER'))  -- ★ プレイヤー自身を 'PLAYER' グループに
SetRelationshipBetweenGroups(0, GetHashKey("GUARDS"), GetHashKey("GUARDS"))  -- GUARDS 同士は Companion(0)
SetRelationshipBetweenGroups(5, GetHashKey("GUARDS"), GetHashKey("PLAYER"))   -- GUARDS → PLAYER = Hate(5)
SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("GUARDS"))

-- 列車中心点 train_data.center 周囲 30m に 15 体スポーン
for i = 1, GUARDS.amount do
    local position = GetRandomPositionInCircle(train_data.center, GUARDS.spawn_range)
    while not IsSpawnPointClear(position) do ... end
    local guard = CreatePed(0, GetHashKey(model), position, 0.0, true, true)
    SetEntityAsMissionEntity(guard)
    SetPedRelationshipGroupHash(guard, GetHashKey("GUARDS"))
    SetPedAccuracy(guard, GUARDS.accuracy)      -- デフォ 50
    SetPedArmour(guard, GUARDS.armour)          -- デフォ 50
    SetPedDropsWeaponsWhenDead(guard, false)
    SetPedFleeAttributes(guard, 0, false)
    GiveWeaponToPed(guard, ..., 255, false, true)
    TaskGuardCurrentPosition(guard, 10.0, 10.0, true)  -- ★ 静止警戒タスク
end
```

### 5.2 MI 化での問題と対応

- `TaskGuardCurrentPosition` は**地面に張り付くタスク**。走行中列車の屋上だと床から落ちる。
- 解決策: スポーン後すぐ `AttachEntityToEntity(guard, wagon, ...)` で wagon に貼り付け、`SetPedKeepTask(guard, true)` + `TaskCombatPed(guard, PlayerPedId(), 0, 16)` でアタッチ位置を維持しつつ戦闘させる。
- または「車内に立つ警備兵」は wagon に attach、「屋根の警備兵」は AttachEntityToEntity で屋根 offset に貼る。

### 5.3 流用可能箇所

- 関係グループ設定（GUARDS / PLAYER ハッシュ）はそのまま使える
- `Entities[#Entities+1] = guard` で一括クリーンアップ管理する設計も流用可
- `SetEntityAsMissionEntity` の呼び出し位置・順序も流用可

**指摘**: `SetPedRelationshipGroupHash(ped, GetHashKey('PLAYER'))` を**プレイヤー自身に対して**実行している（4 行目）。プレイヤーは既に `PLAYER_HASH` グループに属しているので冗長だが、害はない。

---

## 6. インタラクション系（`client/hitboxes.lua`）

### 6.1 仕組み

**不可視のオブジェクトを「当たり判定」として配置し、ox_target / qb-target のメニューを貼る**設計。

```lua
RegisterNetEvent("exp_trainheist:CreateHitbox", function (data)
    local hitbox = CreateObject(GetHashKey(data.model), data.position)
    FreezeEntityPosition(hitbox, true)
    SetEntityInvincible(hitbox, true)
    SetEntityVisible(hitbox, false)              -- ★ 見えないけど ox_target は反応する
    AddEntityMenuItem({...})
    Hitboxes[hitbox] = data.data                 -- container netId, lock netId
    HitboxRegister[hitbox] = data.id             -- ヒットボックス ID（CutDoor → RemoveHitbox の連動用）
end)
```

これは **全プレイヤーに broadcast** される（`server/main.lua::CreateHitbox` で `TriggerClientEvent(..., -1, data)`）。誰かが扉を切ると `RemoveHitbox` も全プレイヤーに broadcast されてその hitbox が消える。

### 6.2 走行中対応への必要な改造

`FreezeEntityPosition(hitbox, true)` だと、列車が動くと hitbox は空中に取り残される。**hitbox を wagon に attach する**か、**毎フレーム位置更新するスレッド**を回す必要がある。

```lua
-- 改造案: AttachEntityToEntity で追随
AttachEntityToEntity(hitbox, wagon, 0,
    offset.x, offset.y, offset.z,
    rotation.x, rotation.y, rotation.z,
    true, true, false, false, 2, true)
```

これで wagon の動きに自動追随する。

### 6.3 流用可能性

- `ox_target` / `qb-target` 両対応の抽象化（`AddEntityMenuItem`）はそのまま使える
- broadcast → 全プレイヤーで同じ hitbox を生成、という設計も維持可
- 削除イベント（`RemoveHitbox`）も流用可

---

## 7. アニメーション（`client/animations.lua`）

### 7.1 AnimateContainerOpening の構造

`anim@scripted@player@mission@tunf_train_ig1_container_p1@male@` の **synchronised scene** を再生。これは GTA 本編 The Diamond Casino Heist の「貨車コンテナをグラインダーで開ける」シーンのアニメで、`action`（プレイヤー）、`action_container`、`action_lock`、`action_angle_grinder`、`action_bag` の **5 つのエンティティを同期** している。

```lua
local scene = NetworkCreateSynchronisedScene(animPos, GetEntityRotation(container), 2, true, false, 1.0, 0.0, 1.0)
NetworkAddPedToSynchronisedScene(ped, scene, anim_dict, "action", ...)
NetworkAddEntityToSynchronisedScene(container, scene, anim_dict, "action_container", ...)
-- ...

SetEntityCoords(ped, animPos)         -- ★ プレイヤーをアニメ開始位置にテレポート
NetworkStartSynchronisedScene(scene)

Wait(3000)                            -- 演出の段階的タイミング
-- xsound でグラインダー音再生
Wait(1000)
StartParticleFxLoopedOnEntity('scr_tn_tr_angle_grinder_sparks', grinder, ...)
Wait(1000)
StopParticleFxLooped(sparks, true)
Wait(GetAnimDuration(anim_dict, 'action') * 1000 - 7000)
-- カメラ復帰
Wait(2000)
TriggerServerEvent('exp_trainheist:SynchronizeContainer', {...})
DeleteObject(grinder); DeleteObject(bag); DeleteObject(container); DeleteObject(lock)
```

### 7.2 走行中対応の問題

`SetEntityCoords(ped, animPos)` で**プレイヤーを絶対座標に固定**してアニメを始めるので、列車が動いていると **アニメ中に列車が前進してプレイヤーがコンテナから取り残される**。

対応方針:

1. **アニメ中だけ列車を停止**: `SetTrainCruiseSpeed(train, 0.0)` でいったん減速 → アニメ完了後に再加速。**MI 風としては微妙だが実装は最も簡単**。
2. **プレイヤーを wagon に attach してから synchronised scene**: 列車の移動に追随する。ただし synchronised scene の `animPos`（ワールド座標基準）と attach の組み合わせは挙動が不安定になりがちで、要検証。
3. **演出短縮**: グラインダーの 10〜15 秒アニメを短縮版に切り替える（プログレスバー + 短い切断アニメ）

**推奨**: 1（アニメ中だけ列車減速）。MI 映画でも「侵入したら列車を制御」する展開は自然。

### 7.3 AnimateGoldGrabbing も同様

`anim@scripted@heist@ig1_table_grab@gold@male@` の synchronised scene を使い、`enter` → `grab` → `exit` の 3 フェーズ。同じく `SetEntityCoords` 固定なので、走行中は列車減速が必要。

---

## 8. サーバー権威・経済（`server/main.lua`）

### 8.1 設計の良し悪し

**良い点**:

- `SD.Callback.Register` で各クライアント要求を権威化（`HasItem`, `CanCarryGold`）
- 金銭付与は `DeliverGold` イベント時に**サーバー側でのみ** `SD.Money.AddMoney` 実行
- アイテム付与（`GiveGold`）も `SD.Inventory.AddItem` でサーバー権威
- Discord ログを `DiscordLog` で記録（`SD.Logger`）

**問題点**（`60-fivem-server-authority.mdc` 違反）:

```lua
RegisterNetEvent('exp_trainheist:GiveGold', function()
    local _source = source                    -- ★ source 退避はしているが…
    SD.Inventory.AddItem(_source, LOOT.item, LOOT.stack)
end)
```

このイベントには**何の検証もない**。クライアントから `exp_trainheist:GiveGold` を直接トリガーすれば、ヘイストに参加していなくても誰でも `gold_ingot * 25` がもらえる。**重大な脆弱性**。

- ヘイスト進行状態（`IsHeistActive` + 参加者リスト）を見るべき
- 取得回数の上限（コンテナ数 = 2 個 × 1 スタック）を見るべき
- クールダウン（最後の取得から N 秒以内は拒否）

```lua
SD.Callback.Register("exp_trainheist:CanCarryGold", function(source)
    return true   -- ★ 常に true。所持上限チェック未実装
end)
```

`QB_MAX_WEIGHT = 120000` が config にあるのに、`CanCarryGold` で使われていない。

### 8.2 流用するならここを直す

MI 化のついでに以下を入れる:

1. `IsHeistActive` フラグだけでなく **参加者リスト**（`HeistParticipants[src] = true`）を持ち、`GiveGold` の冒頭で `if not HeistParticipants[_source] then return end`
2. `CanCarryGold` を実装（`SD.Inventory.CanCarryItem(source, LOOT.item, LOOT.stack)` 相当を呼ぶ）
3. クールダウン（`60-fivem-server-authority.mdc §5`）

### 8.3 警察 carejob 数

```lua
function GetPoliceCount()
    local count = 0
    for _, sid in ipairs(SD.GetPlayers()) do
        if SD.HasGroup(source, POLICE_JOBS) then   -- ★ バグ: sid ではなく source を渡している
            count = count + 1
        end
    end
    return count
end
```

**バグ発見**: ループ変数 `sid` を使うべきところで `source` を参照している。`GetPoliceCount` 呼び出し元の `source` のジョブを毎回チェックしているだけで、まともにカウントできていない。`POLICE_REQUIRED = 0` がデフォルトなのでデフォルト設定だと露呈しないが、`POLICE_REQUIRED = 2` 等にすると即座にバグる。

修正版:

```lua
if SD.HasGroup(sid, POLICE_JOBS) then
```

---

## 9. クリーンアップ（`onResourceStop`）

```lua
RegisterNetEvent('exp_trainheist:ResetAndWipe', function()
    if HeistBlip then RemoveBlip(HeistBlip) end
    for index, value in ipairs(Entities) do
        DeleteEntity(value)
    end
    Entities = {}
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    TriggerEvent("exp_trainheist:ResetAndWipe")
end)
```

`Entities` テーブルに**生成したエンティティを全部蓄積**して一括 `DeleteEntity` する設計は綺麗（`60-fivem-lua.mdc §6` 準拠）。

ただし `DeleteEntity` は **ネットワーク所有権がないと効かない**。`Entities[]` のうちネットワーク化された container/lock/gold については `NetworkRequestControlOfEntity` を待ってから `DeleteEntity` するべきだが、現実装はそのチェックがない。リスタート時にゴミが残る可能性あり。

---

## 10. ヘリ侵入機能の欠落

`exp_trainheist` には**ヘリから列車屋根に飛び移る機能は一切ない**。`config.lua`、`client/*` のどこにもヘリコプター関連コードはなし。

MI 化ではこれを**完全新規実装**する必要がある。設計骨子:

```lua
-- 擬似コード
CreateThread(function()
    while phase == 'heli_approach' do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and IsThisModelAHeli(GetEntityModel(veh)) then
            local lastWagon = wagons[#wagons]
            if DoesEntityExist(lastWagon) then
                local heliCoords = GetEntityCoords(veh)
                local trainCoords = GetEntityCoords(lastWagon)
                local dist = #(heliCoords - trainCoords)
                if dist < 8.0 and heliCoords.z - trainCoords.z < 10.0 then
                    -- ヘルプテキスト表示「[E] 列車に飛び移る」
                    ShowFloatingHelpNotification(...)
                    if IsControlJustPressed(0, 51) then -- E
                        -- ヘリから降りる
                        TaskLeaveVehicle(ped, veh, 4160) -- jump out
                        Wait(500)
                        -- 列車屋根に AttachEntityToEntity
                        AttachEntityToEntity(ped, lastWagon, 0, 0.0, 0.0, 2.0, ...)
                        Wait(1000)
                        DetachEntity(ped, true, true)
                        phase = 'on_roof'
                    end
                end
            end
        end
        Wait(0)
    end
end)
```

一人プレイ対応では、降りた後のヘリを `TaskHeliMission` で自動退避させる:

```lua
-- ヘリのドライバ ped に AI タスクを与える（プレイヤー降車時に自動生成は無いので、別途 AI ped を雇うか、空のままにする）
-- 簡易: SetVehicleAsNoLongerNeeded(veh) でゲームが片付ける
```

---

## 11. config.lua の問題点

```lua
LANGUAGE = 'en'
POLICE_REQUIRED = 0
POLICE_JOBS = { police = 0, sheriff = 0 }
ROBBERY_INTERVAL = 2*60*60000 -- 2 Hours
BREAK_ITEM = "grinder"
QB_MAX_WEIGHT = 120000 -- Only For QB-Core    -- ★ 使われていない
MONEY_TYPE = "money"
LOOT = { item = "gold_ingot", stack = 25, price = 300 }
START_SCENE = {...}
GUARDS = {...}
TRAIN = {...}
TRAIN_PARTS = {"freightcar", "freightcont1", "freightcont2", "freightgrain", "tankercar"}
```

- **すべてグローバル変数**（`60-fivem-lua.mdc §1` 違反、ただし `config.lua` は shared なのでこれは慣習的に許容）
- `QB_MAX_WEIGHT` は宣言されているが**コードで一切使われていない**（dead config）
- MI 化では `TRAIN.position` / `TRAIN.heading` を「**スポーン点**」として再定義、`TRAIN.cruiseSpeed`, `TRAIN.trackId` を追加する必要がある

---

## 12. 流用 vs 書き換えマトリクス（実装計画）

| 項目 | ファイル | 状態 | MI 改造での対応 |
|---|---|---|---|
| 開始 NPC + ox_target | `_main.lua` 冒頭 + `functions.lua::SpawnNPC` | ✅ 流用 | そのまま |
| ヘイスト開始判定 | `_main.lua::StartTrainHeist` + `server/main.lua::CanPlayerStartHeist` | ⚠️ 部分流用 | 「400m 接近待ち」をヘリ召喚フェーズに置換 |
| 列車スポーン | `train.lua::BuildTrain / SpawnWagon` | ❌ **全面書き換え** | `CreateMissionTrain` + `SetTrainCruiseSpeed` + `GetTrainCarriage` |
| コンテナ・鍵生成 | `train.lua::SetupContainers` | ⚠️ 部分書き換え | `FreezeEntityPosition` を `AttachEntityToEntity(wagon)` に置換 |
| 金塊設置 | `train.lua::SetupLoot` | ⚠️ 部分書き換え | 同上（attach 化） |
| hitbox 配置 | `hitboxes.lua` | ⚠️ 部分書き換え | hitbox を wagon に attach |
| 警備兵スポーン | `_main.lua::SpawnGuards` | ⚠️ 部分書き換え | 警備兵を wagon に attach + `TaskCombatPed` |
| コンテナ切断アニメ | `animations.lua::AnimateContainerOpening` | ✅ 流用 | アニメ中だけ `SetTrainCruiseSpeed(train, 0.0)` |
| 金塊取得アニメ | `animations.lua::AnimateGoldGrabbing` | ✅ 流用 | 同上 |
| サーバー権威・報酬 | `server/main.lua` | ⚠️ バグ修正 + 強化 | `GiveGold` の参加者検証、`GetPoliceCount` の `sid` バグ修正、`CanCarryGold` 実装 |
| クリーンアップ | `_main.lua::ResetAndWipe` | ⚠️ 強化 | `CreateMissionTrain` で作った train は `DeleteMissionTrain` で消す + `SetRandomTrains(true)` 復帰 |
| ヘリ侵入 | （なし） | ➕ **新規** | 上記擬似コード参照 |
| Discord ログ | `server/main.lua` + `functions.lua::DiscordLog` | ✅ 流用 | そのまま |
| sd_lib 依存 | `fxmanifest.lua` | ⚠️ 検討 | sd_lib をやめて ox_lib のみにできれば standalone 度が上がる（`60-fivem-fxmanifest.mdc` §「ox エコシステム統一」） |

---

## 13. sd_lib 依存の代替検討

`sd_lib` は SD Studios の独自ライブラリで、以下を提供:

| sd_lib API | 用途 | ox_lib 代替 |
|---|---|---|
| `SD.Locale.LoadLocale / T` | 多言語 | `lib.locale` |
| `SD.Callback.Register` / `SD.Callback` | コールバック | `lib.callback.register` / `lib.callback.await` |
| `SD.Inventory.HasItem / AddItem / RemoveItem` | インベントリ | `exports.ox_inventory:GetItem / AddItem / RemoveItem` |
| `SD.Money.AddMoney` | 経済 | `exports.qbx_core:GetPlayer(src).Functions.AddMoney` または ESX |
| `SD.GetPlayers` / `SD.HasGroup` | プレイヤー検索 | フレームワーク直接 |
| `SD.Name.GetFullName` | フル名取得 | フレームワーク直接 |
| `SD.Logger` | Discord Webhook | 自前で `PerformHttpRequest` |
| `SD.ShowNotification` | 通知 | `lib.notify` |

**推奨**: AGENTS.md の方針通り、jp- フォーク版を作るなら sd_lib 依存を切って ox_lib + qbx_core で書き直すと、ライセンス・依存管理がシンプルになる。ただし**初期実装はまず sd_lib 込みで動かす**ことを優先し、移植は次フェーズに回すのが効率的（`00-karpathy-guidelines §3` Surgical Changes）。

---

## 14. 既知のバグ・脆弱性まとめ

| ID | 重要度 | 箇所 | 内容 | 修正方針 |
|---|---|---|---|---|
| B-01 | 🔴 Critical | `server/main.lua::GiveGold` | クライアントから直接トリガー可能、検証なし | 参加者リスト + クールダウンで権威化 |
| B-02 | 🟡 High | `server/functions.lua::GetPoliceCount` | ループ変数 `sid` ではなく `source` を渡している | `SD.HasGroup(sid, POLICE_JOBS)` に修正 |
| B-03 | 🟡 High | `server/main.lua::CanCarryGold` | 常に `true`、容量チェック未実装 | `SD.Inventory.CanCarryItem` 等を呼ぶ |
| B-04 | 🟢 Medium | `_main.lua` 各所 | グローバル変数を多用 | `local State = { ... }` に集約 |
| B-05 | 🟢 Medium | `_main.lua::ResetAndWipe` | ネットワーク所有権チェックなしで `DeleteEntity` | `NetworkRequestControlOfEntity` 待ち |
| B-06 | 🟢 Low | `config.lua::QB_MAX_WEIGHT` | dead config | 削除 or 実装 |
| B-07 | 🟢 Low | `_main.lua::SpawnGuards` | プレイヤー自身に `SetPedRelationshipGroupHash` 冗長 | 削除可（害なし） |

---

## 15. 次のステップ提案

このレポートを踏まえて、以下の順序で実装計画を立てる:

1. **走り続ける列車スポーンのプロトタイプ**（`mi-train/research/02_moving_train_prototype.md` 仮）
   - `CreateMissionTrain(variation=24, ...)` + `SetTrainCruiseSpeed(20.0)` の最小サンプル
   - `GetTrainCarriage` で各車両を取り出してデバッグ blip を貼る
   - 走行中に減速・再加速のテスト

2. **DBuz747 add-on の検証**（マスター側で配置 + 試走）
   - `stream/` に配置するファイル一覧
   - vehicle meta の variation 登録方法

3. **ヘリ→屋根侵入のプロトタイプ**
   - 最後尾 wagon に `AttachEntityToEntity` で着地

4. **`exp_trainheist` のフォーク化 + 列車部の差し替え**
   - `BuildTrain` を `BuildMovingTrain` に置換
   - hitbox / container / loot を wagon に attach
   - アニメ中の列車減速ロジック追加
   - サーバー権威バグ修正（B-01 / B-02 / B-03）

5. **MI 風演出の追加レイヤー**
   - ロープ降下、屋根上カメラワーク、列車内潜入時のスクリプテッドシーン

---

## 16. 解析メタ情報

- 解析範囲: 全 11 ファイル（README, fxmanifest, config, client/*, server/*, locales/en）読了
- 解析対象 commit: `b61a68b`
- 解析者: AI（Claude）
- 解析日時: 2026-05-27
- 関連調査: 走行レール仕様（Track ID 0 = 47.8km ループ、1 周 約 33 分）は前段リサーチに記載
