# Lua 文字列抽出（i18n 置換前）

- **対象**: `client/`, `server/`, `shared/framework.lua`、`shared/config.lua` の **Config.FurnitureTypes** のみ（`Config.Furnitures` / `Apartments` / `Shells` の `label` は除外）。
- **未対象**: `lib.inputDialog`、`chat:addMessage`、`QBCore.Functions.Notify` 直叩きは **本コードベースでは未使用**（`Framework[Config.Notify]` 経由）。
- **動的本文**: `data.message`（NUI から）や `v.name` を `title` にする行は **キー化時にテンプレ分離**が必要 → 行だけ列挙。

---

## `client/client.lua`

- L56: `description = 'Luxury Apartments!'`（qbx_properties 連携データ）  
  → suggested key: `ui.apartment.luxury_description`
- L123–132: `lib.alertDialog` — `header = 'Purchase Confirmation'`, `content = 'Are you sure...'`（動的: street, id, amount）, `confirm = "Purchase"`, `cancel = "Cancel"`  
  → suggested keys: `dialog.purchase.header`, `dialog.purchase.content`, `dialog.purchase.confirm`, `dialog.common.cancel`
- L136–145: `header = 'Raid'`, `content = 'Do you want to raid...'`, `confirm = "Raid"`, `cancel = "Cancel"`  
  → `dialog.raid.header`, `dialog.raid.content`, `dialog.raid.confirm`, `dialog.common.cancel`
- L149–158: `header = 'Ring Doorbell'`, `content = 'You dont have a key...'`, `confirm = "Ring"`, `cancel = "Cancel"`  
  → `dialog.doorbell.header`, `dialog.doorbell.content`, `dialog.doorbell.confirm`, `dialog.common.cancel`
- L162–171: `header = 'Showcase Property'`, `content = 'Do you want to showcase this property?'`, `confirm = "Yes"`, `cancel = "Cancel"`  
  → `dialog.showcase.header`, `dialog.showcase.content`, `dialog.showcase.confirm_yes`, `dialog.common.cancel`

---

## `client/apartment.lua`

- L54: `Notify("You dont have an apartment here.", "error")` → `notify.apartment.none_here`
- L59, L85: `Notify("There are no apartments here.", "error")` → `notify.apartment.none_in_building`
- L66: `title = "Apartments"` → `menu.apartments.list_title`
- L92: `title = "Apartments To Raid"` → `menu.apartments.raid_list_title`
- L98: `title = "Raid " .. …`（動的）→ `menu.apartments.raid_option_title` + `string.format`

---

## `client/cl_property.lua`

- L186: `content` 組み立て `"**Owner:** "` 等 → `dialog.property_info.owner_label`, `description_label`, `street_label`, `region_label`, `shell_label`, `forsale_label`, `yes`, `no`, `price_label`（分割推奨）
- L192–196: `lib.alertDialog`（`header` は動的 street+id）→ `dialog.property_info.header` は format、本文は上記ラベル群
- L397: `"Furniture Menu"` → `radial.furniture_menu.label`
- L410: `"Manage Property"` → `radial.manage_property.label`
- L435: `Notify("Only the owner can do this.", "error")` → `notify.property.owner_only`
- L443: `title = "Manage Access"` → `menu.access.manage_title`
- L448: `title = "Give Access"` → `menu.access.give_option`
- L455: `title = "Revoke Access"` → `menu.access.revoke_option`
- L475: `title = "Give Access"` → `menu.access.give_title`
- L486: `description = "Give Access"` → `menu.access.give_description`
- L496: `Notify("No one is in the property", "error")` → `notify.access.no_players_inside`
- L508: `title = "Revoke Access"` → `menu.access.revoke_title`
- L520: `description = "Remove Access"` → `menu.access.remove_description`
- L530: `Notify("No one has access to this property", "error")` → `notify.access.none_to_revoke`
- L538: `Notify("No one is at the door", "error")` → `notify.doorbell.no_visitors`
- L545: `title = "People at the door"` → `menu.doorbell.title`
- L266: `label = ... " Garage"`（動的）→ `ui.garage.label_suffix` または format

