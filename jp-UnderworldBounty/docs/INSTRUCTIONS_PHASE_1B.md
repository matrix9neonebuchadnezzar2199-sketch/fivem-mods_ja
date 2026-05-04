# INSTRUCTIONS_PHASE_1B

PHASE 1b 作業指示書（Cursor 自走用・完全版）

- 最終更新: 2026-05-04
- バージョン: v1.1
- 対象リポジトリ: `fivem-mods_ja/jp-UnderworldBounty/`
- 想定所要時間: 1〜2時間
- 前提指示書: `docs/INSTRUCTIONS_PHASE_1A.md`、`docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md`（共に完了済み）

---

## 1. 目的

`docs/BRIDGE_API.md` §9 に列挙された改善候補を、優先度付きの Issue 化用ドキュメント `docs/BRIDGE_API_IMPROVEMENTS.md` として整理する。各候補に対して、影響範囲・優先度・対応方針・想定工数・v1.1 採用可否を記述する。

実装コードは一切変更しない。ドキュメント整備のみ。

---

## 2. 作業前の前提確認（必ず最初に実施し、結果を報告してから本作業へ進む）

以下を順に確認し、§9 のフォーマットで結果を報告すること。すべて OK でなければ本作業に進まない。

1. カレントディレクトリが `fivem-mods_ja/jp-UnderworldBounty/` 配下であること。
2. `git status` で **`jp-UnderworldBounty/` 配下に未コミット変更がないこと**。他プロジェクトの未コミット変更は無視してよい。
3. ブランチが `main` であること。
4. 以下のファイルが存在すること:
   - `docs/BRIDGE_API.md`
   - `bridge/_init.lua`
   - `bridge/sv_bridge.lua`
   - `bridge/cl_bridge.lua`
   - `CHANGELOG.md`
   - `docs/2026-05-04_開発日記.md`
5. `docs/BRIDGE_API.md` §9 の改善候補が**6件**（命名1、非対称3、ドキュメント2）であることを目視確認。「v1.1 再評価対象（保留扱い）」§9.4 は対象外。件数が異なる場合は中断し §9 で報告。
6. `docs/BRIDGE_API_IMPROVEMENTS.md` が**存在しないこと**。既に存在する場合は中断し §9 で報告（誤って既存ファイルを上書きしないため）。

---

## 3. 禁止事項

- `bridge/` 配下の**全ファイル**の変更（コメント追加も含めて一切不可）。
- `docs/BRIDGE_API.md` の§9以外のセクションの変更。
- `fxmanifest.lua` の変更。
- 公式ドキュメント（ESX/QBCore/Qbox）への参照による仕様確定。**コード観察のみで判断**し、確定不能なら「要実機確認」と記載。
- v1.1 の実装着手・リファクタコードの提案以外の作業。
- `git checkout -- .`（モノレポ全体に影響するため禁止）。
- `git tag` の付与。
- 主観的・推測ベースの優先度判定（後述の判定基準に厳密に従うこと）。

---

## 4. タスク

### 4.1 改善候補の再列挙と分類確認

`docs/BRIDGE_API.md` §9 から以下の6項目を抽出し、識別子を付与する。識別子は本指示書内および改善候補ドキュメント内で一貫して使用する。

| 識別子 | カテゴリ | 概要（BRIDGE_API.md §9 の記述から1行で要約） |
|---|---|---|
| IMP-N1 | 命名 | （§9.1 から抽出） |
| IMP-A1 | 非対称 | （§9.2 から抽出、1件目） |
| IMP-A2 | 非対称 | （§9.2 から抽出、2件目） |
| IMP-A3 | 非対称 | （§9.2 から抽出、3件目） |
| IMP-D1 | ドキュメント | （§9.3 から抽出、1件目） |
| IMP-D2 | ドキュメント | （§9.3 から抽出、2件目） |

抽出時は BRIDGE_API.md §9 の記述を**改変せず**、要約のみ行う。元の記述番号（§9.1.x 等）も併記する。

### 4.2 各候補の評価軸

各 IMP-* について以下5項目を評価する。

#### 影響範囲

該当コードを `grep -rn` で検索し、ヒット箇所をすべて列挙。

検索対象は `bridge/`、`server/`、`client/`、`config/`、`shared/` 配下。

形式:

```
- 定義: bridge/sv_bridge.lua:LXX
- 呼び出し元: server/heist.lua:LYY, server/rewards.lua:LZZ
- 呼び出し元数: 2
```

