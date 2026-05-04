# jp-UnderworldBounty（闇の指名手配）

[English](#english) · [日本語](#日本語)

日本語 RP 向け FiveM リソース。裏賭場の強盗シナリオと、成功後のヤクザ側「闇の指名手配」（報復ウェーブ）を **設定駆動** で追加できます。ESX / QBCore（Qbox 環境の qb-core 含む）/ Standalone に対応しています。

**バージョン**: 1.0.0（リリース候補） · **実装**: PHASE 0〜8 ベースライン済み（FSM 完全寄せ・拡張は `docs/RETALIATION_FSM.md` 参照）

**リポジトリ**: [fivem-mods_ja](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja) 内の `jp-UnderworldBounty/`

---

## 日本語

### 概要

**jp-UnderworldBounty** は、警察の指名手配とは別軸でヤクザ側の報復 NPC が襲ってくる **Underworld Bounty** を強調したクライム系スクリプトです。運営は `config/scenarios.lua` などを編集してシナリオを増やせます。

### ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| [DESIGN.md](docs/DESIGN.md) | 全体設計・PHASE 計画 |
| [PLAYER_FLOW.md](docs/PLAYER_FLOW.md) | プレイヤー体験シーン |
| [RETALIATION_FSM.md](docs/RETALIATION_FSM.md) | 報復 FSM（§13 実装パターン） |
| [SEQUENCE_DIAGRAMS.md](docs/SEQUENCE_DIAGRAMS.md) | サーバー↔クライアント通信 |
| [EVENT_HOOKS.md](docs/EVENT_HOOKS.md) | 公開イベント API |
| [INSTRUCTIONS_PHASE_1A.md](docs/INSTRUCTIONS_PHASE_1A.md) | PHASE 1a 作業指示（Bridge API をドキュメント化する手順・Cursor 向け） |
| [BRIDGE_API.md](docs/BRIDGE_API.md) | Bridge 層 API リファレンス（v1.0.0 コードスナップショット） |
| [CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md) | 運営向け設定 |
| [SCENARIO_GUIDE.md](docs/SCENARIO_GUIDE.md) | シナリオ追加 |
| [SCENARIO_TEMPLATE.md](docs/SCENARIO_TEMPLATE.md) | シナリオ設計テンプレ |

Greenfield 向けマニフェストの参照用: ルートの `fxmanifest.full.lua.template`（現行の `fxmanifest.lua` と bridge 構成は異なる旨を記載済み）。

### インストール

1. `jp-UnderworldBounty` を `resources` 配下に配置する。  
2. `server.cfg` に `ensure jp-UnderworldBounty` を追加。  
3. `config/rewards.lua` のアイテム名を自サーバーに合わせる。  
4. 詳細は [CONFIG_GUIDE.md](docs/CONFIG_GUIDE.md)、[SCENARIO_GUIDE.md](docs/SCENARIO_GUIDE.md)、[EVENT_HOOKS.md](docs/EVENT_HOOKS.md)。

### コマンド

| コマンド | 対象 | 説明 |
|----------|------|------|
| `/ub_test` | プレイヤー | 名前・所持金・職業・概算警官数 |
| `/ub_cancel` | プレイヤー | 強盗キャンセル（サーバー状態とクライアント掃除） |

### クイックスタート

1. `config/config.lua` で `Config.Framework`（`auto` 推奨）と `Config.Locale`。  
2. サンプルロケーション付近のマーカーで **E** → ミニゲーム → 戦闘完了で報酬・指名手配。

### ライセンス

MIT — [LICENSE](LICENSE)。

---

## English

### Overview

**jp-UnderworldBounty** is a configurable underground casino heist resource with **Underworld Bounty** retaliation waves (separate from police wanted level). Supports **ESX**, **QBCore** (including typical Qbox + `qb-core` setups), and **Standalone**.

### Requirements

- FXServer with OneSync recommended  
- **No hard dependency** on ox_lib / qb-target  

### Documentation

Authoritative detail lives in `docs/`. Start with `DESIGN.md`, `RETALIATION_FSM.md`, `SEQUENCE_DIAGRAMS.md`, and `EVENT_HOOKS.md`.

### Install

Copy the folder into `resources`, `ensure jp-UnderworldBounty`, align `config/rewards.lua` item names with your inventory.

### Commands

See the Japanese table above (`/ub_test`, `/ub_cancel`).

### License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgments

Part of [fivem-mods_ja](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja).
