# INSTRUCTIONS_PHASE_1A_FOLLOWUP

PHASE 1a フォローアップ作業指示書（Cursor 自走用・完全版）

- 最終更新: 2026-05-04
- 対象リポジトリ: `fivem-mods_ja/jp-UnderworldBounty/`
- 想定所要時間: 30〜60分
- 前提指示書: `docs/INSTRUCTIONS_PHASE_1A.md`（PHASE 1a 本体・完了済み）

---

## 1. 目的

`docs/BRIDGE_API.md` の残り「要確認」マーカー2件を確定または「要実機確認」へ分類し、未使用関数 `Bridge.RemoveMoney` / `Bridge.RemoveItem` に中立的な保留コメントを追加する。あわせて開発日記と CHANGELOG を更新する。

実装ロジックは変更しない。コメント追加とドキュメント更新のみ。

---

## 2. 作業前の前提確認（必ず最初に実施し、結果を報告してから本作業へ進む）

以下を順に確認し、§9 のフォーマットで結果を報告すること。すべて OK でなければ本作業に進まない。

1. カレントディレクトリが `fivem-mods_ja/jp-UnderworldBounty/` 配下であること。
2. `git status` で **`jp-UnderworldBounty/` 配下に未コミット変更がないこと**。他プロジェクト（jp-losmon, jp-tcgbook 等）の未コミット変更は無視してよい。
3. ブランチが `main` であること。
4. 以下のファイルが存在すること:
   - `bridge/_init.lua`
   - `bridge/sv_bridge.lua`
   - `bridge/cl_bridge.lua`
   - `docs/BRIDGE_API.md`
   - `docs/2026-05-04_開発日記.md`
   - `CHANGELOG.md`
5. `docs/BRIDGE_API.md` 内の「要確認」マーカー数を grep で数え、**2件**であること。3件以上または0件なら中断し §9 で報告。

---

## 3. 禁止事項

- `bridge/sv_bridge.lua` および `bridge/cl_bridge.lua` の**ロジック変更**（コメント追加のみ可）。
- `bridge/_init.lua` の変更（フレームワーク検出ロジックは触らない）。
- `fxmanifest.lua` の変更。
- 公式ドキュメント（ESX/QBCore/Qbox）への参照による仕様確定。**コード観察のみで判断**し、確定不能なら「要実機確認」へ倒す。
- `git checkout -- .`（モノレポ全体に影響するため禁止。`git checkout -- jp-UnderworldBounty/` を使う）。
- `git tag` の付与。
- `BRIDGE_API.md` への環境情報（導入リソース一覧等）の記載。環境情報は**開発日記のみ**に記録する。
- PHASE 1a フォローアップで対象外の改善候補（命名統一、非対称解消等）のコード反映。

---

## 4. タスク

### 4.1 Qbox 依存確認

#### grep 対象

`bridge/` 配下の全 `.lua` ファイルに対し、以下4パターンを検索する:

```
qb-core
qbx_core
qbx-core
GetCoreObject
```

具体的には:

```bash
grep -rn -E "qb-core|qbx_core|qbx-core|GetCoreObject" bridge/
```

#### 判定基準

| 検出パターン | 分類 | BRIDGE_API.md への反映 |
|---|---|---|
| `qb-core` のみ呼び出し、`qbx_core` 系なし | パターンA: Qbox 互換性問題あり | 「Qbox 環境では `qb-core` 不在のため動作不可。要実機確認」 |
| `qbx_core` または `qbx-core` を直接参照 | パターンB: Qbox ネイティブ対応済み | 「Qbox ネイティブ対応済み」マーカー削除 |
| `GetCoreObject` のみで qb/qbx 区別なし | パターンC: 抽象化されており判定不能 | 「要実機確認」マーカー維持 |

#### 反映先

`docs/BRIDGE_API.md` 第9章（改善候補）の Qbox 依存項目を上記分類に従って書き換える。

### 4.2 AddItem 戻り値契約確認

#### 調査範囲

`bridge/sv_bridge.lua` 内の `Bridge.AddItem` 関数定義のみ。フレームワーク側のソースは読まない。

#### 判定基準

各フレームワーク分岐（ESX / QBCore / Qbox / Standalone）で以下を確認:

- `return` 文の有無
- 返している値の型（boolean / nil / その他）

すべての分岐で `return` 文が存在し、型が一致 → 「契約確定」。
分岐ごとに `return` の有無や型が異なる → 「非対称あり」として §9 に追記。
コード観察だけでは型が判定できない（フレームワーク関数の戻り値に依存） → 「要実機確認」マーカー維持。

