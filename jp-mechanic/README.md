# jp-mechanic

整備工場前の NPC から、伝票（症状・車種・診断）に合う**部品・作業**を右のリストから選び、**発注**する内職 NUI です。流れは同リポ内の `jp-hospital`（カルテ整理）と同型で、難易度別に `data/slips_*.lua` の出題とダミー数が変わります。

## 主な参照ファイル

- `config.lua` — NPC 座標、難易度、部品マスタ `Config.Parts`
- `data/slips_easy.lua` / `slips_medium.lua` / `slips_hard.lua` — 各 30 問（`answers` の id は `Config.Parts` と一致させる）
- `tools/gen_slips.py` — 出題庫再生成用（`python tools/gen_slips.py`）
- 依存: `qbx_core`（`AddMoney`）、`ox_target`、`ox_lib`（`fxmanifest` の `dependencies` 参照）

導入後: `start jp-mechanic`、ゲーム内で難易度 **中止** あり、退勤で日報。
