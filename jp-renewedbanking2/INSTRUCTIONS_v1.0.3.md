# jp-renewedbanking2 v1.0.3-ja 指示書

## 0. 目的とスコープ

v1.0.1-ja / v1.0.2-ja で残った 4 つの実機バグを修正する hotfix リリース。原作 Renewed-Banking のコアロジック（取引・口座権限・通知）には触れない。Web の UI レイアウトも最小限の追加のみに留める。

本リリースで修正する範囲は次の 4 点に限定する。それ以外の修正・リファクタは v1.0.4-ja 以降に持ち越す。

## 1. 問題と原因

### バグ 1: メイン画面のボタンラベル（入金・出金・送金）が見えない

**問題**: ATM/銀行 NPC で UI を開くと、メイン画面のオレンジ/グレーのボタン上にラベルが表示されない。ポップアップ側のラベル（金額入力など）は正常。

**原因**: v1.0.1-ja のコミット 1（i18n 修正）で Web 側は `useNuiEvent('updateLocale', payload => translations.set(payload.translations))` という購読を持つようになったが、Lua 側で対応する `SendNUIMessage({action='updateLocale', ...})` を送る実装が追加されなかった。結果として `$translations` ストアが空のまま `$translations.deposit_but` などが `undefined` を返し、ボタンラベルが空文字描画される。

`debugData` では `updateLocale` を発火しているためブラウザ単体では動くが、FiveM 実機では Lua からのメッセージが必須であり、そこが欠落している。

### バグ 2: ESC でメニューを閉じてもキャラが ATM 前で固まる

**問題**: メイン画面 ESC（パターン A）でも、ポップアップ → メイン画面の ESC（パターン B）でも、UI は消えるがキャラが ATM の前で固まり、移動・ALT などのキー入力が一切効かなくなる。F8 から `renewedbanking:close` を実行すると復帰する。

**原因**: `client/main.lua` の `closeInterface` コールバックで以下が漏れている。

- `SetNuiFocus(false, false)` の呼び出しが条件分岐の中にあり ESC 経路で実行されないか、または呼ばれていても十分でない。
- `openBankUI` で開始した `PROP_HUMAN_ATM` シナリオを `ClearPedTasksImmediately(PlayerPedId())` で解除していない。

シナリオが残ったままだとキャラはアニメーション再生中の扱いになり、移動入力を受け付けない。F8 の `renewedbanking:close` コマンドだけが復帰できているのは、そちらに `ClearPedTasksImmediately` 相当の処理が入っているため。`closeInterface` 側にも同等の処理を追加する必要がある。

### バグ 3: SQL 投入の二重実装

**問題**: 機能上の不具合は出ていないが、`server/main.lua` 冒頭に元の `createTables` 関数と `MySQL.transaction.await(...)` 経由の DDL が残っており、v1.0.2-ja で追加した `LoadResourceFile('Renewed-Banking','Renewed-Banking.sql')` 経由の自動投入と二重で動いている。

**原因**: v1.0.2-ja の作業時に新規経路を追加したが、原作の `createTables` を撤去しなかった。`CREATE TABLE IF NOT EXISTS` で冪等のため壊れていないが、保守性とログの分かりにくさが残る。**ユーザー選択: A（v1.0.2 経路に一本化）**。

### バグ 5: UI に閉じるボタンが無い

**問題**: 銀行 UI のメイン画面・ポップアップ画面に閉じるボタン（× / 閉じる）が存在しない。ESC が壊れている現状では UI から脱出する手段が `renewedbanking:close` コマンドしかない。

**原因**: 原作 Renewed-Banking には元々画面右上に閉じるボタンが存在する。v1.0.1-ja のコミット 4（HelpModal の a11y 修正）またはコミット 5（Svelte 4 / Rollup 4 移行）の副作用で、メイン画面の閉じるボタンの DOM が消えた、もしくは見えない位置にずれた可能性が高い。バグ 2 を修正しても予防線として閉じるボタンは必須。

