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

## 3 フェーズ（PR 分割案）

### フェーズ 1 — 基盤のみ（PR1）

- `web/src/components/common/MarqueeText.vue`
- `web/src/directives/marquee.ts`（ディレクティブ版も上記と同順: **単体計測 → 必要時のみ複製**）
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
