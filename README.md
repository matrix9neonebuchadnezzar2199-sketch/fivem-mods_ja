# fivem-mods（JP-Mods）

日本語 FiveM RP 向けの **スタンドアロン** リソースをまとめた **モノレポ** です。ルート直下の **各フォルダがそれぞれ 1 つの FiveM リソース**（`ensure` 名 = フォルダ名）になります。原則 **フレームワーク非依存**・**他 MOD フォルダを参照しない** 設計です（例外は各リソースの README を優先）。

| | |
| --- | --- |
| **リポジトリ** | 複数 MOD を同一ルートに並べる開発レイアウト（[`docs/STYLEGUIDE.md`](docs/STYLEGUIDE.md) の表記・UTF-8 方針に準拠） |
| **ルート LICENSE** | [`LICENSE`](LICENSE) は **MIT**（**個別フォルダに LICENSE / `fxmanifest` の `license` がある場合はそちらが優先**） |
| **開発ガイド** | [`AGENTS.md`](AGENTS.md) · [`CONTRIBUTING_JP.md`](CONTRIBUTING_JP.md) |

作成者: [@eiho_tsukuyomi](https://x.com/eiho_tsukuyomi)　／　使用する際はフォロー＆リツイートなどで応援いただけると嬉しいです。

---

## 目次

- [概要](#概要)
- [要件](#要件)
- [このリポジトリの使い方（入手〜起動）](#このリポジトリの使い方入手起動)
- [ドキュメントリファレンス](#ドキュメントリファレンス)
- [文字コードと `config.lua`（全 MOD 共通の約束）](#文字コードと-configlua全-mod-共通の約束)
- [収録リソース一覧](#収録リソース一覧)
- [ツール](#ツール)
- [トラブルシュート](#トラブルシュート)
- [ライセンス](#ライセンス)

---

## 概要

- **モノレポ**: 1 つの Git リポジトリに複数の FiveM リソースが並びます。必要なフォルダだけをサーバーの `resources` に配置して `ensure` します（全体を丸ごとコピーする必要はありません）。
- **独立性**: 各 MOD はフォルダ単位で完結します。**`jp-<名前>/`** 形式が多いですが、命名の例外もあります（[`AGENTS.md`](AGENTS.md)）。
- **ドキュメント**: インストール・依存関係・Convar は **各フォルダの `README.md`** が正。ルート README は索引と共通ルールのみです。
- **更新方針**: 既存のフォルダ名・イベント名・運営向け `config` の値を無断で変えず、**ドキュメントやロケールだけ足す**運用を推奨します。

---

## 要件

| 項目 | 説明 |
| --- | --- |
| **FiveM サーバー** | 各リソースは `fxmanifest.lua` を持ち、`cerulean` / `lua54 'yes'` を前提にしているものが多いです。 |
| **Git** | クローンして必要なフォルダだけ取り出す用途。 |
| **（任意）PowerShell** | [`tools/apply_nui_i18n.ps1`](#ツール) を使う場合。 |

個別リソースが **ox_lib・oxmysql・qb-core** などを要求する場合は、**そのリソースの README と `fxmanifest` の `dependencies`** を必ず確認してください。

---

## このリポジトリの使い方（入手〜起動）

1. リポジトリを **clone** するか、ZIP で入手します。
2. 利用したい **リソースフォルダだけ** を、サーバーの `resources` 配下にコピーします（例: `[jp-mods]/jp-timer`）。
3. **`server.cfg`** に **`ensure <フォルダ名>`** を追記します（`<フォルダ名>` は `fxmanifest` があるディレクトリ名と一致）。
4. **依存リソースを先に `ensure`** します。順序はリソースによります（例: `ox_lib` → `ox_inventory` → 対象 MOD）。迷ったら **対象 MOD の README の「インストール」「要件」** を参照してください。
5. コンソールから **`refresh`** → **`ensure <名前>`**、または txAdmin で再起動し、**F8 クライアントログ** でエラーがないか確認します。

開発時の典型的な流れは [`AGENTS.md`](AGENTS.md) の「開発フロー」（`scripts\deploy.bat`・`refresh`・再起動）にあります。

---

## ドキュメントリファレンス

| ドキュメント | 内容 |
| --- | --- |
| [`docs/STYLEGUIDE.md`](docs/STYLEGUIDE.md) | 用語・文体・**UTF-8（BOM 禁止）** |
| [`AGENTS.md`](AGENTS.md) | フォルダ構成、`jp-<mod>:イベント` 命名、開発日記の置き場 |
| [`CONTRIBUTING_JP.md`](CONTRIBUTING_JP.md) | 外部 MOD の日本語化・フォーク配布の判断・作業の型 |

---

## 文字コードと `config.lua`（全 MOD 共通の約束）

運営・開発の両方で次を共通ルールとします（詳細は [`docs/STYLEGUIDE.md`](docs/STYLEGUIDE.md)）。

| 項目 | ルール |
| --- | --- |
| **エンコーディング** | **UTF-8**。**UTF-8 with BOM（先頭 `EF BB BF`）は付けない**（Lua で **`unexpected symbol near '<\239>'`** などになり得る）。 |
| **`config.lua`** | サーバー運営が読めるよう、**項目ごとに日本語コメント**を書く方針（[`AGENTS.md`](AGENTS.md)）。 |
| **運営固有の値** | 座標・価格・設置場所などは、**依頼や自分の運営方針で変える項目以外は無断で戻さない**（フォーク・PR 時も注意）。 |

---

## 収録リソース一覧

**インストール・依存・ライセンスの詳細は各リンク先の README が正本です。** バージョンは各 `fxmanifest.lua` の `version`、ライセンスはフォルダ内 `LICENSE` / manifest を参照してください。

| フォルダ | 概要 |
| --- | --- |
| [RefBoard](RefBoard/README.md) | サッカー試合管理（oxmysql・編集ロック・スコア履歴・Vue NUI・JA/EN・MIT） |
| [bakery_appearance](bakery_appearance/README.md) | 外見カスタム（Bakery Appearance 系フォーク・日本語ロケール / i18next・ゾーン案内は GTA 標準ヘルプ・共有・取り込み・店員 Ped などは `shared/config.lua` で UI 表示を切替可能・ox_lib / oxmysql） |
| [dvd-maker](dvd-maker/README.md) | DVD に YouTube を焼いて所持・再生（ox_inventory・Vanilla JS NUI・URL 検証・MIT） |
| [jp-110](jp-110/README.md) | `/110` 警察向け無線風一斉通知 |
| [jp-b2b_documents](jp-b2b_documents/README.md) | Quill ベースのドキュメント／メモエディター（日本語 UI・ESX/QB/Qbox・ox / qb / ESX インベントリ抽象化・原作 alnd029 系） |
| [jp-blackmarket/matkez_blackmarket_ja](jp-blackmarket/matkez_blackmarket_ja/README.md) | ブラックマーケット（日本語化・QBCore 対応・ox_inventory 前提・原作 GPL-3.0） |
| [jp-card](jp-card/README.md) | `/card` 3D 回転付きトランプ抽選 |
| [jp-coin](jp-coin/README.md) | `/coin` 3D 回転付きコイントス |
| [jp-ddm](jp-ddm/README.md) | モーション連続再生 + YouTube 音楽同期（クライアント・KVS） |
| [jp-deliveryjobv2](jp-deliveryjobv2/README.md) | 配達ジョブ nek_deliveryjobV2 の日本語化（ESX/QB・ox_target・Webhook 任意・原作リポジトリ参照） |
| [jp-gacha](jp-gacha/README.md) | ガチャ（NUI・1 連 / 10 連・現金支払い） |
| [jp-gacha2](jp-gacha2/README.md) | ガチャ v2（ox_inventory・管理・NUI カプセル） |
| [jp-glitch28](jp-glitch28/README.md) | Glitch Minigames 日本語 UI（28+ ミニゲーム・`glitch-minigames` 名で配置・GPL-3.0） |
| [jp-hospital](jp-hospital/README.md) | 病院カルテ整理・薬梱包（NUI 内職・Qbox） |
| [jp-koban](jp-koban/README.md) | 警察向け住宅地巡回パトロール（Qbox・完遂ボーナス） |
| [jp-LetterCarrier](jp-LetterCarrier/README.md) | 配達ジョブ（NUI・配送車・報酬） |
| [jp-losmon](jp-losmon/README.md) | 育成型 Los-Mon（クライアント完結・サーバー負荷ほぼなし） |
| [jp-mch](jp-mch/README.md) | ミニマルクリーン HUD（クライアント完結・ESX/QB/Qbox/standalone・日本語 UI・Munlay HUD 系フォーク） |
| [jp-mbt_emote_menu](jp-mbt_emote_menu/README.ja.md) | MBT Emote Menu 日本語対応（rpemotes-reborn・NUI・**`README.ja.md`** 参照・原作 PolyForm Noncommercial） |
| [jp-mechanic](jp-mechanic/README.md) | 整備工場 伝票整理内職（NUI・部品照合・Qbox） |
| [jp-sentinel](jp-sentinel/README.md) | 警察向け Sentinel Ball（追尾ドローン・マップ共有・ESX/QB/Qbox/ACE） |
| [jp-slot](jp-slot/README.md) | カジノスロット（着席 NUI・抽選 / 現金はサーバー権威） |
| [jp-tcgbook](jp-tcgbook/README.md) | スタンドアロン TCG・BOOK（コレクション／デッキ編成／CPU・PvP・Elo・対戦履歴・ランキング・段位徽章・JA/EN UI・oxmysql） |
| [jp-timer](jp-timer/README.md) | 画面カウントダウン（`/min`・RP 向け軽量） |
| [jp-UnderworldBounty](jp-UnderworldBounty/README.md) | 闇の指名手配（裏賭場シナリオ・報復ウェーブ・設定駆動・ESX/QB/Standalone） |
| [jp-uv-books2](jp-uv-books2/README.md) | 本の執筆／閲覧 uv-books 2.0 の日本語版（ESX/QB/QBox・ox_inventory・日本語フォント同梱） |
| [jp-v-farming](jp-v-farming/README.md) | 農業・青果売却（ox_target / ox_lib / ox_inventory・日本語 i18n・原作 MIT） |
| [pls_jobsystem](pls_jobsystem/README.md) | PLS Job System 日本語化（動的ジョブ管理・React NUI・フォルダ名 `pls_jobsystem` 固定・原作 MIT） |
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

## トラブルシュート

| 現象 | 確認すること |
| --- | --- |
| **特定 MOD だけ Lua エラー（先頭が変な文字）** | 当該ファイルが **UTF-8 with BOM** になっていないか（エディタのステータスバーで確認）。 |
| **`ensure` したが動かない** | **依存リソース**が先に起動しているか、`dependencies` と README の順序。 |
| **`auto` 判定で ox が拾われない** | `server.cfg` で **`ensure ox_inventory`（等）が対象 MOD より前**か。 |
| **設定が意図せず初期値に戻った** | 第三者の PR・マージで `config.lua` が上書きされていないか。運営は Git で差分確認を推奨。 |

---

## ライセンス

- **リポジトリルート**の [`LICENSE`](LICENSE) は **MIT**（Copyright JP-Mods）。
- **個別リソース**に別ファイルや `fxmanifest` の `license` がある場合は、**そのリソース単位で優先**されます。