---

## `client/modeler.lua`

- L469: `Notify("Your cart is empty", "error")` → `notify.furniture.cart_empty`
- L480: `Notify("You don't have enough money!", "error")` → `notify.furniture.insufficient_funds`
- L591: `Notify('Stash is not empty', 'error')` → `notify.furniture.stash_not_empty`
- L697: `Notify(data.message, data.type)` → **動的**（NUI）— 別キー群またはサーバ側でキー渡し

---

## `client/migrate.lua`

- L1: `RegisterCommand("migratehouses", …)` — **help 文字列なし** → 将来 `command.migratehouses.help`

---

## `client/shell.lua`

- L59: コメントアウト `Notify("You left the shell", "error")` → 抽出のみ `notify.shell.left`（無効行）

---

## `server/server.lua`

- L13: `print("Error: No result returned from properties query.")` → `debug.db.properties_no_result`
- L56: `print("Error querying properties: " .. err)` → `debug.db.properties_query`
- L119–359: 各種 `print("Error: ...")` → `debug.*` キー（約 12 文）
- L161: `Notify(..., "Open radial menu for furniture...")` → `notify.spawn.furniture_radial_hint`
- L292, L408: `SendLog("Creating new apartment for ...")` → `log.apartment.creating`
- L387: `Notify(..., "You are already in this apartment", "error")`（`targetSrc`）→ `notify.apartment.already_in_tenant`
- L388–390: `Notify(..., "This person is already in this apartment", "error")`（**`realtorSrc`**、`if realtorSrc then`）→ `notify.apartment.peer_already_in`（2026-05-08 案 B で宛先修正済み。旧 upstream は同一 `targetSrc` への二重通知バグ）
- L418–419: アパート新規作成成功（動的文面）→ `notify.apartment.moved_success`, `notify.realtor.added_tenant`
- L442: `Notify(..., "Player not found.", "error")` → `notify.common.player_not_found`

---

## `server/sv_property.lua`

通知（抜粋・行番号は 2026-05-08 時点のファイル基準）:

- L107 `Someone is at the door.` → `notify.doorbell.someone_at_door`
- L111 `You rang the doorbell. Just wait...` → `notify.doorbell.rang_wait`
- L116 `No one answered the door.` → `notify.doorbell.no_answer`
- L146 `This Property is being Raided.` → `notify.raid.property_being_raided`
- L334 `Go far away and come back...` → `notify.door.refresh_distance`
- L338–339 購入済み系 → `notify.purchase.already_own`, `notify.realtor.client_already_owns`
- L347–348 確認拒否 → `notify.purchase.not_confirmed`, `notify.realtor.client_not_confirmed`
- L353–354 残高不足 → `notify.purchase.insufficient_bank`, `notify.realtor.client_insufficient_bank`
- L372 売却（動的）→ `notify.property.sold_message`
- L399–400 購入成功（動的金額）→ `notify.purchase.buyer_success`, `notify.realtor.sale_success`
- L516–518 アパート変更 → `notify.realtor.apartment_changed`, `notify.tenant.apartment_changed`
- L542 削除 → `notify.realtor.property_removed`
- L659, L692 レイド → `notify.raid.started`, `notify.raid.in_progress`
- L696–704 レイド拒否理由 → `notify.raid.need_stormram`, `notify.raid.police_only`, `notify.raid.need_onduty`, `notify.raid.need_rank`
- L780 金欠 → `notify.furniture.insufficient_funds`
- L818 家具購入 → `notify.furniture.purchase_success`
- L892, L945 オーナーでない → `notify.property.not_owner`
- L906–972 アクセス付与・剥奪系（動的名前多数）→ `notify.access.*` テンプレ群

