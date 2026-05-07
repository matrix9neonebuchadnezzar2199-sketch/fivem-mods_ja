# Cursor 指示書: jp-renewedbanking2 v1.0.2-ja SQL 自動投入

## 0. 目的とスコープ

`jp-renewedbanking2` v1.0.1-ja を起点に、**サーバー初回起動時に `Renewed-Banking.sql` を自動実行してテーブルを作成する機能を追加**する。これにより phpMyAdmin / HeidiSQL からの手動 SQL 投入が不要になる。

**スコープ外（やらないこと）**

原作 Renewed-Banking のロジック変更（口座権限、トランザクション処理、money 移動仕様）。マイグレーション履歴管理（`_migrations` テーブル等）。**`Renewed-Banking.sql` の内容変更**（DDL 文言は本家互換のまま）。Web 側 (Svelte) の変更。

**SQL パーサの範囲（確定方針）**

- **行頭 `--` の単行コメント除去 + `;` で分割**でよい。現行 `Renewed-Banking.sql` に **`/* */` ブロックコメントや、文字列リテラル内の `;` は含まれない**前提（作業開始時に一度目視確認すること）。
- 将来 SQL が複雑化したら **パーサ拡張**または **別方式（マイグレーションツール／分割 SQL ファイル）** を `known_issues` と CHANGELOG の「既知の制限」に追記して検討。**v1.0.2-ja では `/* */` 対応を実装しない**（スコープと複雑さのトレードオフ）。

## 1. 前提条件

```powershell
cd <repo_root>\jp-renewedbanking2
git fetch origin --tags --prune
git checkout -b work/jp-renewedbanking2-v1.0.2 jp-renewedbanking2/v1.0.1-ja
```

ベースは **タグ `jp-renewedbanking2/v1.0.1-ja`** で固定する。具体ハッシュをコピペしない。`<repo_root>` は環境ごとに異なる（例: `H:\CURSOR\Dev\fivem-mods_ja`、`F:\Cursor\fivem-mods_ja`）。

開発フォルダ名は `jp-renewedbanking2`、サーバーで ensure する名前は **`Renewed-Banking`**。`LoadResourceFile` の第 1 引数も **`'Renewed-Banking'`** を使う（v1.0.1-ja で確立した方針）。SQL ファイルはリソースルートの **`Renewed-Banking.sql`**（`jp-renewedbanking2/Renewed-Banking.sql`）。

## 2. 環境準備

```powershell
cd web
pnpm install
pnpm run build
cd ..
luacheck client server --no-global --std=lua54
```

build と luacheck が v1.0.1-ja 時点と同じ結果（build 成功、luacheck は既知の警告のみ）であることを確認してから作業開始。`luacheck` が未インストールの環境では、マージ前にインストールするか、実施スキップを PR / 完了報告に明記する。

## 3. コミット分割（2 件）

### コミット 1: feat — SQL を起動時に自動投入

**対象ファイル**

- `server/main.lua`
- `fxmanifest.lua`

**作業内容**

`server/main.lua` の冒頭付近（既存の require / グローバル宣言の直後、メイン処理の前）に、起動時 SQL 自動投入処理を追加する。実装方針は以下:

oxmysql の起動完了を `GetResourceState('oxmysql') ~= 'started'` のポーリングで待つ。タイムアウト 10 秒、ポーリング間隔 100ms。タイムアウト時は警告ログを出して処理を中断（サーバー起動自体は止めない）。

`LoadResourceFile('Renewed-Banking', 'Renewed-Banking.sql')` で SQL ファイルを読み込む。読み込み失敗時は警告ログを出して処理を中断。

読み込んだ SQL 文字列を以下の手順で複数文に分解する:

1. 行頭 `--` で始まる単行コメントを除去（`/* */` 形式の複数行コメントは **現行 SQL に無い前提で対応不要**。将来追加する場合は known_issues を更新しパーコー拡張を検討）
2. `;` で分割
3. 各文の前後の空白・改行を `string.match` または `string.gsub` で除去
4. 空文字列をスキップ

分解した各 SQL 文を **`MySQL.query.await(trimmed)`** で逐次実行（プロジェクト既存の oxmysql await スタイルに合わせる。`jp-b2b_documents` の `promise` + `execute` コールバック方式に無理に合わせない）。

