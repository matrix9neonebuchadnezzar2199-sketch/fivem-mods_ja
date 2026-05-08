
# TECTON - FiveM Builder's Toolkit 開発指示書

**作業ディレクトリ**: `H:\CURSOR\Dev\fivem-mods_ja\tecton-fivem`
**ライセンス**: LGPL-3.0
**用途**: 無料OSS公開のみ（商用配布なし）
**プロジェクト名**: TECTON
**リソース名**: `tecton`
**コマンド**: `/tecton`（短縮 `/tec`）
**DBプレフィクス**: `tec_`

## 0. プロジェクト概要

GTA V / FiveMサーバー上で、管理者・ビルダーが家具・ドア・駐車場・スタッシュを直感的に配置・管理できるOSSツール「TECTON」を開発する。日本語UIと日本語ドキュメントを第一級でサポートし、特に**逆引きヘルプ**を必須機能とする。

技術スタックは Lua（クライアント／サーバー）、TypeScript + React + Vite（NUI）、oxmysql、ox_lib、object_gizmo、ox_doorlock、ox_inventory。

## 1. 初期セットアップ手順（Cursorが最初に実行する）

```powershell
cd H:\CURSOR\Dev\fivem-mods_ja\tecton-fivem
git init
git branch -M main
```

ディレクトリ構成は次節の通り作成。LGPL-3.0全文を `LICENSE` に配置。`.gitignore` にはNode/Vite/IDE系の標準的な除外を記載（`node_modules/`, `web/dist/`, `.vscode/`, `.idea/`, `*.log`, `.DS_Store` 等）。

`.editorconfig` を配置：
```
root = true
[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
[*.lua]
indent_size = 4
```

全Luaファイルと全TS/TSXファイルの先頭にSPDX識別子 `-- SPDX-License-Identifier: LGPL-3.0-or-later` または `// SPDX-License-Identifier: LGPL-3.0-or-later` を必ず入れる。

## 2. ディレクトリ構成

```
tecton-fivem/
├── LICENSE
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── .gitignore
├── .editorconfig
├── fxmanifest.lua
├── docs/
│   └── ja/
│       ├── spec.md                # 本指示書
│       ├── getting-started.md
│       ├── reverse-index.md       # 逆引きヘルプの原本
│       ├── ui-guide.md
│       ├── shortcuts.md
│       ├── data-model.md
│       ├── troubleshooting.md
│       ├── faq.md
│       └── contributing-thumbnails.md
├── config/
│   ├── config.lua
│   ├── props.lua
│   └── permissions.lua
├── client/
│   ├── main.lua
│   ├── gizmo.lua
│   ├── placement.lua
│   ├── snap.lua
│   ├── history.lua
│   ├── autosave.lua
│   ├── nui_bridge.lua
│   └── modes/
│       ├── furniture.lua
│       ├── door.lua
│       ├── parking.lua
│       └── stash.lua
├── server/
│   ├── main.lua
│   ├── db.lua
│   ├── history.lua
│   ├── autosave.lua
│   ├── recover.lua
│   └── api.lua
├── shared/
│   ├── types.lua
│   └── enums.lua
├── sql/
│   └── install.sql
├── tools/
│   └── thumb_gen/                 # サムネ生成スクリプト
├── assets/
│   └── thumbnails/
└── web/
    ├── package.json
    ├── vite.config.ts
    ├── tsconfig.json
    ├── index.html
    └── src/
        ├── main.tsx
        ├── App.tsx
        ├── theme.ts
        ├── i18n/ja.ts
        ├── store/
        │   ├── builderStore.ts
        │   ├── historyStore.ts
        │   └── helpStore.ts
        ├── components/
        │   ├── Sidebar.tsx
        │   ├── CategoryTree.tsx
        │   ├── PropGrid.tsx
        │   ├── SearchBar.tsx
        │   ├── FilterPanel.tsx
        │   ├── RecentList.tsx
        │   ├── FavoritesList.tsx
        │   ├── ColorPalette.tsx
        │   ├── TransformPanel.tsx
        │   ├── HistoryPanel.tsx
        │   ├── HelpDrawer.tsx
        │   └── ReverseHelp.tsx
        └── pages/
            ├── Builder.tsx
            └── Help.tsx
```

## 3. fxmanifest.lua

