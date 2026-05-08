# DVD Maker for FiveM

<p align="right"><strong>日本語</strong> · <a href="./README.en.md">English</a></p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-326CB5?style=flat-square" alt="MIT License"></a>
  <a href="https://www.lua.org/"><img src="https://img.shields.io/badge/Lua-5.4-000080?style=flat-square&logo=lua&logoColor=white" alt="Lua 5.4"></a>
  <img src="https://img.shields.io/badge/FiveM-cerulean-111111?style=flat-square" alt="FiveM">
  <a href="https://github.com/overextended/ox_inventory"><img src="https://img.shields.io/badge/ox__inventory-required-EF7F31?style=flat-square" alt="ox_inventory required"></a>
</p>

<p align="center">
  <sub>スタンドアロン · Vanilla JS NUI · YouTube IFrame API · サーバー側 URL 検証</sub>
</p>

> プレイヤーが **空の DVD** に YouTube の **タイトル**と **URL** を書き込み、**パッケージ種類**（不織布スリーブ / クリアケース / トールケース）に応じた **記録済み DVD** として所持・再生する **ox_inventory 専用**リソース。ESX / QBCore 等への依存はありません。  
> インベントリから「使う」と NUI が開きます。**トール**では任意の **表紙画像 HTTPS URL**、再生メニューは **左：表紙プレビュー** / **右：ケース画像**。記録時は **`metadata.image`**（`Config.InventorySlotImage`）でスロット絵を上書き（**`metadata.imageurl` は付与しません**）。

---

## 目次

