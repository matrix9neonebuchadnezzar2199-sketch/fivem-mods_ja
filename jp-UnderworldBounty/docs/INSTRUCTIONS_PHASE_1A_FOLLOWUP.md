# PHASE 1a フォローアップ作業指示書

> **ファイル名**: `docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md`  
> **対象 Cursor**: このファイルに従って作業を進めてください。  
> **作業者**: Cursor AI Assistant  
> **レビュー**: 人間（リポジトリオーナー）  
> **想定所要時間**: 30〜60 分  
> **成果物**: `docs/BRIDGE_API.md` の「要確認」2 件確定と §9 整理、`bridge/sv_bridge.lua` への用途コメント追加、開発日記への記録  
> **参照優先順位**: PHASE 1a フォローアップ期間中は本ファイルを最優先  

---

## 1. 作業の目的

PHASE 1a で作成した `docs/BRIDGE_API.md` には以下の積み残しがある。本作業でこれらを確定させ、`BRIDGE_API.md` を「v1.0.0 完全スナップショット」として完成させる。

第一に、「要確認」マーカー 2 件の事実確定。第二に、未使用関数 `RemoveMoney` / `RemoveItem` の方針コメント追加。第三に、Qbox 環境であることが確定したため、その情報を開発日記に記録。

**重要原則**: 本作業では bridge 実装コードの**ロジックを一切変更しない**。`bridge/sv_bridge.lua` への変更は**コメント追加のみ**許可。挙動を変える変更は禁止。

---

## 2. 作業前の前提確認

開始前に以下を確認すること。確認できなければ作業を中断し、ユーザーに報告する。

**第一に**、リポジトリのルート（jp-UnderworldBounty 配下）にいることを確認する。モノレポ環境なので、作業対象は `jp-UnderworldBounty/` 配下のみ。他プロジェクト（jp-losmon、jp-tcgbook 等）のファイルには一切触れない。

**第二に**、`docs/BRIDGE_API.md` が存在し、PHASE 1a 完了時点のスナップショットになっていることを確認する。「要確認」マーカーが 2 件残っているはず（Qbox の qb-core 依存、AddItem の戻り値契約）。

**第三に**、`jp-UnderworldBounty/` 配下の git 状態がクリーンであることを確認する。リポジトリ全体のクリーン状態は不要（モノレポ運用）。

**第四に**、`bridge/sv_bridge.lua` が存在し、`RemoveMoney` / `RemoveItem` 関数が定義されていることを確認する。

---

## 3. 確定すべき事実（環境調査結果）

ユーザーから以下の環境情報が提供された。本作業ではこれを事実として扱う。

### 3.1 サーバー環境

ユーザーの FiveM サーバーの `resources` 配下には以下のリソースが存在する：

`qbx_core` `qbx_spawn` `qbx_vehicles` `qbx_hud` `qbx_radialmenu` `qbx_smallresources`、`ox_inventory` `ox_lib` `ox_target` `oxmysql`、`illenium-appearance`、`[gamemodes]` `[gameplay]` `[jp-mods]` `[local]` `[managers]` `[system]` `[test]`。

**重要事実**: `qb-core` は存在しない。**純粋な Qbox 環境**である。

### 3.2 これが意味すること

PHASE 1a で残った「要確認」のうち、Qbox の qb-core 依存に関する論点は以下のように確定する。

ユーザーの環境では `qb-core` リソースが存在しないため、Bridge コードが `exports['qb-core']:GetCoreObject()` のような呼び出しを行っているなら、その経路は**この環境では動作しない**。ただし、`qbx_core` が `qb-core` 互換の export を提供している可能性があるため、`bridge/sv_bridge.lua` および `bridge/cl_bridge.lua` のコードを再確認し、Qbox での実際の動作経路を特定する必要がある。

---

## 4. 作業内容

### 4.1 タスク 1: Qbox 依存の事実確定

**目的**: `BRIDGE_API.md` の「要確認」のうち、Qbox の qb-core 依存に関する記述を事実として確定する。

**手順**:

**第一に**、`bridge/_init.lua` `bridge/sv_bridge.lua` `bridge/cl_bridge.lua` の 3 ファイルで、`qb-core` または `GetCoreObject` を grep する。具体的には `'qb-core'` `"qb-core"` `GetCoreObject` の各文字列を検索。

**第二に**、grep で見つかったコードを実際に読み、以下を判定する：

- (a) Qbox 環境で `qb-core` リソースを直接参照しているか  
- (b) `qbx_core` の export を経由しているか  
- (c) フレームワーク自動検出で Qbox を QBCore として扱っているか  

**第三に**、判定結果に基づき `BRIDGE_API.md` の該当「要確認」マーカーを以下のように書き換える：

**確定パターン A**（qb-core を直接参照している場合）：

