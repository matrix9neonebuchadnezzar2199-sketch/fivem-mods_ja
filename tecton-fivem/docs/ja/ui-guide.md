# TECTON UI ガイド

## UI サイズ規約

TECTON の NUI はベース解像度 1920×1080 を想定し、**ルートの `font-size` を `16px × uiScale`（既定 `uiScale = 1.5` → **24px**）** で設計する。

- **サイズ指定は `rem` 単位**で書く（レイアウト・余白・角丸・線幅を含む。`px` の直書きは避ける）。
- **フォントサイズ**は `web/src/theme.ts` の `fontSize` 定数を参照する。
- **スケールを変えたいとき**は `theme.ts` の `uiScale`（および `App.tsx` での `document.documentElement.style.fontSize` 反映）を変更する。`:root` の CSS フォールバック値も揃えると初回ペイントが安定する。
- 本規約は **M1-e で策定**し、**M2 以降の UI も同じルールに従う**。

## 関連ファイル

- `web/src/theme.ts` — `uiScale`, `BASE_FONT_PX`, 色・`fontSize`（rem）
- `web/src/index.css` — `:root` のフォールバック `font-size`
- `web/src/App.tsx` — マウント時にルート `font-size` を `BASE_FONT_PX * uiScale` に設定
