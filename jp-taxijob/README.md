# jp-taxijob

Qbox（`qbx_core` + `ox_lib` + `ox_target`）向けのタクシーNPCミッションです。`qbx_taxijob` の乗降地点・PolyZone 等を踏襲し、受付NPC＋`ox_target` から **勤務開始/終了** できる操作体系に寄せています。

## 依存

- `qbx_core`（必須）
- `ox_lib`（必須）
- `ox_target`（必須）
- `ox_inventory`（`cryptostick` 付与を使う場合）

## 導入

1. 本フォルダを `resources/[jp-mods]/jp-taxijob/` に配置
2. **Qbox 前提**: `qbx_core` / `ox_lib` / `ox_target` 本体を `resources` に**インストール済み**であること
3. `server.cfg` では、**必ず** `ox_lib` → `qbx_core` 等を **`jp-taxijob` より上（先）**に `ensure` する
   - **FiveM Basic Server** だけ（デフォ数個）だと `ox_lib` リソースが**無い** → クライアント2行目で止まる。先に [ox_lib](https://github.com/communityox/ox_lib) を導入する
4. `server.cfg` に `ensure jp-taxijob`（`qb-taxijob` / `qbx_taxijob` は併用しない想定）
5. `config/client.lua` / `config/shared.lua` をサーバー方針に合わせて調整
6. `refresh` → `ensure jp-taxijob`

#### 起動してるか分からないとき

- サーバーコンソールに `server/bootstrap.lua LOADED`（`====` 区切り）→ サーバー側は起動できている
- 何も出ない → `ensure jp-taxijob` 無し / デプロイ先が古い / `resources` のフォルダ名違い
- F8 に `client/bootstrap.lua LOADED` → 先頭のクライアントは読めている
- F7 無反応＋上記なし → **リソース未起動**、または `ox_lib` 未導入で2行目以降が読めていない

## 重要メモ

- 互換のため `provide 'qb-taxijob'` があります。内部イベント/コールバック名は原則 `jp-taxijob:` 系です（互換用に `qb-taxi:server:spawnTaxi` 等も生かしています）。
- 受付前の黄色い円＋`E`、または受付NPCの `ox_target` から会話を開始します。

## 設定

- `config/client.lua`
  - 拠点/Blip/メーター/HUD/勤務制限/ボーナス等
- `config/shared.lua`
  - 乗車/降車の `vec4` 一覧