ヒットなしなら「呼び出し元なし」と記載。

#### 優先度

以下の判定基準に厳密に従う。**主観で動かさない**。

| 優先度 | 判定基準 |
|---|---|
| P0 | 動作不能・データ破壊・セキュリティ脆弱性を引き起こす |
| P1 | 特定フレームワーク環境で動作不一致・運用上の混乱を引き起こす |
| P2 | コード品質・保守性の問題で、動作には影響しない |
| P3 | ドキュメント・命名のみ。コード変更不要または軽微 |

各候補について、判定基準のどれに該当するかを1行で記述する。

#### 対応方針

以下のいずれかを選択し、選択理由を1〜3行で記述。

- **A. v1.1 でリファクタ実装**: コード変更を伴う。後方互換性を維持。
- **B. v1.1 でドキュメント追記のみ**: コード変更なし、ドキュメント更新のみ。
- **C. v2.0 まで保留**: 破壊的変更を含むため、メジャーバージョンアップまで先送り。
- **D. 却下**: 改善不要と判断。判定理由を必ず記述。

#### 想定工数

| 規模 | 目安 |
|---|---|
| XS | 30分以内 |
| S | 1〜2時間 |
| M | 半日 |
| L | 1日以上 |

#### v1.1 採用可否

「採用」「保留」「却下」のいずれか。対応方針が A/B のものは原則「採用」、C は「保留」、D は「却下」。

### 4.3 `docs/BRIDGE_API_IMPROVEMENTS.md` の作成

UTF-8 LF で新規作成。以下の構造で記述する。

```markdown
# BRIDGE_API 改善候補リスト

- 最終更新: 2026-05-04
- バージョン: v1.0
- 対象: BRIDGE_API.md v1.0.0 スナップショット時点の §9 改善候補
- 関連: docs/BRIDGE_API.md, docs/INSTRUCTIONS_PHASE_1B.md

## 1. 目的

PHASE 1a / フォローアップで抽出された Bridge 層改善候補を、優先度・対応方針・工数とともに整理し、v1.1 以降の作業計画の基礎資料とする。

## 2. 評価軸の凡例

（§4.2 の判定基準を表形式で再掲）

## 3. 改善候補一覧

### 3.1 IMP-N1（命名）

- BRIDGE_API.md 該当: §9.1.x
- 概要: （1〜2行）
- 影響範囲:
  - 定義: （ファイル:行）
  - 呼び出し元: （ファイル:行 のリスト）
  - 呼び出し元数: N
- 優先度: P[0-3]
  - 判定根拠: （1行）
- 対応方針: [A/B/C/D]
  - 理由: （1〜3行）
- 想定工数: [XS/S/M/L]
- v1.1 採用可否: [採用/保留/却下]

### 3.2 IMP-A1（非対称）
（同形式）

### 3.3 IMP-A2（非対称）
（同形式）

### 3.4 IMP-A3（非対称）
（同形式）

### 3.5 IMP-D1（ドキュメント）
（同形式）

### 3.6 IMP-D2（ドキュメント）
（同形式）

## 4. v1.1 採用候補サマリ

採用判定の項目のみを以下の表で再掲。

| 識別子 | カテゴリ | 優先度 | 工数 | 対応方針 |
|---|---|---|---|---|
| IMP-* | ... | P? | ? | A/B |

合計工数（採用分のみ）: XS×N + S×N + M×N + L×N

## 5. 保留・却下候補サマリ

保留・却下判定の項目を理由とともに列挙。

| 識別子 | 判定 | 理由（1行） |
|---|---|---|

## 6. 実機テスト依存項目

「要実機確認」マーカーが残っている項目（INSTRUCTIONS_PHASE_1A_FOLLOWUP の完了報告で2件確定済み）と、本ドキュメントの IMP-* との関連を記述。

| 実機テスト項目 | 関連 IMP-* | 関連理由 |
|---|---|---|
| Qbox 依存（qb-core 不在環境） | IMP-? | （関連があれば1行） |
| AddItem 戻り値契約 | IMP-? | （関連があれば1行） |

関連がない場合は「直接の関連なし」と記載。

## 7. 関連ドキュメント

- docs/BRIDGE_API.md
- docs/INSTRUCTIONS_PHASE_1A.md
- docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md
- CHANGELOG.md

## 8. 改訂履歴

- 2026-05-04 v1.0: 初版作成。BRIDGE_API.md §9 の6項目を評価。
```

