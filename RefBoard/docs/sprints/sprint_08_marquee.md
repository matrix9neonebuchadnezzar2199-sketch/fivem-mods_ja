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

フェーズ 2 以降の置換で速度判断を散らさないため、`MarqueeText` に **`variant?: 'default' | 'scoreboard' | 'ticker' | 'subtle'`** を持たせ、既定値は定数 1 箇所で調整する。

| `variant` | speed (px/s) | gap (px) | delay (ms) | 想定用途 |
|-----------|-------------:|---------:|-----------:|----------|
| `default` | 40 | 48 | 1000 | 汎用 |
| `scoreboard` | 28 | 64 | 2200 | スコアボード（凝視が長いので遅め・初回読了の猶予） |
| `ticker` | 60 | 32 | 500 | トースト・短い通知 |
| `subtle` | 35 | 40 | 1500 | サイドバー・メニュー |

- `speed` / `gap` / `delay` を props で渡した場合は **variant 値を上書き**（`props.speed ?? VARIANTS[variant].speed` の形）。
- 微調整は **`VARIANTS` 定数のみ**を触れば全画面に反映される想定。

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

### フェーズ 2 — 高視認エリア（PR2）

優先: サイドバー、ヘッダー（試合名・編集者名）、ヘルプ（タイトル・逆引きラベル・パンくず相当）、トースト、スコアボード（チーム名・得点者名）。

#### スコアボード適用方針（案 A 確定）

- **方針**: オーバーフロー時は常時マーキーで **チーム正式名を全文表示**（省略しない）。LED ボード演出の主役。
- **MarqueeText**: `variant="scoreboard"` を使用（フェーズ 1 のプリセット: speed **28** px/s、delay **2200** ms、gap **64** px）。必要なら個別 props で上書き。
- **適用箇所**: `ScoreBoardCard.vue` のホームチーム名・アウェイチーム名（およびフェーズ 3 で得点者名と連動スタイル）。
- **ホバー挙動**: 一時停止は **ローカルのみ**（他クライアントに影響しない）。上記「表示方針」と同じ。
- **演出連動**: スコア変動時の `score-flash` と組み合わせ、**フラッシュ後にマーキーが続く**リズムでドラマ性を出す（フェーズ 3 で詳細実装可）。
- **得点者名**: `scorer-name-marquee` クラス（LED 風境界線・背景）で表示（フェーズ 3 と併せてもよいが、フェーズ 2 で枠だけ入れてもよい）。

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
| 設定 | `web/src/stores/settings.ts`, `web/src/views/Settings.vue` |

---

**改版履歴**

- 2026-05-06: 初版（Sprint 07 から v0.6.1 マーキーを切り出し、3 フェーズ PR 案を記載）。
- 2026-05-06: 案 A（常時マーキー全文）確定、`variant` プリセット、スコアボード方針・ホバー注記を追記。
