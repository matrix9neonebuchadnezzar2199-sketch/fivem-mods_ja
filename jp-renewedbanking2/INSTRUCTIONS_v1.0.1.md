# Cursor 指示書: jp-renewedbanking2 v1.0.1-ja 品質改善

## 0. 目的とスコープ

`jp-renewedbanking2`（Renewed-Banking の日本語化フォーク）について、原作ロジックに踏み込まずに以下を改善する。

- i18n（引数順・キー化・ja/en 整合）の致命的バグ修正
- Web (Svelte) NUI のエラーハンドリング・null 安全化・a11y 警告解消
- Font Awesome バージョン統一と CSS タイポ修正
- Lua / Web の保守性向上（fxmanifest dependencies、stores 型、命名統一など）
- ビルド環境整理（lockfile 統一、terser プラグイン置換、tsconfig 整備）
- ドキュメント整備（CHANGELOG、known_issues、README 整合）

**スコープ外（やらないこと）**

- `server/main.lua` のトランザクション仕様、口座権限ロジック、money 移動ルールなど、原作の挙動を変える変更。これらが必要になった場合は別ブランチ `experimental/jp-renewedbanking2-logic` で別 PR を切ること。
- 新機能追加。今回は品質修正のみ。

## 1. 前提条件

作業開始前に必ず以下を実行する。

```powershell
cd <repo_root>\jp-renewedbanking2
git fetch origin --tags --prune
git checkout -b work/jp-renewedbanking2-v1.0.1 jp-renewedbanking2/v1.0.0-ja
```

ベースは **タグ `jp-renewedbanking2/v1.0.0-ja`** で固定する。指示書執筆時点のハッシュは `9b58448` だが、別マシン・別クローンでは必ずタグ参照を優先すること。具体ハッシュをコピペしない。

リポジトリの作業ディレクトリは `<repo_root>\jp-renewedbanking2`。`<repo_root>` は環境ごとに異なる（例: `H:\CURSOR\Dev\fivem-mods_ja`、`F:\Cursor\fivem-mods_ja`）。

**重要: 開発フォルダ名 ≠ デプロイ名**

開発フォルダ名は `jp-renewedbanking2` だが、FiveM サーバーで ensure する名前は `Renewed-Banking`（`fxmanifest.lua` の暗黙リソース名・`exports['Renewed-Banking']` と一致）である。`server.cfg` に `ensure jp-renewedbanking2` と書かないこと。リソースフォルダを配置する際もフォルダ名を `Renewed-Banking` にリネームしてから resources 配下に置く運用を前提とする。

## 2. 環境準備

```powershell
cd web
pnpm install        # lockfile 統一後（コミット5以降）は pnpm 固定
pnpm run build      # 既存ビルドが通ることを確認
cd ..
luacheck client server --no-global  # 既存 luacheck で 0 警告を確認
```

ここで build / luacheck が通らない場合は作業を始めず報告する。

## 3. コミット分割（6 件）

各コミットは独立してビルド・lint が通る単位とする。コミットメッセージは `<type>(jp-renewedbanking2): <内容>` 形式。

### コミット 1: i18n 引数順・キー化修正

**対象**

- `locales/ja.json`、`locales/en.json`
- ja/en で参照されているキーの呼び出し箇所（`server/main.lua`、`client/main.lua`、`web/src/**/*.svelte` で locale を参照する箇所）
- 新規 `docs/i18n_audit.md`

**作業**

1. ja/en 全キーを突き合わせ、欠落キーと未使用キーを `docs/i18n_audit.md` に表形式で記録する。
2. 引数順反転バグ（例: `"%s に現金 $%s を渡しました"` で名前と金額が逆になっているケース）を修正。
3. ハードコードされた日本語文字列を locale キー化（既存キーで吸収できるものは流用、新規キーは `_help_*` 等の既存命名規則に合わせる）。
4. `${renewed_banking}` 等の interpolation キーが ja/en 両方に存在することを確認。

**コミットメッセージ例**

```
fix(jp-renewedbanking2): i18n 引数順とキー化を修正、ja/en 整合監査を追加
```

### コミット 2: Web NUI エラーハンドリングと null 安全化

**対象**

- `web/src/utils/fetchNui.ts`
- `web/src/utils/debugData.ts`
- `web/src/utils/useNuiEvent.ts`
- `web/src/components/Popup.svelte`
- `web/src/components/Accounts/AccountsContainer.svelte`（または該当する親コンポーネント）
- `web/src/utils/formatMoney.ts`（または該当ファイル）

**作業**

1. `fetchNui` を Promise reject まで握り潰さない実装に改装（try/catch とログ）。
2. `Popup.submitInput` に `.catch(err => …)` を追加し、失敗時の UI 状態を戻す。
3. `AccountsContainer` で `$accounts` が `undefined` / 空配列のときのガードを入れる。
4. `formatMoney` の初期値（`amount` 未定義時の挙動）を `0` 固定に。
5. `useNuiEvent` 本体は触らず、`debugData` 側を `useNuiEvent` が期待するフラット構造（`{ action, data }` をそのまま `MessageEvent.data` に乗せる）に合わせる。型定義もこれに追従。

