# INSTRUCTION-020 設計書：サイト・ナイン MAP 導入（**Cayo Perico 版・v3 / 確定**）

> 本タスクは `jp-meridian9/全体設計.txt` §7 M0 環境構築の積み残し。マスター実機検証により採用 MAP を確定。
>
> 採用変遷:
> - v1 The Apocalypse Project → 撤回（LS 内ジオメトリ置換で bucket 分離不可）
> - v2 North Yankton → 撤回（Prologue 専用ジオメトリ未完成、建物の横壁が無い、雪で移動が重い）
> - **v3 Cayo Perico（本書）= 確定**：完成度の高い熱帯島、海上独立、bucket × `SetIslandEnabled` で真の分離

---

## 0. 前提

| 項目 | 値 |
|---|---|
| 採用 MAP | **Cayo Perico**（GTA Online Heist DLC ステージ。GTA V 本体に標準同梱、build 2189+） |
| 地形 enable | **`SetIslandEnabled('HeistIsland', true/false)`**（クライアントローカルネイティブ、bob74_ipl 不要） |
| El Rubio 邸宅内装 | `bob74_ipl/dlc_cayoperico/base.lua` が `h4_ch2_mansion_final` IPL を起動時にロード済み |
| 配置座標 | 中心 約 `(4840, -5174, 2.0)`、メインビーチ `(4523, -4974, 4.5)`、邸宅 `(4985, -5765, 35)` |
| ライセンス | バニラ GTA V（Rockstar Games 著作物） + Bob74/bob74_ipl（MIT、内装 IPL 用） |
| 同梱方針 | bob74_ipl は本リポに同梱しない（運営者が GitHub から取得） |
| デプロイ先パス | `H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources\[jp-mods]\jp-meridian9` |

---

## 1. Cayo Perico 採用の根拠

### 1-A. 完成度の決定差

| 観点 | 北ヤンクトン (v2) | Cayo Perico (v3) |
|---|---|---|
| 建物ジオメトリ | ✗ 前面のみ・横壁欠落（Prologue 専用未完成） | ✓ 完成（GTA Online 商用 DLC） |
| 戦闘エリア | △ 街中心狭め、線形 | ✓ ジャングル・コンパウンド・ビーチ・滑走路の多層構造 |
| 床コンディション | ✗ 雪で移動減速 | ✓ 平地・砂浜・ジャングル |
| ミニマップ | ✗ LS 用のまま、北ヤンクトン MAP 出ない | ✓ Heist Island 用 MAP データ同梱 |

### 1-B. 「海の向こう」要件を完全に満たす

- LS から **直線距離 約 7 km の海上独立島**（座標 X≈4840）
- バニラでは **海面のみ**配置（GTA Online Heist DLC を有効化したクライアントのみ表示）
- **車・ヘリで物理的に行こうとしても海面しかなく**、ゲート転送以外でアクセス不可
- bucket 外プレイヤーには **完全に海**（任務 bucket 内だけ島がレンダリングされる）

### 1-C. 技術的優位（**v3 確定運用**）

- `SetIslandEnabled('HeistIsland', true)` は **クライアントローカルネイティブ**
- **重要な実装上の制約**: マスター実機検証（2026-05-15）で「`SetIslandEnabled(false)` を呼ぶと GTA V ストリーミングエンジン上で LS のメモリリーク・読み込み失敗が発生」と判明。動的 ON/OFF は実用に耐えない（FiveM コミュニティ公知の問題）。
- **対処**: クライアント起動時に `SetIslandEnabled('HeistIsland', true)` + `EnableMpDlcMaps(true)` を呼んで **常時 ON 固定**。Disable しない運用に確定。
- 結果として bucket 0 のプレイヤーにも海上に Cayo Perico が遠景として見えるが、ゲート転送以外で物理アクセスは不可（海上独立島）。世界観上は「Meridian-9 が次元観測している海上拠点が、ヴェガ事務所からの彼方に見える」と説明可能で、むしろ存在感が増す。
- **bucket 分離するのは演出のみ**（天気・時間・タイムサイクル・街灯）。地形は共通。
- `bob74_ipl` は El Rubio 邸宅内装と将来拡張のため依存維持。

### 1-D. 世界観適合（再解釈）

- 「**サイト・ナイン = 次元の歪みで現実世界から切り離された熱帯島**」
- 「**El Rubio の元秘密基地が異次元化、研究員 25 名はジャングル深部で失踪**」
- 「**Subject-0 はメインコンパウンド地下のサブマリン基地に眠る**」
- 夜と雷雨の演出で **熱帯ホラー**（インシデント・ゼロ系の不気味さは温度湿度演出で表現）
- ストーリー §「インシデント・ゼロ」「APERTURE-J」「Subject-0」「研究員失踪」と整合