各文は `pcall` でラップしてエラーを捕捉し、失敗した文があればコンソールに警告ログを出す（`print('[Renewed-Banking] SQL execution warning: ' .. tostring(err))`）。1 文の失敗で全体を止めず、残りの文も続けて実行する（`CREATE TABLE IF NOT EXISTS` なので冪等で、既存環境で再実行しても害はない）。

全文の実行が完了したらコンソールに完了ログを出す（`print('[Renewed-Banking] DB schema check complete')`）。

`fxmanifest.lua` の **`files`** に **`'Renewed-Banking.sql'`** を追加する（`LoadResourceFile` で読むために必要）。既存の `files` ブロックに追記する。

**実装例（指針・既存スタイルに合わせて調整可）**

```lua
CreateThread(function()
    -- oxmysql 起動待ち（最大 10 秒）
    local timeout = 100
    while GetResourceState('oxmysql') ~= 'started' and timeout > 0 do
        Wait(100)
        timeout = timeout - 1
    end
    if GetResourceState('oxmysql') ~= 'started' then
        print('[Renewed-Banking] oxmysql not started, skip auto schema setup')
        return
    end

    local sql = LoadResourceFile('Renewed-Banking', 'Renewed-Banking.sql')
    if not sql or sql == '' then
        print('[Renewed-Banking] Renewed-Banking.sql not found, skip auto schema setup')
        return
    end

    -- 行頭 -- コメントを除去（単行のみ。現行 Renewed-Banking.sql 前提）
    sql = sql:gsub('%-%-[^\n]*', '')

    -- ; で分割して逐次実行
    for stmt in sql:gmatch('[^;]+') do
        local trimmed = stmt:match('^%s*(.-)%s*$')
        if trimmed and trimmed ~= '' then
            local ok, err = pcall(function()
                MySQL.query.await(trimmed)
            end)
            if not ok then
                print('[Renewed-Banking] SQL execution warning: ' .. tostring(err))
            end
        end
    end

    print('[Renewed-Banking] DB schema check complete')
end)
```

日本語コメントを併記すると保守性が高まる。

**完了条件**

- `luacheck client server --no-global --std=lua54` が v1.0.1-ja 時点と同程度（**新規の error を増やさない**。warning は既知の範囲で可）
- `pnpm run build` 成功（影響しないはずだが念のため）
- 実機で DB を空にした状態でサーバー起動 → 2 テーブル（`bank_accounts_new`、`player_transactions`）が自動作成されることを確認（実機テストは作業者の環境で実施可能なら。不可なら完了報告に「未実施、依頼者側で確認」と明記）

**コミットメッセージ例**

```
feat(jp-renewedbanking2): 起動時に Renewed-Banking.sql を自動投入

oxmysql 起動完了を待機後、SQL ファイルをセミコロン分割して
MySQL.query.await で逐次実行。手動 phpMyAdmin/HeidiSQL 不要化。
失敗時もサーバー起動は継続。
```

### コミット 2: docs — README・CHANGELOG・known_issues 更新

**対象ファイル**

- `README.md`
- `README.en.md`
- `CHANGELOG.ja.md`
- `docs/known_issues.md`

**作業内容**

`README.md` のセットアップ手順から「SQL を手動で流す」ステップを削除し、「初回起動時に自動でテーブルが作成される」旨に書き換える。`Renewed-Banking.sql` の場所は引き続き記載し、「手動投入も可能（DDL 確認・バックアップ復元用）」として補足する。

`README.en.md` も同様に更新（`## Install` / setup 相当セクション）。

`CHANGELOG.ja.md` の先頭に **既存形式**で v1.0.2-ja 節を追加する（`## [1.0.2-ja] - YYYY-MM-DD`）。例:

```markdown
## [1.0.2-ja] - YYYY-MM-DD

### 追加

- 起動時に `Renewed-Banking.sql` を自動投入する機能（手動 phpMyAdmin/HeidiSQL 不要化）。oxmysql 起動完了を待機後、SQL をセミコロン分割して `MySQL.query.await` で逐次実行。

### 変更

- `README.md` / `README.en.md` のセットアップ手順から手動 SQL 投入ステップを削除。

### 既知の制限

- SQL パーサは行頭 `--` 単行コメントと `;` 区切りの単純実装。`/* */` 複数行コメントや、文字列リテラル内の `;` には対応しない（現状の `Renewed-Banking.sql` には該当なし）。
```

