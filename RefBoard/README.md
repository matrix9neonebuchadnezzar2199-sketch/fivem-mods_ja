<div align="center">

<picture>
  <img src="./docs/logo.svg" width="96" height="96" alt="RefBoard" />
</picture>

# RefBoard

### 審判・運営向け &nbsp;·&nbsp; ローカルファーストのサッカー試合管理

**通信なし・DB なし。** 各監督・審判の端末に閉じた NUI で、スコア・時計・交代・カード・PK までを一気通貫で記録します。

<p>
  <a href="https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/blob/main/RefBoard/fxmanifest.lua"><img src="https://img.shields.io/badge/release-v0.6.0-5b6cf9?style=flat-square" alt="version" /></a>
  <img src="https://img.shields.io/badge/FiveM-cerulean-1a1a2e?style=flat-square" alt="FiveM cerulean" />
  <img src="https://img.shields.io/badge/Vue-3-42b883?style=flat-square&logo=vue.js&logoColor=white" alt="Vue 3" />
  <img src="https://img.shields.io/badge/TypeScript-5-3178c6?style=flat-square&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Lua-5.4-000080?style=flat-square" alt="Lua 5.4" />
  <a href="../LICENSE"><img src="https://img.shields.io/badge/License-MIT-9ca3af?style=flat-square" alt="MIT" /></a>
</p>

[English](./README.en.md) &nbsp;·&nbsp; [CHANGELOG](./CHANGELOG.md) &nbsp;·&nbsp; [引継資料（HANDOVER）](./docs/HANDOVER.md)

<br />

</div>

---

## なぜ RefBoard か

| 観点 | 内容 |
|------|------|
| **プライバシー** | 試合データは **当該端末の `localStorage` のみ**。外部サーバや MySQL には送信しません。 |
| **スタンドアロン** | **ESX / QBCore / oxmysql 非依存。** `ensure RefBoard` だけで動かせます。 |
| **二言語 UI** | 日本語を既定に、英語に切り替え可能（`vue-i18n`）。 |
| **現場志向** | 通常表示に加え **コンパクト（小窓）モード**、**PK 専用ドック**、コンテキスト別 **ヘルプ**（検索・逆引き付き）。 |

> **データ管理機能について（v0.4.0 以降）**
> RefBoard はサーバ通信を行わず、データはこの端末の `localStorage` にのみ保存されます。**v0.4.0 でデータ管理画面と CSV / JSON エクスポートは削除されました**。バックアップはアプリ外でご自身の運用（スクリーンショット・手元メモ等）にお任せしています。経緯と詳細は [CHANGELOG.md](./CHANGELOG.md) を参照してください。

---

## 機能ハイライト

- **試合** — 作成・一覧・詳細、試合時計、ゴールウィザード、手動スコア編集と履歴
- **選手** — ロスター連携、交代、イエロー／レッド
- **PK 戦** — 3 列 UI（先攻／後攻）、先攻チームの永続化、**直前キックの取消**、キック 0 件時の **先攻再抽選**、**PK 戦全体キャンセル**（後半に復帰）、両チーム 1 名以上の入口バリデーション
- **チーム** — 登録・ロスター管理
- **ヘルプ** — 16 記事（日英）、Fuse.js 検索、画面ごとの `?`（試合詳細ではモーダル内で記事を完結）、はじめてガイドは画面スクリーンショット付き
- **開発支援** — 設定から **疑似データ**の投入・削除（本番ではオフ推奨）

---

## クイックスタート（FiveM）

1. 本リポジトリの **`RefBoard/`** フォルダを、サーバの `resources` 配下に配置（例: `resources/[local]/RefBoard`）。  
2. `server.cfg` に **`ensure RefBoard`** を追記（**`oxmysql` は不要**）。  
3. ゲーム内で **`F6`**（既定）または **`/refboard`** で NUI を開く。  
4. 初回は **表示名**（任意）と **チーム** を整え、試合を作成して運用開始。

キー割当は [`config.lua`](./config.lua) の `Config.OpenKey` / `Config.DefaultLocale` で変更できます。

---

## UI のビルド（開発者向け）

```bash
cd RefBoard/web
npm install
npm run dev          # ブラウザで単体プレビュー
npm run build        # 成果物 → web/dist（FiveM が読み込む）
npx vue-tsc --noEmit # 型チェック
npm test             # vitest（v0.6.0 時点 55 件）
npm run check:help   # ヘルプ記事 ja/en の整合チェック（記事を増減したら必ず実行）
```

`fxmanifest.lua` は `web/dist/index.html` とアセットを参照します。配布前に必ず **`npm run build`** を実行してください。

---

## ドキュメント

| 文書 | 内容 |
|------|------|
| [**docs/HANDOVER.md**](docs/HANDOVER.md) | アーキテクチャ、ディレクトリ構成、既知 TODO、ロードマップ |
| [**CHANGELOG.md**](CHANGELOG.md) | バージョン別の変更履歴（破壊的変更は冒頭に明記） |
| [**docs/diary/**](docs/diary/) | 開発日記・リブート経緯 |

旧 **MySQL 連動版**（v0.8.x 系）の履歴や DDL は、リポジトリ外の素材庫 **`RefBoard_old/`**（`.gitignore`）を参照してください。現行 `RefBoard/` には **`sql/` や `docs/01_database.md` は含まれません**。

---

## ライセンス

**MIT** — リポジトリルートの [LICENSE](../LICENSE) を参照してください。

---

<div align="center">

<sub>Built with discipline for Japanese FiveM communities · 問題や改善案は <strong>Issues</strong> / <strong>Pull requests</strong> へ</sub>

</div>
