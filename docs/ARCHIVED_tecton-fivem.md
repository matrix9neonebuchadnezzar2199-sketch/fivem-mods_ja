# tecton-fivem（TECTON）— 凍結・リポジトリからの削除

**日付**: 2026-05-08（運用判断）

## 方針

- **開発凍結**: TECTON（フォルダ名 `tecton-fivem`）の継続開発を行わない。
- **本モノレポから削除**: `fivem-mods_ja` の `main` から `tecton-fivem/` を除去した（以降の clone には含まれない）。

## ソースコードの参照

削除前のツリーは **Git 履歴に残ります**。復元や差分確認は例えば次のように可能です。

```sh
git log --oneline -- tecton-fivem/
git show <commit>:tecton-fivem/fxmanifest.lua
```

特定コミット時点のフォルダを取り出す場合は `git checkout <commit> -- tecton-fivem`（作業ツリーに復元）など。

## GitHub について

- **このリポジトリ（fivem-mods_ja）**: `tecton-fivem` 削除を `main` に push すれば、GitHub 上の既定ブランチからもフォルダは消えます（履歴は残る）。
- **tecton を単体リポジトリとして公開していた場合**: GitHub の **Settings → Danger zone → Delete this repository** で別途削除が必要です（API/CLI でも可）。本記録では単体リポの有無は未確認のため、該当すれば手動で実施してください。

## 備考

- サーバーに既に配置済みの `tecton-fivem` リソースフォルダは、運営が手動でアンインストールする必要があります（本リポからは提供終了）。
