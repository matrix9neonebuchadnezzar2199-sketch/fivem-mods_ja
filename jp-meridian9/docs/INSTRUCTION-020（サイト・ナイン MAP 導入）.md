# INSTRUCTION-020 設計書：サイト・ナイン MAP 導入（M0 積み残し）

> 本タスクは `jp-meridian9/全体設計.txt` の §2.1 / §2.3 / §7 M0 環境構築で「The Apocalypse Project を導入」と明記されていたが、INSTRUCTION-001〜019 を進める間 **未完了のまま放置されていた M0 積み残し作業**。新規スコープ追加ではなく、設計書通りに戻すための再着手。
>
> ファイル名は Windows で `/` が使えないため全角中点を使用。

---

## 0. 前提

- 採用 MAP: **[Arcainex/The-Apocalypse-Project](https://github.com/Arcainex/The-Apocalypse-Project)**
- README に **「FREE」「by the community for the community」** と明示
- LICENSE ファイル無し → GitHub デフォルトでは「全権利留保」扱いだが、README の明示で **利用は OK**、**再配布は明示許可なし**
- 関連 INSTRUCTION-017（ゲート転送演出）と分担：本 020 は **MAP 導入**、017 は **転送演出（フェード・SFX・パーティクル）**

---

## 1. The Apocalypse Project の構成（GitHub 実調査）

GitHub API で各サブフォルダの内容を確認した結果（2026-05-15 時点）。

### `assets_map`（地域別ジオメトリ差し替え・大）

| サブフォルダ | 主な ymap / 内容 | 想定影響範囲 |
|---|---|---|
| `Factory` | `Savfactory.ymap`, `cs5_3.ymap` | Sandy Shores 北東の工場地帯 |
| `[Barriers]` | ハイウェイバリア各種 `.ytd` | 全島の高速道路 |
| `[CountyUpgrade]` | `Eastern Highway Part 1〜3`, `Harmony Forest`, `Paleto Bay Part 1` 等 | **東部ハイウェイ・ハーモニー・パレト一帯** |
| `[DestroyedBldg]` | `dt1_18_*`（downtown 1 ブロック 18） | **ダウンタウン中心（Mission Row 近接）** |
| `[Mine]` | `cs6_08_minelight_*` | Grand Senora Desert の鉱山 |
| `casino` | `casinolot.ymap`, `hei_ch3_12_*` | **Diamond Casino 周辺（Vinewood Hills）** |
| `paleto` | `paleto.ymap`, `paleto2.ymap`, `hei_cs2_roadsa.ymap` | **Paleto Bay 中心市街** |
| `sak` | `mirrorroads.ymap` | （詳細不明、おそらく郊外） |

### `assets_map2`（メイン荒廃エリア）

| サブフォルダ | 内容 |
|---|---|
| `BendTunnel` | 曲がりトンネル |
| `DeadOrAlive` / `DeadOrAlive_props` | **メイン荒廃ジオメトリ＋小物** |
| `Metro` | 地下鉄路線 |
| `[Highway]` / `[Highway2]` | 改造ハイウェイ |
| `[TheFalloftheBridge]` | 崩落した橋 |

`fxmanifest.lua` で `DLC_ITYP_REQUEST`: `v_metro_sections`, `sm_20_interior_sm20_tun1`, `sm_20_interior_sm20_tun4`（地下鉄系インテリア参照）

### `assets_map3`（DeadOrAlive 続編）

| サブフォルダ | 内容 |
|---|---|
| `DeadOrAlive2` / `3` / `4` | `assets_map2/DeadOrAlive` の続編エリア |

### `postapo-interior`（廃ビル内部）

`_manifest.ymf` + 標準 GTA インテリア参照 `.ytyp`（`v_int_7/10/22/28/38/46/49/51/66`）。**廃ビル内部に入れるようにする補助**。`__resource.lua` 形式（古い manifest）。

---

## 2. 技術的制約：**bucket 単位の荒廃分離は不可能**

マスター指示「方式 (I) bucket 内だけ荒廃」の実装可否を調査した結果。

| 候補手法 | 可否 | 理由 |
|---|---|---|
| **routing bucket** | ❌ | エンティティ・プレイヤー同期のみ。**ワールドジオメトリ（ymap）は対象外** |
| **`RequestIpl` / `RemoveIpl`** | ❌（本 MAP では） | IPL 名で IPL 単位のロード制御は可能だが、**The Apocalypse Project は ymap ベースで IPL 切替対応していない**。各 ymap の `_manifest.ymf` が起動時に登録される構造 |
| **`EnableMpDlc` 系** | ❌ | DLC 単位の有効化。MAP リソース粒度ではない |
| **クライアントごとの ymap 読み込み制御** | ❌ | ymap は streaming engine が座標に応じてグローバルに配信。プレイヤー別状態を持てない |

**結論**：The Apocalypse Project を `ensure` した時点で、**全クライアントが荒廃 LS を見る**ことが避けられない。

---

## 3. 採用案の比較

設計書 §3.1 の状態遷移（IDLE＝通常 LS / IN_MISSION＝サイト・ナイン）を成立させる現実解。

| 案 | 内容 | 設計書整合 | 工数 | リスク |
|----|------|----------|------|------|
| **(I) bucket 内分離** | クライアント別 ymap ロード | — | — | **技術的不可能** |
| **(II) 全 ensure・常時荒廃** | 4 リソース全部 ensure | △ 世界観改変（LS 全体が荒廃済み） | 小 | ヴェガ事務所周辺も荒廃化 |
| **(III) ymap 座標オフセット** | ymap を別座標（海上・離島）に hex 改変 | ◎ 完全分離 | **大**（労力＋著作権リスク） | The Apocalypse Project の改変は LICENSE 明示なしのため再配布不可問題が再燃 |
| **(IV) 部分採用** | **ヴェガ事務所周辺（Mission Row / downtown）に影響する** `[DestroyedBldg]` `casino` 等を除外して ensure | ○ ヴェガ事務所は綺麗、Sandy Shores 北部以遠が荒廃 | 中 | RP 設定の補正が必要 |

### 採用：**(IV) 部分採用**

理由：
- (I) は不可能、(III) は労力＋著作権リスク
- (II) は世界観が「LS 全体が荒廃した別の世界線」になり、`ストーリー.txt` の「Mission Row の路地裏オフィス（綺麗な街）」と衝突
- (IV) なら **「サイト・ナイン＝ロスサントス北部の人類撤退・隔離区域」** と再定義でき、設計書の「次元の歪みでこの区域だけ別次元から漏れ出した」と整合させやすい

### (IV) で **除外する** サブリソース／フォルダ（暫定）

| フォルダ | 除外理由 |
|---|---|
| `assets_map/[DestroyedBldg]` | **dt1_18 = downtown 1**。ヴェガ事務所（Mission Row, 約 (427, -979)）の至近に影響 |
| `assets_map/casino` | Vinewood Hills の Diamond Casino。市街地に近接 |
| `assets_map/paleto` | Paleto Bay 中心市街。任務スポーン候補地に近いが、RP 上「街中は綺麗」を優先 |

### (IV) で **採用する** サブリソース／フォルダ（暫定）

| リソース／フォルダ | 採用理由 |
|---|---|
| `assets_map/Factory` | Sandy Shores 北東の廃工場（任務スポーン候補） |
| `assets_map/[CountyUpgrade]` | 郊外ハイウェイ・森林（移動経路の演出） |
| `assets_map/[Mine]` | Grand Senora 鉱山（任務スポーン候補） |
| `assets_map/[Barriers]` | ハイウェイバリア（演出補強） |
| `assets_map/sak` | mirrorroads（要実機確認） |
| `assets_map2/*` 全て | **メイン荒廃 MAP**（DeadOrAlive 一帯）。座標が街中なら一部削除検討 |
| `assets_map3/*` 全て | DeadOrAlive 続編。同上 |
| `postapo-interior` | 標準インテリアの廃ビル化補助。市街地への影響は限定的 |

> 上記は**実機で見るまで暫定**。マスターと一緒に実機検証→確定する。

---

## 4. 配布・同梱方針

- **本リポには同梱しない**（LICENSE 不明・再配布リスク回避）
- `resources/[maps]/apocalypse_project/` は `.gitignore` で除外
- 運営者は GitHub から直接 clone：

```powershell
cd C:\FiveMServer\server-data\resources
mkdir [maps] -ErrorAction SilentlyContinue
cd [maps]
git clone https://github.com/Arcainex/The-Apocalypse-Project.git apocalypse_project
# 不要フォルダの削除（INSTRUCTION-020 §3 (IV) で除外したもの）
Remove-Item apocalypse_project/assets_map/stream/[DestroyedBldg] -Recurse -Force
Remove-Item apocalypse_project/assets_map/stream/casino -Recurse -Force
Remove-Item apocalypse_project/assets_map/stream/paleto -Recurse -Force
```

`server.cfg` 抜粋:

```
ensure assets_map
ensure assets_map2
ensure assets_map3
ensure postapo-interior
ensure jp-meridian9
```

`postapo-interior` は古い `__resource.lua` 形式なので注意（cerulean 以降の FiveM では `resource_manifest_version` 行で動作可能）。

---

## 5. 影響範囲とファイル変更

| ファイル | 変更 |
|---------|------|
| `jp-meridian9/fxmanifest.lua` | `dependencies`（または起動チェック）に MAP リソース名を **オプショナル**として扱う（未 ensure でも警告のみ） |
| `jp-meridian9/config.lua` | `Config.Mission.spawnPoint` を **MAP 内の安全地帯**に更新。`Config.ExtractPoints` / `Config.LootSpawns` を MAP 内座標に再配置 |
| `jp-meridian9/server/main.lua` | 起動時に `GetResourceState('assets_map')` 等を確認し、未起動なら `[WARN] サイト・ナイン MAP が未導入。演出のみで動作` を出す |
| `jp-meridian9/.gitignore` 系（リポルート `.gitignore`） | `resources/[maps]/` 配下は jp-meridian9 のリポにはそもそも含まれないので変更不要（本リポは MOD 単体で、テストサーバー側 `[maps]/` はリポ管理外） |
| `jp-meridian9/README.md` | 「**5. サイト・ナイン MAP 導入手順**」セクション新設。GitHub URL・除外フォルダリスト・`server.cfg` 抜粋 |
| `jp-meridian9/docs/CREDITS.md` | Arcainex / The Apocalypse Project / 寄与者（denedwin, miltonalves, YopatPA, All_NightGamer, Limu, MrAvenue, Fr0zzty23, Savolent, Michal10d）を追記 |
| `jp-meridian9/docs/FORMAL_POLICIES.md` | INSTRUCTION-020 の正本セクション追記：「外部 MAP は本リポに同梱しない」「サイト・ナイン＝ロスサントス北部荒廃区域」「bucket 単位荒廃は技術的不可能の記録」 |
| `jp-meridian9/docs/design.md` | M0 積み残し完了の旨を反映 |
| `jp-meridian9/docs/milestones.md` | M0 を完了状態に更新（INSTRUCTION-020 紐付け） |
| `jp-meridian9/client/transition.lua` | INSTRUCTION-014 追補で入れた `Config.SiteNine` 演出（雪・寒色フィルター・街灯消灯）は **そのまま残す**。MAP の上に重ねる補助演出として位置付け |

---

## 6. 推奨座標案（実機確認前の暫定）

ヴェガ事務所（Mission Row, 約 `(427, -979)`）から離れた荒廃区域内の候補。

| ロール | 座標案 | 補足 |
|------|--------|------|
| **任務スポーン** `Config.Mission.spawnPoint` | `vector4(2960.0, 2810.0, 50.0, 0.0)` 付近 | Grand Senora Desert の鉱山地帯 |
| **代替候補** | `vector4(2400.0, 4750.0, 35.0, 0.0)` 付近 | Sandy Shores 北東の廃工場（cs5_3） |
| **代替候補** | `vector4(1972.0, 3818.0, 33.4, 0.0)` | 既存暫定値。MAP 内なら継続使用も可 |
| **`Config.ExtractPoints`** | 上記スポーンの北・南・東 各 ~500m | 既存と同じ思想で 3 箇所 |
| **`Config.LootSpawns`** | スポーン半径 200〜400m 圏内に 15 箇所程度 | 既存の `pickRadialLootCoords` フォールバックも継続動作 |

> 実機で見ながら座標確定。**マスターと一緒に決める**作業。

---

## 7. 起動チェック実装案

```lua
-- server/main.lua（起動スレッド内）
local function checkApocalypseMap()
    local resources = { 'assets_map', 'assets_map2', 'assets_map3', 'postapo-interior' }
    local missing = {}
    for _, r in ipairs(resources) do
        if GetResourceState(r) ~= 'started' then
            missing[#missing + 1] = r
        end
    end
    if #missing == 0 then
        print('[jp-meridian9] (server) サイト・ナイン MAP 導入確認 OK')
        return true
    end
    print(('[jp-meridian9] (server) [WARN] サイト・ナイン MAP 未導入: %s。演出のみで動作（INSTRUCTION-020 §4 参照）'):format(table.concat(missing, ', ')))
    return false
end
```

`Config.SiteNine.installed` フラグでクライアントへ通知し、クライアントは MAP 有無に応じてカメラ初期演出を出し分ける（後段の演出強化で使う）。

---

## 8. RP 設定の補正

`ストーリー.txt` を **無改変** で整合させるための解釈：

- 「**第 9 次元**」＝ロスサントス北部の人類撤退・隔離区域
- 「**APERTURE-J**」＝ヴェガ事務所地下のゲートが、地理的に閉鎖されたこの区域へ転送する
- ロスサントスの **市街地（Mission Row／ダウンタウン／カジノ／パレト中心）は綺麗なまま** で、当初構想の「裏稼業 + 法律事務所」の二重生活が成立
- 区域内（Sandy Shores 北以遠）は「次元の歪みで現実が変質した区域」とすると、世界観破綻なく雪・寒色・荒廃ジオメトリが説明できる

---

## 9. テスト観点

- [ ] `assets_map`/`assets_map2`/`assets_map3`/`postapo-interior` を ensure してサーバー起動可
- [ ] ヴェガ事務所（Mission Row）に立ったとき、**周辺が綺麗なまま**である
- [ ] 任務スポーン地点で **荒廃景色** が見える
- [ ] サイト・ナインから帰還後、ヴェガ事務所に **綺麗に戻れる**
- [ ] `resmon` でストリーミング負荷が許容内
- [ ] 既存 ESX/QBCore リソース（建物配置系）と衝突しない（マスターの実環境で要確認）
- [ ] `Config.SiteNine.installed = false`（MAP 未導入）でも従来通り起動できる（演出だけ動作）

---

## 10. リスク・既知の罠

- The Apocalypse Project の **最終コミットが古い**（2 年以上前）。FiveM 本体の API 変更で破綻する可能性。代替候補（`Apocalyptic Sandy Shores`, `Dead Town`, `Wasteland LA` 等）も控えに把握しておく
- LICENSE 不明 → 将来 GitHub から削除される可能性。**本リポにフォーク／同梱しない理由**でもある
- `postapo-interior` の `__resource.lua` は古い形式。FiveM Cerulean 以降で動作するか実機確認
- `assets_map2` の `DeadOrAlive` の座標が市街地に重なる可能性。実機で確認して衝突するなら追加除外
- 既存サーバーリソース（街中の Custom MLO・住宅 MOD 等）と ymap が衝突する可能性。**マスターの環境で実機確認**

---

## 11. 着手順序

1. **マスター承認**（本設計書の §3 採用案・§5 影響範囲）  
2. The Apocalypse Project を マスターのテストサーバー `resources/[maps]/apocalypse_project/` に clone  
3. § 4 の除外フォルダを削除  
4. `server.cfg` に `ensure` 追記、起動して **ヴェガ事務所周辺が荒廃しないか確認**（衝突あれば追加除外）  
5. `Config.Mission.spawnPoint` を MAP 内へ更新  
6. `Config.ExtractPoints` / `Config.LootSpawns` を MAP 内に再配置  
7. `fxmanifest.lua` 起動チェック追加  
8. `README.md` / `docs/CREDITS.md` / `docs/FORMAL_POLICIES.md` / `docs/milestones.md` / `docs/design.md` 更新  
9. 開発日記追記＋コミット＋push

---

## 12. 完了条件

1. 4 リソース ensure 後にサーバーが起動できる
2. **ヴェガ事務所が綺麗**（Mission Row 周辺が荒廃しない）
3. **任務スポーン地点で荒廃景色が出る**
4. 脱出してヴェガ事務所に綺麗に帰還できる
5. `resmon` クライアント時 < 5ms、サーバー < 1ms
6. `docs/FORMAL_POLICIES.md` に正本セクション
7. `docs/milestones.md` で M0 完了
8. 開発日記 + コミット + push
