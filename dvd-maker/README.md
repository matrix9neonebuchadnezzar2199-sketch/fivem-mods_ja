# DVD Maker for FiveM

プレイヤーが **空の DVD** に YouTube 動画のタイトルと URL を書き込み、**データ入り DVD** として所持・再生できるスタンドアロンリソースです。**ox_inventory 専用**で、ESX / QBCore 等への依存はありません。

DVD をインベントリから「使う」と NUI が開きます。サーバー側で URL をホワイトリスト検証するため、YouTube 以外のサイトは使えません。

## 機能一覧

- **空 DVD への記録**: タイトル（最大40文字）と YouTube URL を入力 → データ入り DVD に変換（空 DVD 1 枚消費）
- **データ入り DVD の再生**: メニューから YouTube を IFrame で再生
- **動画ソース**: `youtube.com` / `youtu.be` / `m.youtube.com` の許可形式のみ

## 必要環境

- FiveM サーバー（比較的新しい Artifact を推奨）
- **ox_inventory**

---

## インストール手順（この順でやる）

### 1. リソースを置く

このフォルダ全体を、サーバーの `resources` 配下にコピーする。  
フォルダ名がそのままリソース名になる（例: `resources/[standalone]/dvd-maker`）。

以降の説明ではリソース名を **`dvd-maker`** と書く。別名にしたら、手順 3・4 の **`dvd-maker` の部分をすべてその名前に置き換える**。

### 2. server.cfg で起動する

`server.cfg` に次を追加する（フォルダ名に合わせる）。

```cfg
ensure dvd-maker
```

### 3. アイコン画像を ox_inventory にコピーする

インベントリ画面に絵を出すには、PNG を **ox_inventory 側**にも置く必要がある。

1. 本リソースの `html/img/disc_128_tight.png` をコピーする  
2. 本リソースの `html/img/dvd_case_128_tight.png` をコピーする  
3. 両方を **ox_inventory の画像フォルダ**へ貼り付ける（多くの環境では `ox_inventory/web/images/`）

ファイル名は **`disc_128_tight.png`** と **`dvd_case_128_tight.png`** のままにする（下記 `items.lua` の `image` と一致させる）。

画像を差し替える場合は、同じファイル名で上書きするか、`items.lua` の `image` と NUI 用 `html/script.js` のパスを自分で揃える。

### 4. ox_inventory にアイテムを追加する

**編集するファイルの例**: `ox_inventory/data/items.lua`  
（環境によっては `items.lua` を分割している。その場合は **アイテム定義がまとまっているファイル** に同じ内容を書く。）

`items.lua` はだいたい次の形になっている。

```lua
return {
    -- 既存のアイテム定義 …
    ['bread'] = { ... },

    -- ★ ここに下の2つを追記する（カンマの付き方に注意）
}
```

**その `return { ... }` の中身**に、次のブロックをコピーして貼り付ける。  
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

    -- DVD Maker: 記録済みDVD（タイトル・URL は metadata で1枚ずつ違う）
    ['dvd_recorded'] = {
        label = 'DVD',
        weight = 20,
        stack = false,
        close = true,
        description = '映像が記録されたDVD',
        client = {
            image = 'dvd_case_128_tight.png',
            export = 'dvd-maker.useRecorded',
        },
    },
```

**リソース名を `dvd-maker` 以外にした場合**は、次の2か所だけリソース名に合わせる。

- `export = 'あなたのリソース名.useBlank'`
- `export = 'あなたのリソース名.useRecorded'`

**config.lua の名前と揃える**: `dvd-maker/config.lua` の `Config.BlankItem` / `Config.RecordedItem` は、上の `['dvd_blank']` / `['dvd_recorded']` と**同じ文字列**にする（変えた場合は両方変更）。

| フィールド | 意味 |
|------------|------|
| `stack = true`（空） | 空 DVD は積み重ね可能 |
| `stack = false`（記録済み） | **必須**。1枚ごとに別の metadata（タイトル・URL）を持たせるため |
| `client.image` | `ox_inventory/web/images/` に置いた PNG のファイル名 |
| `client.export` | 使用時に呼ばれる export（リソース名がプレフィックス） |

### 5. サーバーで読み込み直す

コンソールまたは txAdmin で:

```
refresh
ensure dvd-maker
restart ox_inventory
```

（`items.lua` を変えたら **ox_inventory の再起動**が必要なことが多い。）

---

## 使い方（プレイヤー向け）

1. インベントリで **DVD（空）** を使う → 記録メニューが開く  
2. タイトルと YouTube URL を入れて保存 → 空 DVD が 1 枚減り、記録済み **DVD** が 1 枚増える  
3. 記録済み **DVD** を使う → 再生メニュー → 「再生」で動画。「停止してメニューに戻る」または終了でメニューへ。「取り消し」で閉じる  

## 設定（config.lua）

| 項目 | 説明 |
|------|------|
| `Config.BlankItem` | 空 DVD のアイテム名（既定: `dvd_blank`） |
| `Config.RecordedItem` | データ入り DVD のアイテム名（既定: `dvd_recorded`） |
| `Config.MaxTitleLength` | タイトル最大文字数（UTF-8 文字、既定: 40） |

## 既知の制限

- 動画は **YouTube のみ**（サーバー側ホワイトリスト）
- ブラウザの仕様で **初回はミュート再生**になりやすい  
- NUI はビルド不要（Vanilla JS）

## ライセンス

MIT License（[LICENSE](LICENSE)）。著作権表記の `YourName` は配布前に差し替えてください。

## コントリビューション

バグ修正・改善のプルリクエスト歓迎です。大きな仕様変更の前は Issue で相談いただけると助かります。
