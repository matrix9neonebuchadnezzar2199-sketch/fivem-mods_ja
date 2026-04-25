# FiveM JP-Mods 開発プロジェクト

## このプロジェクトについて
日本語FiveM RPサーバー運営者向けの無料MODを開発する趣味プロジェクト。
対象はGTA5（FiveM）およびGTA6（将来のROME/SixM）。

## 絶対に守ること
- 各MODは `jp-<名前>/` フォルダで完全に独立させる（standalone）
- ESX・QBCore等のフレームワークに依存しない
- 他のMODフォルダのファイルを参照しない
- UIテキスト・コメントは日本語をデフォルトにする
- config.lua はサーバー運営者が読めるよう全項目に日本語コメントを書く

## MODのフォルダ構造（必ずこの形にする）
jp-<mod名>/ ├── fxmanifest.lua ├── config.lua ├── locales/ │ └── ja.lua ├── client/ │ └── main.lua ├── server/ │ └── main.lua └── html/（NUIが必要な場合のみ）


## 開発フロー
1. Cursorでコードを書く
2. `scripts\deploy.bat jp-<mod名>` でテストサーバーにコピー
3. txAdminコンソールで `refresh; restart jp-<mod名>`
4. FiveMクライアントから localhost:30120 で接続して確認
5. F8でエラーログを確認、問題があればCursorに戻って修正

## テストサーバーのパス
C:\FiveMServer\server-data\resources\[jp-mods]\

## イベント命名規則
すべてのイベント名は `jp-<mod名>:アクション名` とする。
例: `jp-taxi:startShift`, `jp-gps-tracker:throwDevice`
