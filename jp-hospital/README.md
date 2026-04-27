# jp-hospital

**病院カルテ整理・薬梱包**のミニゲーム（NUI 内職）です。症状に合わせて**正しい薬を梱包**し、**サーバ側**で正解を二重検証したうえで報酬（現金）を付与します。Qbox 系（`qbx_core`）想定。

## スクリーンショット

| 内容 |  |
| --- | --- |
| カルテ1 | ![カルテ1](docs/images/01-karte-1.png) |
| カルテ2 | ![カルテ2](docs/images/02-karte-2.png) |
| リザルト画面 | ![リザルト画面](docs/images/03-result.png) |

## 遊び方（プレイヤー）

1. **就業用 NPC**（`config.lua` の `Config.JobPedCoords`）に近づき、`ox_target` 等でメニューから**難易度**（初級／中級／上級）を選ぶ。出題数・正解数・ダミー数・基礎報酬（`Config.Difficulties`）が変わる。
2. 画面左に**症状・診断**、右に**梱包する薬の候補**（ダミー混じり）が出る。**正解の薬だけ**を梱包エリアにドラッグする。
3. カルテを**確定**すると、連続正解（コンボ）に応じた**倍率**がかかった報酬が支払われる。退勤は `config.lua` の **`Config.ExitCommand`**（既定 `hospital`）等で NUI を閉じる。

## 導入（サーバ運営者）

| 前提 | 備考 |
| --- | --- |
| `qbx_core` | 職・現金付与 |
| `ox_lib` | 通知等 |
| `ox_target` | 就業 NPC 操作 |

1. `jp-hospital` を `resources` に置く。  
2. `server.cfg` 例: `ensure jp-hospital`（依存リソースを先に起動）。  
3. **主に触るのは** `config.lua`（NPC 座標・`Config.Difficulties`・`Config.Medicines`・`Config.Kartes` ほかは日本語コメント付き）。**`refresh` 後「出題庫が空」**になるときは、サーバーの `jp-hospital` フォルダに**ローカルと同じ `config.lua` が置けているか**（デプロイ漏れ）を確認してください。中・上級専用の 30 問に分けたい場合は、ファイル末の `Config.KartesMedium` / `Config.KartesHard` を、初級と別テーブルとして定義し直せます（現状は初級と同じ出題を参照）。

## 仕様（簡易）

- **正解の生成**はサーバ、クライアント表示と**サーバ検証**の二重化で、チート向けの単純な偽装を想定。  
- カルテ内容・薬の種類は `config.lua` の `Config.Kartes` / `Config.Medicines` で拡張可能。

## クレジット

- 紹介画像: `docs/images/01-karte-1.png` ほか 3 枚。

## バージョン

- `fxmanifest.lua` の `version` 参照