### 4.4 関連ドキュメント更新

#### `docs/BRIDGE_API.md`

§9 の冒頭（章タイトル直下）に以下の1行を追加:

```markdown
> 各候補の優先度・対応方針・工数評価は `docs/BRIDGE_API_IMPROVEMENTS.md` を参照。
```

§9 の本文・項目構成は変更しない。

#### `docs/DESIGN.md`

ドキュメントツリー / 付録セクションに `BRIDGE_API_IMPROVEMENTS.md` の行を追加。位置は `BRIDGE_API.md` の直後。

#### `README.md`

ドキュメント表に `BRIDGE_API_IMPROVEMENTS.md` の行を追加。位置は `BRIDGE_API.md` の直後。説明文は「Bridge層改善候補の優先度・工数評価」とする。

#### `CHANGELOG.md`

`[Unreleased]` の `### Added` に以下を追加:

```markdown
- `docs/BRIDGE_API_IMPROVEMENTS.md`: BRIDGE_API.md §9 改善候補6件の優先度・対応方針・工数評価。v1.1 採用判断の基礎資料。
```

`### Changed` に以下を追加:

```markdown
- `docs/BRIDGE_API.md`: §9 冒頭に IMPROVEMENTS.md への参照を追加。
```

#### `docs/2026-05-04_開発日記.md`

末尾に PHASE 1b 完了セクションを追加:

```markdown
## PHASE 1b 完了（改善候補の優先付け）

- `docs/BRIDGE_API_IMPROVEMENTS.md` を新規作成。
- 対象: BRIDGE_API.md §9 の改善候補6件（命名1、非対称3、ドキュメント2）。
- v1.1 採用候補: N件、保留: M件、却下: K件。
- 合計採用工数: XS×N + S×N + M×N + L×N（実時間換算で約X時間）。
- 実機テスト依存項目（Qbox 依存、AddItem 戻り値契約）との関連を §6 にマッピング。
- 次アクション: 実機テスト指示書 `INSTRUCTIONS_PHASE_1A_LIVE_TEST.md` 作成、または PHASE 1c（後方互換リファクタ）着手の判断。
```

---

## 5. セルフチェックリスト（コミット前に必ず全項目確認）

- [ ] §2 の前提確認をすべて満たした
- [ ] `bridge/` 配下のファイルを一切変更していない（`git diff bridge/` で確認）
- [ ] `docs/BRIDGE_API_IMPROVEMENTS.md` が新規作成され、6項目すべてに5評価軸の記述がある
- [ ] 各 IMP-* の優先度判定根拠が§4.2 の判定基準に従っている（主観表現なし）
- [ ] 影響範囲の grep 結果が具体的な行番号付きで記載されている
- [ ] §4「v1.1 採用候補サマリ」と §5「保留・却下候補サマリ」の合計件数が6件と一致
- [ ] §6「実機テスト依存項目」が記述されている
- [ ] `docs/BRIDGE_API.md` §9 冒頭に IMPROVEMENTS.md への参照行が追加されている
- [ ] `docs/DESIGN.md`、`README.md`、`CHANGELOG.md`、開発日記が更新されている
- [ ] `git diff --stat` で変更ファイル数が**6ファイル**（`docs/BRIDGE_API_IMPROVEMENTS.md` 新規 + `docs/BRIDGE_API.md` / `docs/DESIGN.md` / `README.md` / `CHANGELOG.md` / `docs/2026-05-04_開発日記.md` の5ファイル更新）であること

---

## 6. コミット手順

```bash
git status
# jp-UnderworldBounty/ 配下のみがステージ対象であることを目視確認

git add jp-UnderworldBounty/docs/BRIDGE_API_IMPROVEMENTS.md
git add jp-UnderworldBounty/docs/BRIDGE_API.md
git add jp-UnderworldBounty/docs/DESIGN.md
git add jp-UnderworldBounty/README.md
git add jp-UnderworldBounty/CHANGELOG.md
git add jp-UnderworldBounty/docs/2026-05-04_開発日記.md

git diff --cached --stat
# 6ファイル、bridge/ 配下が一切含まれないことを確認

git commit -m "docs(jp-UnderworldBounty): add BRIDGE_API_IMPROVEMENTS with priority and effort matrix"
git push origin main
```

`git add .` や `git add -A` は使わない。ファイル単位で明示的にステージする。

---

## 7. 完了報告フォーマット

