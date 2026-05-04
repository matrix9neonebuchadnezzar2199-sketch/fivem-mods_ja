# フォルダ名を `jp-uv-books2.0` に統一する手順（Linux / ensure 互換）

Git インデックス上の **`jp-uv-books2.0/` 重複エントリは削除済み**です。残作業は **作業ツールを閉じた状態**で、ディスク上のフォルダ名だけを小文字に揃えることです（Windows は大小無視のため二段階リネームが必要）。

## 前提

- Cursor（またはエクスプローラー）で **`jp-UV-Books2.0` をワークスペースに開いているとリネームに失敗**します。先にワークスペースを閉じるか、親フォルダ `Dev` を開き直してください。

## PowerShell（`H:\CURSOR\Dev` で実行）

```powershell
cd "H:\CURSOR\Dev"

git rm -r --cached "jp-UV-Books2.0" 2>$null
git rm -r --cached "jp-uv-books2.0" 2>$null

if (Test-Path "jp-UV-Books2.0") {
    Rename-Item -LiteralPath "jp-UV-Books2.0" "jp-uv-books2.0__tmp"
    Rename-Item -LiteralPath "jp-uv-books2.0__tmp" "jp-uv-books2.0"
}

git add "jp-uv-books2.0"
git status
git commit -m "chore: ディレクトリ名を jp-uv-books2.0 に小文字統一（Linux互換性）"
git push origin main
```

## 確認

```powershell
git ls-files | Select-String "jp-UV-Books2"   # 出力なし
Get-ChildItem -Directory "H:\CURSOR\Dev\jp-*" | Where-Object { $_.Name -match "book" }
```

`jp-uv-books2.0` のみが存在し、`ensure jp-uv-books2.0` と README の記述が一致すれば完了です。
