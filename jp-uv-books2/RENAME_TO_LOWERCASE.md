# リソース名・フォルダ名の注意（ox_inventory）

## なぜ `jp-uv-books2` か（ピリオドを含めない）

`ox_inventory` は `data/items.lua` の `server.export = 'リソース名.エクスポート名'` を、内部で **`string.strsplit('.', ...)` による「先頭の `.` だけ」**で二つに分けます。

そのため **`jp-uv-books2.0.book`** は次のように誤解釈されます。

- リソース名: `jp-uv-books2`
- エクスポート名: `0.book`（存在しない）

結果として **USE してもサーバー側の `exports('book', …)` に届かず無反応**になります。

対策: **フォルダ名・`ensure` 名に `.` を含めない**（本リポジトリでは **`jp-uv-books2`**）。

## サーバーで `jp-uv-books2.0` のまま入れている場合の移行

1. リソースフォルダを **`jp-uv-books2`** にリネーム（Windows で大小文字だけ変えるときは二段階リネームが必要なことがあります）。
2. `server.cfg` の `ensure jp-uv-books2.0` を **`ensure jp-uv-books2`** に変更。
3. `ox_inventory/data/items.lua` の本アイテムを **`server = { export = 'jp-uv-books2.book' }`** に変更。
4. **`ensure ox_inventory`** のあと **`ensure jp-uv-books2`**（またはサーバー再起動）。

## 旧メモ（Windows 大小文字の二段階リネーム）

`jp-UV-Books2.0` のような **大文字混じり**を `jp-uv-books2` に直すだけの場合:

```powershell
cd "H:\CURSOR\Dev"
Rename-Item -LiteralPath "jp-UV-Books2.0" "jp-uv-books2__tmp"
Rename-Item -LiteralPath "jp-uv-books2__tmp" "jp-uv-books2"
```

（Cursor 等で当該フォルダを開いたままだと失敗することがあります。先にワークスペースを閉じるか、親フォルダから開き直してください。）
