# 依存関係（Qbox 前提）

`fxmanifest.lua` の **`dependency { }` に明示されているのは `fivem-freecam` のみ**です。  
それ以外は `@ox_lib`、`@oxmysql`、`exports.ox_target` 等の**実行時参照**です。

モノレポ `fivem-mods_ja` 配下に **ox_* / qbx_* のフォルダは同梱されていない**ため、サーバーの `resources` で別途導入されているかを確認してください。

## 一覧（必須 / 推奨 / 省略可）

| リソース | 判定 | モノレポ同梱 | メモ |
|----------|------|--------------|------|
| [ox_lib](https://github.com/overextended/ox_lib) | **必須** | なし | `@ox_lib/init.lua` |
| [oxmysql](https://github.com/overextended/oxmysql) | **必須** | なし | `@oxmysql/lib/MySQL.lua` |
| [ox_target](https://github.com/overextended/ox_target) | **必須**（`Config.Target = "ox"` 時） | なし | `shared/framework.lua`。qb-target 利用時は [qb-target](https://github.com/qbcore-framework/qb-target) |
| [ox_inventory](https://github.com/overextended/ox_inventory) | **推奨**（Qbox 標準） | なし | `Config.Inventory = "ox"` で利用想定 |
| **qbx_core** | **必須**（Qbox） | なし | QBCore 互換 API。本リソースは Qbox の bridge 前提で動作 |
| [fivem-freecam](https://github.com/Deltanic/fivem-freecam) | **推奨**（モデラー利用時は実質必須） | なし | `dependency` 指定。家具配置フリーカム |
| [ps-realtor](https://github.com/Project-Sloth/ps-realtor) | **省略可**（家具・既存物件のみ） / **推奨**（売買・登録フロー） | なし | README では依存として言及。`fxmanifest` には未記載 |

## 補足

- **家具モデラーのみ**運用: `fivem-freecam` は manifest 上必須。`ps-realtor` は無くてもコードの一部は動くが、**物件売買・登録 UI** は別途必要。  
- **フル運用**（不動産ジョブ込み）: `ps-realtor` を導入し、README の起動順に合わせる。
