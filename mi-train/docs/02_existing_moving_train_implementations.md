# 既存リソースの「走り続ける列車」実装比較

- 調査対象: 3 つの代表的 OSS 列車 MOD
- 結論: **全部にある**。ただし**戦略が 3 通り**に分かれており、MI 用途には選び方が重要

---

## 1. 結論サマリー

| リソース | 戦略 | 速度制御 | ホスト管理 | MI 用途への適性 |
|---|---|---|---|---|
| **Blumlaut/FiveM-Trains** | `CreateMissionTrain` を**ホスト 1 人**が呼ぶ | デフォルト速度（指定なし） | `GetHostId()` で取得、再選出なし | ❌ ホスト切断で消える |
| **TheNickoos/FiveM-Trains** | Blumlaut ベース + 速度明示 + 駅停止 | `SetTrainCruiseSpeed(20.0)` | サーバー側で **trainHost 管理 + 再選出ロジック** | ⭐ **最良のベース** |
| **VenomXNL/XNL-FiveM-Trains-U3** | `SetRandomTrains(true)` + `SwitchTrainTrack` でゲームエンジン任せ | エンジン任せ（制御薄い） | 全クライアントが個別に呼ぶ | △ MI には制御権が弱い |

**マスター質問への回答**: 走り続ける列車のコードは**既存に複数ある**。MI 用途には **TheNickoos のサーバー側ホスト管理 + クライアント側 `CreateMissionTrain` パターン** がベース最良。

---

## 2. Blumlaut/FiveM-Trains（オリジナル）

ライセンス: 明示なし（README 参照、自由利用相当）  
クローン先: `mi-train/research/blumlaut/`

### 2.1 列車生成の核心

```lua
-- client.lua
RegisterNetEvent("StartTrain")
function StartTrain()
    Citizen.Trace("a train has arrived")
    randomSpawn = math.random(#TrainLocations)
    x,y,z = TrainLocations[randomSpawn][1], TrainLocations[randomSpawn][2], TrainLocations[randomSpawn][3]

    yesorno = math.random(0,100)
    if yesorno >= 50 then yesorno = true else yesorno = false end

    DeleteAllTrains()
    Train = CreateMissionTrain(math.random(0,22), x,y,z, yesorno)
    MetroTrain = CreateMissionTrain(24, 40.2,-1201.3,31.0, true)
    MetroTrain2 = CreateMissionTrain(24, -618.0,-1476.8,16.2, true)
    CreatePedInsideVehicle(Train, 26, GetHashKey("s_m_m_lsmetro_01"), -1, 1, true)
    -- ...
    SetEntityAsMissionEntity(Train, true, true)
end
```

### 2.2 サーバー側ホスト判定

```lua
-- server.lua
function ActivateTrain()
    if PlayerCount == 1 and not trainspawned then
        TriggerClientEvent('StartTrain', GetHostId())   -- ★ GetHostId() でホストに送る
        trainspawned = true
    end
end
```

### 2.3 評価

- **長所**: 最小実装。`CreateMissionTrain` の使い方が綺麗
- **短所**:
  - `SetTrainCruiseSpeed` が**ない**ので速度はデフォルトに依存
  - ホストが切断したら列車制御不能
  - `hardcap` リソース依存（`PlayerCount` 集計のため）
  - **`__resource.lua`** 時代の古い構文（`fxmanifest.lua` ではない）

MI 用途では**そのまま使えないが、設計思想だけ参考になる**レベル。

---

## 3. TheNickoos/FiveM-Trains（Blumlaut の正統進化版）⭐

ライセンス: LICENSE ファイル同梱（要確認、おそらく MIT 相当）  
クローン先: `mi-train/research/nickoos/`

### 3.1 列車生成（速度明示）

```lua
-- client/client.lua, StartTrain 関数
Wait(100)
Train = CreateMissionTrain(math.random(0,22), x,y,z, yesorno)
while not DoesEntityExist(Train) do
    Wait(800)
    if Debug then print("FiveM-Trains: Waiting for Freight to be created") end
end

SetTrainCruiseSpeed(Train, 20.0)   -- ★ MI 用途の核心 API
Wait(200)

MetroTrain = CreateMissionTrain(24, 40.2,-1201.3,31.0, true)
while not DoesEntityExist(MetroTrain) do Wait(800) end
SetTrainCruiseSpeed(MetroTrain, 15.0)

-- 運転手 ped を InsideVehicle で生成
Driver1 = CreatePedInsideVehicle(Train, 26, TrainDriverHash, -1, 1, true)
SetBlockingOfNonTemporaryEvents(Driver1, true)
SetPedFleeAttributes(Driver1, 0, 0)
SetEntityInvincible(Driver1, true)
SetEntityAsMissionEntity(Driver1, true)

SetEntityAsMissionEntity(Train, true, true)
SetEntityInvincible(Train, true)
```

