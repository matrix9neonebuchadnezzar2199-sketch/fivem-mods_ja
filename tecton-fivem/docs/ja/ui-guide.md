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
- **`PropList`** は `react-window` の **`Grid`** で仮想スクロール（サムネ付きカード）。列数は **最大 4 列**（最小幅 **140px** 相当で `floor(listWidth/140)` により狭い幅では 1〜3 列に縮退）。`Grid` の `style.width` は **`columnWidth * columnCount`** とし、端数 px での横スクロールを避ける。**ビルダーパネル幅**は **`min(60rem, calc(100vw - 2rem))`** とし、全画面化を避けゲーム画面の視認性を確保する（M2-b 追補で一時的に `calc(100vw - 2rem)` としたが覆いすぎたため撤回）。
- **仮選択・ワールド選択 UI（M2-b 追補）**: 旧右カラムは廃止。**カタログの仮選択**（`pendingCatalog`）は **下段フッター**（高さ約 **8rem**）の **`SelectionFooter`** に表示（サムネ 6rem・設置／一覧に戻る・視点ヒント）。**配置済みオブジェクト**（`selectedEntity`）の数値トランスフォームは同じくパネル下端のフッター内（最大高さ `min(22rem, 42vh)`、縦スクロール可）に **`TransformPanel`** を表示。
- **検索**（`SearchBar` + `builderStore.searchQuery`）は **`SEARCH_DEBOUNCE_MS`（150ms）** 後に `filterModelsBySearch`（定数は `web/src/lib/constants.ts`）。**タグチップ**（`TagFilter` + `propsStore.selectedTags`）はカテゴリ内頻出タグから AND 絞り込み。件数は **`CatalogHitCount`**（検索バー直下）。
- **永続化（M2-f 予定）**: 検索は `builderStore`、タグは `propsStore`。`tec_user_prefs` 連携時はどちらに何を保存するか本節または別ドキュメントで揃える。
- カテゴリツリーは **`theme.fontSize.bodyLarge` / `treeBadge`** で本文より大きく表示する（密度調整でサイズは変更されうる）。

## 関連ファイル

- `web/src/theme.ts` — `uiScale`, `BASE_FONT_PX`, 色・`fontSize`（rem）
- `web/src/index.css` — `:root` のフォールバック `font-size`
- `web/src/App.tsx` — マウント時にルート `font-size` を `BASE_FONT_PX * uiScale` に設定
- `web/src/store/propsStore.ts` / `CategoryTree.tsx` / `PropList.tsx` / `SelectionFooter.tsx` — カタログ UI（M2-a 〜 M2-b 追補）