#### 反映先

`docs/BRIDGE_API.md` の `Bridge.AddItem` セクションに「戻り値契約」サブ項目を追加し、上記表を埋める。

### 4.3 未使用関数への保留コメント追加

#### 対象

`bridge/sv_bridge.lua` の以下2関数:

- `Bridge.RemoveMoney`
- `Bridge.RemoveItem`

#### 物理フォーマット（厳守）

各関数定義行の**直前に空行を1行確保**し、その上に以下のコメントブロックを配置する。コメントブロックと関数定義行の間に空行を入れない。コメントブロックは `--` 行で**4行以内**。既存の関数内コメントや既存の関数定義行は変更しない。

```lua
-- [予約 API] v1.0.0 時点では server/*.lua から未参照。
-- 想定用途: 強盗失敗時の罰金、報復NPCへの賄賂支払い等の将来機能。
-- v1.1 で再評価予定。それまで実装は維持する。
function Bridge.RemoveMoney(source, typ, amount)
```

`Bridge.RemoveItem` も同形式で追加する（用途記述は適切に変える）。

#### 検証

`git diff bridge/sv_bridge.lua` で、追加行が**コメントと空行のみ**であり、既存行の削除・改変が一切ないことを確認。違反していたら自分で巻き戻し、再実施。

### 4.4 BRIDGE_API.md §9 整理

「未使用コード」項目を以下の通り変更:

- 見出し: `### 9.4 未使用コード` → `### 9.4 v1.1 再評価対象（保留扱い）`
- 内容: 「`Bridge.RemoveMoney` / `Bridge.RemoveItem` は v1.0.0 時点で未参照だが、想定用途（罰金、賄賂等）のため v1.1 で再評価予定。それまで実装を維持する」

ロードマップ確定的な表現（「v1.1 で必ず削除」「v1.1 で削除予定」等）は**使わない**。中立的な「再評価」「保留」表現に統一する。

### 4.5 開発日記更新

`docs/2026-05-04_開発日記.md` に以下のセクションを追記する:

```markdown
## PHASE 1a フォローアップ実施

### 環境メモ（参考情報。BRIDGE_API.md には載せない）
- フレームワーク: Qbox（qbx_core 使用、qb-core 不在）
- 主要リソース: ox_inventory, ox_lib, ox_target, oxmysql, illenium-appearance
- 備考: ox_inventory は Bridge から未参照（v1.0.0 時点）

### BRIDGE_API.md 確定内容
- Qbox 依存: （4.1 の判定結果を1〜3行で記述）
- AddItem 戻り値契約: （4.2 の判定結果を1〜3行で記述）

### 未使用関数の方針
- `Bridge.RemoveMoney` / `Bridge.RemoveItem` に保留コメント追加。
- §9.4 を「v1.1 再評価対象（保留扱い）」へ分類変更。
- ロードマップに縛らない中立文言で記載。
```

### 4.6 CHANGELOG.md 更新

`[Unreleased]` セクションに以下を追記:

```markdown
### Changed
- `docs/BRIDGE_API.md`: 「要確認」マーカー2件を確定または「要実機確認」へ分類。§9.4 を「v1.1 再評価対象（保留扱い）」へ変更。
- `bridge/sv_bridge.lua`: `Bridge.RemoveMoney` / `Bridge.RemoveItem` に保留コメントを追加（ロジック変更なし）。
```

---

## 5. セルフチェックリスト（コミット前に必ず全項目確認）

- [ ] §2 の前提確認をすべて満たした
- [ ] `bridge/sv_bridge.lua` の変更が**コメント追加と空行のみ**である（`git diff bridge/sv_bridge.lua` で確認）
- [ ] `bridge/sv_bridge.lua` の追加行数が **8行以下**である（`git diff --stat bridge/sv_bridge.lua` で確認。超過したら中断・報告）
- [ ] `bridge/_init.lua` および `bridge/cl_bridge.lua` を変更していない
- [ ] `BRIDGE_API.md` の「要確認」マーカーが0件、または明示的に「要実機確認」へ書き換え済み
- [ ] §9.4 が中立文言（「再評価」「保留」）で書かれている。「削除予定」等の確定的表現がない
- [ ] 環境情報（ox_inventory 等の導入リソース）は**開発日記のみ**に記載され、`BRIDGE_API.md` には記載していない
- [ ] CHANGELOG `[Unreleased]` の `### Changed` に該当エントリがある
- [ ] 開発日記に PHASE 1a フォローアップセクションが追加されている