**完了条件**

- `pnpm run build` が成功
- 開発時 `debugData` を呼んでも `useNuiEvent` のハンドラが正しく発火することを目視確認

**コミットメッセージ例**

```
fix(jp-renewedbanking2): Web NUI のエラー処理と null 安全性を強化、debugData をフラット構造に統一
```

### コミット 3: Font Awesome 統一と CSS タイポ修正

**対象**

- `web/public/index.html`（CDN 参照）
- `web/src/components/Notification.svelte`
- その他 Font Awesome を参照している Svelte ファイル

**作業**

1. Font Awesome のバージョンを 1 つに統一（CDN URL を 1 箇所に集約、または将来のローカル化に備えて `index.html` 内コメントで TODO を残す）。
2. `Notification.svelte` の CSS タイポ（既存指摘箇所）を修正。
3. Notification のフォントサイズが極端に小さい (`0.69vw` 等) ものを `rem` 基準に整える（具体値は本家のデザインに寄せる、未定なら `1rem` を起点）。
4. `Notification.svelte` のスクリプト部に `lang="ts"` を追加（型を使う場合）。

**コミットメッセージ例**

```
fix(jp-renewedbanking2): Font Awesome バージョンを統一し Notification の CSS タイポと font-size を修正
```

### コミット 4: Lua / Web 保守性改善 + a11y 修正 + svelte-check 一回目

**対象**

- `fxmanifest.lua`
- `web/src/store/stores.ts`
- `web/src/utils/setClipboard.ts`（旧名がタイポしている場合）
- `web/package.json`（`name` フィールド、`sirv-cli` の位置）
- `web/src/components/HelpModal.svelte`（W8 / W9 a11y。リポ内の実パスに合わせる）
- 関連する import 修正

**作業**

1. `fxmanifest.lua` に `dependencies { 'ox_lib', 'oxmysql', 'ox_target' }` を追記。`server_version` を書く場合は **必ず** 手元の `resources/[ox]/ox_lib/fxmanifest.lua` の `version` 値、または ox_lib リリースノートを参照して決定し、決定根拠（参照したバージョン番号と日付）をコミットメッセージ本文に記載する。固定値のコピペは禁止。
2. `stores.ts` の export を `const` 化し、型定義（`Account`、`Transaction` 等）を追加。
3. `setClipboard` のファイル名 / 関数名タイポを修正（`setClipboad` → `setClipboard` 等）し、import 側も追従。
4. `package.json` の `name` を `"renewed-banking-ui"` に変更。`sirv-cli` を `dependencies` から `devDependencies` に移動。
5. **W8 / W9 a11y 修正**: `HelpModal.svelte` のオーバーレイ要素 `<div on:click={close}>` を `<button type="button" class="overlay" on:click={close}>` に置き換える。ESC キーハンドリングは既存の `VisibilityProvider` に委ねる旨をコメントで残す。対象は **`HelpModal.svelte` 1 ファイルのみ**。
6. コマンド名等のリネームが必要な箇所（既存指摘 W4 系）があれば併せて修正。

**完了条件**

- `cd web && pnpm run check` を実行し、svelte-check 警告 0（または既知の許容範囲のみ）。a11y 関連 (`a11y-click-events-have-key-events`, `a11y-no-static-element-interactions`) が消えていること。
- これがコミット 4 の **必須完了条件**。コミット 1〜3 の段階では debugData の型移行中で一時的にノイジーになるため、check はここで初めて通す。

**コミットメッセージ例**

```
refactor(jp-renewedbanking2): fxmanifest dependencies と stores 型を整備、HelpModal の a11y を修正

ox_lib 依存の server_version は <参照したバージョンと日付> を根拠に決定。
```

### コミット 5: ビルド環境整理

**対象**

- `web/package.json` の `devDependencies`
- `web/package-lock.json` または `web/pnpm-lock.yaml`（どちらか一方を残す）
- `web/rollup.config.js`
- `web/tsconfig.json`
- 新規 `web/src/global.d.ts`
- 新規または更新 `.gitattributes`

**作業**

1. lockfile を **pnpm に統一**。`package-lock.json` を削除し `pnpm-lock.yaml` のみコミット。`README` 側の記述（pnpm 推奨）と整合させる。
2. `rollup-plugin-terser` を `@rollup/plugin-terser` に置換し、`rollup.config.js` の import を更新。
3. 依存を Svelte 4 / Rollup 4 / TypeScript 5 系に更新（互換性が壊れる場合はコミットを 5a / 5b に分割可、ただし build は必ず通すこと）。
4. `tsconfig.json` に `target` と `lib` を明示（例: `"target": "ES2020"`, `"lib": ["ES2020", "DOM"]`）。
5. `web/src/global.d.ts` を新設し、NUI 環境用の型補完（`window.invokeNative` 等）を最小限定義。
6. リポジトリ直下に `.gitattributes` がない、または改行設定がない場合は `* text=auto eol=lf`、`*.lua text eol=lf`、`*.md text eol=lf`、`*.bat text eol=crlf` を設定。これは過去に発生した CRLF/LF 差分ノイズの再発防止のため。

