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
  - `jp-meridian9/client/arena.lua`
- **改変概要**: jp-meridian9 向けに命名・構造を再構成し、フレームワーク抽象化を削除。サーバー主導のスポーン座標選定とクライアント側 `CreatePed` 委譲を組み合わせる。

## マップ素材

### サイト・ナイン（Cayo Perico）— **採用** ✓ INSTRUCTION-020 v7

- **GTA V 本体同梱の Cayo Perico**（GTA Online Heist DLC、build 2189+）
  - Rockstar Games 著作物
- **[Monarch-Devs/mnr_cayo](https://github.com/Monarch-Devs/mnr_cayo)** — Cayo Perico IPL ローダー（**必須・本流実装**）
  - License: **GPL-3.0**
  - Author: IlMelons / Monarch-Devs
  - スタンドアロン、0.00ms、~250KiB、restart 耐性、カスタム ymap（邸宅ゲート開閉可）
  - クライアントログイン時に Cayo Perico の IPL を一度だけロード、海上に常時表示
  - **`jp-meridian9` 側は MAP 切替ネイティブを一切呼ばない**（壊さない構成）
  - 同梱せず、運営者が `git clone` で取得
- **[Bob74/bob74_ipl](https://github.com/Bob74/bob74_ipl)** — IPL ローダー（互換維持・現運用では未使用）
  - License: **MIT**
  - 旧 v2 北ヤンクトン採用時に使用、現運用では呼出ゼロ。jp-meridian9 dependencies に残置
  - 将来の北ヤンクトン拡張・他 IPL 制御の余地として依存維持

### 検証期間中の代替実装（コード上は残置）

- **GTA V Prologue「Ludendorff」（北ヤンクトン）**
  - jp-meridian9 v2 で採用したが、ジオメトリ未完成（建物の横壁欠落・雪で移動減速）のため v3 で Cayo Perico に切替
  - `client/transition.lua` の `applyNorthYankton` / `clearNorthYankton` および `Config.SiteNine.island = 'northYankton'` は **コード上残置**（将来のホラー演出・ロアロケーション拡張用）
  - `m9_ny` デバッグコマンドも維持

### 検討したが採用しなかった案

- **The Apocalypse Project** by Arcainex（[GitHub](https://github.com/Arcainex/The-Apocalypse-Project)）
  - LS 内の ymap 直配置型で、bucket 単位のクライアント分離ができないため不採用（詳細は `docs/INSTRUCTION-020（サイト・ナイン MAP 導入）.md` v1）
- **alberttheprince/NorthYankton**（[GitHub](https://github.com/alberttheprince/NorthYankton)）
  - Bob74/bob74_ipl ベースの NorthYankton + bucket 分離の参考実装。jp-meridian9 では同等処理を `client/transition.lua` で自前統合するため不採用
