# INSTRUCTION-022.1 — NPC 会話の E キー化（ポータル演出は撤去済み）

**対象**: `jp-meridian9` v0.1.0-jp 以降  
**目的**: 任務開始導線を **NPC のみ**に一本化する。NPC 操作は `ox_target`（Alt）から **`E` キー＋`lib.showTextUI`** に変更する。

**履歴**: 当初ドキュメント名どおり「紫靄などのポータル演出」を入れたが、実機・保守コストの観点から **2026-05-17 に一式撤去**した。`Config.Portals`・`client/portal.lua`・`server/portal.lua`・`/m9_portal*` は存在しない。

## 実装概要（現状）

| 領域 | 内容 |
|------|------|
| `config.lua` | `Config.NPC.interact`（距離・向き・クールダウン・TextUI）、`Config.NPC.contextMenuScale`（ヴェガ選択肢 NUI の拡大率・既定 2.0）、`Config.NPC.points`（`vega` の有効フラグ。`coords` 省略時は `Config.NPC.coords` を使用） |
| `client/npc.lua` | 200ms 距離スキャン＋候補がいるときのみ毎フレーム処理。向き内積（XY のみ）、`IsControlJustReleased(0, 38)`、車両搭乗中はプロンプト非表示。`TriggerServerEvent(Config.NPC.interact.entryEvent, npcId)` |
| `client/vega_context.lua` / `html/vega_context.*` | ヴェガの**選択肢**のみ自前 NUI（`ox_lib` の `registerContext` はサイズ指定不可のため）。`SetNuiFocus`・ESC／背景で閉じる |
| `client/dialogue.lua` | 台詞は `lib.alertDialog`、選択肢は `MRD9.VegaContextShow` |
| `server/npc.lua` | `mrd9:npc:interact`：`source` 検証、`triggerDistance+1.0` の 2D 距離＋ Z 差 5m、クールダウン、成功時 `TriggerClientEvent('jp-meridian9:client:openDialogue', src)`（既存フロー） |

## 受け入れ基準（抜粋）

- NPC 3m 以内・NPC の方を向いたときに `[E] 話しかける`（または `locales` の `npc_prompt_talk`）。
- 2m 以内で E を離した瞬間に既存の `openDialogue` → `lib.callback` 契約確認フロー。
- 車両搭乗中はプロンプトなし。離脱・リソース停止で **必ず** `lib.hideTextUI()`。

## 補足

- `ox_target` は **ルート取得（`client/loot.lua`）等**のため引き続き `dependencies` に残す。
- **TextUI の見た目** … `Config.NPC.interact.textUiStyle` を `Config.Loot` / `Config.Extract` と同じ緑帯（`#2e7d32`）に揃える。未指定なら `Config.Loot.textUiStyle` を流用。

## トラブルシュート（ヴェガが出ない）

1. **`Config.NPC.spawn.networkPed`** … OneSync 環境では既定 `true`（ネットワーク ped）。まれに `CreatePed` が 0 を返すサーバでは `false` に戻して再テスト。
2. **地表** … `GetGroundZFor_3dCoord` + `RequestCollisionAtCoord` で Z を補正。座標を動かした場合は `coords` を実機で再確認。
