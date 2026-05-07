Cursorに渡す指示書をMarkdown形式で書きます。これをそのまま `H:\CURSOR\Dev\fivem-mods_ja\dvd-maker\INSTRUCTIONS.md` として保存するか、Cursorのチャットに貼り付けてください。

---

````markdown
# Cursor 作業指示書

## 作業ディレクトリ
`H:\CURSOR\Dev\fivem-mods_ja\dvd-maker`

このディレクトリ配下に、以下の仕様に従って **FiveM用リソース「dvd-maker」** を新規作成してください。一気に完成させてください。質問は不要です。仕様で曖昧な部分は指示書末尾の「判断基準」に従って自己判断してください。

---

## プロジェクト概要

FiveM（GTA V マルチプレイヤーMOD）用のリソース。プレイヤーが「空のDVD」アイテムにYouTube動画のタイトルとURLを書き込み、「データ入りDVD」として保存・再生できるシステム。完成後はMITライセンスでGitHub公開する。

## 技術要件

- フレームワーク: **ox_inventory 専用**（他フレームワーク互換は実装しない）
- サーバー/クライアント: Lua 5.4
- UI: HTML5 + CSS3 + Vanilla JavaScript（フレームワーク不使用）
- 外部依存: ox_inventory のみ
- ライセンス: MIT（著作権者名は `YourName` というプレースホルダー、年は `2026`）
- コメント言語: **日本語**
- README言語: **日本語**
- コードは他人のコードをコピーせず、ゼロから書くこと

---

## ディレクトリ構成（厳守）

```
dvd-maker/
├── fxmanifest.lua
├── LICENSE
├── README.md
├── .gitignore
├── config.lua
├── client/
│   └── main.lua
├── server/
│   └── main.lua
└── html/
    ├── index.html
    ├── style.css
    ├── script.js
    └── img/
        ├── README.txt          (画像配置の説明)
        ├── disc_128_tight.png       (同梱または差し替え。READMEで案内)
        └── dvd_case_128_tight.png   (同梱または差し替え。READMEで案内)
```

既定では `disc_128_tight.png`（空ディスク）と `dvd_case_128_tight.png`（ケース）を同梱する想定。`html/img/README.txt` でファイル名と ox_inventory へのコピーを案内する。

---

## アイテム仕様

ox_inventory に2種類のアイテムを登録する。**README に items.lua への追記コードを明記**すること（リソース側でアイテムを直接登録するのではなく、ユーザーがox_inventoryのitems.luaに追記する方式）。

### dvd_blank（空のDVD）
- label: `DVD（空）`
- weight: 20
- stack: true
- close: true
- description: `何も記録されていないDVD`
- 使用時: 作成メニューUIを開く

### dvd_recorded（データ入りDVD）
- label: `DVD`
- weight: 20
- stack: **false**（metadataで個別管理するため必須）
- close: true
- description: metadataのタイトルを動的表示
- 使用時: 再生メニューUIを開く
- metadata: `{ title = string, url = string }`

---

## 機能仕様

### 1. 空DVDの使用フロー
1. プレイヤーが `dvd_blank` を使う
2. NUI（作成画面）が開く。マウスフォーカス取得
3. 画面左に `disc_128_tight.png` を大きく表示
4. 画面右に作成メニュー
   - テキスト入力1: 「タイトル」（最大40文字）
   - テキスト入力2: 「YouTube動画のURL」
   - ボタン: 「保存」「取り消し」
5. 「保存」クリック時:
   - クライアント側で簡易バリデーション（両方空でないこと）
   - サーバーに `dvd-maker:create` イベント送信（title, url）
   - サーバーで再バリデーション後、`dvd_blank` を1個消費し、`dvd_recorded` を metadata付きで1個付与
   - NUIを閉じる
6. 「取り消し」クリック時: NUIを閉じるだけ

### 2. データ入りDVDの使用フロー
1. プレイヤーが `dvd_recorded` を使う（slot.metadata に title と url が入っている）
2. NUI（再生メニュー）が開く
3. 画面左に `dvd_case_128_tight.png` を大きく表示
4. 画面右に再生メニュー
   - 見出し: `タイトル: {metadata.title}`
   - ボタン: 「再生」「取り消し」
5. 「再生」クリック時:
   - 全画面の動画プレイヤー画面に遷移
   - YouTube IFrame埋め込みで自動再生
   - 画面下部に「停止してメニューに戻る」ボタン
6. 「停止」または動画終了時:
   - 自動的に再生メニュー画面に戻る
7. 「取り消し」クリック時: NUIを閉じる

---

## セキュリティ要件（必ず実装）

### サーバー側バリデーション（server/main.lua）
- title が string 型であること
- title の長さが 1〜40 文字であること
- url が string 型であること
- url が以下のいずれかの正規表現にマッチすること（YouTubeドメインのホワイトリスト）:
  - `^https://www%.youtube%.com/watch%?v=[%w%-_]+`
  - `^https://youtube%.com/watch%?v=[%w%-_]+`
  - `^https://youtu%.be/[%w%-_]+`
  - `^https://m%.youtube%.com/watch%?v=[%w%-_]+`