---

## 2. スコープ

### 含む
- `SetIslandEnabled` を `Transition.Enter/Leave` に統合
- 排他制御（北ヤンクトン IPL との同時 enable 防止、開発検証期間中）
- `Config.Mission.spawnPoint` / `ExtractPoints` / `LootSpawns` を Cayo Perico 内座標に
- 演出（雷雨・夜・暗色フィルター）
- 起動チェック・ドキュメント整備

### 含まない
- ゲート転送演出（フェード／SFX）→ INSTRUCTION-017
- 査定 UI → INSTRUCTION-015
- El Rubio 邸宅内 NPC・ロアロケーション → 将来拡張

---

## 3. 確定事項

- **採用 MAP**: Cayo Perico（GTA V バニラ + GTA Online Heist DLC）
- **地形制御ネイティブ**: `SetIslandEnabled('HeistIsland', true/false)`（クライアントローカル）
- **bob74_ipl は採用継続**（El Rubio 邸宅内装 + 北ヤンクトン検証用 + 将来のロアロケーション拡張余地）
- **`Config.SiteNine.island = 'cayoperico'`** で MAP 種別を制御。`'northYankton'` も実装上残す（互換性）
- **演出**: 雷雨 (`THUNDER`)・22 時・青み (`phone_cam11`) で熱帯ホラー
- **`Config.SiteNine.blackout = false`**（Cayo Perico は元から街灯少ない、不要）
- **`Config.SiteNine.weather = 'THUNDER'`**（雷雨）
- **`Config.Mission.spawnPoint`**: 仮 `(4523.0, -4974.0, 4.5, 0.0)` メインビーチ（実機精査で確定）

---

## 4. 技術仕様

### 4-A. 採用する外部リソース

| リソース | 用途 | LICENSE |
|---------|------|---------|
| `bob74_ipl` | El Rubio 邸宅内装 IPL の自動ロード（既起動）、将来の内装拡張 | MIT |

`SetIslandEnabled` 自体はバニラネイティブ、追加リソース不要。

### 4-B. `SetIslandEnabled` の挙動（FiveM ドキュメント・実機検証）

```lua
-- 島を有効化（クライアントローカル、即時切替）
SetIslandEnabled('HeistIsland', true)

-- 島を無効化
SetIslandEnabled('HeistIsland', false)
```

- **クライアント単位**: 各クライアントが個別に有効化、サーバー介在なし
- **OneSync routing bucket と独立**: bucket 内のメンバーだけが個別に呼べば、その bucket だけ島が見える
- **ロード時間**: 距離ベースのストリーミング。プレイヤーが島座標に近いほど早く描画
- **要求 build**: `sv_enforceGameBuild 2189` 以上（現環境は 3258、OK）

### 4-C. `client/transition.lua` 拡張

```lua
local function applyCayoPerico()
    SetIslandEnabled('HeistIsland', true)
    State.islandEnabled = 'cayoperico'
end

local function clearCayoPerico()
    if State.islandEnabled == 'cayoperico' then
        SetIslandEnabled('HeistIsland', false)
        State.islandEnabled = nil
    end
end

local function applyIsland()
    local c = cfg()
    if c.island == 'cayoperico' then
        applyCayoPerico()
    elseif c.island == 'northYankton' then
        applyNorthYankton()
    end
end

local function clearIsland()
    clearCayoPerico()
    clearNorthYankton()
end

function MRD9.Transition.Enter()
    if State.active then return end
    State.active = true
    applyIsland()  -- 島の地形ロード開始
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
    clearIsland()
end
```

### 4-D. `TeleportToSiteNine` の島対応

既存の北ヤンクトン用 IPL ロード待ち (`waitIplsActive`) は **`Config.SiteNine.island == 'northYankton'` の時だけ**実行。Cayo Perico の場合は `SetIslandEnabled` 後に `NewLoadSceneStart` + `GetGroundZFor_3dCoord` だけで十分（IPL 連射より高速）。

### 4-E. サーバー側起動チェック（無変更）

`server/main.lua` の `bob74_ipl` 起動確認はそのまま残す（邸宅内装で使う）。

---

## 5. 座標設計

### 5-A. Cayo Perico 主要ロケーション（参考座標、実機精査で確定）