`docs/known_issues.md` に「SQL 自動投入の制限」節を追加（CHANGELOG の「既知の制限」と同内容を詳述）。将来複雑な SQL を追加する場合はパーサ拡張またはマイグレーション方式への移行を検討、と注記。

**完了条件**

- README の手動 SQL 手順が削除または「任意」に落ちている
- CHANGELOG に `[1.0.2-ja]` 節が存在する
- `cd web && pnpm run check` で **0 errors / 0 warnings**（v1.0.1-ja と同様）

**コミットメッセージ例**

```
docs(jp-renewedbanking2): v1.0.2-ja CHANGELOG・README・known_issues を更新

手動 SQL 投入手順を README から削除し、自動投入の説明に差し替え。
SQL パーサの制限を known_issues に明記。
```

## 4. 各コミット共通の検証手順

```powershell
luacheck client server --no-global --std=lua54

cd web
pnpm run build
cd ..
```

`pnpm run check` は **コミット 2 完了時に 1 回**実施し、0 warnings を確認する。

## 5. 最終リリース手順

```powershell
git log --oneline jp-renewedbanking2/v1.0.1-ja..HEAD   # 2 コミットが並んでいることを確認
git tag -a jp-renewedbanking2/v1.0.2-ja -m "jp-renewedbanking2 v1.0.2-ja: SQL 自動投入"
git push origin work/jp-renewedbanking2-v1.0.2
git push origin jp-renewedbanking2/v1.0.2-ja
```

PR を作成する場合は、本指示書の章番号を引きつつ各コミットの diff サマリと検証結果を記載する。個人リポジトリで PR を経由しないなら、ローカルで `main` に merge commit でマージして push でも可:

```powershell
git checkout main
git pull origin main
git merge --no-ff work/jp-renewedbanking2-v1.0.2 -m "Merge branch 'work/jp-renewedbanking2-v1.0.2' into main (v1.0.2-ja)"
git push origin main
git push origin jp-renewedbanking2/v1.0.2-ja
```

**タグをリモートで付け替えた後**に他マシンで取り込む場合は `git fetch origin --tags --force` または一度 `git tag -d jp-renewedbanking2/v1.0.2-ja` してから `git fetch origin tag ...`（`docs/known_issues.md` / `INSTRUCTIONS_v1.0.1.md` と同旨）。

## 6. 完了報告フォーマット

- ブランチ名と最終コミットハッシュ 2 件
- タグ `jp-renewedbanking2/v1.0.2-ja` の確認
- `luacheck` 結果（v1.0.1-ja からの差分: 新規 error / 大幅な warning 増の有無）
- `pnpm run build` 結果
- `pnpm run check` 結果
- 実機テスト結果（DB を空にした状態でサーバー起動 → 2 テーブル自動作成を確認したか。未実施なら「未実施、依頼者側で確認」と明記）

## 7. 付録: 実機テスト手順（参考）

作業者環境で実機テスト可能な場合の手順。

1. テスト用 DB を用意（既存 DB と分離。`renewed_banking_test` 等の名前）
2. `server.cfg` の oxmysql 接続文字列をテスト用 DB に向ける
3. テスト用 DBで `DROP TABLE IF EXISTS bank_accounts_new, player_transactions;` を実行して空にする
4. FiveM サーバーを起動
5. コンソールに `[Renewed-Banking] DB schema check complete` が出力されることを確認
6. テスト用 DB で `SHOW TABLES LIKE 'bank_accounts_new';` と `SHOW TABLES LIKE 'player_transactions';` を実行し、両テーブルが存在することを確認
7. もう一度サーバーを再起動し、エラーや警告が出ないことを確認（既存テーブルへの再実行が冪等であることの確認）

---

## Cursor への渡し方

本ファイルをそのまま作業指示として使ってよい。修正が入った場合は本ファイルを更新し、コミットに含める。

**最終確認（回答）**

- **Cursor に渡してよいか**: **OK**（上記のとおり `CHANGELOG` 見出し形式・SQL パーサ範囲・`MySQL.query.await` 方針を追記済み）。
- **SQL パーサ**: **行頭 `--` のみ + `;` 分割で v1.0.2-ja は十分**。`/* */` は現行 SQL 非含有を前提にスコープ外。将来必要なら別タスク。