> v1.0.0 時点で Bridge コードは `qb-core` リソースを直接参照している。純粋な Qbox 環境（`qb-core` 不在）では当該経路は動作しない可能性がある。本プロジェクトの想定環境（Qbox + qbx_core）での動作確認は v1.1 で実施予定。

**確定パターン B**（qbx_core を経由している場合）：

> v1.0.0 時点で Bridge コードは `qbx_core` の export を経由しており、純粋な Qbox 環境で動作する。

**確定パターン C**（自動検出で QBCore として扱っている場合）：

> v1.0.0 時点で Bridge コードは Qbox を QBCore 互換として扱う。`qb-core` の有無に関わらず、QBCore 系の export が利用可能であれば動作する想定。

判定が困難な場合は、現状の「要確認」マーカーを「**要実機確認（v1.1 で動作検証予定）**」に書き換え、grep 結果と判定の悩みどころを `BRIDGE_API.md` 内にコメント形式で記録する。

---

### 4.2 タスク 2: AddItem 戻り値契約の事実確定

**目的**: もう 1 件の「要確認」マーカー（AddItem の戻り値契約）を確定する。

**手順**:

**第一に**、`bridge/sv_bridge.lua` の `Bridge.AddItem` 関数定義を再確認する。各フレームワーク経路（ESX / QBCore / Qbox / Standalone）で、内部呼び出ししている関数とその戻り値を観察する。

**第二に**、コードからの観察で以下を確定する：

- 各フレームワーク経路で内部関数（例: `xPlayer.addInventoryItem`、`Player.Functions.AddItem`、`exports.ox_inventory:AddItem`）の戻り値が何か  
- `Bridge.AddItem` 自身がそれをどう加工して返すか（return しない / そのまま return / boolean に正規化）  

**第三に**、判定結果を `BRIDGE_API.md` に反映する。フレームワーク間で戻り値が非対称な場合（例: ESX は nil、QBCore は boolean、Qbox は number）は表で明示する。

完全に確定できない場合は「**要実機確認**」マーカーで残し、観察できた事実のみ記録する。

---

### 4.3 タスク 3: 用途予約コメントの追加

**目的**: 未使用関数 `RemoveMoney` / `RemoveItem` に方針コメントを追加し、削除候補ではなく「再評価対象」として扱われるよう明示する。

**手順**:

**第一に**、`bridge/sv_bridge.lua` の **`Bridge.RemoveMoney` の `function` 行の直前**に、次のコメントブロックを挿入する（**既存の `function Bridge.RemoveMoney(source, typ, amount)` 行は削除・変更しない**）。

```lua
-- v1.0.0 時点では server/*.lua から未参照。
-- 削除はせず、v1.1 で必要性を再評価する（中立的な保留扱い）。
-- 参考想定用途: 強盗失敗時の罰金、報復 NPC への賄賂支払いなど（未確定）。
```

**第二に**、`Bridge.RemoveItem` の **`function` 行の直前**にも同様に挿入する：

```lua
-- v1.0.0 時点では server/*.lua から未参照。
-- 削除はせず、v1.1 で必要性を再評価する（中立的な保留扱い）。
-- 参考想定用途: 強盗失敗時のアイテム没収、報復イベント関連など（未確定）。
```

**第三に**、関数のロジック・引数・戻り値・実装本体には**一切手を加えない**。コメント追加のみ。

---

### 4.4 タスク 4: BRIDGE_API.md §9 の整理

**目的**: 改善候補に列挙されている「未使用」項目を、保留扱いに分類変更する。

**手順**:

**第一に**、`docs/BRIDGE_API.md` §9 の「未使用」項目（`RemoveMoney` / `RemoveItem`）を、「**v1.1 で再評価予定**」として分類変更する。

書き換え例：

**変更前** （PHASE 1a 完了時点）:

