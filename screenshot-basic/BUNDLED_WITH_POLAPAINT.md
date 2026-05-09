# screenshot-basic（同梱版）

本ディレクトリは [citizenfx/screenshot-basic](https://github.com/citizenfx/screenshot-basic) の **MIT ライセンス**のもと、**ビルド済み `dist/`** を fivem-mods_ja リポジトリに同梱したものです。著作権表示は `LICENSE` を参照してください。

## 運用

- サーバの `resources`（例: `[jp-mods]`）に **`screenshot-basic` フォルダごと**配置し、`server.cfg` で **`ensure screenshot-basic`** を **`ensure PolaPaint` より前**に書いてください。
- 本同梱版は **事前ビルド済み**のため、元リポジトリの `dependency 'yarn'` / `webpack` は **不要**です（`fxmanifest.lua` を差し替え済み）。

## 再ビルド（メンテナンス用）

元の `package.json` と webpack 設定が必要です。Node 17+ では OpenSSL 互換が必要な場合があります。

```bash
set NODE_OPTIONS=--openssl-legacy-provider
npm install
npx webpack --config client.config.js
npx webpack --config server.config.js
npx webpack --config ui.config.js
```

（上記は上流リポジトリを別クローンして実行する想定。本フォルダにはソースを含めない軽量同梱にしている場合は、上流から取得してください。）
