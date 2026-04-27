# jp-hospital

**病院カルテ整理・薬梱包**のミニゲーム（NUI 内職）です。症状に合わせて**正しい薬を梱包**し、**サーバ側**で正解を二重検証したうえで報酬（現金）を付与します。Qbox 系（`qbx_core`）想定。

## スクリーンショット

| 内容 |  |
| --- | --- |
| カルテ1 | ![カルテ1](docs/images/01-karte-1.png) |
| カルテ2 | ![カルテ2](docs/images/02-karte-2.png) |
| リザルト画面 | ![リザルト画面](docs/images/03-result.png) |

## 遊び方（プレイヤー）

1. **就業用 NPC**（`config.lua` の `Config.JobPedCoords`）に近づき、`ox_target` 等で**勤務開始**。
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
3. **`config.lua` のみ**主に触る。NPC 座標、報酬・コンボ、薬マスタ・症状カルテ、ダミー数、セッション有効秒など、各項目に**日本語コメント**あり。

## 仕様（簡易）

- **正解の生成**はサーバ、クライアント表示と**サーバ検証**の二重化で、チート向けの単純な偽装を想定。  
- カルテ内容・薬の種類は `config.lua` の `Config.Kartes` / `Config.Medicines` で拡張可能。

## クレジット

- 紹介画像: `docs/images/01-karte-1.png` ほか 3 枚。

## バージョン

- `fxmanifest.lua` の `version` 参照
