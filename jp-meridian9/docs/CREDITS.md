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

### サイト・ナイン（廃墟ステージ）

- **The Apocalypse Project** by Arcainex
  - 別途導入が必要（本リポジトリには同梱しない）。`Config.Mission.spawnPoint` は導入後に実座標へ差し替えること。