| ロケーション | 座標案 | 用途 |
|---|---|---|
| **メインビーチ（北東岸）** | `(4523.0, -4974.0, 4.5)` | **spawnPoint 第一候補** |
| **港（西側ドック）** | `(4520.0, -5160.0, 11.0)` | ExtractPoint |
| **滑走路南端** | `(5160.0, -5810.0, 17.0)` | ExtractPoint |
| **北側ジャングル丘陵** | `(4700.0, -5000.0, 30.0)` | ExtractPoint |
| **El Rubio 邸宅前** | `(4985.0, -5765.0, 35.0)` | LootSpawn 高レア |
| **メインコンパウンド門** | `(4760.0, -5500.0, 19.0)` | LootSpawn |
| **ビーチサイドバー（パーティ会場）** | `(4500.0, -4500.0, 4.0)` | LootSpawn |
| **コミュニケーションタワー** | `(4750.0, -5300.0, 35.0)` | LootSpawn 高レア |
| **地下サブマリン**（オフ島・別 IPL） | `(1560.0, 400.0, -50.0)` | ロアロケーション（将来） |

### 5-B. `Config.Mission`

```lua
Config.Mission = {
    timeLimitSeconds = 1200,
    bucketStart = 100,
    bucketEnd = 999,
    maxConcurrentSessions = 20,
    cleanupIntervalSeconds = 60,
    -- INSTRUCTION-020 v3: サイト・ナイン = Cayo Perico メインビーチ
    spawnPoint = vector4(4523.0, -4974.0, 4.5, 0.0),
    returnPoint = vector4(425.0, -979.3, 30.5, 270.0),  -- ヴェガ事務所前
    siteNineLoadWaitMs = 1500,  -- Cayo Perico は IPL 連射不要で短縮可
}
```

### 5-C. `Config.SiteNine`

```lua
Config.SiteNine = {
    -- 演出
    weather = 'THUNDER',                 -- 雷雨（熱帯ホラー）
    timeHour = 22,                       -- 夜 10 時
    timeMinute = 0,
    timeFreeze = true,
    timecycleModifier = 'phone_cam11',   -- 青み・コントラスト
    timecycleStrength = 0.85,
    blackout = false,                    -- Cayo Perico はもともと街灯少ない
    -- INSTRUCTION-020 v3: 島切替
    island = 'cayoperico',               -- 'cayoperico' | 'northYankton' | 'none'
    iplLoadWaitMs = 1500,                -- 北ヤンクトン時の RequestIpl 待ち
}
```

### 5-D. `Config.ExtractPoints`

```lua
Config.ExtractPoints = {
    { coords = vector3(4520.0, -5160.0, 11.0), label = '西港ドック',        radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(5160.0, -5810.0, 17.0), label = '南滑走路',          radius = 4.0, blipSprite = 488, blipColor = 5 },
    { coords = vector3(4700.0, -5000.0, 30.0), label = '北ジャングル丘陵',  radius = 4.0, blipSprite = 488, blipColor = 5 },
}
```

### 5-E. `Config.LootSpawns`（仮、実機精査前提）

```lua
Config.LootSpawns = {
    -- メインビーチ
    { coords = vector3(4523.0, -4974.0, 4.5),  weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    { coords = vector3(4490.0, -5050.0, 3.8),  weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    -- 港
    { coords = vector3(4520.0, -5160.0, 11.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(4470.0, -5180.0, 4.5),  weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    -- 北側ジャングル
    { coords = vector3(4700.0, -5000.0, 30.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(4760.0, -5150.0, 27.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    -- メインコンパウンド周辺
    { coords = vector3(4760.0, -5500.0, 19.0), weight = { common = 50, uncommon = 35, rare = 12, legendary = 3 } },
    { coords = vector3(4860.0, -5560.0, 22.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(4985.0, -5765.0, 35.0), weight = { common = 40, uncommon = 35, rare = 18, legendary = 7 } }, -- 邸宅
    -- ビーチサイドバー
    { coords = vector3(4500.0, -4500.0, 4.0),  weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    -- コミュニケーションタワー（高レア寄り）
    { coords = vector3(4750.0, -5300.0, 35.0), weight = { common = 40, uncommon = 35, rare = 18, legendary = 7 } },
    -- 滑走路
    { coords = vector3(5160.0, -5810.0, 17.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(5050.0, -5650.0, 15.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
    -- ジャングル深部
    { coords = vector3(4900.0, -5200.0, 28.0), weight = { common = 60, uncommon = 30, rare = 8,  legendary = 2 } },
    { coords = vector3(4830.0, -5100.0, 24.0), weight = { common = 70, uncommon = 25, rare = 4,  legendary = 1 } },
}
```

---

## 6. ファイル変更

