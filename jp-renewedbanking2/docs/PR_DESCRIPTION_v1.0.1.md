# PR 説明雛形（jp-renewedbanking2 v1.0.1-ja）

GitHub の Pull Request Description にそのまま貼れるよう、`INSTRUCTIONS_v1.0.1.md` 第 6 章に沿った完了報告です。

## 概要

- ベースタグ: `jp-renewedbanking2/v1.0.0-ja`
- ブランチ: `work/jp-renewedbanking2-v1.0.1`
- 方針: 原作ロジック非変更、Web 派生品質改善、当初 **6 コミット分割** + ドキュメント追記 **2 コミット**（計 8）、**merge commit でマージ**（squash しない）

## 完了報告（指示書 6 章）

- **ブランチ名**: `work/jp-renewedbanking2-v1.0.1`
- **コミット**: `jp-renewedbanking2/v1.0.0-ja` から **計 8 件**（品質改善 6 + マージ前レビュー反映 1 + タグ fetch 注記・luacheck 例 1）。一覧は `git log --oneline jp-renewedbanking2/v1.0.0-ja..work/jp-renewedbanking2-v1.0.1`。
- **タグ**: `jp-renewedbanking2/v1.0.1-ja`（注釈付きで push 済み想定）
- **`pnpm run build`**: 各コミット完了時に OK（最終は Svelte 4 / Rollup 4 / TS 5）
- **`pnpm run check`**: コミット 4 完了時・コミット 6 完了時の 2 回とも **0 errors / 0 warnings**
- **`luacheck`**: CI / レビュア環境に **未インストールのため本 PR では未実行**。マージ前に `jp-renewedbanking2` 直下で `luacheck client server --no-global --std=lua54` を実行し、結果を PR コメントへ貼付推奨（FiveM 由来のグローバル警告のみなら PR コメントで注記して可。`.luacheckrc` は本スコープ外）。
- **ensure 名検証（4 点）**:
  1. `fxmanifest.lua` コメント・リソース名想定 → `Renewed-Banking`
  2. `server/main.lua` `LoadResourceFile("Renewed-Banking", …)` → 一致
  3. `README.md` / `README.en.md` の `ensure Renewed-Banking` → 一致
  4. `server.cfg` 例文（README 記載）→ `ensure jp-renewedbanking2` 等の誤記なし
- **i18n 監査表**: `docs/i18n_audit.md`
- **スコープ外・既知**: `docs/known_issues.md`（`useNuiEvent` 短絡評価の v1.0.2 検討、bundle 運用フォロー、ox_lib 3.x 想定 等）

## Breaking changes（マージノート）

- クライアントコマンド: **`closeBankUI` → `renewedbanking:close`**（`CHANGELOG.ja.md` の v1.0.1-ja 節に明記）

## 指示書からの逸脱（許容範囲内）

- `useNuiEvent.ts` 本体は未改修（`debugData` をフラット構造に統一する方針のため）
- `fxmanifest.lua` に `server_version` 未記載（ワークスペース外の ox_lib を参照して運用側で追記）
- `pnpm` は `npx pnpm@9` 経由で実行（ローカルに pnpm が無い環境）

## マージ後の推奨作業

1. **merge commit** で `main` へマージ
2. `git tag -v jp-renewedbanking2/v1.0.1-ja` で注釈確認（署名は任意）
3. GitHub Releases: `CHANGELOG.ja.md` の `[1.0.1-ja]` 節をベースにリリースノート作成
4. 作業ブランチ `work/jp-renewedbanking2-v1.0.1` の削除

## フットノート: タグ `jp-renewedbanking2/v1.0.1-ja` をリモートで付け替えたあと

既に同名タグを fetch 済みのクローンでは、`git fetch --tags --prune` だけではローカルタグが古いままの場合がある。別マシンで作業を再開するときは次のいずれかで上書きすること。

```powershell
git fetch origin --tags --force
```

または:

```powershell
git tag -d jp-renewedbanking2/v1.0.1-ja
git fetch origin tag jp-renewedbanking2/v1.0.1-ja
```
