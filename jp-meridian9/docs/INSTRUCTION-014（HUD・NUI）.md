# INSTRUCTION-014 設計書：HUD / NUI

> このドキュメントは **実装 AI が自走できる粒度** で記述する。前提・確定事項・未確定の Q を分離し、未確定 Q はマスター回答後に確定欄を埋めて着手する。
>
> ファイル名は Windows で `/` が使えないため `INSTRUCTION-014（HUD・NUI）.md` とする。

---

## 0. 前提（リポジトリ正本との突合）

- 関連ルール: `.cursor/rules/fivem-nui.mdc`、`.cursor/rules/fivem-perf.mdc`、`.cursor/rules/fivem-server-authority.mdc`、`AGENTS.md`（i18n 節）
- 既存ファイル
  - `jp-meridian9/client/hud.lua` … 1 行スタブ（`-- HUD 連携（INSTRUCTION-014）`）
  - `jp-meridian9/html/index.html` … ロゴ + 「HUD は INSTRUCTION-014 で拡張予定です」のヒント
  - `jp-meridian9/html/style.css` … `#app { pointer-events: none }` のオーバーレイ枠
  - `jp-meridian9/html/app.js` … `type: 'open' / 'close'` の 2 メッセージのみ受信
  - `Config.HUD` … `updateInterval=500` / `showPartyHP=true` / `showTimer=true` / `showInventory=true`
- 既存 NUI は **フォーカス取得しないオーバーレイ**（`SetNuiFocus(false, false)` のまま `SendNUIMessage` で更新する設計を踏襲）
- ロケールはサーバー側 `Config.Locale = 'ja'` 固定（INSTRUCTION-014 では英語切替を実装しない方針）

---

## 1. スコープ

| 項目 | 含む / 含まない |
|------|------|
| ミッション中 HUD（タイマー / 自分 HP / パーティ HP / インベントリ / ウェーブ） | **含む** |
| 脱出ゾーン進入時の HUD 表示 | **含む**（ただし `lib.progressCircle` は INSTRUCTION-013 のまま流用） |
| ロード / 査定 / 報酬画面 | **含まない**（INSTRUCTION-015） |
| 蘇生 UI | **含まない**（INSTRUCTION-016） |
| 死亡時のロスト演出 | **含まない**（INSTRUCTION-016） |
| 言語切替 UI（ja / en） | **含まない**（将来追加余地は残す） |
| 設定画面 / メインメニュー | **含まない** |
| NPC 対話 UI | **含まない**（INSTRUCTION-009 で `lib.registerContext` 採用済み） |

---

## 2. 確定事項

- **オーバーレイのみ**：`SetNuiFocus(false, false)` のまま運用。マウス・キーボードのフォーカスは取らない。
- **`MRD9.CurrentSession == nil` の間は HUD を隠す**（`onMissionStart` で開く、`onMissionEnd` で閉じる）。
- **イベント名規約**：`jp-meridian9:client:hud:*` / `jp-meridian9:server:hud:*`（既存命名と整合）。
- **NUI ↔ Lua プロトコル**：`SendNUIMessage` は **`type` ディスパッチ**（`m9_hud_show` / `m9_hud_hide` / `m9_hud_locale` / `m9_hud_state` / `m9_hud_event`）。定期更新の本体は `m9_hud_state`（`fivem-nui.mdc` の `type` 駆動に整合）。
- **i18n**：`html/app.js` 内で `STR.ja` 辞書を持ち、`t(key)` を関数化。将来 `en` を追加するときは `STR.en` を埋める。INSTRUCTION-014 では `ja` のみで可。

---

## 3. 設計 Q（確定済み・マスター回答反映）

> 本節はマスター回答済み。**実装は以下の確定案に従う。**

### Q1: パーティ HP のソース

