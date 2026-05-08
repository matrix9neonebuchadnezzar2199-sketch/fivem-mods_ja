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

- **8A-next-2-2 済み**: `Notify` → `Locale('notify.*')`、`SendLog` → `LocaleEn('log.*')`。アパート説明 `string.format` → `Locale('property.description.apartment', …)`。
- `print("Error: ...")` 等 — **ロケール化しない**（英語ベタ。下記「server 側除外」）。
- `Debug(...)` — **同上**。

---

## `server/sv_property.lua`

- **8A-next-2-2 済み**: 上記キー表に対応する `Notify` はすべて `Locale()`、`SendLog` は **`LocaleEn('log.*')`**（ja 未定義・英語固定）。
- **除外**: `print`、`Debug`、`RemoveMoney` / `AddMoney` の **取引メモ文字列**（`"Bought Property: "` 等）は英語のまま。
- **qbx ガレージ**: `label` は `Locale('ui.garage.label_format', …)`（サーバで解決）。

---

## `server/migrate.lua`

- `print("Finished migrating apartments/houses")` — **英語ベタのまま**（ロケールキー削除方針に合わせ YAGNI）。

---

## `shared/framework.lua`

- **8A-next-2-2 済み**: サーバ ox 通知 `title`、クライアント qb/ox ターゲット各 `label`、`lib.notify` の `title` → `Locale('notify.framework.property_title')` / `Locale('target.*')`。

---

## `shared/config.lua`（FurnitureTypes のみ）

- **8A-next-2-2 済み**: `AddTargetEntity` のラベル → `Locale('target.furniture.storage')` / `Locale('target.furniture.clothing')`（関数実行時に解決）。

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
2. ~~server / shared の置換~~ → **8A-next-2-2 完了**（2026-05-08）。`LocaleEn`、`log.*` の ja 削除、`debug.*` キー削除、`notify.apartment.peer_already_in` 案 C を含む。
3. 以降: NUI（Svelte）i18n、フォント、家具 CSV 等は別フェーズ。

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

## 8A-next-2-2 サーバ・共有側の除外（英語ベタのまま）

| 種別 | 例 | 理由 |
|------|-----|------|
| `server/server.lua` / `server/migrate.lua` の `print(...)` | DB エラー、移行完了 | 運営コンソール向け。`debug.*` ロケールキーは削除済み（YAGNI）。 |
| `server/*.lua` の `Debug(...)` | 物件更新トレース等 | 同上。 |
| `sv_property.lua` L27 付近 `RegisterInventory(..., 'Property: ' .. …)` | スタッシュ表示ラベル | 本タスクでは未キー化（必要なら将来 `inventory.*`）。 |
| `Framework.qb.SendLog` の呼び出し元 | — | メッセージはすべて `LocaleEn` 経由の英語。 |

---

## 旧 `debug.*` キー（削除済み・復活用メモ）

ロケールからは削除したが、過去に `locales/en.lua` / `ja.lua` に存在した **18 キー**（`debug.db.*`, `debug.migrate.*`, `debug.resource.*`）は、将来コンソール文言を統一したくなった場合の候補として [i18n-translation-review.md](i18n-translation-review.md) と併せて参照。
