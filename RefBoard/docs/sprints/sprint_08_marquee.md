# Sprint 08 — v0.6.1（マーキー / 1 行テキストの視覚言語）

## ゴール

**オーバーフローした 1 行テキストは `text-overflow: ellipsis` で省略せず、マーキーで全文を見せる**方針を RefBoard 全体の約束事にする。スタジアム LED・中継テロップ感とブランドを揃えつつ、`prefers-reduced-motion` と設定でのオフを用意する。

## Sprint 07 との関係

- **Sprint 07**（[sprint_07.md](sprint_07.md)）は **v0.6.0 アプリ内ヘルプの完成まで継続**。リリースノート・受け入れ基準は分離する。
- マーキー基盤を先に入れると、ヘルプの逆引きラベルや長いタイトルの UI 判断が楽になる（実装順は併走可）。

## 設計の正（計測）

- **1 本分の幅**は、常に存在する **先頭の `span`（`contentRef`）の `scrollWidth` のみ**で測る。クローン有無に `scrollWidth` が依存しないこと。
- **gap** は先頭コンテンツの `padding-right` で表現し、`distance = contentWidth + gap` をアニメーション移動量に使う。
- **ResizeObserver** はコンテナとコンテンツ（先頭 span）の両方に張り、フォント読み込み後に再計測する。

## 表示方針（案 A 確定）

- **方針**: オーバーフロー時は **常時マーキーで全文表示**（`ellipsis` は使わない）。RefBoard のスポーツ／LED ボード感とブランドを優先する。
- **短い文字列**: `isOverflowing === false` のときは **静止**（マーキーアニメなし）。計測ロジックで担保。
- **ホバー一時停止**: `animation-play-state: paused` は **各クライアントの NUI ローカルのみ**。他の審判画面やサーバーには影響しない（ブロードキャストしない）。設計上の安心用の明記。

## MarqueeText `variant` プリセット（フェーズ 1 で実装）

フェーズ 2 以降の置換で速度判断を散らさないため、`MarqueeText` に **`variant?: 'default' | 'scoreboard' | 'ticker' | 'subtle'`**（オプション、省略時は `'default'`）を持たせ、既定の speed / gap / delay の組は **定数 1 箇所**で調整する。個別 props（`speed` / `gap` / `delay`）は **variant を上書き可能**（例: `props.speed ?? VARIANTS[variant].speed`）。

TypeScript 表現（実装時の単一情報源イメージ）:

```typescript
const VARIANTS = {
  default:    { speed: 40, gap: 48, delay: 1000 },   // 汎用
  scoreboard: { speed: 28, gap: 64, delay: 2200 },  // スコアボード（案 A 確定）
  ticker:     { speed: 60, gap: 32, delay: 500 },   // トースト・通知
  subtle:     { speed: 35, gap: 40, delay: 1500 },  // サイドバー・メニュー
} as const
```

| `variant` | speed (px/s) | gap (px) | delay (ms) | 用途指針 |
|-----------|-------------:|---------:|-----------:|----------|
| `default` | 40 | 48 | 1000 | 一般的な 1 行テキスト。ヘッダー試合名・タイムライン本文・ヘルプ記事タイトル等。 |
| `scoreboard` | 28 | 64 | 2200 | **凝視対象**。ゆっくり流し、初回数秒で陣営とスコアを読んでから動き始めるリズム。 |
| `ticker` | 60 | 32 | 500 | **短時間で要点を流す**通知系。トースト本文など。 |
| `subtle` | 35 | 40 | 1500 | **補助情報**。控えめに流す。サイドバー項目・プレイヤー一覧の名前等。 |

- 微調整は **`VARIANTS` 定数のみ**を触れば全画面に反映される想定。
- **数値について**: 上記 speed / gap / delay は **初期値**である。実機テストやチーム名の最大長を踏まえ、必要なら **`VARIANTS` のみ**で調整してよい（画面ごとにバラバラのマジックナンバーを増やさない）。