| 案 | 内容 | 採用 |
|----|------|------|
| (a) サーバー側の **`server/hud.lua` を新設**し、500ms 周期で各バケット内メンバー全員の `GetEntityHealth` / `GetPedArmour` を集約 → 各メンバーへ broadcast | **推奨**。中央集権・整合性が良い。OneSync 下でサーバー側からのネイティブが使えない場合は (b) | 採用 |
| (b) クライアント側でリーダーが集約し、`TriggerLatentClientEvent` で配信 | リーダー負担。サーバーよりはレイテンシ予測しにくい |  |
| (c) 各クライアントが自分の HP のみ送信し、サーバーは中継するだけ | シンプル。但しクライアント改ざんに弱い（HUD 表示用なら許容） |  |

**確定: (a)** — `server/hud.lua` + `jp-meridian9:client:hud:state`。

### Q2: HUD のインベントリ表示

| 案 | 内容 | 採用 |
|----|------|------|
| (α) アイテム総数（数字 1 個）と **レアリティ別カウンタ**（C/U/R/L） | 軽量・視認性高い・**推奨** | 採用 |
| (β) アイテムごとの個別リスト（最大 N 行） | 詳細だが画面が混む。HUD 用には情報過多 |  |
| (γ) 合計値（推定 $）のみ | プレイヤー判断に有用だが、査定基準ぶれの誤解を招く |  |

**確定: (α)** — `inventory.total` + `inventory.byRarity`、NUI は `Config.HUD.inventoryMode` に追従。

### Q3: 自分 HP の表示形式

| 案 | 内容 | 採用 |
|----|------|------|
| (i) GTA 既定 HP バーを残し、HUD には数値のみ表示 | GTA UI と二重表示だが安全 |  |
| (ii) GTA 既定 HP バーを **隠して**、NUI でカスタムバー表示 | 雰囲気は出るが GTA UI 操作が増える（`HudWeapon` 等は残す） |  |
| (iii) HUD には数値もバーも出さず、パーティ HP リストの最上段に自分を含める | 最小構成・**推奨**（情報の重複を避ける） | 採用 |

**確定: (iii)** — パーティ一覧先頭が自分（`isSelf`）。数値は **HP/最大・AP** のコンパクト表示（バーなし）。

### Q4: ウェーブ表示

| 案 | 内容 | 採用 |
|----|------|------|
| (A) 画面中央上にバナー「WAVE 2 / 3 — 7 体残存」（**推奨**） | アリーナ系の定番。雰囲気がエクストラクション系 | 採用 |
| (B) 右下に小さなインジケーター | 控えめ |  |
| (C) ウェーブ開始時 / クリア時のみ大バナー、平常時は非表示 | 演出寄り |  |

**確定: (A)** — `arena` スナップショット（`MRD9.Arena.GetHudSnapshot`）を `m9_hud_state` に同梱。`Config.HUD.showWaveBanner` で抑止可。

### Q5: 脱出ゾーン進入時の HUD

| 案 | 内容 | 採用 |
|----|------|------|
| (I) **`lib.showTextUI` のまま**変更なし（INSTRUCTION-013 の挙動を維持） | シンプル | 採用 |
| (II) HUD 側にも「脱出可能: ◯◯」のサブバッジを出す（`lib.showTextUI` と併用）| 二重表示。視線誘導は強い |  |
| (III) `lib.showTextUI` を撤去し HUD バッジに統一 | 統一感は高いが INSTRUCTION-013 を巻き戻す |  |

**確定: (I)** — `client/extract.lua` に HUD 脱出バッジは追加しない。

### Q6: 配信周期

| 値 | 用途 |
|----|------|
| `Config.HUD.tickServerMs`（既定 500） | サーバー → クライアントの HP / アーマー集約 |
| `Config.HUD.tickClientMs`（既定 250） | NUI への自分 HP / タイマー差分送信 |
| `Config.HUD.tickRenderMs`（既定 100） | NUI 内アニメーション（CSS で完結する分は不要） |

**確定: 既定値のまま** — `tickServerMs=500` / `tickClientMs=250` / `tickRenderMs=100`（レンダリング用途は現状未使用）。

---

## 4. データモデル

### 4-A. クライアント内集約状態（`MRD9.HUDClient`）