## 2. 事前準備

```powershell
cd H:\CURSOR\Dev\fivem-mods_ja\jp-renewedbanking2
git fetch origin --tags --prune
git checkout -b work/jp-renewedbanking2-v1.0.3 jp-renewedbanking2/v1.0.2-ja
```

ベースタグ: `jp-renewedbanking2/v1.0.2-ja`
作業ブランチ: `work/jp-renewedbanking2-v1.0.3`
最終タグ: `jp-renewedbanking2/v1.0.3-ja`
fxmanifest.lua の `version` は `'2.1.4-ja.3'` に更新する（コミット 4 と同梱可）。

環境セットアップ（Web 側修正がある場合のみ実施）:

```powershell
cd web
pnpm install   # pnpm が無ければ npm install -g pnpm@9
pnpm run build
cd ..
```

luacheck がローカルにインストール済みであれば併走させる:

```powershell
luacheck client server --no-global --std=lua54
```

## 3. コミット計画（4 コミット、各コミット単独でビルド・lint が通ること）

### コミット 1: feat — Lua から updateLocale を送信

対象バグ: バグ 1。

対象ファイル:

- `client/main.lua`
- `client/framework.lua`（必要なら）

実装方針:

1. `openBankUI` 関数の冒頭、`SetNuiFocus(true, true)` の直前に翻訳データを送信する処理を挿入する。
2. 翻訳データは `LoadResourceFile('Renewed-Banking', ('locales/%s.json'):format(GetConvar('ox:locale', 'en')))` で読み込み、`json.decode` でテーブル化する。失敗時は `en.json` にフォールバックする。
3. `SendNUIMessage({ action = 'updateLocale', translations = <table>, currency = Config.currency or 'USD' })` を送信する。
4. 性能のためモジュールロード時に一度だけ読み込み、`local cachedTranslations` にキャッシュする。`openBankUI` の度にファイル I/O は行わない。
5. 失敗時は `print('[Renewed-Banking] locale load failed: '..tostring(err))` で警告ログを出すのみで処理は継続する（UI は空ラベルになるが起動は阻害しない）。

サンプルコード（参考、実装はコードベースに合わせて調整）:

```lua
local cachedTranslations
local function loadTranslations()
    if cachedTranslations then return cachedTranslations end
    local locale = GetConvar('ox:locale', 'en')
    local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(locale))
    if not raw then
        raw = LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')
    end
    local ok, decoded = pcall(json.decode, raw or '{}')
    cachedTranslations = ok and decoded or {}
    return cachedTranslations
end
```

`openBankUI` 内の SendNUIMessage 順序: `updateLocale` → `setVisible`（既存）。`setVisible` より前に翻訳が届いていれば、初回描画時にラベルが入る。

完了条件:

- ATM/銀行 NPC を開いた瞬間にメイン画面のオレンジ/グレーボタンに「入金」「出金」「送金」が表示される。
- `pnpm run build`（または `npm run build`）が 0 警告で通る。
- luacheck の警告総数が v1.0.2-ja から増えない。

コミットメッセージ:

```
feat(jp-renewedbanking2): Lua から updateLocale を送信して翻訳ストアを初期化
```

### コミット 2: fix — closeInterface でシナリオ解除とフォーカス解除を実装

対象バグ: バグ 2。

対象ファイル:

- `client/main.lua`

実装方針:

1. `closeInterface` の `RegisterNUICallback` 内で、以下を順に実行する。

   ```lua
   SetNuiFocus(false, false)
   ClearPedTasksImmediately(PlayerPedId())
   isVisible = false   -- 既存のフラグがあればそれを使う
   cb('ok')            -- 既存の cb 呼び出しを維持
   ```

