# Contributing

TECTON is LGPL-3.0-or-later. By contributing, you agree your contributions are licensed under the same terms.

- Read [`docs/ja/spec.md`](docs/ja/spec.md) for architecture and milestones.
- Prefer **UTF-8 without BOM** for Lua and web sources.
- Every **`.lua` / `.ts` / `.tsx`** file must start with SPDX: `LGPL-3.0-or-later`.

## `config/props.lua`（自動生成・データ系）

`npm run build:props` が出力する **`config/props.lua` は GPL-3.0 由来データ**（ShiftyWreckzz/prop-list → Menyoo 系譜）を **変換した事実上のデータベース**です。リポジトリ本体の Lua/TS 実装は **LGPL-3.0-or-later** のままですが、この生成物を改変・再配布する場合は **GPL-3.0 の要件**（クレジット・ソース提供方針等）に従う必要があります。詳細は生成ファイル先頭のコメントと [README.md](README.md) の Credits を参照してください。

(WIP — issue templates and CI will land in later milestones.)
