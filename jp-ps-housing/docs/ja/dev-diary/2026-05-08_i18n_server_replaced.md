# 開発日記: server / shared の `Locale()`・`LocaleEn()` 置換（8A-next-2-2）

**日付**: 2026-05-08  
**コミット**: メッセージ `feat(server,shared): wire Locale()/LocaleEn(); refine peer_already_in (case C); drop debug locale keys`（`git log -1 --grep='LocaleEn'` 等で特定）

## 実施内容

- `shared/locale.lua`: **`LocaleEn(key, ...)`** 追加（常に `Locales['en']`）。
- `server/server.lua` / `server/sv_property.lua`: プレイヤー通知は **`Locale('notify.*', …)`**、**`SendLog` は `LocaleEn('log.*', …)`**。
- `shared/framework.lua`: qb-target / ox_target の **`label`**、`lib.notify` / ox サーバ通知の **`title`** を `Locale()` 化。
- `shared/config.lua`: **`Config.FurnitureTypes`** の target ラベル（Storage / Clothing）を `Locale()` 化。
- **`locales/en.lua`**: `debug.*` **18 キー削除**、`notify.apartment.peer_already_in` を案 C 英文へ、`log.property.apartment_description` を **`property.description.apartment`** に移し替え（DB 説明用・両言語）。
- **`locales/ja.lua`**: `debug.*` 削除、**`log.*` 12 キー削除**、`peer_already_in` 和訳更新、`property.description.apartment` 追加。
- **`tools/verify-locale-keys.mjs`**: **`log.*` は ja 欠落許容**。

## 確認手順（実機があれば）

1. `Config.Locale = 'ja'` — ゲーム内通知・ターゲットが日本語。
2. Discord / qb-log — メッセージが**英語**（Markdown 太字維持）。
3. アパート二重割当 — テナントと不動産でそれぞれ適切な日本語通知（不動産は案 C 相当）。

## コード差分サンプル（実機なし時）

**SendLog**

```lua
-- before
Framework[Config.Logs].SendLog("**House Bought** by: **"..a.." "..b.."** for $"..p.." from **"..c.." "..d.."** !")
-- after
Framework[Config.Logs].SendLog(LocaleEn('log.property.house_bought', a, b, p, c, d))
```

**Notify**

```lua
Framework[Config.Notify].Notify(src, Locale('notify.doorbell.someone_at_door'), "info")
```

**Debug（変更なし）**

```lua
Debug("Player is trying to enter property", property_id)
```

## 参照

- 計画（退避）: `tools/_archive/_replace-plan-server_20260508.md`
- 方針: [i18n-design.md](i18n-design.md)（`LocaleEn`・ログ英語固定）
