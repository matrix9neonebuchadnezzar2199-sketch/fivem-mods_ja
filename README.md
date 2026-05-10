# fivem-mods（JP-Mods）

日本語 FiveM RP サーバー向けの **スタンドアロン** リソースをまとめた **モノレポ** です。各フォルダが独立した FiveM リソースであり、原則として **ESX / QBCore に依存しません**（個別 MOD の README に例外がある場合はそちらを優先）。

| | |
| --- | --- |
| **既定ライセンス** | ルートの [`LICENSE`](LICENSE) は **MIT**（個別フォルダに `LICENSE` がある場合は **その MOD のライセンスが優先**） |
| **ドキュメント** | [`docs/STYLEGUIDE.md`](docs/STYLEGUIDE.md) · [`AGENTS.md`](AGENTS.md) · [`CONTRIBUTING_JP.md`](CONTRIBUTING_JP.md) |

作成者: [@eiho_tsukuyomi](https://x.com/eiho_tsukuyomi)

---

## 目次

- [このリポジトリの考え方](#このリポジトリの考え方)
- [開発・運営が読むドキュメント](#開発運営が読むドキュメント)
- [文字コードと設定ファイル](#文字コードと設定ファイル)
- [収録 MOD 一覧](#収録-mod-一覧)
- [ツール](#ツール)
- [ライセンス](#ライセンス)

---

## このリポジトリの考え方

- **レイアウト**: ルート直下に複数リソースフォルダを並べる **モノレポ型**（`ensure` する名前は **フォルダ名 = リソース名**）。
- **独立性**: 各 MOD は **`jp-<名前>/`** や **`polapaint`** のようにフォルダ単位で完結。**他 MOD のファイルを参照しない** 設計を既定とします（[`AGENTS.md`](AGENTS.md)）。
- **ドキュメントだけの追記**: 既存のフォルダ名・依存関係を変えずに、`README.md` やインストール手順だけ足す運用を推奨します。
- **利用について**: フォーク・学習・サーバー組み込みは各 MOD のライセンスに従ってください。

---

## 開発・運営が読むドキュメント

| ドキュメント | 内容 |
| --- | --- |
| [`docs/STYLEGUIDE.md`](docs/STYLEGUIDE.md) | 用語・文体・**UTF-8（BOM 禁止）** など表記ルール |
| [`AGENTS.md`](AGENTS.md) | フォルダ構成、`jp-<mod>:イベント` 命名、開発フロー、開発日記の置き場 |
| [`CONTRIBUTING_JP.md`](CONTRIBUTING_JP.md) | 外部 MOD の日本語化・フォーク配布の判断・作業の型 |

---

## 文字コードと設定ファイル

- **すべてのテキストは UTF-8**。**UTF-8 with BOM（先頭 `EF BB BF`）は付けない**でください。Lua の `shared_script` / `config.lua` などで **BOM 付きファイルだけパースエラー**になる事例があります。
- 運営が触る **`config.lua`** は、項目ごとに **日本語コメント** を書く方針です（各 MOD の README に詳細）。

---

## 収録 MOD 一覧

各フォルダの **`README.md`** にインストール・設定・依存関係があります。**バージョン・ライセンスは各リソースの `fxmanifest.lua` / フォルダ内 `LICENSE` を参照**してください。

| フォルダ | 概要 |
| --- | --- |
| [RefBoard](RefBoard/README.md) | サッカー試合管理（oxmysql・編集ロック・スコア履歴・Vue NUI・JA/EN・MIT） |
| [bakery_appearance](bakery_appearance/README.md) | 外見カスタム（Bakery Appearance 系フォーク・日本語ロケール / i18next・ゾーン案内・共有・店員 Ped 等は `shared/config.lua` で切替・ox_lib / oxmysql） |
| [dvd-maker](dvd-maker/README.md) | DVD に YouTube を焼いて所持・再生（ox_inventory・Vanilla JS NUI・URL 検証・MIT） |
| [jp-110](jp-110/README.md) | `/110` 警察向け無線風一斉通知 |
| [jp-b2b_documents](jp-b2b_documents/README.md) | Quill ベースのドキュメント／メモエディター（日本語 UI・ESX/QB/Qbox・インベントリ抽象化・原作 alnd029 系） |
| [jp-blackmarket/matkez_blackmarket_ja](jp-blackmarket/matkez_blackmarket_ja/README.md) | ブラックマーケット（日本語化・QBCore・ox_inventory 前提・原作 GPL-3.0） |
| [jp-card](jp-card/README.md) | `/card` 3D 回転付きトランプ抽選 |
| [jp-coin](jp-coin/README.md) | `/coin` 3D 回転付きコイントス |
| [jp-ddm](jp-ddm/README.md) | モーション連続再生 + YouTube 音楽同期（クライアント・KVS） |
| [jp-deliveryjobv2](jp-deliveryjobv2/README.md) | 配達ジョブ nek_deliveryjobV2 の日本語化（ESX/QB・ox_target・Webhook 任意・原作リポジトリ参照） |
| [jp-gacha](jp-gacha/README.md) | ガチャ（NUI・1 連 / 10 連・現金支払い） |
| [jp-gacha2](jp-gacha2/README.md) | ガチャ v2（ox_inventory・管理・NUI カプセル） |
| [jp-glitch28](jp-glitch28/README.md) | Glitch Minigames 日本語 UI（28+ ミニゲーム・`glitch-minigames` 名で配置・GPL-3.0） |
| [jp-hospital](jp-hospital/README.md) | 病院カルテ整理・薬梱包（NUI 内職・Qbox） |
| [jp-uv-books2](jp-uv-books2/README.md) | 本の執筆／閲覧 uv-books 2.0 の日本語版（ESX/QB/QBox・ox_inventory・日本語フォント同梱） |
| [jp-v-farming](jp-v-farming/README.md) | 農業・青果売却（ox_target / ox_lib / ox_inventory・日本語 i18n・原作 MIT） |
| [pls_jobsystem](pls_jobsystem/README.md) | PLS Job System 日本語化（動的ジョブ管理・React NUI・フォルダ名 `pls_jobsystem` 固定・原作 MIT） |
| [jp-koban](jp-koban/README.md) | 警察向け住宅地巡回パトロール（Qbox・完遂ボーナス） |
| [jp-LetterCarrier](jp-LetterCarrier/README.md) | 配達ジョブ（NUI・配送車・報酬） |
| [jp-losmon](jp-losmon/README.md) | 育成型 Los-Mon（クライアント完結・サーバー負荷ほぼなし） |
| [jp-mch](jp-mch/README.md) | ミニマルクリーン HUD（クライアント完結・ESX/QB/Qbox/standalone・日本語 UI） |
| [jp-mbt_emote_menu](jp-mbt_emote_menu/README.ja.md) | MBT Emote Menu 日本語対応（rpemotes-reborn・NUI・**`README.ja.md`** 参照・原作 PolyForm Noncommercial） |
| [jp-mechanic](jp-mechanic/README.md) | 整備工場 伝票整理内職（NUI・部品照合・Qbox） |
| [polapaint](polapaint/README.md) | ポラロイド撮影・サーバー側ローカル保存・署名付き GET 配信・NUI 閲覧／編集（screenshot-basic・ox_lib・ox / QB インベントリ・**GPL-3.0-or-later**） |
| [jp-sentinel](jp-sentinel/README.md) | 警察向け Sentinel Ball（追尾ドローン・マップ共有・ESX/QB/Qbox/ACE） |
| [jp-slot](jp-slot/README.md) | カジノスロット（着席 NUI・抽選 / 現金はサーバー権威） |
| [jp-tcgbook](jp-tcgbook/README.md) | スタンドアロン TCG・BOOK（コレクション／デッキ編成／CPU・PvP・Elo・対戦履歴・ランキング・段位徽章・JA/EN UI・oxmysql） |
| [jp-timer](jp-timer/README.md) | 画面カウントダウン（`/min`・RP 向け軽量） |
| [jp-UnderworldBounty](jp-UnderworldBounty/README.md) | 闇の指名手配（裏賭場シナリオ・報復ウェーブ・設定駆動・ESX/QB/Standalone） |
| [qb-storerobbery-ja](qb-storerobbery-ja/README.md) | `qb-storerobbery` 日本語化フォーク（コンビニ強盗・KVP クールダウン・ox_inventory ブリッジ） |

---

## ツール

| ツール | パス | 説明 |
| --- | --- | --- |
| 汎用 NUI 日本語化適用 | [`tools/apply_nui_i18n.ps1`](tools/apply_nui_i18n.ps1) | 各 MOD の `web/dist/assets/index.js` を翻訳マップに従って日本語化。**詳細は [`tools/README_JA.md`](tools/README_JA.md)**。 |

**実行例（プレビュー）:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode preview
```

---

## ライセンス

- **リポジトリルート**の [`LICENSE`](LICENSE) は **MIT**（Copyright JP-Mods）。
- **個別 MOD** に別の `LICENSE` や `fxmanifest.lua` の `license` 記載がある場合は、**その MOD は個別ライセンスが適用**されます（例: `polapaint` は GPL-3.0-or-later）。