## 3 フェーズ（PR 分割案）

### フェーズ 1 — 基盤のみ（PR1）

- `web/src/components/common/MarqueeText.vue`（**`variant` プリセット込み**、上表）
- `web/src/directives/marquee.ts`（ディレクティブ版も上記と同順: **単体計測 → 必要時のみ複製**。`binding.value` で `variant` / `speed` 等を渡せるようにしてもよい）
- `web/src/main.ts` でディレクティブ登録
- `web/src/styles/marquee.css`（`data-marquee-mode` 別の挙動を CSS で切替）
- `stores/settings.ts`: `marqueeMode: 'always' | 'hover-only' | 'off'`
- ルート（例: `App.vue`）に `:data-marquee-mode` をバインド
- `Settings.vue` + i18n `settings.marquee_mode.*`
- デフォルト `always`。**`prefers-reduced-motion: reduce` のときは自動で `off` 相当**（コンポーネント／CSS 両面で停止）
- **このフェーズでは既存画面への置換は行わない**

完了確認: `npm run build`、CHANGELOG v0.6.1（フェーズ1）追記。

### フェーズ 1 進捗

- **2026-05-06: フェーズ1完了（実装マージ）**。`MarqueeText.vue`、`directives/marquee.ts`、`styles/marquee.css`、`utils/marqueeVariants.ts`（`VARIANTS` 共有）、`main.ts` 登録、`settings.marqueeMode`、`App.vue` の `data-marquee-mode` + `provide('marqueeMode')`、`Settings.vue` ラジオ、日英 i18n。`vue-tsc` / `npm run build` 成功。既存の試合一覧・スコアボード等には **未適用**（フェーズ2）。
- **設計書との差分**: `VARIANTS` をコンポーネント内ではなく **`web/src/utils/marqueeVariants.ts`** に切り出し、`MarqueeText` と `v-marquee` で共有（数値の単一ソース化）。`off` 時の省略は **`rb-marquee--ellipsis`** と（ディレクティブ向け）**`rb-marquee-track-ellipsis`** で CSS 実装。

### フェーズ 2 — 高視認エリア（PR2）

優先: サイドバー、ヘッダー（試合名・編集者名）、ヘルプ（タイトル・逆引きラベル・パンくず相当）、トースト、スコアボード（チーム名・得点者名）。

#### スコアボード適用方針（案 A 確定）

- **方針**: オーバーフロー時は **常時マーキーで全文表示**し、チーム正式名を **省略せず完全に流す**（`ellipsis` は使わない）。
- **確定理由**: RefBoard の **スポーツアプリ感を最大化**し、LED ボード演出の **主役**としてチーム名を扱うため。
- **MarqueeText 推奨**: `variant="scoreboard"`（プリセット: speed **28** px/s — デフォルト 40 より遅く目の負担を抑える、delay **2200** ms — 初回把握の猶予、gap **64** px — 視認性）。必要なら個別 props で上書き。
- **適用箇所**: `ScoreBoardCard.vue` の **ホーム・アウェイのチーム名**（得点者名はフェーズ 3 で `scorer-name-marquee` と連動してもよい）。
- **ホバー挙動**: 一時停止は **各 NUI クライアントのローカルのみ**。他の審判の画面へブロードキャストしない（技術的にもそうなるが、**設計意図として明記**）。上記「表示方針」と整合。
- **演出連動**: スコア変動時の **`score-flash`** と組み合わせ、**フラッシュ後にマーキーが続く**リズムでドラマ性を出す（詳細タイミングはフェーズ 2〜3 で調整可）。
- **得点者名**: **`scorer-name-marquee`** スタイル（LED 風の境界線・背景）で表示。
- **短いチーム名**: コンテナに収まり **`isOverflowing === false`** のときは **静止のまま**（修正版計測で担保。追加ロジック不要）。

