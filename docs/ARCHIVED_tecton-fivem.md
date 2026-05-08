# tecton-fivem（TECTON）— 凍結・リポジトリからの削除

> ⚠️ **PROJECT FROZEN (2026-05-08)** — 環境が Qbox 確定のため、housing 機能まで揃う ps-housing 日本語化に主軸を移行。本ツリーはモノレポから削除済み。履歴・復元は下記「ソースコードの参照」を利用。

**日付**: 2026-05-08（運用判断）

## [Frozen] - 2026-05-08（CHANGELOG 相当）

- **凍結理由**: Qbox（qbx_core, ox_lib, ox_inventory, ox_target, oxmysql）前提が確定し、住宅・家具モデラーまで一気通貫で扱うなら **ps-housing 派生（`jp-ps-housing`）** に集中する方が運用コストが低い。
- **完了済みマイルストーン（参照用）**: M1 / M2-a / M2-b / M2-e（詳細は削除前コミット履歴 `tecton-fivem/` を参照）。
- **リポジトリ上の扱い**: `fivem-mods_ja` の `main` から `tecton-fivem/` を除去（以降の clone には含まれない）。

## プロジェクト方針変更（2026-05-08）（旧 `docs/ja/spec.md` 追記相当）

1. **Qbox 環境確定** — フレームワーク周りは ox 系・Qbox 前提で統一する。
2. **ps-housing-ja（`jp-ps-housing`）への主軸移行** — 住宅・不動産・家具配置のユーザー体験をここで日本語化・調整する。
3. **TECTON 資産の保全方針** — 以下は `jp-ps-housing` の NUI / ドキュメントへ逆移植する際の参考として履歴に残す:
   - react-window 仮想スクロール、150ms debounce、TagFilter、Transform パネル
   - `docs/ja/ui-guide.md`（削除前ツリー内に存在）
4. **将来の逆移植先** — `jp-ps-housing` の NUI（Svelte / 既存 ps-housing UI）側で必要に応じて取り込む。

## 開発日記メモ（2026-05-08 追記相当）

- Qbox 前提が固まったため、単体の汎用モデラー（TECTON）より ps-housing 日本語化を優先する判断とした。
- モノレポから `tecton-fivem` を外し、メンテナンス対象を `jp-ps-housing` に絞る。
- 技術検証で得た UI パターンは、必要になったタイミングで housing 側に移植する。

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