| ファイル | 変更 |
|---------|------|
| `jp-meridian9/config.lua` | `Config.Mission.spawnPoint` を Cayo Perico へ、`Config.SiteNine` を熱帯ホラー演出に、`island='cayoperico'` 追加。`Config.ExtractPoints` / `Config.LootSpawns` を Cayo Perico 内座標へ |
| `jp-meridian9/client/transition.lua` | `applyCayoPerico` / `clearCayoPerico` 追加。`applyIsland` / `clearIsland` で `Config.SiteNine.island` 分岐 |
| `jp-meridian9/server/main.lua` | 既存の `bob74_ipl` 起動チェックは維持（邸宅内装で使用） |
| `jp-meridian9/server/session.lua` | `TransferIn` テレポート委譲（v2 で実装済み・無変更） |
| `jp-meridian9/README.md` | サイト・ナイン MAP 導入手順を Cayo Perico に書き直し |
| `jp-meridian9/docs/CREDITS.md` | 採用 MAP を Cayo Perico に書き直し、北ヤンクトンは「検証期間中の代替案として実装したが採用見送り」と記録 |
| `jp-meridian9/docs/FORMAL_POLICIES.md` | INSTRUCTION-020 を v3 に書き直し |
| `jp-meridian9/docs/milestones.md` | M0 INSTRUCTION-020 完了（Cayo Perico 版）を反映 |
| `jp-meridian9/docs/design.md` | 「サイト・ナイン MAP」現状節を Cayo Perico に更新 |

---

## 7. 着手順序

1. ✅ マスター承認（Cayo Perico 確定）
2. 設計書 v3 を `docs/INSTRUCTION-020...md` に保存（本書）
3. `config.lua` 変更（spawnPoint / ExtractPoints / LootSpawns / SiteNine）
4. `client/transition.lua` 変更（`applyCayoPerico` / `applyIsland` / 分岐）
5. ドキュメント整備（README / CREDITS / FORMAL_POLICIES / milestones / design）
6. `scripts/deploy.bat jp-meridian9` でテストサーバーへ反映
7. **マスター実機テスト**:
   - 任務開始 → 雷雨の Cayo Perico メインビーチに着地
   - 3 ウェーブ戦闘
   - 港 / 滑走路 / 丘陵のいずれかから脱出
   - ヴェガ事務所へ綺麗に帰還
8. **マスターから座標精査の vector4 集**を受領（任務開始地・脱出 3 ヶ所・ルート 5〜15 ヶ所）
9. `Config.Mission.spawnPoint` / `Config.ExtractPoints` / `Config.LootSpawns` を実機座標で確定
10. 開発日記 + コミット + push

---

## 8. パフォーマンス目標

- **クライアント resmon**：
  - `SetIslandEnabled` 後のロード瞬間 < 2.0 ms（IPL 連射しない分、北ヤンクトン版より軽い）
  - 任務中定常 < 0.5 ms
  - 任務外 < 0.05 ms
- **サーバー resmon**：< 1.0 ms

---

## 9. セキュリティ・権威

- `SetIslandEnabled` はクライアントローカル、サーバー権威の対象外
- bucket 外プレイヤーが手元で `SetIslandEnabled('HeistIsland', true)` を呼んでも、座標 (4840, -5174) に居なければ何も見えない（既存 LS のまま）
- 任務 bucket への参加・テレポート・インベントリはサーバー権威（`fivem-server-authority.mdc` 準拠）

---

## 10. RP 整合・世界観

### ストーリー再解釈（`ストーリー.txt` 無改変で整合）

- 「**サイト・ナイン**」＝ **次元の歪みで現実世界から切り離された熱帯島**
- 「**APERTURE-J ゲート**」＝ ヴェガ事務所地下のゲート、座標を Cayo Perico メインビーチへワープ
- 「**インシデント・ゼロ**」＝ 27 名の研究チームが Cayo Perico の El Rubio 元秘密基地で観測活動中、47 分後通信途絶
- 「**Subject-0**」＝ メインコンパウンド地下のサブマリン基地（地下倉庫）に眠る
- 「**夜と雷雨**」＝ 第 9 次元の異常気象。本来熱帯島だが、次元の歪みで天候が異常化
- 「**前任研究員の遺品**」＝ ビーチ・港・ジャングル・邸宅・通信塔に散在

### `ストーリー.txt` との整合

- 「Sandy Shores 郊外の地下施設に APERTURE 建造」→ そのまま（本社の本格ゲート）
- 「Mission Row の路地裏オフィス + APERTURE-J」→ そのまま（小型ゲート、行き先は Cayo Perico）
- 「次元観測装置」→ Cayo Perico は **観測した第 9 次元**、本社 APERTURE が観測点、APERTURE-J が転送装置
- 「**過去最高は一回の任務で 25 万ドル相当**」→ El Rubio 邸宅の高価値遺品で実現