```markdown
### 9.4 未使用 API

- `RemoveMoney`、`RemoveItem` は現リポジトリの `server/*.lua` から **呼ばれていない**（将来用または dead code 候補）。
```

**変更後** （フォローアップ後）:

```markdown
### 9.4 v1.1 再評価対象（保留扱い）

- `Bridge.RemoveMoney` / `Bridge.RemoveItem` は v1.0.0 時点で `server/*.lua` から未参照。
  削除候補ではなく、v1.1 で必要性を再評価する保留扱い。
  関数定義の直前にも同旨のコメントを追加済み（`bridge/sv_bridge.lua`）。
```

**第二に**、改善候補のセクション内訳が変わるので、§9 全体のリスト構成を見直す。命名・非対称・ドキュメント不足の各カテゴリは現状維持、「未使用」カテゴリのみ「v1.1 再評価対象」にリネーム。

---

### 4.5 タスク 5: 開発日記への記録

**目的**: 環境情報と本作業の判断を記録する。

**手順**:

`docs/2026-05-04_開発日記.md` の末尾に「追記（PHASE 1a フォローアップ）」セクションを追加する。記録内容は以下の構成でよい（具体文はタスク 1・2 の結果で埋める）。

- **環境情報の確定**（純粋 Qbox、ox_*、illenium-appearance 等）  
- **BRIDGE_API.md の確定**（Qbox 依存、AddItem 戻り値の要約 1〜2 行ずつ）  
- **RemoveMoney / RemoveItem の方針**（v1.1 再評価・参考想定用途・未確定である旨）  
- **関連コミット** メッセージ  

---

### 4.6 タスク 6: CHANGELOG.md の更新

`CHANGELOG.md` の `[Unreleased]` セクションに以下を追記する：

```markdown
### Changed

- `docs/BRIDGE_API.md` の「要確認」2 件を確定。Qbox は純粋環境（qb-core 不在）を前提として記述。
- `Bridge.RemoveMoney` / `Bridge.RemoveItem` を「v1.1 再評価対象」として分類変更。
  関数定義に保留方針コメントを追加（実装ロジックは変更なし）。
```

---

## 5. 作業対象外（明示的に禁止）

以下は本作業では**絶対に行わない**。

`fxmanifest.lua` の `dependencies` セクション変更（ox_lib 有効化等）。これは PHASE 5/6 で別途扱う。

`bridge/sv_bridge.lua` `bridge/cl_bridge.lua` `bridge/_init.lua` の**ロジック変更**。コメント追加のみ許可。引数の追加・戻り値の変更・条件分岐の追加は禁止。

`server/*.lua` `client/*.lua` `config/*.lua` の変更。本作業では Bridge 関連ドキュメントとコメントのみが対象。

新しい関数の追加。`Bridge.PenaltyMoney` のような新 API は v1.1 設計時に別途議論する。

LICENSE の変更。

git tag の追加（PHASE 1 全体完了まで保留）。

force push、rebase、過去コミットの書き換え。

`.gitignore` で除外されているファイル（`.cursor/`、`*.local.lua` 等）の commit。

ユーザー個人情報、API キー、サーバー設定など秘匿情報の commit。

---

## 6. セルフチェックリスト

提出前に以下を全て確認すること。

**事実確定について**、`BRIDGE_API.md` の「要確認」マーカー 2 件が確定または「要実機確認」に書き換えられている。Qbox 関連の記述がユーザー環境（純粋 Qbox）と整合している。AddItem 戻り値の各フレームワーク経路が記述されている。

**コメント追加について**、`bridge/sv_bridge.lua` の `RemoveMoney` 直前にコメントが追加されている。`RemoveItem` 直前にも同様のコメントが追加されている。コメント以外の変更（ロジック・引数・戻り値）が一切ない。

**ドキュメント更新について**、`BRIDGE_API.md` §9 の「未使用」が「v1.1 再評価対象」に書き換えられている。`docs/2026-05-04_開発日記.md` に追記が追加されている。`CHANGELOG.md` の `[Unreleased]` に追記がある。

**git diff について**、`git diff --stat` で変更ファイルが想定通り（`BRIDGE_API.md`、`sv_bridge.lua`、開発日記、`CHANGELOG.md` の 4 ファイル）。`bridge/cl_bridge.lua`、`bridge/_init.lua`、`server/*.lua`、`client/*.lua` が変更されていない。

**形式について**、文字コードが UTF-8、改行が LF。日本語と英数字の間に半角スペース。

---

## 7. コミット手順

セルフチェック完了後、以下の順序で commit する。

```bash
# 変更状況確認
git status

# 期待される変更ファイル（jp-UnderworldBounty/ 配下のみ）:
#   modified: jp-UnderworldBounty/docs/BRIDGE_API.md
#   modified: jp-UnderworldBounty/bridge/sv_bridge.lua
#   modified: jp-UnderworldBounty/docs/2026-05-04_開発日記.md
#   modified: jp-UnderworldBounty/CHANGELOG.md

# jp-UnderworldBounty/ 配下のみ stage
git add jp-UnderworldBounty/docs/BRIDGE_API.md
git add jp-UnderworldBounty/bridge/sv_bridge.lua
git add jp-UnderworldBounty/docs/2026-05-04_開発日記.md
git add jp-UnderworldBounty/CHANGELOG.md

# モノレポ配下他プロジェクトの変更が混入していないか最終確認
git diff --cached --stat

# コミット
git commit -m "docs(jp-UnderworldBounty): finalize BRIDGE_API.md and reserve unused bridge functions

PHASE 1a follow-up:
- Confirm Qbox environment (qbx_core only, no qb-core) and update BRIDGE_API.md
- Resolve AddItem return value contract per framework path
- Reclassify Bridge.RemoveMoney / Bridge.RemoveItem as 'v1.1 reevaluation target'
  with neutral hold-comments at function definitions
- Update development log with environment confirmation and rationale

No implementation logic changes. Comments and documentation only.

See docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md for the full task spec."

# プッシュ
git push origin main
```

タグは付けない（PHASE 1 全体完了まで保留）。

**注**: 本作業指示書自体を初回コミットする場合は、`git add -f jp-UnderworldBounty/docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md` を別コミットにしてもよい（フォローアップ実行コミットと分離）。

---

## 8. 完了報告のフォーマット

作業完了後、以下のフォーマットでユーザーに完了報告する。

```
## PHASE 1a フォローアップ 完了報告

### 「要確認」確定状況
- Qbox の qb-core 依存: [確定 / 半確定（要実機確認）] - [判定結果の要約 1 行]
- AddItem の戻り値契約: [確定 / 半確定] - [判定結果の要約 1 行]

### Bridge.RemoveMoney / RemoveItem 処置
- bridge/sv_bridge.lua にコメント追加（v1.1 再評価対象として保留）
- BRIDGE_API.md §9 の分類を「未使用」→「v1.1 再評価対象」に変更

### 環境情報の記録
- 純粋 Qbox 環境（qb-core 不在、qbx_core 系のみ）であることを開発日記に記録
- ox_lib / ox_inventory / ox_target / oxmysql / illenium-appearance の存在を記録
- PHASE 5/6 で活用予定の依存リソースとして将来参照可能な形で残置

### 作成・更新したファイル
- 更新: docs/BRIDGE_API.md（要確認確定、§9 分類変更）
- 更新: bridge/sv_bridge.lua（コメント 2 箇所追加、ロジック変更なし）
- 更新: docs/2026-05-04_開発日記.md（追記セクション）
- 更新: CHANGELOG.md（[Unreleased] に追記）

### Git
- コミット: docs(jp-UnderworldBounty): finalize BRIDGE_API.md and reserve unused bridge functions
- プッシュ: origin main 済み
- 実装ロジック: 変更なし（§5 準拠）

### 残課題（人間判断が必要なもの）
- [もし「半確定」のまま残った要確認があれば、その内容と確認方法を列挙]

### 次のアクション提案
- (a) PHASE 1b（改善候補の優先づけ・Issue 化）
- (b) PHASE 5/6 の依存方針確定（ox_lib 等の dependencies 有効化）
- (c) v1.1 の機能設計（罰金・賄賂システム等）
```

---

## 9. 不明点・例外発生時の対応

作業中に以下のような状況が発生した場合は、**作業を一時中断してユーザーに報告**する。

`bridge/sv_bridge.lua` で `RemoveMoney` または `RemoveItem` が見つからない（PHASE 1a の観察と矛盾）。

grep で `qb-core` `GetCoreObject` を検索しても 1 件もヒットしない（PHASE 1a の観察と矛盾、または別の経路で QBCore 系を検出している可能性）。

「要確認」マーカーが 2 件以外の数だけ存在する（3 件以上、または 0 件）。

`bridge/sv_bridge.lua` への変更がコメント追加のみに収まらない（リファクタが必要に思える）。

報告フォーマット：

```
PHASE 1a フォローアップ作業中に以下を確認したい。
[状況の説明]
判断を求める：
(a) ...
(b) ...
推奨: (X)
```

ユーザーの指示を受けてから作業を再開する。

---

## 10. 関連ドキュメント

- `docs/INSTRUCTIONS_PHASE_1A.md` — 元になった作業指示書  
- `docs/BRIDGE_API.md` — 本作業で更新する対象  
- `docs/DESIGN.md` — 全体設計  
- `docs/RETALIATION_FSM.md` — Bridge を呼び出すサーバー側ロジックの主要利用者  

---

## 11. 改訂履歴（本指示書）

| 日付 | 版 | 変更内容 |
|------|-----|----------|
| 2026-05-04 | v1.0 | 初版、PHASE 1a フォローアップ作業指示書として作成 |

---

## Cursor への投げ方（ユーザー向け補足）

このファイルを保存したうえで、チャットで例えば次のように指示する。

```
@docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md に従って作業を実施してください。
進める前に「§2 作業前の前提確認」をすべてチェックし、結果を報告してから本作業に入ってください。
不明点があれば §9 のフォーマットで報告してください。
完了したら §8 のフォーマットで完了報告をしてください。
```

**レビュー時**: `bridge/sv_bridge.lua` に**コメント以外の変更**がないか `git diff` で確認する。ロジック行に `-` が付いていれば NG。コメント追加のみなら、本体の削除は発生しない想定。