- バリデーション失敗時は何もせず即return（エラーログのみ出力）
- プレイヤーが `dvd_blank` を所持しているか `ox_inventory:Search` で確認
- アイテム消費は `ox_inventory:RemoveItem`、付与は `ox_inventory:AddItem` を使用

### NUI側XSS対策（html/script.js）
- titleをDOMに挿入する箇所はすべて `escapeHtml()` 関数を通すこと
- innerHTML で title を直接展開しない

### YouTube ID抽出（html/script.js）
- URLから動画IDを正規表現で抽出してから `https://www.youtube.com/embed/{ID}` 形式に変換して埋め込み
- 不正なURLが渡された場合は再生せずメニューに戻る

---

## コード詳細仕様

### fxmanifest.lua
```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'YourName'
description 'DVD recording and playback system for FiveM'
version '1.0.0'
license 'MIT'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png'
}

dependency 'ox_inventory'
```

### config.lua
- `Config.BlankItem = 'dvd_blank'`
- `Config.RecordedItem = 'dvd_recorded'`
- `Config.MaxTitleLength = 40`

### client/main.lua の必須エクスポート
- `exports('useBlank', function(data, slot) ... end)` — 空DVD使用時
- `exports('useRecorded', function(data, slot) ... end)` — データ入りDVD使用時

### NUIコールバック
- `save` — title と url を受け取りサーバーに転送
- `close` — NUIフォーカス解除
- 全コールバックで `cb('ok')` を必ず呼ぶこと

### NUI画面状態
- `hidden`（非表示）
- `create`（作成メニュー）
- `playerMenu`（再生メニュー）
- `playing`（動画再生中）

各状態の遷移は `script.js` 内で関数として実装する。

---

## デザイン要件（style.css）

- 背景: 黒の半透明オーバーレイ（`rgba(0,0,0,0.85)`）
- パネル: 角丸12px、内側パディング30px
- DVD画像: 200x200px
- フォント: sans-serif
- 文字色: 白
- ボタン: ホバー時に色が変わる
- 動画プレイヤー: 80vw × 80vh の中央配置
- レスポンシブは不要（FiveMはほぼ固定解像度想定）

---

## README.md に書く内容

以下のセクションを順に含めること:

1. **タイトル**: `# DVD Maker for FiveM`
2. **概要**: 1〜2段落の機能説明
3. **機能一覧**: 空DVDへの記録、データ入りDVDの再生、YouTube動画対応
4. **必要環境**:
   - FiveM サーバー（最新Artifact推奨）
   - ox_inventory
5. **インストール手順**:
   1. このリポジトリをクローンまたはダウンロードして `resources/dvd-maker` に配置
   2. ox_inventory の `data/items.lua` に以下を追記（コード例を記載）
   3. `html/img/disc_128_tight.png` と `html/img/dvd_case_128_tight.png` を配置（同梱想定）
   4. ox_inventory のアイコン用ディレクトリ（`web/images/`）にも同じPNGをコピー
   5. `server.cfg` に `ensure dvd-maker` を追加
6. **使い方**: 空DVDを使ってタイトルとURLを入力 → データ入りDVDが完成 → 使うと再生
7. **設定**: `config.lua` の項目説明
8. **既知の制限**: YouTubeのみ対応、自動再生ポリシーで初回ミュートになる可能性
9. **ライセンス**: MIT
10. **コントリビューション**: PR歓迎

### items.lua追記コードの例（READMEに含める）
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

---

## LICENSE ファイル

標準のMITライセンス全文を記載。著作権表記は:
```
Copyright (c) 2026 YourName
```

---

## .gitignore

以下を含めること:
```
*.log
.vscode/
.idea/
.DS_Store
Thumbs.db
node_modules/
```

---

## 判断基準（迷ったら）

- **エラーハンドリング**: サイレント失敗を基本とする。ユーザー向けのエラー通知は最小限（ox_inventoryのnotify機能があれば使ってよいが、必須ではない）
- **ログ**: サーバー側で `print()` による不正リクエストログだけ出力
- **コードスタイル**: 関数名はcamelCase、ローカル変数もcamelCase、定数はUPPER_SNAKE_CASE
- **行数**: 各ファイル150行以内を目安にシンプルに
- **コメント**: 各関数の冒頭に1〜2行の日本語コメント
- **未指定の細部**: 動作する最小実装で進め、過剰な機能追加はしない

---

## 完成後の確認チェックリスト

完成したら以下が満たされていることを確認してください:

- [ ] `fxmanifest.lua` に dependency 'ox_inventory' が記載されている
- [ ] `dvd_blank` と `dvd_recorded` の使用時にそれぞれ正しいUIが開く
- [ ] サーバー側で title 長さチェックとYouTube URLホワイトリストが機能する
- [ ] NUIで title が `escapeHtml` を通って表示される
- [ ] YouTube ID抽出が `youtube.com/watch?v=`、`youtu.be/`、`m.youtube.com` の3形式で動く
- [ ] 「停止してメニューに戻る」で再生メニューに戻る
- [ ] LICENSE が MIT で著作権者は `YourName`、年は `2026`
- [ ] README が日本語で全セクション記載されている
- [ ] コードコメントが日本語

---