**MI 用途的に重要な API がすべて使われている**:
- `CreateMissionTrain(variation, x, y, z, direction)` — variation は 0〜24
- `DoesEntityExist(train)` の待ちループ（**スポーンは非同期**）
- `SetTrainCruiseSpeed(train, 20.0)` — m/s 単位
- `SetEntityAsMissionEntity(train, true, true)` — ゲームによる自動削除を防止
- `SetEntityInvincible(train, true)` — 列車を破壊不能化
- `CreatePedInsideVehicle(train, seatIndex=26, model, ...)` — 運転席に運転手 ped 配置
- `SetBlockingOfNonTemporaryEvents(driver, true)` — 戦闘時に運転手が逃げないように

### 3.2 一時停止（駅停止ロジック・MI で流用可）

```lua
function StopTrain(train)
    if NetworkHasControlOfEntity(train) then              -- ★ 所有権チェック必須
        table.insert(MetroTrainStopped, train)
        SetTrainCruiseSpeed(train, 0.0)                   -- 減速指令
        Citizen.Wait(100)
        if train ~= nil then
            local stoppedTimer = GetGameTimer()
            repeat
                Citizen.Wait(0)
            until GetEntitySpeed(train) <= 0              -- ★ 実速度ゼロまで待機
            while (GetGameTimer() - stoppedTimer < 20 * 1000) do
                Citizen.Wait(0)                           -- 20 秒停車
            end
        end
        Citizen.Wait(100)
        SetTrainCruiseSpeed(train, 15.0)                  -- 再加速
        local timer = GetGameTimer()
        while (GetGameTimer() - timer < 5000) do
            removebyKey(MetroTrainStopped, train)
            Citizen.Wait(0)
        end
    end
end
```

**MI 用途で直接流用できる**:
- アニメ中（コンテナ切断・金塊取得）は `SetTrainCruiseSpeed(train, 0.0)` で停止
- `GetEntitySpeed(train) <= 0` の待機ループも参考になる
- 再加速時にクルーズスピードを元に戻すパターン

### 3.3 サーバー側ホスト再選出ロジック（MI で流用必須）⭐

```lua
-- server/server.lua
local trainHost = nil

RegisterServerEvent("FiveM-Trains:PlayerSpawned")
AddEventHandler('FiveM-Trains:PlayerSpawned', function()
    local _source = source
    SpawnTrain(_source)
end)

AddEventHandler('playerDropped', function()
    local _source = source
    if trainHost == _source then            -- ★ ホストが切断したら
        trainspawned = false
        trainHost = nil
        ChooseRandomPlayer(_source)         -- 別プレイヤーをホストに昇格
    end
end)

function ChooseRandomPlayer(leaver)
    for _, playerId in ipairs(GetPlayers()) do
        if tonumber(playerId) ~= tonumber(leaver) then
            SpawnTrain(playerId)
            break
        end
    end
end

function SpawnTrain(player)
    if not trainHost then
        if not trainspawned then
            TriggerClientEvent('StartTrain', tonumber(player))
            trainspawned = true
            trainHost = player
        end
    end
end
```

これは **MI ヘイストの「列車オーナーを固定 + 切断時に委譲」** の基本パターンとそのまま使える。ただし以下の改善が必要:

- `ChooseRandomPlayer` は単にリストの先頭を取るだけ（コメント "Yeah, pretty bad random" の通り）。MI ヘイストでは**ヘイスト開始者 → 残存参加者 → 任意プレイヤー**の優先順で再選出するのが望ましい
- `SpawnTrain` 時に**ホストへ既存列車の状態（位置・速度・編成）を引き継ぐ**ロジックがない。これは MI でも問題になるので別途設計が必要

### 3.4 評価

