# i18n キー命名規約（Lua）

プレフィックスで用途を分け、必要なら2階層以上のコンテキストを付与する（例: `notify.realtor.client_owns_property`）。

| プレフィックス | 用途 | 例 |
|----------------|------|-----|
| `notify.<context>.<event>` | `Framework[Config.Notify].Notify` / `ox_lib:notify` の本文 | `notify.purchase.success`, `notify.doorbell.no_answer` |
| `menu.<context>.<item>` | `lib.registerContext` の `title` / `options[].title` | `menu.apartments.list_title`, `menu.access.give` |
| `target.<context>.<action>` | ox / qb ターゲットの `label` | `target.property.enter`, `target.doorbell.ring` |
| `command.<name>.help` | `RegisterCommand` の help 文字列 | `command.migratehouses.help` |
| `dialog.<context>.<field>` | `lib.alertDialog` の `header` / `content` / `labels.confirm` 等 | `dialog.purchase.header`, `dialog.purchase.confirm` |
| `error.<context>` | 汎用エラー（細分化する場合は `error.<scope>.<reason>`） | `error.property.not_owner` |
| `log.<context>` | `SendLog` / 運営向け Discord ログの定型文 | `log.property.sold` |
| `debug.<context>` | `print` / 開発者向け（本番で翻訳しない場合もキーだけ確保可） | `debug.db.query_failed` |
| `radial.<id>.<field>` | ラジアルメニュー表示名 | `radial.furniture_menu.label` |
| `ui.<surface>.<field>` | ブリップ説明・動的 UI 断片（クライアント Lua） | `ui.apartment.blip_description` |

## 境界の例外

- 長いコンテキストは `notify.realtor.client_insufficient_funds` のように **2〜3 セグメント**まで許容する。  
- 同一英文が複数箇所で使われる場合は **1キーに統一**し、行番号は `i18n-extraction.md` で相互参照する。
