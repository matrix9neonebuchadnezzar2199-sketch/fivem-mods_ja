# jp-UnderworldBounty（闇の指名手配）

日本語 RP 向け FiveM リソース。裏賭場の強盗シナリオと、成功後のヤクザ側「闇の指名手配」（報復ウェーブ）を **設定駆動** で追加できます。ESX / QBCore（Qbox 環境の qb-core 含む）/ Standalone に対応しています。

---

## jp-UnderworldBounty (English)

FiveM resource for JP-style RP: configurable underground casino heists and post-heist retaliation waves (“shadow bounty”). Supports **ESX**, **QBCore** (including typical Qbox setups using `qb-core`), and **Standalone**.

### Requirements

- FXServer with OneSync recommended  
- **No hard dependency** on ox_lib / qb-target (optional integrations are not bundled)

### Install

1. Copy `jp-UnderworldBounty` into `resources/[local]/` (or your mods folder).  
2. `ensure jp-UnderworldBounty`  
3. Adjust `config/*.lua` and align reward **item names** with your inventory (e.g. `markedbills`).  
4. See `docs/CONFIG_GUIDE.md`, `docs/SCENARIO_GUIDE.md`, `docs/EVENT_HOOKS.md`.

### Commands

| Command    | Scope  | Description                                      |
|-----------|--------|--------------------------------------------------|
| `/ub_test`| player | Shows name / cash / job / approximate cop count |
| `/ub_cancel` | player | Cancels an active heist (cleanup + server state) |

### License

MIT — see `LICENSE`.

---

## クイックスタート（日本語）

1. フォルダを `resources` 配下に配置する。  
2. `server.cfg` に `ensure jp-UnderworldBounty` を追加。  
3. `config/config.lua` で `Config.Framework`（`auto` 推奨）と `Config.Locale` を確認。  
4. `config/rewards.lua` のアイテム名を自サーバーのアイテムに合わせる。  
5. ゲーム内でサンプルロケーション（南 LS / 港 / 市内）付近のマーカーに入り **E** で開始。

詳細は `docs/` を参照（体験フロー表: `docs/PLAYER_FLOW.md`、報復 FSM: `docs/RETALIATION_FSM.md`、シナリオ設計テンプレ: `docs/SCENARIO_TEMPLATE.md`）。