```lua
-- SPDX-License-Identifier: LGPL-3.0-or-later
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TECTON Contributors'
description 'TECTON - A builder''s toolkit for FiveM'
version '0.1.0'
repository 'https://github.com/<your-account>/tecton-fivem'
license 'LGPL-3.0-or-later'

shared_scripts {
  '@ox_lib/init.lua',
  'shared/*.lua',
  'config/*.lua'
}

client_scripts { 'client/**/*.lua' }
server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/**/*.lua'
}

ui_page 'web/dist/index.html'
files {
  'web/dist/index.html',
  'web/dist/assets/*',
  'assets/thumbnails/*.webp',
  'docs/ja/reverse-index.json'
}

dependencies { 'ox_lib', 'oxmysql', 'object_gizmo' }
```

ox_doorlock と ox_inventory は任意依存とし、起動時に `GetResourceState` で検出。

## 4. データベース（sql/install.sql）

```sql
CREATE TABLE IF NOT EXISTS tec_objects (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  category      VARCHAR(32) NOT NULL,
  model         VARCHAR(64) NOT NULL,
  pos_x DOUBLE, pos_y DOUBLE, pos_z DOUBLE,
  rot_x DOUBLE, rot_y DOUBLE, rot_z DOUBLE,
  meta          JSON NULL,
  scene_id      VARCHAR(64) NOT NULL,
  created_by    VARCHAR(64),
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at    TIMESTAMP NULL,
  INDEX idx_scene (scene_id),
  INDEX idx_cat (category)
);

CREATE TABLE IF NOT EXISTS tec_history (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  scene_id    VARCHAR(64) NOT NULL,
  user_id     VARCHAR(64),
  action      VARCHAR(16) NOT NULL,
  target_id   INT NULL,
  before_data JSON NULL,
  after_data  JSON NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_scene_time (scene_id, created_at)
);

CREATE TABLE IF NOT EXISTS tec_autosave (
  scene_id   VARCHAR(64) PRIMARY KEY,
  snapshot   JSON NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tec_user_prefs (
  user_id    VARCHAR(64) PRIMARY KEY,
  recents    JSON,
  favorites  JSON,
  ui_state   JSON
);
```

## 5. 設定ファイル（config/）

`config/config.lua`：DB接続前提、シーン既定値、オートセーブ間隔、Undo保持件数（既定500）、UI色テーマ、ショートカット既定値、ホットキー（既定 `F2` でビルダー、`F1` でヘルプ）。

`config/permissions.lua`：ACE権限名 `tecton.use` `tecton.delete` `tecton.admin`。

`config/props.lua`：カテゴリツリーとプロップ辞書。初版はShiftyWreckzz/prop-listをベースに整形（取り込みスクリプト `tools/import_props.mjs` を同梱）。スキーマは前回提示の通り。

## 6. UI仕様

レイアウトは左サイドバー（カテゴリツリー＋検索）、中央透過キャンバス（ゲーム画面が見える）、右パネル（トランスフォーム＋カラー＋履歴＋ヘルプドロワー）、上部ツールバー（モード切替・Undo/Redo・保存・ヘルプ・閉じる）。

文字サイズ最小14px、見出し18px以上、背景 `rgba(20,22,28,0.92)`、文字 `#F5F7FA`、アクセント `#4FC3F7`。WCAG AA以上のコントラストを確保し、ハイコントラストモードも提供。

カテゴリツリーは折りたたみ式、各ノードに件数バッジ。ルートに「最近使用」「お気に入り」「全て」を常設。検索はインクリメンタル、タグ・色・サイズ・チンク可否のフィルタチップ。

プロップグリッドはサムネ画像必須、無い場合はプレースホルダ＋警告。ホバーでモデル名・タグ・カテゴリパスをツールチップ表示。

カラーパレットは `tintable=true` のみ表示。木材／金属／ファブリック／カスタムRGB＋HEX入力。

トランスフォームパネルはXYZ位置・回転・スケール（ユニフォーム＋個別）。ステップ `0.01 / 0.1 / 1.0` 切替。サーフェススナップ、グリッドスナップ（0.05/0.1/0.25/0.5/1.0）、回転スナップ（1°/5°/15°/45°/90°）、ピボット切替（中心／底面）、隣接スナップ。

履歴パネルは時系列で「いつ・誰が・何を」一覧、クリックでプレビュー、確定で復元。