| 観点 | 評価 |
|---|---|
| API 使い方 | ⭐ 模範的 |
| 速度制御 | ⭐ あり |
| ホスト管理 | ⭐ 再選出あり（ただし単純） |
| OneSync 対応 | △ `playerSpawned` で初回同期するが、状態引き継ぎなし |
| 駅停止ロジック | ⭐ MI 流用可 |
| クリーンアップ | `DeleteMissionTrain` を `onResourceStop` で実行（◯） |
| コードスタイル | グローバル変数多用、`Wait(0)` ループあり（要改善） |

**結論**: **MI のベースとして最良**。ただしコード品質は古く（`fxmanifest.lua` ではなく旧 `fx_version 'adamant'`、グローバル変数多用）、**書き直し前提で参考**にする。

---

## 4. VenomXNL/XNL-FiveM-Trains-U3（ゲームエンジン任せ）

ライセンス: 「使う時はクレジットを残せ」（README ヘッダ）  
クローン先: `mi-train/research/venomxnl/`

### 4.1 別アプローチ: 自前で `CreateMissionTrain` を呼ばない

```lua
-- client.lua（先頭スレッド）
Citizen.CreateThread(function()
    SwitchTrainTrack(0, true)                  -- Track 0: 貨物レール
    SwitchTrainTrack(3, true)                  -- Track 3: メトロレール
    SetTrainTrackSpawnFrequency(0, 120000)     -- 貨物列車の自動スポーン頻度（ms）
    SetTrainTrackSpawnFrequency(3, 120000)     -- メトロの自動スポーン頻度
    SetRandomTrains(true)                      -- ★ ゲームエンジンに列車スポーンを任せる
    SetTrainsForceDoorsOpen(false)
end)
```

これは「**ゲームエンジンに任せて自動スポーン**」させる戦略。`CreateMissionTrain` を一度も呼ばない。

### 4.2 メリット・デメリット

| 観点 | メリット | デメリット |
|---|---|---|
| 実装の単純さ | ⭐ コード量が劇的に少ない | — |
| 速度・編成制御 | — | ❌ ゲーム任せ、`SetTrainCruiseSpeed` を呼ぶ対象 entity ハンドルが取れない |
| ホスト管理 | ⭐ 不要（全クライアント独立） | — |
| MI 用ヘイスト | — | ❌ 「**特定の編成を狙う**」設計に合わない |
| 一般的な RP サーバー | ⭐ メトロ・貨物列車を世界に走らせるだけなら最適 | — |

### 4.3 評価

VenomXNL は **RP サーバー全体の「世界の賑わい」用途には最高**だが、MI 風ヘイスト（特定の編成を追跡・侵入）には**列車ハンドルの所在が不明**になるので不向き。

ただし**部分的に流用**できる API は以下:

- `SwitchTrainTrack(0, false)` を**最初に呼んで自動スポーンを切る**（exp_trainheist の改造で必須、§5 で詳述）
- `SetRandomTrains(false)` で他の列車との衝突回避
- `SetTrainsForceDoorsOpen(false)` でドア勝手に開かないように

---

## 5. MI 用途のレシピ（3 実装を統合）

`docs/01_exp_trainheist_analysis.md` の §15 で示した「走行する列車のプロトタイプ」設計を、3 実装の知見で具体化:

### 5.1 クライアント側コア（TheNickoos ベース）

