# NUI フォント方針（日本語）

## 方針

- **Web フォント**: Google Fonts **Noto Sans JP** を CDN で読み込む。  
  `https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap`
- **フォールバック**: `'Noto Sans JP', 'Hiragino Sans', 'Yu Gothic UI', sans-serif`

## 現状の `font-family`（書き換え候補）

| ファイル | 内容 |
|----------|------|
| `ui/src/Tailwind.css` | `font-family: 'Satoshi', sans-serif;`（ルート）→ **Noto Sans JP を先頭に追加**予定 |
| `html/index.css` | Tailwind プリフライト由来の `html { font-family: ui-sans-serif, system-ui, … }`（1 行バンドル）→ **ビルド後に上書き or ソース側で統一**予定 |

※ 本リポジトリでは **ソースは `ui/`（Svelte + Vite）**、`html/` はビルド成果物。恒久対応は **`ui/src/Tailwind.css` とエントリ HTML の link** を直し、`pnpm build` で `html/` を再生成するのが安全です。

## レイアウト

- 日本語は英語より幅が増えやすいため、固定 `width` のパネルは **`max-width` + `min-width` + `word-break: break-word`（必要なら `overflow-wrap`）** で調整する方針とする。
