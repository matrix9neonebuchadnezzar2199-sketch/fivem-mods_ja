# MERIDIAN-9 クレジット

## 設計参考

### ルーティングバケット管理

- **JaredScar/Multiverse-World-Manager** (MIT License)
  - https://github.com/JaredScar/Multiverse-World-Manager
  - `server/session.lua` のバケット切替・座標テレポートの考え方を参考にした**独自実装**（ソースコードの直接利用はなし）。

### TP-Advanced-Zombies（Apache License 2.0）

- **作者**: TitansProductions
- **URL**: https://github.com/TitansProductions/TP-Advanced-Zombies
- **ライセンス**: Apache License 2.0（全文は `jp-meridian9/LICENSE-APACHE-2.0`）
- **ステータス**: リポジトリアーカイブ済み（NO LONGER SUPPORTED の表記あり）
- **利用範囲**: AI コア・スポーン制御の**思想・パターンを参考にした派生実装**（ESX/QBCore 依存の除去、`MRD9.Arena` 統合、バケット対応、波制御分離）
- **派生ファイル**:
  - `jp-meridian9/server/arena/spawn.lua`
  - `jp-meridian9/client/arena/zombie_ai.lua`
- **改変概要**: jp-meridian9 向けに命名・構造を再構成し、フレームワーク抽象化を削除。サーバー主導のスポーン座標選定とクライアント側 `CreatePed` 委譲を組み合わせる。

## マップ素材

### サイト・ナイン（北ヤンクトン）— **採用**

- **GTA V 本体同梱の North Yankton（Prologue「Ludendorff」ステージ）**
  - Rockstar Games 著作物。jp-meridian9 では IPL の有効化のみ（ymap の改変はしない）
- **[Bob74/bob74_ipl](https://github.com/Bob74/bob74_ipl)** — IPL ローダー
  - License: **MIT**
  - 用途: `exports['bob74_ipl']:GetNorthYanktonObject()` 経由で `NorthYankton.Enable(true/false)` / `Grave.Set` / `Traffic.Enable` を呼び出す
  - jp-meridian9 の `fxmanifest.lua` に `dependencies { 'bob74_ipl' }` として追加
  - 同梱せず、運営者が `git clone https://github.com/Bob74/bob74_ipl.git` で取得
  - 参考: [Wiki: GTA V North Yankton](https://github.com/Bob74/bob74_ipl/wiki/GTA-V:-North-Yankton)

### 検討したが採用しなかった案

- **The Apocalypse Project** by Arcainex（[GitHub](https://github.com/Arcainex/The-Apocalypse-Project)）
  - LS 内の ymap 直配置型で、bucket 単位のクライアント分離ができないため不採用（詳細は `docs/INSTRUCTION-020（サイト・ナイン MAP 導入）.md` v1→v2 の変更点）
- **alberttheprince/NorthYankton**（[GitHub](https://github.com/alberttheprince/NorthYankton)）
  - Bob74/bob74_ipl ベースの NorthYankton + bucket 分離の参考実装。jp-meridian9 では同等処理を `client/transition.lua` で自前統合するため不採用