```lua
-- 擬似コード: mi-train の client/train_spawn.lua として実装予定
local TRAIN_VARIATION  = 24  -- メトロ。貨物なら 0〜22
local TRAIN_SPAWN      = { x = 2533.0, y = 2833.0, z = 38.0 }
local TRAIN_CRUISE_MPS = 20.0  -- ≒ 72 km/h

local function PrepareTrackForHeist()
    -- VenomXNL の知見: 既存ランダム列車を一掃
    DeleteAllTrains()
    SetRandomTrains(false)
    SwitchTrainTrack(0, false)
    SwitchTrainTrack(3, false)
end

local function RestoreTrackAfterHeist()
    SetRandomTrains(true)
    SwitchTrainTrack(0, true)
    SwitchTrainTrack(3, true)
end

---@return number trainEntity 機関車エンティティ
local function SpawnMovingTrain()
    PrepareTrackForHeist()

    -- TheNickoos の知見: 全モデルプリロード
    for _, model in ipairs({"freight", "freightcar", "freightcont1", "freightcont2", "tankercar"}) do
        local hash = GetHashKey(model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(0) end
    end

    -- TheNickoos の知見: CreateMissionTrain + 存在待ち + クルーズスピード
    local train = CreateMissionTrain(TRAIN_VARIATION, TRAIN_SPAWN.x, TRAIN_SPAWN.y, TRAIN_SPAWN.z, true)
    while not DoesEntityExist(train) do Wait(100) end

    SetTrainCruiseSpeed(train, TRAIN_CRUISE_MPS)
    SetEntityAsMissionEntity(train, true, true)
    SetEntityInvincible(train, true)

    -- 運転手 ped を配置（戦闘で逃げないように）
    local driverHash = GetHashKey("s_m_m_lsmetro_01")
    RequestModel(driverHash)
    while not HasModelLoaded(driverHash) do Wait(0) end
    local driver = CreatePedInsideVehicle(train, 26, driverHash, -1, 1, true)
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedFleeAttributes(driver, 0, 0)
    SetEntityInvincible(driver, true)
    SetEntityAsMissionEntity(driver, true)
    SetModelAsNoLongerNeeded(driverHash)

    -- exp_trainheist 流: 各車両ハンドルを保持
    local wagons = { train }
    for i = 1, 5 do
        local carriage = GetTrainCarriage(train, i)
        if DoesEntityExist(carriage) then
            wagons[#wagons + 1] = carriage
        end
    end

    return train, wagons
end

---@param train number 列車ハンドル
local function PauseTrainForAnimation(train, durationMs)
    -- TheNickoos の StopTrain を簡略化
    if not NetworkHasControlOfEntity(train) then
        NetworkRequestControlOfEntity(train)
        local t = GetGameTimer()
        while not NetworkHasControlOfEntity(train) and GetGameTimer() - t < 2000 do
            Wait(0)
        end
    end
    SetTrainCruiseSpeed(train, 0.0)
    local t = GetGameTimer()
    repeat Wait(0) until GetEntitySpeed(train) <= 0.1 or GetGameTimer() - t > 5000

    Wait(durationMs)

    SetTrainCruiseSpeed(train, TRAIN_CRUISE_MPS)
end
```

### 5.2 サーバー側ホスト管理（TheNickoos ベース、改良版）

```lua
-- 擬似コード: mi-train の server/host.lua として実装予定
---@type integer|nil
local HeistHost = nil

---@type table<integer, boolean>
local HeistParticipants = {}

local function PromoteToHost(src)
    HeistHost = src
    TriggerClientEvent('mi-train:becomeHost', src)
    print(('[mi-train] %s (%d) is now the train host'):format(GetPlayerName(src), src))
end

AddEventHandler('playerDropped', function()
    local src = source
    HeistParticipants[src] = nil

    if HeistHost == src then
        HeistHost = nil
        -- 改良: 残存参加者 → 任意プレイヤーの順で再選出
        for participant, _ in pairs(HeistParticipants) do
            if GetPlayerEndpoint(participant) then
                PromoteToHost(participant)
                return
            end
        end
        for _, pid in ipairs(GetPlayers()) do
            PromoteToHost(tonumber(pid))
            return
        end
    end
end)
```

### 5.3 採用 API まとめ表

| API | 出典 | MI での用途 |
|---|---|---|
| `CreateMissionTrain(variation, x, y, z, dir)` | Blumlaut/Nickoos | ヘイスト用列車の生成 |
| `DoesEntityExist(train)` 待ちループ | Nickoos | スポーン完了待機 |
| `SetTrainCruiseSpeed(train, mps)` | Nickoos | 速度制御。MI で停止/再加速の核 |
| `GetEntitySpeed(train)` | Nickoos | 実速度ゼロ判定 |
| `NetworkHasControlOfEntity(train)` | Nickoos | 所有権チェック |
| `NetworkRequestControlOfEntity(train)` | （標準） | 所有権取得 |
| `SetEntityAsMissionEntity(train, true, true)` | Blumlaut/Nickoos | 自動削除防止 |
| `SetEntityInvincible(train, true)` | Nickoos | 列車破壊防止 |
| `GetTrainCarriage(train, index)` | exp_trainheist 設計の延長 | 各車両ハンドル取得 |
| `CreatePedInsideVehicle(train, 26, ...)` | Blumlaut/Nickoos | 運転手 ped |
| `SetBlockingOfNonTemporaryEvents(driver, true)` | Nickoos | 運転手の戦闘逃走防止 |
| `SetPedFleeAttributes(driver, 0, 0)` | Nickoos | 同上 |
| `DeleteAllTrains()` | Blumlaut | 既存列車一掃 |
| `SetRandomTrains(false)` | VenomXNL | 自動スポーン無効化 |
| `SwitchTrainTrack(0, false)` | VenomXNL | Track 0 の自動スポーン無効化 |
| `SetTrainTrackSpawnFrequency(0, ms)` | VenomXNL | スポーン頻度（事後復帰用） |
| `SetTrainsForceDoorsOpen(false)` | VenomXNL | ドア勝手に開く対策 |
| `DeleteMissionTrain(train)` | Nickoos `onResourceStop` | クリーンアップ |