2. F8 用の `renewedbanking:close` コマンドハンドラも同じ 3 行を呼ぶよう統一する。重複を避けるため `local function closeBankUI() ... end` を定義し、両者から呼び出す形にリファクタする。
3. `openBankUI` 側で `TaskStartScenarioInPlace(ped, 'PROP_HUMAN_ATM', 0, true)` を実行している場合、それに対応する `ClearPedTasksImmediately` がここで効く。シナリオを開始していない経路（NPC バンカー等）でも `ClearPedTasksImmediately` を呼んで害は無い。

完了条件:

- パターン A（メイン画面 ESC）でキャラがすぐに動けるようになる。
- パターン B（ポップアップから ESC で閉じた後の状態）でもキャラが動ける。
- ALT・移動キーが正常に反応する。
- F8 の `renewedbanking:close` も従来通り動く。

コミットメッセージ:

```
fix(jp-renewedbanking2): closeInterface でシナリオ解除と NUI フォーカス解除を確実に実行
```

### コミット 3: refactor — SQL 自動投入を v1.0.2 経路に一本化

対象バグ: バグ 3（ユーザー選択 A）。

対象ファイル:

- `server/main.lua`

実装方針:

1. 原作 `createTables` 関数の定義と呼び出しを削除する。
2. `assert(MySQL.transaction.await({ ... }))` の DDL ブロックも削除する。
3. v1.0.2-ja で追加した `CreateThread` 内の `LoadResourceFile + ; 区切り + MySQL.query.await` 経路はそのまま残す。
4. 完了ログ `[Renewed-Banking] DB schema check complete` は維持する（実機テストで使うため）。
5. 削除に伴い未使用となるローカル関数・変数は併せて整理する。

完了条件:

- 空 DB でサーバーを起動 → `[Renewed-Banking] DB schema check complete` が 1 回だけ出力される。
- `bank_accounts_new` と `player_transactions` の 2 テーブルが作成されている。
- 再起動しても同じログが 1 回だけ出る（冪等）。
- luacheck の警告総数が増えない（むしろ減る可能性あり）。

コミットメッセージ:

```
refactor(jp-renewedbanking2): SQL 自動投入を v1.0.2 経路に一本化し原作 createTables を削除
```

### コミット 4: feat — UI に閉じるボタンを追加 + version 更新

対象バグ: バグ 5。

対象ファイル:

- `web/src/App.svelte`（または `web/src/components/MainPage.svelte` 等、メイン画面のコンテナ）
- `web/src/components/Popup/Popup.svelte`（ポップアップにも追加する場合）
- `fxmanifest.lua`（version を `'2.1.4-ja.3'` に更新）
- `CHANGELOG.ja.md`、`README.md`、`README.en.md`（v1.0.3-ja 節の追加。コミット 4 にまとめる）
- `docs/known_issues.md`（必要なら更新）

実装方針:

1. メイン画面の右上に閉じるボタンを配置する。最小実装は `<button class="close-btn" on:click={() => fetchNui('closeInterface', {})} aria-label="閉じる">×</button>`。
2. CSS は既存のカードと統一感のあるスタイルにする。`position: absolute; top: 12px; right: 12px;` 程度で十分。タップ領域は 32x32 px 以上を確保。
3. ポップアップ側にも同じパターンで閉じるボタンを追加する。ポップアップの閉じるは `popupDetails.set(null)` などストアを直接戻す形にする（Lua への通知は不要）。
4. キーボード操作（Tab→Enter）でも閉じられるように `<button>` 要素を使う。`<div on:click>` は使わない（a11y 違反）。
5. svelte-check が 0 警告で通ること。
6. `fxmanifest.lua` の version を更新する。
7. CHANGELOG にバグ 1, 2, 3, 5 の修正を簡潔に記述する。

完了条件:

- メイン画面右上に × ボタンが表示され、クリックでキャラが動ける状態に戻る。
- ポップアップ右上に × ボタンが表示され、クリックでポップアップだけが閉じる（メイン画面は残る）。
- `pnpm run build` と `pnpm run check`（または npm 同等）が 0 警告で通る。
- CHANGELOG・README に v1.0.3-ja 節が追加されている。

