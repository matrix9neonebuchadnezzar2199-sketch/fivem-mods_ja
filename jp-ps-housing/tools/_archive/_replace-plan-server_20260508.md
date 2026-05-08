# Server / shared i18n 置換チェックリスト（8A-next-2-2）— 完了 2026-05-08

## shared/locale.lua

- [x] `LocaleEn()` 追加

## locales

- [x] `en.lua` — `debug.*` 削除、`peer_already_in` 案 C、`property.description.apartment` 追加、`log.property.apartment_description` 削除
- [x] `ja.lua` — 同上 + `log.*` 削除

## tools

- [x] `verify-locale-keys.mjs` — `log.*` を ja 必須から除外

## server/server.lua

- [x] `Notify` / `SendLog` / `property.description.apartment` / `GetCitizenid` 通知

## server/sv_property.lua

- [x] 全 `Notify` → `Locale`
- [x] 全 `SendLog` → `LocaleEn`
- [x] qbx ガレージ `label` → `Locale('ui.garage.label_format', …)`

## shared/framework.lua

- [x] サーバ ox 通知 title
- [x] クライアント qb / ox 全 target ラベル
- [x] クライアント `lib.notify` title

## shared/config.lua

- [x] `FurnitureTypes` Storage / Clothing

## docs

- [x] `i18n-design.md`, `i18n-keys-master.md`, `i18n-extraction.md`, `upstream-issues.md`, `dev-diary/2026-05-08_i18n_server_replaced.md`