**完了条件**

- `cd web && pnpm install` がクリーンに通る
- `pnpm run build` が成功
- `pnpm run dev` が起動する

**コミットメッセージ例**

```
chore(jp-renewedbanking2): lockfile を pnpm に統一し依存とビルド設定を更新
```

### コミット 6: Docs 整備 + ensure 名検証 + svelte-check 二回目

**対象**

- `CHANGELOG.ja.md`
- `README.md`、`README.en.md`
- 新規 `docs/known_issues.md`
- `INSTRUCTIONS.md`（既存があれば追記）
- `LICENSE` / `LICENSE.ja.md` の整合確認

**作業**

1. `CHANGELOG.ja.md` に v1.0.1-ja 節を追加し、コミット 1〜5 の変更を箇条書きで列挙。
2. `README.md` / `README.en.md` の手順（pnpm install → pnpm run build → サーバー配置）を改訂後の構成に合わせて更新。
3. `docs/known_issues.md` を新設し、スコープ外として持ち越した項目（あれば）と、原作ロジック変更案件は `experimental/jp-renewedbanking2-logic` ブランチで扱う旨を記載。
4. `INSTRUCTIONS.md` の冒頭に **太字で** 「サーバーで ensure する名前は `Renewed-Banking`（`jp-renewedbanking2` ではない）」と明記。
5. **ensure 名検証**: `fxmanifest.lua` のリソース名想定、`exports['Renewed-Banking']` 呼び出し箇所、`README` のサーバー配置手順、`server.cfg` 例文の 4 箇所すべてで `Renewed-Banking` に統一されていることを目視確認。検証結果をコミットメッセージ本文に列挙。
6. **svelte-check 二回目**: `cd web && pnpm run check` で 0 警告を再確認。
7. `LICENSE`（CC BY-NC-SA 4.0）と `LICENSE.ja.md` の参考訳が乖離していないかを軽く目視。

**コミットメッセージ例**

```
docs(jp-renewedbanking2): v1.0.1-ja 向けに CHANGELOG・README・known_issues を整備し ensure 名を再確認
```

## 4. 各コミット共通の検証手順

各コミット完了時に以下を実行し、結果をコミットメッセージ本文または PR 説明に記録する。

```powershell
# Lua 側
luacheck client server --no-global

# Web 側
cd web
pnpm run build
cd ..
```

`pnpm run check`（svelte-check）は **コミット 4 とコミット 6 の二回のみ** 実施する。コミット 1〜3、5 では実施しなくてよい。

## 5. 最終リリース手順

すべてのコミットが完了したら以下を行う。

```powershell
git log --oneline jp-renewedbanking2/v1.0.0-ja..HEAD   # 6 コミットが並んでいることを確認
git tag -a jp-renewedbanking2/v1.0.1-ja -m "jp-renewedbanking2 v1.0.1-ja: 品質改善リリース"
git push origin work/jp-renewedbanking2-v1.0.1
git push origin jp-renewedbanking2/v1.0.1-ja
```

PR を作成し、本指示書の章番号を引きつつ各コミットの diff サマリを書く。

## 6. 完了報告フォーマット

作業完了時に以下を提出すること。

- ブランチ名と最終コミットハッシュ 6 件
- タグ `jp-renewedbanking2/v1.0.1-ja` の確認
- 各コミットでの `pnpm run build` 結果（OK / NG）
- `pnpm run check` の結果（コミット 4 完了時、コミット 6 完了時の 2 回）
- `luacheck` の結果
- ensure 名検証の 4 箇所チェック結果
- ja/en i18n 監査表（`docs/i18n_audit.md`）のリンク
- スコープ外として持ち越した項目（あれば `docs/known_issues.md` に記載済みであることを確認）

## 7. 付録: スコープ外案件の取り扱い

原作ロジック（口座権限、トランザクション順序、money 移動仕様など）に踏み込む変更が必要と判明した場合、**本ブランチでは作業しない**。`experimental/jp-renewedbanking2-logic` を別途 `jp-renewedbanking2/v1.0.1-ja` から派生させ、CHANGELOG にも「実験」「fork-only」節として分離して記載する。レビュアー（依頼者）が原作との差分を一目で把握できるようにすることが目的。

---

差分パッチ形式（既存 INSTRUCTIONS.md にどこを追加・変更するかだけの diff）が必要なら、現行 `INSTRUCTIONS.md` のどの節構成になっているか教えてください。それに合わせて patch 形式で出し直します。