コミットメッセージ:

```
feat(jp-renewedbanking2): メイン画面とポップアップに閉じるボタンを追加し v1.0.3-ja のドキュメントを更新
```

## 4. 各コミット後の共通検証

```powershell
cd H:\CURSOR\Dev\fivem-mods_ja\jp-renewedbanking2
luacheck client server --no-global --std=lua54
cd web
pnpm run build
pnpm run check    # コミット 1, 4 の後は必須
cd ..
```

luacheck の警告総数は v1.0.2-ja 時点（48 warnings / 2 errors、すべて line-too-long と FiveM 互換の `+=`/`-=`）から増えないこと。新たな警告が出た場合は該当コミットで対処する。

## 5. リリース手順

```powershell
git log --oneline   # 4 コミットがあること、ベースが v1.0.2-ja であることを確認
git tag -a jp-renewedbanking2/v1.0.3-ja -m "jp-renewedbanking2 v1.0.3-ja: 実機バグ hotfix"
git push origin work/jp-renewedbanking2-v1.0.3
git push origin jp-renewedbanking2/v1.0.3-ja
```

PR を立てて main にマージ（Create a merge commit）。マージ後にローカル main を最新化し、ブランチ削除。

## 6. 実機テスト手順（ユーザー実施）

`INSTRUCTIONS_v1.0.2.md` §7 のリソース配置・server.cfg 確認手順を再利用する。`robocopy ... /XD node_modules .git dist` でコピーし（`INSTRUCTIONS_v1.0.2.md` §7 と同一）、`<server>/resources/Renewed-Banking` 配下に最新が入っていることを確認した後、以下を実施する。

1. ATM に近づき UI を開く。メイン画面のオレンジ/グレーボタンに「入金」「出金」「送金」が表示されること（バグ 1 修正確認）。
2. ESC を押す。キャラがすぐ動け、ALT・移動キーが反応すること（バグ 2 パターン A 修正確認）。
3. 再度 ATM を開き、出金ボタンでポップアップを表示。ESC を押す。ポップアップとメイン画面が消え、キャラが動けること（バグ 2 パターン B 修正確認）。
4. メイン画面右上の × ボタンで閉じる。キャラが動けること（バグ 5 修正確認）。
5. ポップアップ右上の × ボタンを押す。ポップアップだけが閉じ、メイン画面が残ること（バグ 5 修正確認）。
6. 空 DB でサーバー起動 → `[Renewed-Banking] DB schema check complete` が 1 回だけ出ること、テーブルが 2 つ作成されること（バグ 3 修正確認）。
7. サーバー再起動 → 同じログが 1 回出てエラー無しであること、テーブルデータが残っていること。

## 7. 完了報告に含める項目

- ブランチ名と最終 4 コミットのハッシュ。
- タグ確認（`git tag --verify` または log 出力）。
- `pnpm run build` / `pnpm run check` の結果。
- luacheck の結果（v1.0.2-ja からの警告差分）。
- 実機テスト 7 項目の結果（OK / NG、NG の場合はログ抜粋）。
- `docs/known_issues.md` に持ち越した項目があればリンク。

## 8. 持ち越し（v1.0.4-ja 以降）

- `openBankUI` の `SetTimeout` レースコンディション（実害稀、優先度低）。
- luacheck の line-too-long 警告 44 件のフォーマット整理。
- pnpm への完全統一（npm の併用を廃止）。
- リリース自動化（GitHub Actions でタグ push 時にリリース作成）。

---

この指示書をそのまま Cursor に渡して大丈夫です。1〜4 のコミットは独立しているので、Cursor が途中で止まった場合も部分マージが可能。終わったら最終 4 コミットのハッシュと build/check 結果、実機テストの 7 項目の結果を報告してください。

## Cursor への渡し方

本ファイルをそのまま作業指示として使ってよい。修正が入った場合は本ファイルを更新し、コミットに含める。