```markdown
## PHASE 1b 完了報告

### 1. 改善候補一覧
| 識別子 | カテゴリ | 優先度 | 対応方針 | 工数 | v1.1 |
|---|---|---|---|---|---|
| IMP-N1 | 命名 | P? | ? | ? | ? |
| IMP-A1 | 非対称 | P? | ? | ? | ? |
| IMP-A2 | 非対称 | P? | ? | ? | ? |
| IMP-A3 | 非対称 | P? | ? | ? | ? |
| IMP-D1 | ドキュメント | P? | ? | ? | ? |
| IMP-D2 | ドキュメント | P? | ? | ? | ? |

### 2. 採用候補サマリ
- v1.1 採用: N件
- 保留: M件
- 却下: K件
- 合計採用工数: 約X時間（XS×?, S×?, M×?, L×?）

### 3. 実機テスト依存項目との関連
- Qbox 依存: 関連 IMP-* または「直接の関連なし」
- AddItem 戻り値契約: 関連 IMP-* または「直接の関連なし」

### 4. ドキュメント更新
- 新規: docs/BRIDGE_API_IMPROVEMENTS.md
- 更新: docs/BRIDGE_API.md §9 冒頭、docs/DESIGN.md、README.md、CHANGELOG.md、開発日記

### 5. Git
- コミットハッシュ: xxxxxxx
- 変更ファイル数: 6
- bridge/ 配下の変更: なし（git diff bridge/ で確認済み）
- `git diff HEAD~1 --stat` 出力:
  ```
  （ここに stat を貼る）
  ```

### 6. 残課題・次アクション提案
- 実機テスト指示書作成の要否
- PHASE 1c（後方互換リファクタ）着手の判断材料
- その他気づき
```

---

## 8. 不明点・例外発生時の報告フォーマット

作業を中断し、以下の形式で報告する。

```markdown
## PHASE 1b 中断報告

### 発生事象
（何が想定と違ったか、1〜3行）

### 該当ファイル・行
（grep 結果や git status 出力など）

### 想定との差異
- 想定: （指示書の記述）
- 実態: （観察結果）

### 提案
- A案: （対応案1）
- B案: （対応案2）

### 判断を仰ぐ事項
（ユーザーに確認したい1〜2点）
```

中断条件の例:

- §2 の前提確認で1項目でも NG
- BRIDGE_API.md §9 の改善候補数が6件でない
- `docs/BRIDGE_API_IMPROVEMENTS.md` が既に存在する
- 影響範囲の grep で予期しない大量ヒット（50件以上）
- 優先度判定基準で複数の P レベルに該当し判断不能
- bridge/ 配下を変更する必要があると判断される状況

---

## 9. 関連ドキュメント

- `docs/INSTRUCTIONS_PHASE_1A.md`（PHASE 1a 本体・完了済み）
- `docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md`（PHASE 1a フォローアップ・完了済み）
- `docs/BRIDGE_API.md`（評価対象の §9 を含む）
- `docs/DESIGN.md`
- `CHANGELOG.md`

---

## 10. .cursorrules への一時優先指定

PHASE 1b 着手時に `.cursorrules` の優先指定セクションへ以下の1行を追加すること。完了報告後、§11 の手順で削除する。

```
- PHASE 1b 作業中: `docs/INSTRUCTIONS_PHASE_1B.md` を最優先で参照する。
```

---

## 11. PHASE 1b 完了後のクリーンアップ

完了報告後、以下を別コミットで実施する。

```bash
# .cursorrules から PHASE 1b 優先指定行を削除
grep -E "INSTRUCTIONS_PHASE_1B" .cursorrules
# ヒット行を削除

git add jp-UnderworldBounty/.cursorrules
git commit -m "chore(jp-UnderworldBounty): remove PHASE 1b priority directive after completion"
git push origin main
```

`.cursorrules` クリーンアップは PHASE 1b 本体コミットと**分離**する（本体の差分を読みやすく保つため）。

---

## 12. 改訂履歴

- 2026-05-04 v1.1: §5 セルフチェックの変更ファイル数を5→6に修正（§6 コミット手順との整合）。
- 2026-05-04 v1.0: 初版作成。

---

## 13. Cursor への投げ方（コピー用）

```
@docs/INSTRUCTIONS_PHASE_1B.md に従って作業してください。§2 の前提確認結果を最初に報告し、OK の場合のみ本作業へ進んでください。不明点があれば §8 のフォーマットで報告してください。完了したら §7 のフォーマットで完了報告をしてください。
```