```lua
MRD9.HUDClient = {
    visible = false,
    session = {
        sessionId = '',
        timerSec = 0,             -- 残り秒
        endsAtMs = 0,             -- GetGameTimer() ベースの絶対値
    },
    self = {
        src = 0,
        hp = 100,
        maxHp = 200,
        armor = 0,
    },
    members = {                   -- 自分含む
        -- [src] = { name = 'Foo', hp = 100, maxHp = 200, armor = 0, alive = true, isLeader = true, isSelf = false }
    },
    inventory = {
        total = 0,
        byRarity = { common = 0, uncommon = 0, rare = 0, legendary = 0 },
        -- Q2=(β) の場合のみ: items = { { id, name, qty, rarity } }
    },
    arena = {
        active = false,
        wave = 0,
        totalWaves = 0,
        zombiesAlive = 0,
    },
    extract = {
        active = false,
        label = '',
    },
}
```

### 4-B. サーバー → クライアント DTO（`m9_hud_state`）

```ts
type HudStateDTO = {
    sessionId: string;
    timerSec: number;
    self: { hp: number; maxHp: number; armor: number };
    members: Array<{
        src: number;
        name: string;
        hp: number;
        maxHp: number;
        armor: number;
        alive: boolean;
        isLeader: boolean;
        isSelf: boolean;
    }>;
    inventory: {
        total: number;
        byRarity: { common: number; uncommon: number; rare: number; legendary: number };
        items?: Array<{ id: string; name: string; qty: number; rarity: string }>;
    };
    arena: { active: boolean; wave: number; totalWaves: number; zombiesAlive: number };
};
```

- **タイマーは `timerSec` のみ送る**（`endsAtMs` はクライアント側で `GetGameTimer()` 加算）。サーバー→クライアントのレイテンシ吸収のため、クライアントは `tickClientMs` 周期で `timerSec` をローカルデクリメント。
- **`name`**：`GetPlayerName(src)` をサーバーで取得（PII 取り扱い注意。INSTRUCTION-014 では本人 + パーティのみ送るため許容）。
- **`byRarity`**：`Config.Items[i].rarity` を集計して算出（INSTRUCTION-006 の `Config.Items` を参照）。

---

## 5. NUI ↔ Lua プロトコル（メッセージ型一覧）

`SendNUIMessage({ type, payload })` の **単一 `type` ディスパッチ**。`fivem-nui.mdc` の規約に従う。

| `type` | 方向 | payload | 用途 |
|--------|------|---------|------|
| `m9_hud_show` | Lua → NUI | `{}` | HUD 表示 |
| `m9_hud_hide` | Lua → NUI | `{}` | HUD 非表示 |
| `m9_hud_state` | Lua → NUI | `HudStateDTO` | 定期スナップショット |
| `m9_hud_event` | Lua → NUI | `{ kind, label?, ms? }` | 一過性イベント（`kind`: `'wave_start'` / `'wave_cleared'` / `'mission_success'` / `'mission_failed'` / `'extract_success'`） |
| `m9_hud_locale` | Lua → NUI | `{ locale: 'ja' \| 'en', strings: {...} }` | 起動時に 1 度送る（i18n 初期化） |

NUI → Lua の `RegisterNUICallback` は **使わない**（フォーカス取らないオーバーレイのため）。将来必要になったら追加。

---

## 6. UI レイアウト（CSS グリッド前提）

```
┌──────────────────────────────────────────────────────────┐
│ [LOGO]              WAVE 2 / 3 — 7 体残存                │  ← 上中央: arena
│                                                          │
│ ┌── パーティ ──┐                          ┌── タイマー ──┐│
│ │ ★ Self  HP100 │                          │   12:34       ││  ← 左上: members
│ │ • Foo   HP 80 │                          │   残り        ││     右上: timer
│ │ • Bar   HP 60 │                          └───────────────┘│
│ └───────────────┘                                          │
│                                                          │
│                                                          │
│                                          ┌── インベントリ ─┐│
│                                          │ 合計 12 個    ││  ← 右下: inventory
│                                          │ C 7  U 4  R 1 ││
│                                          └───────────────┘│
│                                                          │
└──────────────────────────────────────────────────────────┘
```