#### フェーズ 2 置換時の variant 割り当てガイドライン

置換作業でブレないよう、初期割り当てを次のとおり **推奨**する（個別画面の体裁で上書きしてもよい）。

| 箇所 | 推奨 `variant` |
|------|------------------|
| `ScoreBoardCard` チーム名 | `scoreboard` |
| ヘッダー試合名 | `default` |
| サイドバーメニュー項目 | `subtle` |
| トースト本文 | `ticker` |
| ヘルプ記事タイトル | `default` |
| プレイヤーリストの選手名 | `subtle` |
| イベントタイムライン本文 | `default` |

### フェーズ 3 — 全域＋演出（PR3）

プレイヤーリスト、イベントタイムライン、試合一覧、TeamManage / DataManage / Settings の残り、PresenceBadge、エラートースト等。スコア変動時の `score-flash`、得点者の LED 風クラス（`scorer-name-marquee` 等）を追加。

## 受け入れ基準（v0.6.1 全体・最終）

フェーズ 3 完了時点で満たす想定:

1. `MarqueeText` と `v-marquee` が実装され、対象 UI で期待どおり動作する。  
2. `text-overflow: ellipsis` をリポジトリ内 Grep で **0 件**（方針どおり廃止）。  
3. Settings に `marqueeMode` 切替がある。  
4. `prefers-reduced-motion` で自動停止、ホバー一時停止、両端フェードマスク（既定 12px）。  
5. スコアボードにスコア変動時のフラッシュ演出。  
6. `npm run build` 成功。  
7. `CHANGELOG.md`・`docs/USER_GUIDE.md`（および必要なら `.en`）に記載。  
8. デモ GIF: `docs/screenshots/marquee_demo.gif`（フェーズ3またはリリース直前）。

## 関連ファイル（予定）

| 種別 | パス |
|------|------|
| コンポーネント | `web/src/components/common/MarqueeText.vue` |
| ディレクティブ | `web/src/directives/marquee.ts` |
| スタイル | `web/src/styles/marquee.css` |
| プリセット定数 | `web/src/utils/marqueeVariants.ts` |
| 設定 | `web/src/stores/settings.ts`, `web/src/views/Settings.vue` |

## フェーズ 1 着手前チェックリスト

フェーズ 1（マーキー基盤）の実装 PR に入る直前に確認する。

1. **vue-tsc 緑化コミットが完了していること**（`PenaltyShootoutPanel.vue` の未使用変数、`nuiMock.ts` の型修正など）。マーキー実装と型エラーを混在させない。
2. **`MarqueeText` に variant プリセットを含めること**（上記 `VARIANTS` と props 上書きルール）。
3. **`directives/marquee.ts` も variant 相当の引数**（例: `binding.value` に `variant` / `speed` 等）を受け取れるようにすること。
4. **`styles/marquee.css` で `data-marquee-mode` 別の挙動**を **CSS のみ**で切り替えること（設定ストアとルート属性の連携はフェーズ 1 の範囲）。

**チェックリスト反映（2026-05-06）**: 上記 1〜4 はフェーズ1完了時点で満たした（vue-tsc 緑化は先行コミット `5287770`）。

---

**改版履歴**

- 2026-05-06: 初版（Sprint 07 から v0.6.1 マーキーを切り出し、3 フェーズ PR 案を記載）。
- 2026-05-06: 案 A（常時マーキー全文）確定、`variant` プリセット、スコアボード方針・ホバー注記を追記。
- 2026-05-06: TypeScript `VARIANTS` 表現・用途指針・フェーズ 2 の variant 割り当て表・数値は初期値（実機後に調整可）の注記・フェーズ 1 着手前チェックリストを追記（設計固定用）。
- 2026-05-06: フェーズ1実装完了（進捗節・関連ファイル表に `marqueeVariants.ts` 追記、チェックリスト消化を明記）。
