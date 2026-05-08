# TECTON UI ガイド

## UI サイズ規約

TECTON の NUI はベース解像度 1920×1080 を想定し、**ルートの `font-size` を `16px × uiScale`（既定 `uiScale = 1.5` → **24px**）** で設計する。

- **サイズ指定は `rem` 単位**で書く（レイアウト・余白・角丸・線幅を含む。`px` の直書きは避ける）。
- **フォントサイズ**は `web/src/theme.ts` の `fontSize` 定数を参照する。
- **スケールを変えたいとき**は `theme.ts` の `uiScale`（および `App.tsx` での `document.documentElement.style.fontSize` 反映）を変更する。`:root` の CSS フォールバック値も揃えると初回ペイントが安定する。
- 本規約は **M1-e で策定**し、**M2 以降の UI も同じルールに従う**。

## カテゴリツリー・プロップ一覧（M2-a 〜 M2-b）

- データは **`tecton:props:fetch`** で `Config.Props`（`dictionary` + `categories`）を取得し、クライアントが **`setProps` NUI メッセージ**で Web に渡す。
- **`CategoryTree`** は 8 ルートを展開し、子カテゴリ選択で `builderStore.selectedCategory`（`furniture` または `furniture/residential` 形式）を更新する。**カテゴリ変更時**は `propsStore.selectedTags` をクリアする（検索文字列 `searchQuery` は維持）。
- **`PropList`** は `react-window` の **`Grid`** で仮想スクロール（サムネ付きカード）。列数は中央列幅に応じ可変（最大 8 列目安）。**ビルダーパネル幅**は `min(75rem, calc(100vw - 2rem))` とし、左右サイドバーを引いた中央列でグリッドが横スクロールしにくいようにする。
- **検索**（`SearchBar` + `builderStore.searchQuery`）は **150ms デバウンス**後に `filterModelsBySearch`。**タグチップ**（`TagFilter` + `propsStore.selectedTags`）はカテゴリ内頻出タグから AND 絞り込み。件数は **`CatalogHitCount`**（検索バー直下）。
- カテゴリツリーは **`theme.fontSize.bodyLarge` / `treeBadge`** で本文より大きく表示する（密度調整でサイズは変更されうる）。

## 関連ファイル

- `web/src/theme.ts` — `uiScale`, `BASE_FONT_PX`, 色・`fontSize`（rem）
- `web/src/index.css` — `:root` のフォールバック `font-size`
- `web/src/App.tsx` — マウント時にルート `font-size` を `BASE_FONT_PX * uiScale` に設定
- `web/src/store/propsStore.ts` / `CategoryTree.tsx` / `PropList.tsx` — カタログ UI（M2-a）