## 7. 逆引きヘルプ（必須）

`docs/ja/reverse-index.md` をシングルソースとし、ビルド時に `docs/ja/reverse-index.json` へ変換してNUIから読み込む。スキーマと初期項目は前回提示の通り（30項目以上）。検索＋タグフィルタ＋カードリスト＋ステップチェック＋関連リンク。

最重要：UI右上の「？やりたいことから探す」ボタンを常設し、`F1` で逆引きヘルプを直接開く。通常ヘルプとはタブ切替。

## 8. ショートカット（既定）

`F2` 開閉、`F1` ヘルプ、`Ctrl+Z/Ctrl+Shift+Z` Undo/Redo、`Ctrl+S` 保存、`Ctrl+D` 複製、`Delete` 削除、`G` グリッドスナップ、`R` 回転、`T` 移動、`Y` 回転スナップ、`Shift+ドラッグ` 等倍スケール、`Alt` 微調整、`Esc` キャンセル、`F5` シーン再読込。すべて設定でリバインド可能。

## 9. 履歴・オートセーブ・復帰

クライアント Zustand と Lua の二層で操作直後に履歴push、サーバーへ送信、サーバーは `tec_history` 追記＋`tec_objects` 更新＋`tec_autosave` 全体スナップショット上書き。サーバー再起動時に `server/recover.lua` で整合性確認とリプレイ復元。連続移動は500msコアレッシングでログ汚染を防ぐ。

## 10. 連携モジュール

家具モードはプロップ配置＋meta（色／スタッシュID／タグ）。スタッシュモードはターゲットでフォーカス→ox_inventory `RegisterStash` で動的登録、metaに保存、再起動時に再登録。ドアモードはox_doorlockへ委譲（`addDoor` API or `/doorlock` UI）。両開き対応で2エンティティを1ペアとして保持。駐車場モードは座標＋向き＋半径を保存し、`data/parking.json` に汎用フォーマットでも書き出し（mh-parking / Az_parking 等とのブリッジ）。

## 11. README.md に必須記載

プロジェクト名 TECTON とタグライン「A builder's toolkit for FiveM」、LGPL-3.0であること、商用配布想定なし、依存リソース導入手順、SQL適用手順、初回起動手順、ショートカット一覧、逆引きヘルプ導線、コントリビュート方法、サムネ提供のお願い、object_gizmo / ox_lib / ox_inventory / ox_doorlock / ShiftyWreckzz prop-list へのクレジット。

## 12. マイルストーン

M1 最小動作：ビルダー起動／プロップ選択／ギズモ配置／DB保存／再起動後復元。
M2 UI完全版：ツリー・検索・フィルタ・最近使用・お気に入り・サムネ・カラーパレット・トランスフォーム・スナップ全種・ショートカット。
M3 堅牢化：履歴パネル・Undo/Redo・コアレッシング・オートセーブ・クラッシュ復帰・権限。
M4 連携：ドア／駐車場／スタッシュと外部リソース連携。
M5 ヘルプ：通常ヘルプ＋逆引きヘルプ初期項目を全執筆、検索とタグ完備。
M6 公開：README/docs整備、CIで `web` ビルド、`v0.1.0` タグ。

## 13. Cursorへの最初の指示プロンプト

```
作業ディレクトリは H:\CURSOR\Dev\fivem-mods_ja\tecton-fivem です。
このディレクトリで以下を順に実施してください。

1. git init し、main ブランチを作成
2. docs/ja/spec.md（このファイルの内容）を保存
3. セクション2のディレクトリ構成を全て作成（空ファイル/.gitkeep可）
4. LICENSE に LGPL-3.0-or-later 全文を配置
5. .gitignore と .editorconfig を配置
6. fxmanifest.lua（セクション3）を作成
7. sql/install.sql（セクション4）を作成
8. config/config.lua, config/permissions.lua のスキーマ雛形を作成
9. README.md の最小版（プロジェクト名・タグライン・ライセンス・WIP表記）を作成
10. web/ に Vite + React + TypeScript プロジェクトを生成
    （pnpm create vite web -- --template react-ts 相当）

全Lua/TSファイルの先頭に SPDX-License-Identifier: LGPL-3.0-or-later を入れること。
完了したら git add -A して初回コミット "chore: scaffold TECTON project" を作成してください。
```

M2以降は別プロンプトで段階的に投げる。
