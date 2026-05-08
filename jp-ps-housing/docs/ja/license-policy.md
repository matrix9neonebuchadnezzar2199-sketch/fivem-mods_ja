# ライセンス・コメント方針（CC BY-NC-SA 4.0）

## 前提

- 上流同梱の **`LICENSE`** は **CC BY-NC-SA 4.0** です。派生・再配布は **非営利** かつ **同一条件（SA）** で行ってください。
- 帰属は **`NOTICE.md`** に集約しています。

## 新規ファイル

- 本フォークで追加するソース（Lua / TS 等）も、原則 **CC BY-NC-SA 4.0** で提供するのが安全です（上流との混在配布との整合）。
- 先頭行例:  
  - Lua: `-- SPDX-License-Identifier: CC-BY-NC-SA-4.0`  
  - TS/JS: `// SPDX-License-Identifier: CC-BY-NC-SA-4.0`  
- **Markdown**（`docs/**`）に SPDX を付与する必要はありません。

## 上流由来ファイルの改変

- 日本語化・Qbox 向け調整を入れた場合、**ファイル末尾**などに1行追記してよいです:  
  `# Modified by jp-ps-housing (2026-05-08): …`  
  （内容は実際の変更に合わせる。）