- [機能一覧](#features)
- [必要環境](#requirements)
- [インストール手順](#install)
- [使い方（プレイヤー向け）](#usage)
- [トール表紙用: GitHub で画像を管理する](#github-cover-images)
- [記録時の metadata（参考）](#metadata)
- [設定（config.lua）](#config)
- [既知の制限](#limitations)
- [旧バージョンからの移行](#migration)
- [ライセンス](#license)
- [コントリビューション](#contributing)

---

<a id="features"></a>

## 機能一覧

- **空 DVD への記録**: DVD種類・タイトル（最大40文字）・YouTube URL（＋トールのみ表紙 URL 任意）→ 種類に応じた記録済みアイテム 1 枚付与（空 DVD 1 枚消費）
- **記録済み DVD の再生**: メニューから YouTube を IFrame で再生
- **インベントリ表示名**: 付与時の metadata に **`label = タイトル`** を入れるため、スロット名は入力タイトルになる（ox_inventory の仕様）
- **動画ソース**: `youtube.com` / `youtu.be` / `m.youtube.com` の許可形式のみ

<a id="requirements"></a>

## 必要環境

- FiveM サーバー（比較的新しい Artifact を推奨）
- **[ox_inventory](https://github.com/overextended/ox_inventory)**（汎用フレームワーク用ブリッジではなく **専用**の利用形）

---

<a id="install"></a>

## インストール手順（この順でやる）

### 1. リソースを置く

このフォルダ全体を、サーバーの `resources` 配下にコピーする。  
フォルダ名がそのままリソース名になる（例: `resources/[standalone]/dvd-maker`）。

以降の説明ではリソース名を **`dvd-maker`** と書く。別名にしたら、手順 3・4 の **`dvd-maker` の部分をすべてその名前に置き換える**。

**同梱の `html/` は NUI ビルド済み**です。`nui/src/` を変更した場合は `dvd-maker/nui` で `npm install` のあと **`npm run build`** を実行し、`html/index.html` と `html/assets/` を更新してください（ミニファイ済み JS/CSS が出力されます）。

### 2. server.cfg で起動する

`server.cfg` に次を追加する（フォルダ名に合わせる）。

```cfg
ensure dvd-maker
```

### 3. アイコン画像を ox_inventory にコピーする

インベントリ画面に絵を出すには、次の **4 ファイル**を本リソースの `html/img/` から **ox_inventory の画像フォルダ**へコピーする（多くの環境では `ox_inventory/web/images/`）。

| ファイル名 | 用途（同梱 PNG の意味） |
|------------|---------------------------|
| `disc_128_tight.png` | **空 DVD（`dvd_blank`）のみ**（素の白ディスク） |
| `dvd_case_128_tight.png` | 記録済み **不織布スリーブ**（`dvd_recorded1`） |
| `dvd_jewel_transparent_128.png` | 記録済み **クリアケース**（`dvd_recorded2`） |
| `dvd_case_text_transparent_128.png` | 記録済み **トールケース**（`dvd_recorded3`）。再生メニュー右のケース画像でも使用 |

**ファイル名は上表のとおり**にし、`items.lua` の `client.image` と一致させる。

### 4. ox_inventory にアイテムを追加する

**編集するファイルの例**: `ox_inventory/data/items.lua`  
（環境によっては `items.lua` を分割している。その場合は **アイテム定義がまとまっているファイル** に同じ内容を書く。）

`return { ... }` の中に、次のブロックをコピーして貼り付ける。  
既存の最後のアイテムの直後なら、**直前の行の末尾にカンマがあること**を確認する。

```lua
    -- DVD Maker: 空のDVD（記録前）
    ['dvd_blank'] = {
        label = 'DVD（空）',
        weight = 20,
        stack = true,
        close = true,
        description = '何も記録されていないDVD',
        client = {
            image = 'disc_128_tight.png',
            export = 'dvd-maker.useBlank',
        },
    },

    -- DVD Maker: 記録済み（不織布スリーブ想定）
    ['dvd_recorded1'] = {
        label = 'DVD（不織布）',
        weight = 20,
        stack = false,
        close = true,
        description = '不織布スリーブに入った記録済みDVD',
        client = {
            image = 'dvd_case_128_tight.png',
            export = 'dvd-maker.useRecorded',
        },
    },

    -- DVD Maker: 記録済み（クリアケース）
    ['dvd_recorded2'] = {
        label = 'DVD（クリア）',
        weight = 20,
        stack = false,
        close = true,
        description = 'クリアケース入りの記録済みDVD',
        client = {
            image = 'dvd_jewel_transparent_128.png',
            export = 'dvd-maker.useRecorded',
        },
    },

    -- DVD Maker: 記録済み（トールケース）
    ['dvd_recorded3'] = {
        label = 'DVD（トール）',
        weight = 20,
        stack = false,
        close = true,
        description = 'トールケース入りの記録済みDVD',
        client = {
            image = 'dvd_case_text_transparent_128.png',
            export = 'dvd-maker.useRecorded',
        },
    },
```

**リソース名を `dvd-maker` 以外にした場合**は、`export` のプレフィックスだけ置き換える。

**config.lua の対応**: `Config.BlankItem` および `Config.RecordedByPack` の値（`dvd_blank` / `dvd_recorded1`〜`3`）を、上のキーと**同じ文字列**にする。

| フィールド | 意味 |
|------------|------|
| `stack = true`（空） | 空 DVD は積み重ね可能 |
| `stack = false`（記録済み） | **必須**。1枚ごとに別の metadata を持たせるため |
| `client.image` | `ox_inventory/web/images/` に置いた PNG のファイル名 |
| `client.export` | 記録済み 3 種とも **`dvd-maker.useRecorded`** で共通可（**スロットのアイテム名** `dvd_recorded1`〜`3` で見た目を決定） |

**トールを選んだのにインベントリが別パッケージの絵になる場合**は、(1) **`items.lua` の `['dvd_recorded3']` の `client.image`** が **`dvd_case_text_transparent_128.png`** と一致しているか確認する。(2) **新規記録**では `metadata.image` に **拡張子なしベース名**（例: `dvd_case_text_transparent_128`）が入るため、古い枚は **再記録**すると揃うことが多い。

### 5. サーバーで読み込み直す

コンソールまたは txAdmin で:

```
refresh
ensure dvd-maker
restart ox_inventory
```

（`items.lua` を変えたら **ox_inventory の再起動**が必要なことが多い。）

---

<a id="usage"></a>

## 使い方（プレイヤー向け）

1. インベントリで **DVD（空）** を使う → 記録メニュー  
2. **DVD種類**（不織布 / クリア / トール）・タイトル・YouTube URL を入力。トールのときだけ **表紙画像 URL（https）** を任意入力 → 保存  
3. 空 DVD が 1 枚減り、選んだ種類の **記録済み DVD** が 1 枚増える（インベントリ名はタイトル）  
4. 記録済み DVD を使う → 再生メニュー → 「再生」。トールのときは **左に大きな表紙プレビュー**、**右に大きなケース**を表示。表紙は **クリックで拡大**（NUI 内の別レイヤー・`Esc` または「閉じる」で戻る）。表紙 URL が読めない場合は左パネルにエラー文を表示。  

> **インベントリのマス目の大きさ**は **ox_inventory の UI** 依存のため、このリソースからは変更できません（高解像度 PNG でわずかにシャープになる程度）。

<a id="github-cover-images"></a>

## トール表紙用: GitHub で画像を管理する（初心者向け）

**トールケース**の「表紙画像 URL」には、ゲーム内の `<img>` が **そのまま取れる HTTPS の画像**が必要です。無料で手堅いのが **GitHub の public リポジトリ**です（表紙用に **誰でも URL を開ける**前提なので **Private リポは向きません**）。

### 1. アカウントとリポジトリを作る

1. [GitHub](https://github.com) にサインアップ（未登録の場合）してログインする。  
2. 右上の **「+」→ New repository** を選ぶ。  
3. **Repository name** に好きな名前（例: `my-server-dvd-covers`）。  
4. **Public** を選ぶ（表紙 URL をゲームから読むには public が簡単）。  
5. **Create repository** で作成する。

### 2. 画像ファイルをリポジトリに置く

1. 作ったリポジトリのページを開く。  
2. **Add file → Upload files** を選ぶ。  
3. PC から **PNG などの画像**をドラッグ＆ドロップする。  
   - フォルダにまとめたい場合は、先に **Add file → Create new file** で、ファイル名欄に `covers/.gitkeep` のように **スラッシュ付きのパス**を入力して一度保存し、そのあと `covers/` の中に画像をアップロードしてもよい。  
4. 下の **Commit changes** を押して確定する。

**ファイル名**は英数字と `-` `_` だけにするとトラブルが少ない（日本語ファイル名も動くことはありますが、URL が長くなりやすいです）。

### 3. 表紙に貼る URL の取り方（ここが重要）

| URL の種類 | ゲーム内（本 MOD） |
|-------------|-------------------|
| `https://raw.githubusercontent.com/…` | **そのまま利用可**（推奨） |
| `https://github.com/…/blob/…/file.png` | **保存・再生時に raw へ自動変換** |
| リポジトリのトップ・フォルダ一覧・`github.com/…/tree/…` | **不可**（HTML ページのため） |

GitHub 上で **画像ファイルそのもの**を開いた状態にします（一覧ではなく、1 枚のファイルのページ）。

**おすすめ（raw の URL をそのまま使う）**

1. ファイルページの右上あたりにある **「Raw」** ボタンを押す。  
2. ブラウザが **画像だけ**（またはバイナリ）を表示した **別タブ**になる。  
3. そのタブの **アドレスバー**の URL を **すべて選択してコピー**する。  
   - 形式はだいたい  
     `https://raw.githubusercontent.com/ユーザー名/リポジトリ名/ブランチ名/フォルダ/ファイル名.png`  
   - この URL を DVD Maker の **表紙画像 URL** にそのまま貼ればよい。

**Raw を右クリックしてコピーする方法**

- ファイルページで **「Raw」** を **右クリック**し、**「リンクのアドレスをコピー」**（Chrome）や **「リンクの URL をコピー」**（Edge）を選ぶ。これも **raw.githubusercontent.com** の URL になる。Firefox など他ブラウザでも、**リンクの URL をコピー**に相当する項目を選べば同じです。

**GitHub の通常のファイルページの URL を貼ってもよい**

- ブラウザのアドレスが  
  `https://github.com/ユーザー/リポ/blob/main/画像.png`  
  のように **`/blob/`** 入りでも構いません。本 MOD が保存・再生時に **自動で raw の URL** に置き換えます。  
- ただし **「リポジトリのトップ」や「フォルダ一覧」の URL** は画像ではないので使えません。**必ず「1 ファイルのページ」か Raw** にしてください。

### 4. ゲーム内で使う

1. 空 DVD を使い、**DVD種類でトール**を選ぶ。  
2. **表紙画像 URL** に、上でコピーした **https で始まる文字列**を貼り付ける。  
3. タイトル・YouTube URL を入れて保存する。

うまくいかないときは、ブラウザで **同じ URL を新しいタブに貼る**と、**画像だけが表示されるか**確認してください。GitHub のログイン画面や 404 になっていれば、その URL はゲーム内でも読めません。

<a id="metadata"></a>

## 記録時の metadata（参考）

サーバーが付与する主なキー:

| キー | 説明 |
|------|------|
| `title` | 動画タイトル（再生 UI 用） |
| `url` | YouTube URL |
| `label` | インベントリ表示名（タイトルと同じ） |
| `pack` | `fushokufu` / `clear` / `tall`（クライアントの再生メニュー表示用） |
| `coverUrl` | トールかつ表紙指定時のみ（NUI 表紙プレビュー用） |
| `image` | ox スロット画像（**拡張子なし**のベース名。UI が自動で `.png` を付ける。`web/images/` に `ベース名.png` で置く） |

※旧版で付いた `metadata.imageurl` が残っているトール DVD は、ox がその URL を読めず **インベントリが透明**になることがあります。該当スロットの `imageurl` を運営ツール等で削除するか、アイテムを入れ直してください。

※記録が常に不織布（`dvd_recorded1`）になる場合は、**`refresh` / `restart dvd-maker` 後に NUI（`nui/` を `npm run build` した `html/assets/`）が最新か**確認してください。保存ペイロードは `dvdPack` キーで種類を送ります（環境によって JSON の `pack` が欠ける事例への回避）。

**付与アイテムの確認**: 記録成功時、**サーバーコンソール**に  
`[dvd-maker] 記録成功: 付与アイテム=dvd_recorded3 pack=tall player=…`  
のように出ます。ここが `dvd_recorded3` ならサーバーはトール用アイテムを渡しています（インベントリの絵は **`items.lua` の `client.image`** 次第）。

`pack` は `config.lua` の `Config.RecordedByPack` のキーと一致させてある。

<a id="config"></a>

## 設定（config.lua）

| 項目 | 説明 |
|------|------|
| `Config.BlankItem` | 空 DVD のアイテム名（既定: `dvd_blank`） |
| `Config.RecordedByPack` | `pack` 文字列 → 付与するアイテム名（`fushokufu`→`dvd_recorded1` など） |
| `Config.MaxTitleLength` | タイトル最大文字数（UTF-8 文字、既定: 40） |
| `Config.MaxCoverUrlLength` | 表紙 URL の最大長（既定: 768） |
| `Config.InventorySlotImage` | 種類ごとに `metadata.image` へ入れる **拡張子なし**のベース名（`.png` を付けると二重になり表示されない） |

<a id="limitations"></a>

## 既知の制限

- 動画は **YouTube のみ**（サーバー側ホワイトリスト）
- ブラウザの仕様で **初回はミュート再生**になりやすい  
- 表紙 URL は **ブラウザが `<img src>` で直接取れる直リンク**である必要があります。**Google Drive の「共有」リンク**（`drive.google.com/file/d/.../view` や `.../view?usp=sharing`）は **Web ページの URL** であり、画像バイナリではないため **そのままでは読み込めません**。`uc?export=view&id=ファイルID` 形式にしても **FiveM の NUI（CEF）ではブロック・CORS で失敗しがち**です。運用では **自サーバーに置いた `.png` の URL**、**imgbb / imgur 等の直リンク**、**GitHub raw** などを推奨してください。
- **GitHub**: `/blob/` のファイルページ URL は HTML のため `<img>` では読めませんが、本 MOD が **raw 直リンクへ自動変換**します。手順は上の **[トール表紙用: GitHub で画像を管理する](#github-cover-images)** を参照。  
- **Google フォト**の共有（例: [`photos.app.goo.gl/...`](https://photos.app.goo.gl/kgsEmayEjU962cFv5)）も **アルバム用の Web ページ**であり、**この MOD から「URL を渡すだけで表紙として表示する」ことはできません**（公式も直リンク用 URL を公開していないため）。単一写真を別ホストにアップするか、ブラウザで「画像だけ開いたときの URL」が **安定して取れる**場合のみ使えます（多くは期限付きで運用向きではありません）。保存時に共有ページっぽい URL だと **確認ダイアログ**が出ます。  
- 表紙画像は **NUI の CORS** により、配信元によっては表示できない場合があります。
- **ox_inventory の `metadata.image`** は **拡張子なし**のベース名のみ有効（公式 Web UI が `.png` を自動付与）。誤って `xxx.png` を入れると **`xxx.png.png`** になり **インベントリで絵が出ない**。修正後に作った DVD はサーバーが末尾 `.png` を剥がすが、**古いスロットは再記録**が必要なことがあります。
- NUI はビルド不要（Vanilla JS）

<a id="migration"></a>

## 旧バージョンからの移行

以前の **単一アイテム `dvd_recorded`** だけの構成から変わっています。既存プレイヤーに `dvd_recorded` が残っている場合は、運営で回収・付け替えするか、一時的に旧定義を併存させる必要があります。

<a id="license"></a>

## ライセンス

MIT License（[LICENSE](./LICENSE)）。著作権表示: **えいほー**（2026）。

<a id="contributing"></a>

## コントリビューション

バグ修正・改善のプルリクエスト歓迎です。大きな仕様変更の前は Issue で相談いただけると助かります。

---

<p align="center">
  <sub>ドキュメント · <a href="./README.md">日本語 README</a> · <a href="./README.en.md">English README</a></sub>
</p>
