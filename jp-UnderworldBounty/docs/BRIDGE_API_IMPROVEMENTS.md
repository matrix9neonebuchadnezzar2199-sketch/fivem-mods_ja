# BRIDGE_API 改善候補リスト

- 最終更新: 2026-05-04
- バージョン: v1.0
- 対象: BRIDGE_API.md v1.0.0 スナップショット時点の §9 改善候補（§9.4 は対象外）
- 関連: docs/BRIDGE_API.md, docs/INSTRUCTIONS_PHASE_1B.md

## 1. 目的

PHASE 1a / フォローアップで抽出された Bridge 層改善候補を、優先度・対応方針・工数とともに整理し、v1.1 以降の作業計画の基礎資料とする。

評価は `bridge/`・`server/`・`client/`・`config/`・`shared/` への `grep` と `bridge/sv_bridge.lua` の読取のみに基づく（公式 FW ドキュメントによる仕様確定は行っていない）。

## 2. 評価軸の凡例

### 優先度

| 優先度 | 判定基準 |
|--------|----------|
| P0 | 動作不能・データ破壊・セキュリティ脆弱性を引き起こす |
| P1 | 特定フレームワーク環境で動作不一致・運用上の混乱を引き起こす |
| P2 | コード品質・保守性の問題で、動作には影響しない |
| P3 | ドキュメント・命名のみ。コード変更不要または軽微 |

### 対応方針

| 記号 | 意味 |
|------|------|
| A | v1.1 でリファクタ実装（後方互換維持） |
| B | v1.1 でドキュメント追記のみ |
| C | v2.0 まで保留 |
| D | 却下 |

### 想定工数

| 規模 | 目安 |
|------|------|
| XS | 30分以内 |
| S | 1〜2時間 |
| M | 半日 |
| L | 1日以上 |

## 3. 改善候補一覧

### 3.1 IMP-N1（命名）

- BRIDGE_API.md 該当: §9.1（サーバー `Bridge` とクライアント `ClientBridge` でプレフィックスが異なる件）
- 概要: サーバー側テーブル名 `Bridge` とクライアント側 `ClientBridge` が非対称で、対応関係がソースを跨ぐまで分かりにくい。
- 影響範囲:
  - 定義: `bridge/sv_bridge.lua:42` ほか（`Bridge.*` 各関数）、`bridge/cl_bridge.lua:5`（`ClientBridge.Notify`）
  - 呼び出し元: `server/main.lua:25-34`, `server/heist.lua:5,13,28,29,58,63,73,90,153`, `server/rewards.lua:18,29`, `client/notifications.lua:4`
  - 呼び出し元数: 4（ファイル単位）
- 優先度: **P3**
  - 判定根拠: 命名・読みやすさの問題であり、現状コードからは実行時エラーや経済ロジック破壊には直結しない。
- 対応方針: **B**
  - 理由: v1.1 では `BRIDGE_API.md` 等で対応表と命名方針を明示すれば運用可能。テーブル名の機械的改名は外部リソースからの参照がある場合に破壊的になりうるため、まず文書で整理する。
- 想定工数: **XS**
- v1.1 採用可否: **採用**

### 3.2 IMP-A1（非対称）

- BRIDGE_API.md 該当: §9.2 1件目（`AddMoney` / `RemoveMoney` で QB の `black` が cash 扱いになる件）
- 概要: ESX 分岐では `black` / `black_money` を `black_money` アカウントへ載せ替える一方、QB/Qbox 分岐では `mtyp` が `bank` または `cash` のみで、`typ` が black でも `AddMoney`/`RemoveMoney` に `cash` が渡る（`bridge/sv_bridge.lua` L108-109, L143-144 付近のコード観察）。
- 影響範囲:
  - 定義: `bridge/sv_bridge.lua:84-112`（`Bridge.AddMoney`）、`bridge/sv_bridge.lua:119-147`（`Bridge.RemoveMoney`）
  - 呼び出し元: `server/rewards.lua:18`（`Bridge.AddMoney(..., 'cash', ...)` のみ。現状 grep では `black` 指定の呼び出しなし）
  - 呼び出し元数: 1（`AddMoney` の参照ファイル）。`RemoveMoney` の呼び出し元は grep 上なし。