---

## 6. ライセンス整理

MI MOD の構築時にコードを流用する場合のライセンス所属:

| リソース | ライセンス | 流用条件 |
|---|---|---|
| Blumlaut/FiveM-Trains | 明示なし（フォーラム公開時「自由利用」と発言あり） | クレジット推奨 |
| TheNickoos/FiveM-Trains | LICENSE 同梱（要確認） | LICENSE 内容次第 |
| VenomXNL/XNL-FiveM-Trains-U3 | 「使うならクレジット残せ」 | クレジット必須 |
| exp_trainheist | GPL-3.0 | **派生物も GPL-3.0**（強い copyleft） |

**注意**: `exp_trainheist` は GPL-3.0 なので、これを土台にすると MI MOD 全体が GPL-3.0 になる。`60-fivem-jp-localization.mdc` / `60-fivem-security-ethics.mdc §4` の「元 MOD のライセンス尊重」を遵守。

逆に「列車スポーン部分だけ自前で書き、ヘイストロジックも自前で書く」のであれば、TheNickoos / Blumlaut / VenomXNL の**コード自体を直接コピーせず**、上記 API 表を見ながら自前実装すれば、ライセンス感染を避けられる。

---

## 7. 推奨ステップ更新（`01_exp_trainheist_analysis.md §15` の差し替え案）

1. **新規 jp-mi-train を作る**（exp_trainheist フォークではなく**ゼロから書く**）
   - 理由: exp_trainheist の GPL-3.0 感染を避ける、グローバル変数多用などの古い設計を引き継がない
   - API 表（§5.3）と TheNickoos のサーバー側ホスト管理パターンを参考に実装
2. **走り続ける列車プロトタイプ**: §5.1 のコードベース
3. **DBuz747 add-on の `stream/` 配置**: マスター側作業（変更なし）
4. **ヘリ侵入「E」**: 自前実装（変更なし）
5. **MI 演出レイヤー**: ロープ降下・カメラワーク等

→ **方針転換の選択肢**: exp_trainheist を「**設計の参考資料**」として残し、本体は標準 standalone（AGENTS.md 方針）で書く方が**ライセンス・コード品質の両面で有利**。

---

## 8. 補足: `CreateMissionTrain` の variation 番号

3 実装に共通して `0〜24` が使われている:

- **0〜22**: 貨物列車各種（`freight` 機関車 + 様々な貨車組み合わせ）
- **23**: 不明（テストして要確認）
- **24**: メトロ列車（`metrotrain` 2 両編成）

MI で「`freight` 機関車 + 5 両編成、うち 1 両が金庫車（`freightcar`）」を狙うなら、variation = `0〜22` のどれかを試してログを出して中身を確認するのが早い:

```lua
local train = CreateMissionTrain(0, x, y, z, true)
while not DoesEntityExist(train) do Wait(100) end
for i = 0, 10 do
    local c = GetTrainCarriage(train, i)
    if c and c ~= 0 then
        local model = GetEntityModel(c)
        print(('variation 0, carriage %d = model hash %d'):format(i, model))
    end
end
```

または **`DurtyFree/gta-v-data-dumps`** リポジトリの `TrainConfigs.json` に variation ごとの編成表があるので、それを参照すれば一発でわかる（前段リサーチで言及）。

---

## 9. メタ情報

- 解析対象 commit:
  - Blumlaut/FiveM-Trains: `--depth 1` の HEAD
  - TheNickoos/FiveM-Trains: `--depth 1` の HEAD
  - VenomXNL/XNL-FiveM-Trains-U3: `--depth 1` の HEAD
- 解析日時: 2026-05-27
- 関連レポート: `01_exp_trainheist_analysis.md`（ヘイスト本体の解析）