---

## 6. .cursorrules クリーンアップ（コミット前に実施）

PHASE 1a フォローアップ完了に伴い、`.cursorrules` から以下の優先指定行を削除する:

- `INSTRUCTIONS_PHASE_1A.md` の優先指定行
- `INSTRUCTIONS_PHASE_1A_FOLLOWUP.md` の優先指定行

削除後、`.cursorrules` に PHASE 1a 系の優先指定が残っていないことを grep で確認:

```bash
grep -E "INSTRUCTIONS_PHASE_1A" .cursorrules
```

ヒットが0件であること。

---

## 7. コミット手順

```bash
git status
# jp-UnderworldBounty/ 配下のみがステージ対象であることを目視確認

git add jp-UnderworldBounty/docs/BRIDGE_API.md
git add jp-UnderworldBounty/bridge/sv_bridge.lua
git add jp-UnderworldBounty/docs/2026-05-04_開発日記.md
git add jp-UnderworldBounty/CHANGELOG.md
git add jp-UnderworldBounty/.cursorrules

git diff --cached --stat
# 5ファイルのみ、sv_bridge.lua の追加行が8行以下であることを確認

git commit -m "docs(jp-UnderworldBounty): finalize BRIDGE_API.md and reserve unused bridge functions for v1.1"
git push origin main
```

タグは付けない。PHASE 1 全体の完了時にまとめて検討する。

モノレポで他プロジェクト変更を巻き込まないよう、`git add .` や `git add -A` は使わない。ファイル単位で明示的にステージする。

---

## 8. 完了報告フォーマット

完了時、以下の形式で報告する。

```markdown
## PHASE 1a フォローアップ 完了報告

### 1. 要確認マーカー確定状況
- Qbox 依存: [パターンA / B / C / 要実機確認]
  - 根拠: （grep 結果の要約、ヒットしたファイル名と行番号）
- AddItem 戻り値契約: [契約確定 / 非対称あり / 要実機確認]
  - 根拠: （各分岐の return 文の有無）

### 2. 未使用関数コメント追加
- `Bridge.RemoveMoney`: 追加行数 X 行
- `Bridge.RemoveItem`: 追加行数 Y 行
- `bridge/sv_bridge.lua` 合計追加行数: Z 行（8行以下）
- ロジック変更: なし（git diff で確認済み）

### 3. ドキュメント更新
- `docs/BRIDGE_API.md`: §9.4 分類変更、要確認マーカー解消
- `docs/2026-05-04_開発日記.md`: PHASE 1a フォローアップセクション追加
- `CHANGELOG.md`: [Unreleased] に Changed エントリ追加

### 4. .cursorrules クリーンアップ
- INSTRUCTIONS_PHASE_1A 系の優先指定行を削除
- grep 確認: ヒット0件

### 5. Git
- コミットハッシュ: xxxxxxx
- 変更ファイル数: 5
- `git diff HEAD~1 --stat` 出力:
  ```
  （ここに stat を貼る）
  ```

### 6. 残課題・次アクション提案
- （あれば記載。なければ「なし」）
```

---

## 9. 不明点・例外発生時の報告フォーマット

作業を中断し、以下の形式で報告する。

```markdown
## PHASE 1a フォローアップ 中断報告

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
- `BRIDGE_API.md` の「要確認」マーカーが2件でない
- `Bridge.RemoveMoney` または `Bridge.RemoveItem` が `sv_bridge.lua` に存在しない
- grep で `qb-core` / `qbx_core` 系が一切ヒットしない
- `sv_bridge.lua` の追加行が8行を超える見込み
- コメント以外の変更が必要と判断される状況

---

## 10. 関連ドキュメント

- `docs/INSTRUCTIONS_PHASE_1A.md`（PHASE 1a 本体・完了済み）
- `docs/BRIDGE_API.md`（本フォローアップの主要更新対象）
- `docs/DESIGN.md`
- `docs/RETALIATION_FSM.md`

---

## 11. 改訂履歴

- 2026-05-04 v1.1: PATCH 指摘をすべて反映（grep パターン拡張、物理フォーマット明示、`git diff --stat` 必須化、環境情報の記載先明確化、`.cursorrules` クリーンアップ追加、PHASE 1b 範囲の明示は INSTRUCTIONS_PHASE_1B 側に委譲）
- 2026-05-04 v1.0: 初版

---

## 12. Cursor への投げ方（コピー用）

```
@docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md に従って作業してください。§2 の前提確認結果を最初に報告し、OK の場合のみ本作業へ進んでください。
```