---

## 11. リスク・既知の罠

| リスク | 対策 |
|---|---|
| `SetIslandEnabled` のロード遅延 | `NewLoadSceneStart` + `GetGroundZFor_3dCoord` 待機（既存実装） |
| 仮 spawnPoint が海面・岩場 | 実機精査で確定（`m9_cayo coords` で取得） |
| Cayo Perico の地下サブマリン (Z=-50) はオフ島座標 | ロアロケーションとして将来利用、現状の任務エリアには含めない |
| GTA build 要件 | サーバー `sv_enforceGameBuild 3258`（既設定、要件 2189+ 以上）OK |
| El Rubio 邸宅内装の境界 | `bob74_ipl/dlc_cayoperico/base.lua` で起動時ロード済み。任務 bucket 内で問題なく動く |

---

## 12. テスト観点

### 12-A. 単体テスト（ソロ）

- [ ] `restart jp-meridian9` で起動エラーなし
- [ ] 起動ログに `bob74_ipl 起動確認 OK` が出る
- [ ] ヴェガ依頼 → ゲート → **Cayo Perico メインビーチ**にフェードイン
- [ ] 雷雨・夜・青いフィルターが効く
- [ ] 3 ウェーブ戦闘ができる（敵 AI が島内で正常動作）
- [ ] LootSpawns 15 ヶ所からアイテム取得
- [ ] ExtractPoints 3 ヶ所どれでも脱出できる
- [ ] 脱出後にヴェガ事務所（Mission Row）へ綺麗に帰還
- [ ] Mission Row 周辺が綺麗な LS のままである

### 12-B. bucket 分離テスト（運営 + テスト用 1 名）

- [ ] テスト用は LS で待機（bucket 0）
- [ ] 運営は任務開始 → Cayo Perico へ
- [ ] 運営がヘリで海上を飛び、座標 `(4840, -5174)` 付近 → **Cayo Perico の島が見える**
- [ ] テスト用が同座標へ飛ぶ → **海面のまま、島は見えない**
- [ ] 両者が互いを視認できない（bucket 分離）

### 12-C. パフォーマンス

- [ ] resmon クライアント定常 < 0.5 ms
- [ ] ロード瞬間 < 2.0 ms

### 12-D. リソース restart 耐性

- [ ] 任務中に `restart jp-meridian9` してもプレイヤーが Cayo Perico に残らない
- [ ] `onResourceStop` で `Transition.Leave()` → `SetIslandEnabled(false)`

---

## 13. 完了条件

1. `SetIslandEnabled` ベースで Cayo Perico に転送可能
2. ヴェガ依頼 → 雷雨の Cayo Perico ビーチに到着
3. bucket 0 のプレイヤーには **島が見えない**（最重要）
4. 帰還後、Mission Row のヴェガ事務所周辺が綺麗な LS
5. resmon 目標値内
6. 実機精査による座標確定（spawnPoint / ExtractPoints / LootSpawns）
7. ドキュメント更新済み
8. 開発日記 + コミット + push

---

## 14. 参考リンク

- [FiveM 公式 Natives: SetIslandEnabled](https://docs.fivem.net/natives/?_0xCAA6E25F7E92B2F0)
- [Bob74/bob74_ipl](https://github.com/Bob74/bob74_ipl)（MIT、El Rubio 邸宅内装用）
- [FiveM Cookbook: Routing Buckets](https://docs.fivem.net/docs/cookbook/2020/11/27/routing-buckets-split-game-state/)
- [Cayo Perico Heist DLC（Rockstar Games 公式）](https://www.rockstargames.com/newswire/article/k57o5o89aaa3ko/the-cayo-perico-heist-now-available-in-gta-online)

---

## 15. v1 → v2 → v3 の変更履歴

| バージョン | 採用 MAP | 撤回理由 |
|---|---|---|
| v1 | The Apocalypse Project | LS 内 ymap 直配置で bucket 分離不可、地続きアクセス問題 |
| v2 | North Yankton（GTA V Prologue） | ジオメトリ未完成（建物の横壁欠落、Prologue 専用エリア）、雪で移動減速、ミニマップ非対応 |
| **v3** | **Cayo Perico**（GTA Online Heist DLC） | **採用確定**：完成度・bucket 分離・「海の向こう」要件すべて満たす |

v2 までの北ヤンクトン実装（`applyNorthYankton` / `m9_ny` デバッグコマンド）は **コード上は残す**（将来のロアロケーション・ホラー演出付加の余地）。`Config.SiteNine.island` で切替可能にして互換性を担保。