- 優先度: **P1**
  - 判定根拠: QB 環境で API 上は `black` を受け付けるコメントがある一方、実装は現金として処理するため、運営が `black` を渡した場合に意図しない口座へ載る（フレームワーク間・仕様コメントとの不一致）。
- 対応方針: **A**
  - 理由: 振る舞いを ESX と整合させるか、QB のマークドビル等の実際の型に合わせるかはコード観察だけでは確定できないが、少なくとも `typ` と実際の `AddMoney` 引数の対応を明示し後方互換を保った上で修正する必要がある。詳細な QB 側 API は**要実機確認**。
- 想定工数: **S**
- v1.1 採用可否: **採用**

### 3.3 IMP-A2（非対称）

- BRIDGE_API.md 該当: §9.2 2件目（`GetPlayerData.money` が現金のみで銀行・ブラックを統一モデルで返していない件）
- 概要: ESX では `money` に `getMoney()` のみ。QB/Qbox では `Player.PlayerData.money.cash` のみを `money` に格納（`bridge/sv_bridge.lua:63-66`）。銀行・ブラックは返却テーブルに含まれない。
- 影響範囲:
  - 定義: `bridge/sv_bridge.lua:42-78`（`Bridge.GetPlayerData`）
  - 呼び出し元: `server/main.lua:25,32`（`/ub_test` で `d.money` 表示）、`bridge/sv_bridge.lua:219`（`Bridge.GetJob` が内部で `GetPlayerData` を参照）
  - 呼び出し元数: 2（`server/main.lua` と `Bridge.GetJob` の間接利用）
- 優先度: **P1**
  - 判定根拠: テストコマンドや将来ロジックが `money` を「総資産」と誤解すると運用上の混乱につながる。現状は表示の乖離が主だが、フレームワークごとに意味が異なるフィールドを単一キーに載せている。
- 対応方針: **A**
  - 理由: `money` に意味を足すか別フィールドを追加するかは設計判断だが、後方互換のため既存 `money` を維持しつつ `bank` 等を追加する形が現実的。各 FW の口座取得は**要実機確認**を伴う。
- 想定工数: **M**
- v1.1 採用可否: **採用**

### 3.4 IMP-A3（非対称）

- BRIDGE_API.md 該当: §9.2 3件目（Qbox 検出後も `qb-core` Export 依存・純粋 Qbox は要実機確認の件）
- 概要: `ensure_qb()` が `exports['qb-core']:GetCoreObject()` のみを使用（`bridge/sv_bridge.lua:19-29`）。`_init.lua` は `qbx_core` / `qb-core` の started のみ参照（`bridge/_init.lua:8-11`）。`Framework == 'qbox'` でも QB 系 API 経路は同一。
- 影響範囲:
  - 定義: `bridge/sv_bridge.lua:19-37`（`ensure_qb` / `qb_like_player`）、`bridge/_init.lua:1-21`（Framework 検出）
  - 呼び出し元: QB 分岐内の virtually all `Bridge.*`（`grep` 上、`qb_like_player` / `ensure_qb` は `sv_bridge.lua` 内で間接利用）
  - 呼び出し元数: `Bridge` 利用サーバースクリプトは `server/main.lua`, `server/heist.lua`, `server/rewards.lua`（いずれも Framework 依存）
- 優先度: **P1**
  - 判定根拠: `qb-core` リソースが存在しない環境では `ensure_qb()` が失敗し、Qbox と判定されていても Bridge の QB 経路が機能しない可能性がある（コード観察上の結論）。実環境で互換 Export があるかは**要実機確認**。
- 対応方針: **A**
  - 理由: 別リソース名からの `GetCoreObject` 取得やフォールバックを v1.1 で検討する。接続先の確定は実機または運営確認が必要。
- 想定工数: **M**
- v1.1 採用可否: **採用**

### 3.5 IMP-D1（ドキュメント）

- BRIDGE_API.md 該当: §9.3 1件目（`Bridge.Notify` の `typ` が ESX でクライアントに伝わらない件）
- 概要: ESX 分岐は `TriggerClientEvent('esx:showNotification', source, message)` のみで、`typ` を渡していない（`bridge/sv_bridge.lua:240-241`）。QBCore/Qbox は `QBCore:Notify` にマッピング済み。
- 影響範囲:
  - 定義: `bridge/sv_bridge.lua:238-250`（`Bridge.Notify`）
  - 呼び出し元: `server/main.lua:27-34`, `server/heist.lua:5,13,28,29,90,153`
  - 呼び出し元数: 2（ファイル単位）