（Q5=(I) のため **脱出バッジ行は出さない**。脱出案内は `lib.showTextUI` のみ。）

- **`pointer-events: none`** 必須（既存 CSS のとおり）。
- **半透明背景** + **影付き文字** で GTA の明るい背景でも視認可能に。
- **隠す**：`#app.hidden` クラスで丸ごと非表示（既存）。

### 6-A. CSS 命名規約

- BEM 風： `.m9-hud__timer` / `.m9-hud__party` / `.m9-hud__member` / `.m9-hud__inventory` / `.m9-hud__wave-banner` / `.m9-hud__extract-badge`
- 既存 `.header` / `.main` / `.hint` は **削除**（ロゴ＋ヒント文は HUD には残さない）

---

## 7. ファイル変更

| ファイル | 変更内容 |
|----------|---------|
| `jp-meridian9/server/hud.lua` | **新規**。500ms 周期で全アクティブセッションを舐め、メンバー毎の HP/Armor を集約 → `TriggerClientEvent('jp-meridian9:client:hud:state', src, dto)` |
| `jp-meridian9/client/hud.lua` | **本実装**。NUI 表示制御、サーバーからの state 受信、自分 HP のローカル取得、タイマーのローカルデクリメント、Arena/Extract のローカル状態購読 |
| `jp-meridian9/html/index.html` | **書き換え**。`.m9-hud__*` 構造に置換。ロゴ＋ヒントは削除（or 任意で残置） |
| `jp-meridian9/html/style.css` | **書き換え**。レイアウト・配色・タイポ |
| `jp-meridian9/html/app.js` | **書き換え**。`type` ディスパッチ拡張、i18n の `t(key)` 実装、DOM 描画 |
| `jp-meridian9/config.lua` | `Config.HUD` を以下に拡張（後方互換維持）:<br>`tickServerMs=500` / `tickClientMs=250` / `showPartyHP` / `showTimer` / `showInventory` / `showWaveBanner` / `inventoryMode = 'byRarity'\|'items'\|'totalOnly'`（Q2 結果を反映） |
| `jp-meridian9/locales/ja.lua` | HUD 用キー（`hud_timer_remaining` / `hud_party_label` / `hud_inv_total` / `hud_inv_common` / `hud_wave_banner` / `hud_extract_available` 等） |
| `jp-meridian9/fxmanifest.lua` | `server_scripts` に `'server/hud.lua'` を追加。**読み込み順は `server/arena/arena.lua` の直後**（`GetHudSnapshot` 依存）。`client_scripts` では `client/hud.lua` を `client/main.lua` より前に置き `MRD9.HUD` を先行定義。 |
| `jp-meridian9/client/arena.lua` | `MRD9.HUD.PushEvent` でウェーブ系トースト（`lib.notify` と併用）。 |
| `jp-meridian9/client/extract.lua` | Q5=(I) のため **HUD 連携の追記なし**（`lib.showTextUI` のみ）。 |

> 上記の **`client/arena.lua` と `client/extract.lua` への加筆は最小限**（既存ロジックを壊さない）。`MRD9.HUDClient` が存在するときのみ書き込む防御を入れる。

---

## 8. 実装手順（推奨順）

1. **`config.lua`**: `Config.HUD` を拡張。デフォルトは Q1〜Q6 の確定に従う。後方互換のため旧キーは残す。
2. **`server/hud.lua`**: 500ms 周期スレッド + DTO 構築。`Config.Items` の `rarity` を `byRarity` に集計。`onResourceStop` でスレッド停止用フラグ。
3. **`fxmanifest.lua`**: `server/hud.lua` を `server/session.lua` の直後に追加。
4. **`client/hud.lua`**:
   - `MRD9.HUDClient` テーブル初期化
   - `jp-meridian9:client:hud:state` 受信 → `MRD9.HUDClient` 更新 → throttled `SendNUIMessage('m9_hud_state', dto)`
   - `onMissionStart` で `SendNUIMessage('m9_hud_locale', {...})` + `'m9_hud_show'`
   - `onMissionEnd` で `'m9_hud_hide'`
   - `tickClientMs` 周期で self HP / armor / timerSec の差分検出 & 再送
   - `onResourceStop` で `SetNuiFocus(false, false)`（保険）
