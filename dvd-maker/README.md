# DVD Maker for FiveM

プレイヤーが **空の DVD** アイテムに YouTube 動画のタイトルと URL を書き込み、**データ入り DVD** として所持・再生できるスタンドアロンリソースです。**ox_inventory 専用**で、フレームワーク連携は行いません。

DVD を使うと NUI が開き、記録または再生メニューから操作します。サーバー側で URL をホワイトリスト検証するため、任意のサイトへの埋め込みはできません。

## 機能一覧

- **空 DVD への記録**: タイトル（最大40文字）と YouTube URL を入力し、データ入り DVD に変換（空 DVD 1 枚消費）
- **データ入り DVD の再生**: メニューから YouTube を IFrame 埋め込みで再生（全画面に近いプレイヤー）
- **YouTube 動画のみ対応**: `youtube.com` / `youtu.be` / `m.youtube.com` の許可形式のみ

## 必要環境

- FiveM サーバー（Artifact は比較的新しいものを推奨）
- **ox_inventory**（本リソース以外のフレームワーク連携は未対応）

## インストール手順

1. 本フォルダを `resources/dvd-maker`（任意のリソース名で可）に配置する。
2. **ox_inventory** の `data/items.lua`（またはアイテムを定義しているファイル）に、下記「items.lua 追記例」をコピーして追記する。
3. 画像は **`html/img/disc_128_tight.png`**（空ディスク）と **`html/img/dvd_case_128_tight.png`**（ケース）が同梱想定です。差し替える場合は同じファイル名で置き換えてください（詳細は `html/img/README.txt`）。
4. 上記2ファイルを **ox_inventory のアイコン用ディレクトリ**（例: `ox_inventory/web/images/`）にもコピーする。`items.lua` の `image` は下記例のとおりファイル名で一致させる。
5. `server.cfg` に `ensure dvd-maker`（フォルダ名に合わせる）を追加する。
6. サーバーを `refresh` し、リソースを開始する。

### items.lua 追記例

```lua
['dvd_blank'] = {
    label = 'DVD（空）',
    weight = 20,
    stack = true,
    close = true,
    description = '何も記録されていないDVD',
    client = {
        image = 'disc_128_tight.png',
        export = 'dvd-maker.useBlank'
    }
},
['dvd_recorded'] = {
    label = 'DVD',
    weight = 20,
    stack = false,
    close = true,
    description = '映像が記録されたDVD',
    client = {
        image = 'dvd_case_128_tight.png',
        export = 'dvd-maker.useRecorded'
    }
},
```

※ リソースフォルダ名を `dvd-maker` 以外にした場合、`export` の `dvd-maker` 部分をその名前に合わせてください。

## 使い方

1. インベントリで **DVD（空）** を使用する → 作成メニューが開く。
2. タイトルと YouTube URL を入力し、「保存」する → 空 DVD が 1 枚消え、**metadata** にタイトル・URL が入った **DVD** が 1 枚付与される。
3. **DVD**（データ入り）を使用する → 再生メニューが開く。「再生」で動画プレイヤー画面へ。「停止してメニューに戻る」または動画終了でメニューに戻る。「取り消し」で NUI を閉じる。

## 設定（config.lua）

| 項目 | 説明 |
|------|------|
| `Config.BlankItem` | 空 DVD のアイテム名（既定: `dvd_blank`） |
| `Config.RecordedItem` | データ入り DVD のアイテム名（既定: `dvd_recorded`） |
| `Config.MaxTitleLength` | タイトル最大文字数（UTF-8 文字、既定: 40） |

## 既知の制限

- 動画ソースは **YouTube のみ**（サーバー側で URL ホワイトリスト）
- ブラウザの自動再生ポリシーにより、**初回はミュート再生**になる場合がある
- NUI は Vanilla JS のみ（ビルド不要）

## ライセンス

MIT License（詳細は [LICENSE](LICENSE)）。著作権表記の `YourName` は配布前に自分の名前へ置き換えてください。

## コントリビューション

バグ修正・改善のプルリクエストを歓迎します。大きな仕様変更の前には Issue で相談いただけると助かります。
