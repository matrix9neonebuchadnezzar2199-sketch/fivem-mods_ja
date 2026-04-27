# 文字コード方針（全リポジトリ共通）

全作業で次を守る。詳細は `.cursor/rules/utf8-text-encoding.mdc`（Cursor が参照）と同内容。

## 必須

- テキストは **UTF-8**。
- **UTF-8 with BOM（先頭バイト `EF BB BF`）を付けない。**

## 理由

- **Lua**（`shared_script`、特に `data/*.lua`）に BOM があると、先頭行が壊れ `unexpected symbol near '<\239>'` 等のパース失敗になる。
- 日本語を含む **config / NUI / README** も、意図しない BOM を避ける。

## 作業

- 保存前にエディタの表記を **「UTF-8」**（BOM なし）に。 **「UTF-8 with BOM」**は使わない。
- **PowerShell** 単体で `.lua` を `Set-Content` すると BOM が付きやすい。避けるか、`System.Text.UTF8Encoding($false)` で書き出す。

## 再発の例

- 出題庫の「初級ファイル」だけ正しく、「中上級用だけ」別ツールで触った → その2ファイルにだけ BOM → 難易度別の不具合。

Git にコミットする場合、先頭 3 バイトが `EF BB BF` になっていないか注意する。
