# SPDX・改変コメント方針（jp-ps-housing）

## 前提

- 上流 `ps-housing` 同梱の `LICENSE` は **CC BY-NC-SA 4.0** です。新規ファイルのライセンス選定は **この条件と両立するか** を運営が確認してください。
- 以下は作業上の「無難なデフォルト」であり、法的判断ではありません。

## 新規作成ファイル

- 日本語ロケール、ドキュメント（`docs/ja/*` を除くソース）、独自追加機能など **上流に無かった新規ソース**の先頭に、次を付与する方針とする（プロジェクト既定）。  
  - Lua: `-- SPDX-License-Identifier: LGPL-3.0-or-later`  
  - TypeScript / JavaScript: `// SPDX-License-Identifier: LGPL-3.0-or-later`
- **注意**: リポジトリ直下の `LICENSE` は上流どおり **CC BY-NC-SA 4.0** です。LGPL 付き新規ファイルと CC 由来ファイルの**混在配布が許容されるか**は運営側で確認してください。安全寄りに揃えるなら新規も `CC-BY-NC-SA-4.0` に統一する選択肢があります。
- 本リポジトリの **Markdown ドキュメント**（例: `docs/ja/*`）に SPDX を付与する必要はありません。

## 上流由来ファイルの改変

- 本文を日本語化・Qbox 向けに変更した場合、**ファイル末尾**に1行で十分な範囲で追記する:  
  `# Modified by jp-ps-housing 2026-05-08: localized to ja`  
  （Lua 例。他言語は同趣旨の1行コメント。）
- 変更箇所が限定的なら、ブロック直後のコメントでも可。

## ドキュメント

- `LICENSE-derivative.md` および本ファイルは出所説明用です。SPDX はソースファイルを主対象とします。
