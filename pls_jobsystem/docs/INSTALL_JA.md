# 導入手順 (pls_jobsystem 日本語化版)

本ドキュメントは FiveM サーバー運営者向けの導入ガイドです。手順どおりに進めれば、初めて触る方でも日本語 UI で動作させられます。

## 1. 前提

- サーバーが起動しており、`server.cfg` を編集できる
- ox_lib が導入済み（未導入なら先に [ox_lib のリリース](https://github.com/overextended/ox_lib/releases) から `ox_lib.zip` を取得して `resources/[standalone]/ox_lib/` に配置）
- 使用フレームワーク・インベントリ・ターゲットが既に動作している

## 2. 配置

1. 本リポジトリの `pls_jobsystem/` フォルダ全体を、サーバーの `resources/[local]/pls_jobsystem/` に配置します。
2. **フォルダ名は必ず `pls_jobsystem`** にしてください。スクリプト内部でリソース名を使ったセキュリティトークンを生成しているため、別名にすると起動時にエラーが出ます（コンソールに「リソース名は 'pls_jobsystem' でなければなりません」と表示されます）。

## 3. 依存リソースの起動順

`server.cfg` で `pls_jobsystem` より先に依存物を起動します。

```cfg
ensure ox_lib
ensure es_extended         # ESX を使う場合
# ensure qb-core           # QBCore を使う場合
ensure ox_inventory        # 使うインベントリ
ensure ox_target           # 使うターゲット
ensure pls_jobsystem
```

## 4. ブリッジ設定 (`BRIDGE/config.lua`)

| 項目 | 値の例 | 説明 |
|---|---|---|
| `BRIDGE.Framework` | `"ESX"` / `"QB"` / `"OX"` | 使用フレームワーク |
| `BRIDGE.Inventory` | `"ox_inventory"` / `"qb_inventory"` / `"quasar_inventory"` | 使用インベントリ |
| `BRIDGE.ESXOld` | `false` | 旧 ESX(1.1以前)なら `true` |
| `BRIDGE.Target` | `"ox_target"` / `"qb_target"` | 使用ターゲット |
| `BRIDGE.UseMarkers` | `false` | `true` にするとターゲット不要・地面マーカー運用 |
| `BRIDGE.QBStashesReplaceByPLS` | `false` | qb-inventory のスタッシュを置換する場合のみ `true` |

通知関数 `BRIDGE.Notify` はデフォルトで `lib.notify` を使います。独自通知に差し替えたい場合はこのファイル内で関数本体を書き換えてください。

## 5. メイン設定 (`config.lua`)

主な項目を抜粋します。

```lua
Config.Locale = "ja" -- 日本語UI（既定）。他に "en" / "cs"

Config.DirectoryToInventoryImages = "nui://ox_inventory/web/images/"
-- インベントリ画像のNUIパス。qb-inventoryの場合は "nui://qb-inventory/html/images/" 等

Config.BlacklistedStrings = {
    "weapon", "weed", "meth", "coke", "ammo", "gun", "pistol",
    "drug", "c4", "WEAPON", "AMMO", "at_", "keycard",
    "money", "black_money",
}
-- ジョブ作成画面のアイテム選択候補から除外する文字列。
-- 武器・違法品・通貨を一覧から隠す目的です。

Config.DEFAULT_ANIM     = "hack_loop"
Config.DEFAULT_ANIM_DIC = "mp_prison_break"
-- クラフト中の既定アニメーション。

-- ボスメニュー（外部リソース連携）。詳細は docs/BOSSMENU_JA.md
function openBossmenu(jobName)
    -- 例: exports['esx_society']:OpenBossMenu(jobName, function() end, { wash = false })
end

-- 通報（外部リソース連携）。詳細は docs/DISPATCH_JA.md
function SendDispatch(coords, jobLabel)
    -- 例: TriggerServerEvent('ps-dispatch:server:storeAlert', { ... })
end
```

## 6. ジョブの事前登録

このスクリプトは **データベースやフレームワークにジョブを自動登録しません**。各フレームワーク側でジョブを作っておく必要があります。

- **ESX**: `jobs` テーブル + `job_grades` テーブルに登録（`INSERT INTO jobs (name, label) VALUES ('burgershot', 'Burger Shot');` 等）
- **QBCore**: `qb-core/shared/jobs.lua` の `QBShared.Jobs` に追加
- **OX**: `ox_core` の `jobs` 設定に追加

ジョブ名は半角英数で、`/open_jobs` UI 上で「このジョブ名」を入力して紐付けます。

## 7. 起動確認

サーバーを再起動し、ゲーム内で `/open_jobs` を実行します。日本語の管理 UI が開けば成功です。

UI に英語が残っている場合は [`docs/TROUBLESHOOTING_JA.md`](./TROUBLESHOOTING_JA.md) の「NUI に英語が残る」を参照してください。
