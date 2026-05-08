# i18n ユニークキー一覧（正規化済み）

- **総キー数（`locales/en.lua`）**: **132**（うちテスト `_test.*` = **3**、本番 = **129**）
- **`locales/ja.lua`**: **131**（`_test.fallback` は意図的に未定義 → en フォールバック）
- **検証**: `node tools/verify-locale-keys.mjs` で ja が en の全キー（`_test.fallback` 除く）をカバーすることを確認済み

## カテゴリ別件数

| プレフィックス | 件数 |
|----------------|------|
| `_test` | 3 |
| `debug` | 18 |
| `dialog` | 23 |
| `log` | 13 |
| `menu` | 11 |
| `notify` | 47 |
| `radial` | 2 |
| `target` | 13 |
| `ui` | 2 |

## 正規化ルール（適用済み）

- 同一英文・同一文脈は **1 キー**（例: `dialog.common.cancel` を全ダイアログで共用）
- `menu.access.give_*` は upstream で title/description が同語でも **役割が異なる**ためキー分割を維持
- 動的連結は **`string.format` 用プレースホルダ**に統一（コメントで引数順を記載）
- `notify.furniture.insufficient_funds` は client / server で **同一キー**

## キーと主要出現箇所（抜粋）

詳細な行番号は [i18n-extraction.md](i18n-extraction.md) を参照。以下はマスター用の **代表パス** のみ示す。

### notify

- `notify.apartment.already_in_tenant` — "You are already in this apartment" — `server/server.lua`（重複通知ブロック内）
- `notify.apartment.peer_already_in` — "This person is already in this apartment" — 同上（[upstream-issues.md](upstream-issues.md) 参照）
- `notify.apartment.moved_to` — `server/server.lua`
- `notify.common.player_not_found` — `server/server.lua` (`GetCitizenid`)
- `notify.doorbell.*` — `server/sv_property.lua`
- `notify.purchase.*` / `notify.realtor.*` — `server/sv_property.lua`
- `notify.property.*` — `client/cl_property.lua`, `server/sv_property.lua`
- `notify.furniture.*` — `client/modeler.lua`, `server/sv_property.lua`
- `notify.raid.*` — `server/sv_property.lua`
- `notify.access.*` — `server/sv_property.lua`
- `notify.spawn.furniture_radial_hint` — `server/server.lua`

### dialog / menu / radial / ui

- `dialog.*` — `client/client.lua`, `client/cl_property.lua`
- `menu.*` — `client/apartment.lua`, `client/cl_property.lua`
- `radial.*` — `client/cl_property.lua`
- `ui.*` — `client/client.lua`, `client/cl_property.lua`（ガレージラベル）

### target / notify.framework

- `target.*` / `notify.framework.property_title` — `shared/framework.lua`, `shared/config.lua`（Storage / Clothing）

### log / debug

- `log.*` — `server/sv_property.lua`, `server/server.lua`（`SendLog` / 説明文 `string.format`）
- `debug.*` — `server/server.lua`, `server/migrate.lua` の `print`

---

## 次ステップ（8A-next-2）

各出現箇所を `Locale('key', ...)` に置換し、`Framework[Config.Notify].Notify(..., Locale(...), ...)` 形式へ統一する。
