# Client i18n 置換チェックリスト（8A-next-2-1）

作業完了: 2026-05-08。退避: `tools/_archive/_replace-plan-client_20260508.md`

## client/client.lua

- [x] L56: `ui.apartment.luxury_description`
- [x] L123–131: `dialog.purchase.*` + `dialog.common.cancel`
- [x] L135–145: `dialog.raid.*` + `dialog.common.cancel`
- [x] L148–158: `dialog.doorbell.*` + `dialog.common.cancel`
- [x] L161–171: `dialog.showcase.*` + `dialog.common.cancel`

## client/apartment.lua

- [x] L54: `notify.apartment.none_here`
- [x] L59, L85: `notify.apartment.none_in_building`
- [x] L66: `menu.apartments.list_title`
- [x] L92: `menu.apartments.raid_list_title`
- [x] L98: `menu.apartments.raid_option_title`（`string.format`）

## client/cl_property.lua

- [x] L186–194: `dialog.property_info.*`（Yes/No・価格行）
- [x] L192–196: `dialog.property_info.header`（`alertDialog`）
- [x] L266: `ui.garage.label_format`
- [x] L397: `radial.furniture_menu.label`
- [x] L410: `radial.manage_property.label`
- [x] L435: `notify.property.owner_only`
- [x] L443, L448, L455: `menu.access.*`
- [x] L475, L486: `menu.access.give_title`, `menu.access.give_description`
- [x] L496: `notify.access.no_players_inside`
- [x] L508, L520: `menu.access.revoke_title`, `menu.access.remove_description`
- [x] L530: `notify.access.none_to_revoke`
- [x] L538: `notify.doorbell.no_visitors`
- [x] L545: `menu.doorbell.title`

## client/modeler.lua

- [x] L469: `notify.furniture.cart_empty`
- [x] L480: `notify.furniture.insufficient_funds`
- [x] L591: `notify.furniture.stash_not_empty`
- [x] L697: **除外**（NUI `data.message` パススルー — キー化しない）

## client/migrate.lua / client/shell.lua

- [x] 作業なし（ユーザー向け英文ベタなし / コメントのみ）