- 優先度: **P2**
  - 判定根拠: 通知は表示されるが、ESX では `success` / `error` 等の区別がクライアントに伝わらず、他 FW と比べて UX が異なる。経済・状態整合性の破壊には直結しない。
- 対応方針: **B**
  - 理由: 契約を `BRIDGE_API` と運営向けガイドに明示し、ESX で typ を効かせるには別イベント／カスタム実装が必要であることを書き分ける。ESX 側 API の詳細は公式ドキュメント参照が指示禁止のため、コード変更は実機確認つきで別タスクとする。
- 想定工数: **XS**
- v1.1 採用可否: **採用**

### 3.6 IMP-D2（ドキュメント）

- BRIDGE_API.md 該当: §9.3 2件目（`AddItem` / `RemoveItem` の QB 戻り値契約が不明瞭な件）
- 概要: QB/Qbox では `Player.Functions.AddItem` / `RemoveItem` の戻り値をそのまま返す（`bridge/sv_bridge.lua:188,212`）。ESX は `true` 固定。`server/rewards.lua` は `pcall` のみで戻り値未検証（`server/rewards.lua:28-30`）。
- 影響範囲:
  - 定義: `bridge/sv_bridge.lua:173-191`（`Bridge.AddItem`）、`bridge/sv_bridge.lua:197-215`（`Bridge.RemoveItem`）
  - 呼び出し元: `server/rewards.lua:29`（`AddItem` のみ。`RemoveItem` の呼び出し元は grep 上なし）
  - 呼び出し元数: 1
- 優先度: **P3**
  - 判定根拠: 主に契約の明示と呼び出し側の扱いの問題。失敗時も現状は silent に近いが、既存 `BRIDGE_API.md` で非対称は記載済みで、致命的カテゴリ（P0）には該当しない。
- 対応方針: **B**
  - 理由: `BRIDGE_API`・CONFIG_GUIDE で「呼び出し側は戻り値を検証すべき」「QB は FW 依存」を徹底し、必要なら v1.2 以降で boolean 正規化（方針 A）を検討。FW の実戻り値は**要実機確認**。
- 想定工数: **XS**
- v1.1 採用可否: **採用**

## 4. v1.1 採用候補サマリ

| 識別子 | カテゴリ | 優先度 | 工数 | 対応方針 |
|--------|----------|--------|------|----------|
| IMP-N1 | 命名 | P3 | XS | B |
| IMP-A1 | 非対称 | P1 | S | A |
| IMP-A2 | 非対称 | P1 | M | A |
| IMP-A3 | 非対称 | P1 | M | A |
| IMP-D1 | ドキュメント | P2 | XS | B |
| IMP-D2 | ドキュメント | P3 | XS | B |

合計工数（採用分のみ）: XS×3 + S×1 + M×2（目安: 約 6〜10 時間。並行作業・実機確認の有無で変動）

## 5. 保留・却下候補サマリ

該当なし。6件すべて §4 で v1.1「採用」であり、方針 **C（v2.0 まで保留）** / **D（却下）** は付与していない。

## 6. 実機テスト依存項目

| 実機テスト項目 | 関連 IMP-* | 関連理由 |
|----------------|------------|----------|
| Qbox 依存（qb-core 不在環境） | IMP-A3 | `ensure_qb()` の成立条件とフォールバック方針を環境で確定する必要がある。 |
| AddItem 戻り値契約 | IMP-D2 | QB/Qbox の実戻り値と `rewards.lua` のエラーハンドリング方針を実機で確認するとよい。 |

## 7. 関連ドキュメント

- docs/BRIDGE_API.md
- docs/INSTRUCTIONS_PHASE_1A.md
- docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md
- docs/INSTRUCTIONS_PHASE_1B.md
- CHANGELOG.md

## 8. 改訂履歴

- 2026-05-04 v1.0: 初版作成。BRIDGE_API.md §9 の6項目を評価。
