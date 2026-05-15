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
- **文字コード: 全テキストは UTF-8。UTF-8 with BOM（先頭 EF BB BF）は付けない**（Lua では BOM がパース失敗の原因になり得る）

## 言語（jp-tcgbook BOOK / NUI）

- **BOOK のユーザー向け UI** は `jp-tcgbook/html/js/i18n.js` で **日本語（`ja`）／英語（`en`）** を切り替える。選択値は `localStorage` キー `jp-tcgbook-ui-lang` に保存する（ゲーム本体の `locales/*.lua` とは別レイヤー）。
- **新規のユーザー向け文言**を追加するときは、`STR.ja` と **`STR.en` の両方に同じキー**で必ず入れる。欠けがあるとフォールバックでキー名がそのまま表示される。
- **静的 HTML**: `data-i18n`（text）、`data-i18n-html`（HTML）、`data-i18n-placeholder`、`data-i18n-title`、`data-i18n-aria`、`data-i18n-deck-tooltip`（→ `data-deck-tooltip` へ反映）を使う。モーダルを開いた後も言語切替で追従させる場合、`I18n.applyChrome()` がドキュメント全体に適用される。
- **動的 JS**: `I18n.t('key')`、プレースホルダは `I18n.tf('key', { name: value })`（`{name}` 置換）。
- **i18n 対象外でよいもの**: カード名・説明文・レアリティ等のマスタデータ、サーバーから返る任意エラーメッセージ本文、ログ用コメント・開発者向けコメント。
- **管理者 UI**（`jp-tcgbook/html/admin/`）は BOOK 本体とは別ページ。運用上英語化が必要になったら同ファイルに辞書を増やすか、共通の `i18n.js` を読み込んで同規約で揃える。

## MODのフォルダ構造（必ずこの形にする）
jp-<mod名>/ ├── fxmanifest.lua ├── config.lua ├── locales/ │ └── ja.lua ├── client/ │ └── main.lua ├── server/ │ └── main.lua └── html/（NUIが必要な場合のみ）


## 開発フロー
1. Cursorでコードを書く
2. `scripts\deploy.bat jp-<mod名>` でテストサーバーにコピー
3. txAdminコンソールで `refresh; restart jp-<mod名>`
4. FiveMクライアントから localhost:30120 で接続して確認
5. F8でエラーログを確認、問題があればCursorに戻って修正

## 開発日記（必須・エージェント含む）

詳細仕様は `.cursor/rules/dev-diary-required.mdc` を正とする。要点：

- **保存パス（MOD 作業）**: `<mod>/docs/YYYY-MM-DD_開発日記.html`
- **保存パス（横断作業）**: `docs/diary/YYYY-MM-DD_開発日記.html`（`.cursor/` 編集や複数 MOD を同時に触る作業）
- **1 日 1 ファイル**。同日に複数回作業した場合は内部に `<section id="entry-HHMM">` を追記
- **フォーマット**: HTML のみ。`.md` で新規追加しない（既存 `.md` は履歴として保持）
- **テンプレ**: `.cursor/templates/diary-template.html` を使う（CSS は `../../.cursor/templates/diary-style.css` が既定）
- **記録内容**: コミットハッシュ、変更ファイル一覧（➕📝❌🔄）、概要、未完了、動作確認結果
- **Cursor の AI エージェント**は、コード／設定／ドキュメントを変更したセッションの**終了前**に自律的に追記する（マスター指示を待たない）。実手順は `.cursor/skills/fivem-write-diary/SKILL.md`

## パス情報
- 開発フォルダ: H:\CURSOR\Dev\fivem-mods_ja\
- テストサーバー: H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources\[jp-mods]\
  - 旧記載 `C:\FiveMServer\server-data\resources\[jp-mods]\` は誤情報（訂正 2026-05-15）

## イベント命名規則
すべてのイベント名は `jp-<mod名>:アクション名` とする。
例: `jp-taxi:startShift`, `jp-gps-tracker:throwDevice`

## 関連ドキュメント
- 外部 MOD の日本語化・フォーク配布の判断・作業の型: [CONTRIBUTING_JP.md](CONTRIBUTING_JP.md)
