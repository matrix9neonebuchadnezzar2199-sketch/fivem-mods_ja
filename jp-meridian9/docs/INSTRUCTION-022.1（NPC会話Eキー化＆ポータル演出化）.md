# INSTRUCTION-022.1 — NPC 会話の E キー化＆ポータル演出化

**対象**: `jp-meridian9` v0.1.0-jp 以降  
**目的**: 任務開始導線を **NPC のみ**に一本化し、ポータルは **視覚演出のみ**とする。NPC 操作は `ox_target`（Alt）から **`E` キー＋`lib.showTextUI`** に変更する。

## 実装概要

| 領域 | 内容 |
|------|------|
| `config.lua` | `Config.NPC.interact`（距離・向き・クールダウン・HUD）、`Config.NPC.points`（`vega` の有効フラグ。`coords` 省略時は `Config.NPC.coords` を使用）、`Config.Portals`（`points` / `lod` / `haze` / `gate`。**interact 系なし**） |
| `client/npc.lua` | 200ms 距離スキャン＋候補がいるときのみ毎フレーム処理。向き内積（XY のみ）、`IsControlJustReleased(0, 38)`、車両搭乗中はプロンプト非表示。`TriggerServerEvent(Config.NPC.interact.entryEvent, npcId)` |
| `server/npc.lua` | `mrd9:npc:interact`：`source` 検証、`triggerDistance+1.0` の 2D 距離＋ Z 差 5m、クールダウン、成功時 `TriggerClientEvent('jp-meridian9:client:openDialogue', src)`（既存フロー） |
| `client/portal.lua` | `DrawMarker` による靄系演出、`mrd9:portal:setState` / `syncAll` 同期、近傍のみ `Wait(0)` |
| `server/portal.lua` | ポータル ID ごとの ON/OFF、`mrd9:portal:requestSync`、運営コマンド `/m9_portal` `/m9_portal_all` `/m9_portal_list`、`Config.Debug` 時のみ `/m9_portal_tp` |
| `shared/portal_defs.lua` | ネットイベント名の定数（将来差し替え用） |

## 受け入れ基準（抜粋）

- NPC 3m 以内・NPC の方を向いたときに `[E] 話しかける`（または `locales` の `npc_prompt_talk`）。
- 2m 以内で E を離した瞬間に既存の `openDialogue` → `lib.callback` 契約確認フロー。
- 車両搭乗中はプロンプトなし。離脱・リソース停止で **必ず** `lib.hideTextUI()`。
- ポータル近傍に **ox_target は無い**。`/m9_portal <id> off` で演出のみ消灯。

## 補足

- `ox_target` は **ルート取得（`client/loot.lua`）等**のため引き続き `dependencies` に残す。
- マスター指示の「`2026-05-17_開発日記.md`」は本リポの日記規約により **`docs/YYYY-MM-DD_開発日記.html`** 側に追記する。