5. **`client/arena.lua`** / **`client/extract.lua`**: `MRD9.HUDClient` への書き込みフックを追加（Arena / Extract サブ状態）。
6. **`html/*`**: 構造・スタイル・JS の本実装。i18n 辞書を `app.js` 内に置く（`STR.ja` のみ）。
7. **`locales/ja.lua`**: NUI でも参照されるキーを Lua 側にも置く（HUD のサーバーフィードバック等で `_()` を使う可能性に備え）。
8. **`docs/FORMAL_POLICIES.md`**: INSTRUCTION-014 正本セクション追記。
9. **`docs/milestones.md`**: 014 を「完了」に変更。
10. **`docs/design.md`**: 現状節へ追記。
11. **`jp-meridian9/2026-05-15_開発日記.md`**（または当日の日記）: エントリ追加 → コミット → push。

---

## 9. パフォーマンス目標

- **サーバー側 hud tick**: 500ms 周期、アクティブセッション数 × メンバー数（≤ 20 × 5 = 100 ped lookup）。`GetEntityHealth` 等は軽量。`MRD9.Log` は debug 時のみ。
- **クライアント側 hud tick**: 250ms 周期。`PlayerPedId()` と `GetEntityHealth` のみ。差分があるときだけ `SendNUIMessage`。
- **NUI**: CSS で表現完結。`requestAnimationFrame` を使った独自描画は不要。
- **アイドル時**：`MRD9.CurrentSession == nil` の間は **すべてのクライアント側 tick を停止**（スレッド終了）。`onMissionStart` で再起動。
- **resmon 目標**：アイドル 0.05ms 未満、ミッション中 0.30ms 未満（`fivem-perf.mdc` 準拠）。

---

## 10. セキュリティ・権威

- HUD 用 DTO は **読み取り専用**。NUI → Lua のコールバックは無し（INSTRUCTION-014 範囲）。
- サーバーは `session.inventory[src]` を集計するだけで、クライアントから受け取った数値は HUD に使わない（`fivem-server-authority.mdc` 準拠）。
- パーティ HP は **同一セッション内に限り** 配信。バケット 0 のプレイヤーには出さない（出すと位置漏洩リスク）。

---

## 11. i18n（INSTRUCTION-014 範囲）

- `html/app.js` 内に `STR = { ja: { ... } }` を持ち、`t(key)` を定義。
- 起動時に Lua 側から `m9_hud_locale` で `locale: 'ja'` を送り、JS は `STR.ja` を選択。
- 将来 `en` を追加するときは `STR.en` を埋め、`Config.Locale = 'en'` のとき送信。
- 静的 HTML 文字列は **最小化**（タイマーラベル等の固定テキストもキー経由）。
- `data-i18n` 属性は使わなくて良い（INSTRUCTION-014 の HUD は動的更新が主体で `data-i18n` の利点が薄い）。**JSON 辞書 + JS で組み立てる**方式を採用。

辞書例：

```js
const STR = {
    ja: {
        hud_timer_remaining: '残り',
        hud_party_label: 'パーティ',
        hud_inv_total: '合計',
        hud_inv_common: 'C',
        hud_inv_uncommon: 'U',
        hud_inv_rare: 'R',
        hud_inv_legendary: 'L',
        hud_wave_banner: 'WAVE {wave} / {total} — {alive} 体残存',
        hud_extract_available: '脱出可能: {label}',
        hud_event_wave_cleared: 'ウェーブ {wave} クリア',
        hud_event_mission_success: 'ミッション成功',
        hud_event_mission_failed: 'ミッション失敗',
        hud_event_extract_success: '{label} から脱出',
    },
};
```

`{key}` のプレースホルダは `t('hud_wave_banner', { wave: 2, total: 3, alive: 7 })` で展開する小さなフォーマッタを実装。

