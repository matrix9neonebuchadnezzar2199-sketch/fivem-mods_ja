# jp-ps-housing 依存関係チェックリスト

`fxmanifest.lua` の **`dependency` ブロック**で明示されているのは次のみです。

- [ ] **fivem-freecam** — `dependency { 'fivem-freecam' }`。`client/modeler.lua` で `exports['fivem-freecam']` を使用。**家具モデラー（フリーカム）を使うなら必須**。

次は **shared_script** 等で参照されるが、`dependencies` に列挙されていないものです。

- [x] **ox_lib** — `@ox_lib/init.lua`。**モノレポ `fivem-mods_ja` 配下には `ox_lib` フォルダは含まれない**（サーバー側 `[standalone]` 等で別途導入が前提）。
- [ ] **oxmysql** — `@oxmysql/lib/MySQL.lua`。Qbox セットアップに通常含まれる。**モノレポ内フォルダなし**。
- [ ] **ox_target** — `shared/framework.lua` で `exports.ox_target`（`Config.Target = "ox"` 時）。**モノレポ内に `ox_target` フォルダなし**（別途導入）。
- [ ] **ps-realtor** — `fxmanifest` には無いが、不動産ジョブ UI（物件登録・売買フロー）と連携するリソース。**モノレポ内に `ps-realtor` フォルダなし**。家具配置・既存物件のみなら省略可能、**売買・リアルター業務まで使うなら導入必須**に近い。
- [ ] **qb-banking / QBCore 系** — `server/sv_property.lua` 等に `qb-banking` export の参照あり。Qbox では代替（銀行スクリプト）に差し替え要検討。

## まとめ

| リソース | モノレポ同梱 | 備考 |
|----------|--------------|------|
| ox_lib | なし | 導入済み前提 |
| ox_target | なし | Qbox で通常導入 |
| oxmysql | なし | 導入済み前提 |
| fivem-freecam | なし | モデラー利用時は必須 |
| ps-realtor | なし | フル housing 運用なら要検討 |