**SendLog**（運営ログ）: L202, L222, L240, L260, L397, L416, L453, L499, L520, L544, L820 等 → `log.property.*` / `log.furniture.*`

**print**: L44 `print(src, self.property_id)` — デバッグ → `debug.property.trace` または除外可

---

## `server/migrate.lua`

- L28: `RegisterCommand("migrateapartments", …, true)` — help なし
- L38–39: `description = "This is " .. aptName .. " Apartment "...`（動的）→ `log.migrate.apartment_description` テンプレ
- L47, L121: `print("Finished migrating apartments/houses")` → `debug.migrate.apartments_done`, `debug.migrate.houses_done`

---

## `shared/framework.lua`

- L21: `title="Property"`（ox notify）→ `notify.framework.property_title`
- L84–231, L315–450: qb / ox ターゲット `label`（同一12語が二重定義）  
  → `target.property.enter`, `target.property.showcase`, `target.property.info`, `target.doorbell.ring`, `target.property.raid`, `target.apartment.enter`, `target.apartment.see_all`, `target.apartment.raid`, `target.property.leave`, `target.door.check`, `target.common.leave`
- L299: `title = 'Property'`（radial 系）→ `notify.framework.property_title` と共通化可

---

## `shared/config.lua`（FurnitureTypes のみ）

- L616: `"Storage"` → `target.furniture.storage`
- L627: `"Clothing"` → `target.furniture.clothing`

---

## 集計（抽出エントリ）

| 領域 | 本ドキュメントの「行アイテム」数（おおよそ） | 備考 |
|------|-----------------------------------------------|------|
| client | **約 48** | ダイアログの `Cancel` 等の重複キーは共通化想定 |
| server | **約 62** | `Notify` + `print` + `SendLog` を含む |
| shared | **約 15** | ターゲットラベル12 + Property タイトル重複 + config 2 |
| **合計** | **約 125** | タスク7の「client 約40・server 約55」は **Notify/Context 中心の目安**で、本抽出は **print / SendLog / radial / dialog 全ラベル / config FurnitureTypes** を加えたため多め |

### タスク7概算とのズレの原因

- **範囲拡張**: `print`・`SendLog`・ラジアル・プロパティ情報ダイアログのラベル行を含めた。  
- **1行複数キー**: 各 `alertDialog` が `header` / `content` / `labels` で **複数キー**に分割される。  
- **重複**: `dialog.common.cancel` のように共通化すると **ユニークキー数は 90 前後**に収束する見込み。

---

## 次アクション

1. ~~client: `Locale('key', ...)` 置換~~ → **8A-next-2-1 完了**（2026-05-08）
2. server / shared の置換 → **8A-next-2-2**
3. `Framework[Config.Notify]` のラッパーで `Locale` を強制するかは任意（現状は呼び出し側で明示）

---

## 8A-next-2-1 クライアント置換後の除外リスト（意図的に英語のまま／`Locale` 未適用）

| 箇所 | 理由 |
|------|------|
| `client/client.lua` `Debug("Initialising properties")` / `Debug("Initialised properties")` | 開発用ログ。`debug.*` キーは主に server DB 系。 |
| `client/cl_property.lua` `Debug(aptName .. " not found in Config")` / `Debug("Object: ".. …)` | 同上。 |
| `client/modeler.lua` `RegisterNUICallback("showNotification", …)` の `data.message` | NUI / サーバからの動的本文パススルー（`Locale(variable)` を避ける）。 |
| `client/shell.lua` コメント内の `Notify("You left the shell", …)` | 無効行（サンプル）。 |
| `client/modeler.lua` コメント内 `"Stop Placement"` | 開発者向けコメント。 |

---

## 次アクション（残り）

1. `locales/en.lua` / `locales/ja.lua` — server・shared 置換に伴う追記（8A-next-2-2）
2. `Locale('key', ...)` — server / shared（`Framework` ターゲットラベル、`Config.FurnitureTypes` 等）