---

## 12. テスト観点（実装 AI 向けチェックリスト）

- [ ] バケット 0（事務所） で HUD が **非表示**
- [ ] ミッション開始で HUD が表示され、タイマーが減る
- [ ] パーティメンバーの HP がリアルタイム更新（最低 500ms 以内）
- [ ] アイテム取得直後（`jp-meridian9:client:lootRemoved` 後の次 tick）に HUD のインベントリカウンタが増える
- [ ] ウェーブ開始バナーが `waveStart` で表示され、数秒後に消える
- [ ] 脱出成功 → `onMissionEnd` → HUD が非表示
- [ ] リソース restart 中にマウスが取られていないこと
- [ ] アクティブセッションなしでも `server/hud.lua` の tick が走り続けない（CPU 浪費していない）
- [ ] `resmon` で目標値内
- [ ] BOM なしで保存されている（Lua / HTML / CSS / JS すべて）

---

## 13. リスク・既知の罠

- **`SetPlayerRoutingBucket` 直後に `GetEntityCoords` が古い座標を返す瞬間がある** → HUD の HP/armor 取得には影響しないが、座標依存の演出を追加する場合は `Wait(0)` を 1 回挟む。
- **`GetPlayerName(src)` は接続後しか有効でない** → サーバー側で `nil` ガードを入れる。
- **NUI の z-index** が `lib.showTextUI` と被ると消えないことがある → `position: fixed; z-index: 1` 程度で十分（`ox_lib` は別 NUI リソースなので衝突しない想定）。
- **`fxmanifest` の `files {}` 漏れ**：CSS/JS/HTML を後から追加した場合は **必ず列挙**（Linux 本番で fetch エラーになる）。INSTRUCTION-014 では既存 3 ファイルのみで、追加しない想定。
- **後方互換**：`Config.HUD` の旧キー（`updateInterval`）は **削除しない**。`tickServerMs = Config.HUD.tickServerMs or Config.HUD.updateInterval or 500` のようにフォールバック。

---

## 14. 完了条件

1. INSTRUCTION-014 で定義した **全 NUI コンポーネントが動作**（タイマー / パーティ HP 一覧に自分を含む / インベントリ / ウェーブバナー / イベントトースト。**Q5=(I) のため脱出バッジは対象外**）
2. **`resmon` 目標値内**
3. **マスター回答済みの Q1〜Q6 がすべて実装に反映**
4. **`docs/FORMAL_POLICIES.md` に正本セクション追記済み**
5. **`docs/milestones.md` で M6 INSTRUCTION-014 が完了**
6. **当日の `<mod>/YYYY-MM-DD_開発日記.md` にエントリ追加 + コミットハッシュ記載**
7. **`git push origin main` 済み**

---

## 15. 着手前にコーディング AI が行うこと

1. このファイル **§3（Q1〜Q6）が確定済みであることを確認**（空欄・未採用行のみのままならマスターに照会）。
2. `git pull origin main` で最新状態確認。
3. `jp-meridian9/config.lua` / `client/main.lua` / `client/arena.lua` / `client/extract.lua` / `server/session.lua` を読み、既存 API を把握。
4. 既存 NUI（`html/*`）を読み、`type = 'open' / 'close'` の 2 メッセージのみ実装されていることを確認。
5. **実装着手前にマスターへ計画提示 → 確認 → コミット**（`master-profile.mdc` の「コードを書く前に必ず計画を提示」に従う）。

---

## 16. 参考リンク

- `fivem-nui.mdc`（フォーカス / メッセージング / files / i18n）
- `fivem-perf.mdc`（resmon 目標 / ティック粒度）
- `fivem-server-authority.mdc`（`source` 退避・引数検証）
- `AGENTS.md`（i18n 規約・jp-meridian9 専用例外）
- 既存実装：`client/arena.lua`（イベントハンドラの書き方）、`server/loot.lua`（`lib.callback` の書き方）、`client/extract.lua`（`lib.showTextUI` の書き方）
