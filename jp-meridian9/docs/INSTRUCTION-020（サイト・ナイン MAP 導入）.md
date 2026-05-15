# INSTRUCTION-020 設計書：サイト・ナイン MAP 導入（**北ヤンクトン版・v2**）

> 本タスクは `jp-meridian9/全体設計.txt` §7 M0 環境構築の積み残し。**v1 で The Apocalypse Project 採用を提案したが撤回**（LS 内ジオメトリ置換型で「車・ヘリで地続きで行ける」問題が解消できないため）。本 v2 では **GTA V バニラ同梱の North Yankton** を採用し、**クライアントローカル IPL × routing bucket** の組み合わせで真の「別空間」を実現する。
>
> ファイル名は Windows 制約で全角中点を使用。

---

## 0. 前提

| 項目 | 値 |
|---|---|
| 採用 MAP | **North Yankton**（GTA V キャンペーン Prologue「Ludendorff」のステージ。GTA V 本体に標準同梱） |
| IPL ローダー | **[Bob74/bob74_ipl](https://github.com/Bob74/bob74_ipl)**（MIT、現役メンテ、2024 年更新） |
| 配置座標 | 中心 約 `(3217.697, -4834.826, 111.8152)`（**Cayo Perico と同座標に重ねて配置**するのがバニラ仕様） |
| LICENSE 問題 | バニラ GTA V のリソース＋MIT IPL ローダーのみ。**LICENSE クリア** |
| 本リポへの同梱 | bob74_ipl は同梱しない（運営者が GitHub から取得）。North Yankton 自体はバニラなので取得不要 |
| 全体整合 | `ストーリー.txt` §「サイト・ナイン」「Subject-0」「研究員失踪」と高い親和性 |
| サーバーデプロイ先 | `H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources\[jp-mods]\jp-meridian9`（マスター環境で確定済み） |

---

## 1. 北ヤンクトン採用の根拠

### 1-A. 「海の向こう」要件を完全に満たす

- 北ヤンクトンは LS から **直線距離 約 6〜7 km の海上 region**（座標 X≈3217）
- バニラでは **海面のみ**配置（GTA V キャンペーンで一時的にロードされる以外は非表示）
- **車・ヘリで物理的に行こうとしても海面しかなく着地不可**
- **ゲート転送以外でアクセス手段が無い** → サイト・ナインの神秘性が完全に保たれる

### 1-B. 世界観適合度

| 要素 | 北ヤンクトン | サイト・ナイン世界観適合 |
|---|---|---|
| 気候 | **雪国・吹雪** | ◎ `Config.SiteNine.weather='XMAS'` と完全一致 |
| 地形 | **港町・教会・墓地・荒廃した街並み** | ◎ ホラー / SF 隔離区域として完璧 |
| 住民 | **無人**（バニラでは AI 通行人ゼロ） | ◎ 「研究員 25 名失踪」「向こう側」の不気味さを増幅 |
| 既知のロケーション | **Ludendorff 銀行（カットシーン）／墓地／教会** | ◎ ロアアイテム・任務ポイントとして物語化しやすい |

### 1-C. 技術的な決定打：**bucket 内分離が真に成立**

- `Bob74/bob74_ipl` の `NorthYankton.Enable(true)` は **クライアントローカルネイティブ**に展開される
- サーバー介在なし。**呼んだクライアントだけが ipl をロード**する
- routing bucket 内のクライアント全員が `Enable(true)` を呼べば、**その bucket 内でだけ北ヤンクトンが見える**
- bucket 0 のプレイヤーには **海面のまま**（既存 LS の見た目を一切壊さない）
- ヴェガ事務所周辺 (Mission Row) は **完全に綺麗のまま**
- 設計書 §3.1 の IDLE↔IN_MISSION 状態遷移が体感的に完全分離

---

## 2. スコープ

### 含む

- `Bob74/bob74_ipl` の採用と運用方針
- `client/transition.lua` の `Transition.Enter/Leave` に NorthYankton 連携を実装
- `Config.Mission.spawnPoint` / `Config.ExtractPoints` / `Config.LootSpawns` を北ヤンクトン内座標に再配置
- `fxmanifest.lua` の dependencies / 起動チェック
- README / CREDITS / FORMAL_POLICIES / milestones / design 更新
- 既知の罠（穴・broken model）への暫定対策

### 含まない

- ゲート転送の派手な演出（フェード・SFX・カメラワーク）→ **INSTRUCTION-017** で扱う
- 北ヤンクトン自体の改変（穴塞ぎ・テクスチャ修正）→ 必要なら別 INSTRUCTION
- 査定 UI・報酬画面 → INSTRUCTION-015

---

## 3. 確定事項

- **MAP 採用**: バニラ North Yankton（GTA V Prologue 由来）
- **IPL ローダー**: Bob74/bob74_ipl（MIT）
- **`alberttheprince/NorthYankton` は採用しない**（routing bucket 制御を自前の `Transition.Enter/Leave` に組み込む方が `jp-meridian9` セッション設計と整合）
- **bucket 分離方式**: クライアント側 `NorthYankton.Enable(true)` をミッション開始時に呼び、終了時に `Enable(false)` を呼ぶ。**bucket 内のクライアント全員が個別に Enable する**
- **座標基準点**: `(3217.697, -4834.826, 111.8152)`（Ludendorff 街中心、Bob74 公式座標）
- **LS の Mission Row（ヴェガ事務所）は無改変**
- **Cayo Perico との関係**: バニラ仕様で **同座標に重なる**。`NorthYankton.Enable(true)` を呼んだクライアントは Cayo が消えて North が見える。RP 整合上は問題なし（任務 bucket 中はサイト・ナインだけ）

---

## 4. 技術仕様

### 4-A. 採用する外部リソース

| リソース | 用途 | 配置 | LICENSE | リポ |
|---------|------|------|---------|------|
| `bob74_ipl` | IPL ロード基盤・北ヤンクトン制御オブジェクト提供 | `resources/[scripts]/bob74_ipl/` または `resources/bob74_ipl/` | MIT | [Bob74/bob74_ipl](https://github.com/Bob74/bob74_ipl) |

導入手順（運営者向け）:

```powershell
cd "H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources"
git clone https://github.com/Bob74/bob74_ipl.git bob74_ipl
```

`server.cfg`:

```
ensure bob74_ipl
ensure jp-meridian9
```

### 4-B. `bob74_ipl` API 抜粋

```lua
local NorthYankton = exports['bob74_ipl']:GetNorthYanktonObject()

-- 全体 ON/OFF
NorthYankton.Enable(true)   -- IPL ロード（クライアントローカル）
NorthYankton.Enable(false)  -- IPL アンロード

-- 墓地スタイル
NorthYankton.Grave.Set(NorthYankton.Grave.covered)  -- 雪に覆われた墓
NorthYankton.Grave.Set(NorthYankton.Grave.dug)      -- 掘り起こされた墓
NorthYankton.Grave.Set(NorthYankton.Grave.funeral)  -- 葬儀（Prologue 仕様）

-- AI 交通
NorthYankton.Traffic.Enable(false)  -- 廃墟感（jp-meridian9 ではこちら）
```

### 4-C. `client/transition.lua` 拡張案

既存の `MRD9.Transition.Enter/Leave` に NorthYankton 連携を追加。

```lua
local function applyNorthYankton()
    local ok, NY = pcall(function()
        return exports['bob74_ipl']:GetNorthYanktonObject()
    end)
    if not ok or not NY then
        MRD9.Log('NorthYankton: bob74_ipl 未導入。ロードをスキップ')
        return false
    end
    NY.Enable(true)
    if NY.Grave and NY.Grave.Set then
        NY.Grave.Set(NY.Grave.dug)  -- 掘り起こされた墓（不穏な雰囲気）
    end
    if NY.Traffic and NY.Traffic.Enable then
        NY.Traffic.Enable(false)
    end
    State.nyEnabled = true
    return true
end

local function clearNorthYankton()
    if not State.nyEnabled then return end
    local ok, NY = pcall(function()
        return exports['bob74_ipl']:GetNorthYanktonObject()
    end)
    if ok and NY and NY.Enable then
        NY.Enable(false)
    end
    State.nyEnabled = false
end

function MRD9.Transition.Enter()
    if State.active then return end
    State.active = true
    applyNorthYankton()  -- IPL ロード（非同期）
    Wait((Config.SiteNine and Config.SiteNine.iplLoadWaitMs) or 1500)  -- ロード待ち
    applyClockOverride()
    applyWeather()
    applyTimecycle()
    applyBlackout()
end

function MRD9.Transition.Leave()
    if not State.active then return end
    State.active = false
    clearBlackout()
    clearTimecycle()
    clearWeather()
    clearClockOverride()
    clearNorthYankton()
end
```

### 4-D. サーバー側起動チェック (`server/main.lua`)

```lua
local function checkNorthYanktonMap()
    if GetResourceState('bob74_ipl') ~= 'started' then
        print('[jp-meridian9] (server) [WARN] bob74_ipl 未起動。北ヤンクトンが表示されません。INSTRUCTION-020 §4-A 参照')
        return false
    end
    print('[jp-meridian9] (server) bob74_ipl 起動確認 OK（北ヤンクトン利用可）')
    return true
end
```

### 4-E. クライアント間同期

- `NorthYankton.Enable` はクライアントローカル
- bucket 内の全クライアントが個別に `Enable(true)` を呼ぶ必要
- jp-meridian9 では `TriggerClientEvent('jp-meridian9:onMissionStart', src, ...)` がメンバー全員に発火するため、各自で `Transition.Enter()` を呼ぶことで同期成立（既存設計でカバー済み）

### 4-F. ロード待ちと安全テレポート

- `NorthYankton.Enable(true)` 直後は IPL がストリーミング中で **地形コリジョンが未確定**
- `SetEntityCoords` で即テレポートするとプレイヤーが地形を貫通する事故あり
- 対策: クライアント側で **`Wait(1500)`** → `RequestCollisionAtCoord(x, y, z)` を呼んで → `Wait` を再度入れる
- サーバー側 `SetEntityCoords` は **クライアントの `Transition.Enter()` 完了後**に発火させる（イベント順序）

---

## 5. 座標設計

### 5-A. 北ヤンクトン主要ロケーション（バニラ・実調査）

| ロケーション | 座標 (X, Y, Z) | 用途候補 |
|---|---|---|
| **Ludendorff 街中心**（Bob74 公式） | `(3217.697, -4834.826, 111.815)` | spawnPoint 第一候補 |
| **教会前広場** | `(3261.0, -4733.0, 113.0)` 付近 | 探索エリア・ExtractPoint 候補 |
| **銀行前**（プロローグ Heist 場所） | `(3279.0, -4842.0, 112.0)` 付近 | 探索エリア・ロアロケーション |
| **墓地** | `(3127.0, -4671.0, 116.0)` 付近 | 探索エリア・キーロケーション |
| **駅 / 港湾** | `(3360.0, -4793.0, 110.0)` 付近 | ExtractPoint 候補 |

> 座標は バニラ Prologue マップを基準にした概算値。**実機で精査・確定する**。

### 5-B. Config 適用

```lua
Config.Mission = {
    spawnPoint = vector4(3217.697, -4834.826, 113.0, 90.0),  -- Ludendorff 中心、東向き
    returnPoint = vector4(425.0, -979.3, 30.5, 270.0),       -- ヴェガ事務所前（変更なし）
    timeLimitSeconds = 1200,
    -- ... 既存設定
}

Config.ExtractPoints = {
    { coords = vector3(3261.0, -4733.0, 113.0), label = '教会前広場',  radius = 3.5, blipSprite = 488, blipColor = 5 },
    { coords = vector3(3360.0, -4793.0, 110.0), label = '駅プラットフォーム', radius = 3.5, blipSprite = 488, blipColor = 5 },
    { coords = vector3(3127.0, -4671.0, 116.0), label = '墓地裏門',      radius = 3.5, blipSprite = 488, blipColor = 5 },
}

Config.LootSpawns = {
    -- 中心半径 200m 以内、街路上または建物周辺
    { coords = vector3(3220.0, -4810.0, 112.5), weight = { common=70, uncommon=25, rare=4, legendary=1 } },
    { coords = vector3(3245.0, -4825.0, 113.0), weight = { common=70, uncommon=25, rare=4, legendary=1 } },
    -- ... 15 箇所程度（実機で確定）
}
```

### 5-C. アリーナ（ゾンビウェーブ）

- `Config.Arena.spawnRadiusMin/Max` は既存値を踏襲（30〜80m）
- spawnPoint 周辺の建物を遮蔽物として活用
- 雪の中・廃墟・暗闇という条件で AI が見つけにくい → ホラー感増幅

---

## 6. ファイル変更

| ファイル | 変更内容 |
|---------|---------|
| `jp-meridian9/fxmanifest.lua` | `dependencies { 'oxmysql', 'ox_lib', 'ox_target', 'bob74_ipl' }` 追記 |
| `jp-meridian9/config.lua` | `Config.Mission.spawnPoint` を北ヤンクトン中心へ。`Config.ExtractPoints` を 3 箇所に再定義。`Config.LootSpawns` を 15 箇所程度に再定義。`Config.SiteNine` に `iplLoadWaitMs = 1500` を追加 |
| `jp-meridian9/client/transition.lua` | `applyNorthYankton` / `clearNorthYankton` を追加。`Transition.Enter/Leave` の頭で呼ぶ。`pcall` で `bob74_ipl` 未導入時は no-op |
| `jp-meridian9/server/main.lua` | `checkNorthYanktonMap()` を起動シーケンスに追加 |
| `jp-meridian9/server/session.lua` | `TransferIn` でテレポート前に **`Wait(2000)`** 等の追加待機を入れて IPL ロード完了を待つ（必要なら） |
| `jp-meridian9/README.md` | `## 5. サイト・ナイン MAP 導入手順` セクション。Bob74/bob74_ipl の取得手順・参考リンク |
| `jp-meridian9/docs/CREDITS.md` | Bob74 / bob74_ipl (MIT) を追記。GTA V 公式リソース（North Yankton/Prologue マップ）は Rockstar Games 著作物として注記 |
| `jp-meridian9/docs/FORMAL_POLICIES.md` | INSTRUCTION-020 正本セクション追記：「サイト・ナイン＝北ヤンクトン採用」「bob74_ipl を依存に追加」「bucket × クライアントローカル IPL の組み合わせで分離成立」「The Apocalypse Project 採用は撤回」 |
| `jp-meridian9/docs/milestones.md` | M0 を完了状態に更新（INSTRUCTION-020 紐付け） |
| `jp-meridian9/docs/design.md` | サイト・ナイン＝北ヤンクトンの旨を §現状節に追記 |

---

## 7. 着手順序（コード実装はマスター承認後）

1. ✅ **マスター承認**（本設計書）
2. **`AGENTS.md` / `.cursor/rules/cursor-workflow.mdc` のサーバーパス訂正**（`C:\FiveMServer\server-data\resources\` → `H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources\`）
3. テストサーバー側に `bob74_ipl` を clone
4. `server.cfg` に `ensure bob74_ipl` を `ensure jp-meridian9` の前に追加
5. `fxmanifest.lua` の `dependencies` に追記
6. `client/transition.lua` に `applyNorthYankton/clearNorthYankton` 実装
7. `Config.Mission.spawnPoint` を北ヤンクトン中心へ更新
8. `Config.ExtractPoints` を仮の 3 箇所で配置
9. `Config.LootSpawns` を仮の 5〜10 箇所で配置（実機調整の前提）
10. `server/main.lua` の起動チェック追加
11. **実機テスト**（ソロ）：ヴェガ依頼 → ゲート → 雪の北ヤンクトンに転送 → 戦闘 → 脱出 → 事務所綺麗
12. **bucket 分離テスト**（運営＋テスト用キャラ 2 名）：片方は任務、もう片方は通常 LS。海上を飛んで「相手から自分の MAP が見えない」を確認
13. `ExtractPoints` / `LootSpawns` の **座標を実機で精査して確定**
14. ドキュメント整備（README / CREDITS / FORMAL_POLICIES / milestones / design）
15. 開発日記追記 + コミット + push

---

## 8. パフォーマンス目標

- **クライアント resmon**：
  - ロード時瞬間 < 3.0 ms（IPL ロード 1〜2 秒）
  - 任務中定常 < 0.5 ms（追加負荷は SetWeatherTypeNow と Timecycle のみ）
  - 任務外 < 0.05 ms（北ヤンクトンは無効化）
- **サーバー resmon**：< 1.0 ms（既存と同等。bucket 切替時のみ瞬間負荷）

---

## 9. セキュリティ・権威

- `NorthYankton.Enable` はクライアントローカルで、**サーバー権威の対象外**
- ただし「**そもそも bucket に居ないクライアントが Enable(true) を呼んでも、座標 (3217, -4834) に居なければ何も見えない**」ため、悪用面の懸念は小さい
- bucket 切替・テレポート・インベントリは引き続きサーバー権威（`fivem-server-authority.mdc` 準拠）

---

## 10. RP 整合・世界観

### ストーリー上の解釈

- 「**サイト・ナイン**」＝ **北ヤンクトンの隔離区域**
- 「**APERTURE-J ゲート**」＝ ヴェガ事務所地下のゲート、座標を北ヤンクトン中心へワープする装置
- LS と北ヤンクトンは「**海と次元の歪み**」で隔たれている、と説明可能
- バニラの「Prologue」=「次元の歪みが古くから観測されていた区域、Meridian-9 がこれを発見して観測拠点化」と整合
- 「**インシデント・ゼロ**」=「北ヤンクトンに送り込んだ研究員 25 名が死亡し、Subject-0 がここに残された」
- 雪・教会・墓地・荒廃した街並み =「**死者の街**」のテーマでホラー演出強化

### ストーリー.txt との不整合は無いか

- §「Sandy Shores 郊外の地下施設に APERTURE 建造」→ **北ヤンクトンの発見はもっと古い**ことにする / または「Sandy Shores 本社ゲートと、Mission Row のヴェガ事務所地下の Janus ゲートは行き先が違う」と再定義
- §「インシデント・ゼロ 27 名失踪」→ 北ヤンクトンに残された遺体・遺品の回収が JANUS 任務の核
- §「Subject-0 という呼称を、もし現地で目にすることがあれば——即座に撤退してください」→ 北ヤンクトンの **墓地** か **銀行地下** に Subject-0 が眠る、というロア展開が可能

---

## 11. リスク・既知の罠

| リスク | 対策 |
|---|---|
| **バニラ北ヤンクトンの broken model / 穴** | 実機で穴のあるエリアを特定し、`ExtractPoints` / `LootSpawns` で避ける。重大なら別 INSTRUCTION で穴塞ぎ MOD（例: `alberttheprince/NorthYankton` の部分採用）を後追い |
| **Cayo Perico との同座標重複** | バニラ仕様。`NorthYankton.Enable(true)` 呼び出し時に Cayo は自動的に消える。RP 上は問題なし |
| **IPL ロード中の地形貫通** | `Wait(1500)` + `RequestCollisionAtCoord` で対処（§4-F） |
| **bucket 内に新規参加者が来た時の同期** | 新規参加者の `onMissionStart` で `Transition.Enter()` が呼ばれるため、その時点で `NorthYankton.Enable(true)` される。問題なし |
| **bob74_ipl のメンテ停止リスク** | 最終更新 2024 年で現役。代替候補 `jnccloud/fivem-ipl` も控えに把握 |
| **GTA V のバージョン要件** | North Yankton は GTA V Prologue 由来で **全 GTA V 同梱**。バージョン要件なし |
| **runtime `Enable(false)` 時の残留** | bob74_ipl が IPL を `RemoveIpl` するが、テレポート前に `Wait(500)` を入れて確実に |
| **複数セッション同時稼働時** | 全 bucket のクライアントが独立に `Enable(true/false)` を呼ぶので問題なし。座標が同じなので、別 bucket のメンバーが同じ場所に湧いても **互いに見えない**（bucket 分離が機能） |

---

## 12. テスト観点

### 12-A. 単体テスト（ソロ）

- [ ] `bob74_ipl` ensure 後にサーバー起動できる
- [ ] 起動ログに `bob74_ipl 起動確認 OK` が出る
- [ ] ヴェガと契約 → ゲート起動 → **北ヤンクトン中央広場にテレポート**
- [ ] 北ヤンクトン内で **雪が降る・寒色フィルター・街灯消灯**が効く
- [ ] 北ヤンクトン内で 3 ウェーブ戦闘ができる
- [ ] 北ヤンクトン内で `Config.LootSpawns` のアイテムが拾える
- [ ] `Config.ExtractPoints` の 3 箇所どれでも脱出できる
- [ ] 脱出後にヴェガ事務所（Mission Row）へ戻れる
- [ ] 帰還後、Mission Row 周辺が **綺麗な LS のまま**である

### 12-B. bucket 分離テスト（運営 + テスト用 1 名）

- [ ] テスト用キャラは **任務に参加せず** LS で待機（bucket 0）
- [ ] 運営キャラは **任務開始** → 北ヤンクトンへ
- [ ] 運営キャラがヘリで海上を飛び、座標 `(3217, -4834)` 付近を確認 → **北ヤンクトンが見える**
- [ ] テスト用キャラが同じ座標へヘリで飛ぶ → **海面のまま、北ヤンクトンは見えない**
- [ ] 両者が **互いを視認できない**（bucket 分離）

### 12-C. パフォーマンス

- [ ] resmon でクライアント定常 < 0.5 ms
- [ ] ロード時瞬間 < 3.0 ms
- [ ] サーバー側で複数セッション並行時に異常負荷なし

### 12-D. リソース restart 耐性

- [ ] 任務中に `restart jp-meridian9` してもプレイヤーが北ヤンクトンに残らない
- [ ] `onResourceStop` で `Transition.Leave()` が呼ばれて Enable(false) される

---

## 13. 完了条件

1. **bob74_ipl が ensure できる**状態でテストサーバーが起動できる
2. **ヴェガと契約 → ゲート → 北ヤンクトン到着** が成立
3. **bucket 0 のプレイヤーには北ヤンクトンが見えない**（最重要）
4. **任務 bucket 内のプレイヤー同士は互いに見える**
5. **帰還後、Mission Row のヴェガ事務所周辺が綺麗な LS** である
6. resmon 目標値内
7. `docs/FORMAL_POLICIES.md` / `docs/milestones.md` / `docs/design.md` / `docs/CREDITS.md` 更新済み
8. 開発日記追加 + コミット + push

---

## 14. 参考リンク

- [Bob74/bob74_ipl](https://github.com/Bob74/bob74_ipl)（MIT）
- [Bob74_ipl Wiki: North Yankton](https://github.com/Bob74/bob74_ipl/wiki/GTA-V:-North-Yankton)
- [alberttheprince/NorthYankton](https://github.com/alberttheprince/NorthYankton)（採用しないが参考実装として把握）
- [FiveM Cookbook: Routing Buckets](https://docs.fivem.net/docs/cookbook/2020/11/27/routing-buckets-split-game-state/)
- [FiveM 公式 Natives: RequestIpl](https://docs.fivem.net/natives/?_0x338E7EF52B6095A9=)

---

## 15. v1 → v2 の変更点（過去設計の記録）

| 項目 | v1（旧） | v2（本書） |
|---|---|---|
| 採用 MAP | The Apocalypse Project | **北ヤンクトン（バニラ）** |
| ベース | ymap 直配置（LS 内ジオメトリ置換） | **クライアントローカル IPL ロード** |
| 配置場所 | Sandy Shores 北部 / Mt. Chiliad | **LS 南西海上（独立 region）** |
| bucket 分離 | 不可能 | **可能（クライアントローカルネイティブの性質）** |
| 「車・ヘリで地続きアクセス」問題 | 残存 | **完全解消（海上区画）** |
| LICENSE | 不明（再配布リスク） | **MIT（bob74_ipl）＋バニラ** |
| ヴェガ事務所への影響 | 荒廃化避けられない | **完全に綺麗** |
| 工数 | 中（部分採用作業） | **中（IPL 連携＋座標精査）** |

v1（apocalypse_project 案）は **撤回**。clone した `jp-meridian9/map/apocalypse_project/` は削除予定（処理中のロックを解除して削除）。
