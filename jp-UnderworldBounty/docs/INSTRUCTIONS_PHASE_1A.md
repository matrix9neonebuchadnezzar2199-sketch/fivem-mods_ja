# PHASE 1a 作業指示書: Bridge 層の現状スナップショット化

> **対象 Cursor**: このファイルに従って作業を進めてください。  
> **作業者**: Cursor AI Assistant  
> **レビュー**: 人間（リポジトリオーナー）  
> **想定所要時間**: 2〜4時間  
> **成果物**: `docs/BRIDGE_API.md` v1.0 の新規作成と関連ドキュメント更新  
> **参照優先順位**: `.cursorrules` の Documentation Hierarchy に従う（PHASE 1a 専用に本書を最優先してよい）

---

## 1. 作業の目的

このリポジトリ（jp-UnderworldBounty）は既に v1.0.0 相当まで実装済みだが、**Bridge 層（フレームワーク抽象化レイヤー）の API ドキュメントが不足**している。本作業では、現行コードを観察してそのまま `docs/BRIDGE_API.md` に**スナップショット**として記録する。

**重要原則**: 本作業では実装コードを一切変更しない。観察と記録のみ。改善案は別セクションに「候補」として列挙するが、実装変更は PHASE 1c 以降で行う。

---

## 2. 作業前の前提確認

開始前に以下を確認すること。確認できなければ作業を中断し、ユーザーに報告する。

**第一に**、リソースルート（`jp-UnderworldBounty/`）にいること。モノレポ `fivem-mods_ja` で作業する場合は **`jp-UnderworldBounty` サブフォルダ**をルートとしてパスを解釈する。`fxmanifest.lua` `.cursorrules` `README.md` `CHANGELOG.md` が存在すること。

**第二に**、`bridge/` に `_init.lua` `sv_bridge.lua` `cl_bridge.lua` が存在すること。ファイル名が異なる場合（例: `bridge.lua` 単一ファイル）は、その時点でユーザーに報告して指示を仰ぐ。

**第三に**、既存の `docs/BRIDGE_API.md` が**存在しないこと**を確認する。存在する場合は、上書きせず `docs/BRIDGE_API.md.backup` にリネームしてから作業を始める。

**第四に**、現在の git ブランチが `main` であること、未コミットの変更がないことを確認する。`git status` でクリーンな状態であること（ユーザーが意図したローカル変更のみ許容する場合は、その旨を完了報告に記載）。

---

## 3. 観察フェーズ（実装コード読み取り）

### 3.1 読むべきファイル

以下を順に読む。

**第一順位**: `bridge/_init.lua`、`bridge/sv_bridge.lua`、`bridge/cl_bridge.lua`。これらが Bridge 層の正本コード。

**第二順位**: `config/config.lua`（フレームワーク選択フラグ）、`fxmanifest.lua`（Bridge ファイルのロード順序）。

**第三順位**: リポジトリ全体を grep。`Bridge\.`、`exports\[.*bridge`（該当時）、Bridge 専用の独自イベント名（あれば）。

### 3.2 抽出すべき情報

各 Bridge 関数について以下を記録する。

関数名、定義場所（ファイル・おおよその行番号）、引数シグネチャ（型推測）、戻り値、対応フレームワーク（ESX / QBCore / Qbox / Standalone）、内部で呼ぶ FW 固有 API、呼び出し元ファイル、副作用の有無。

### 3.3 観察の注意点

**第一に**、推測ではなく**コードに書いてある通り**を記録する。不明確な場合は「**要確認**」マーカーを付ける。

**第二に**、フレームワーク間で非対称な場合は明記する。

**第三に**、Standalone のスタブ実装パターンも記録する。

---

## 4. ドキュメント作成フェーズ

### 4.1 出力ファイル

`docs/BRIDGE_API.md` を新規作成する。文字コード UTF-8、改行 LF、BOM なし。

### 4.2 ドキュメントの章構成

第 1 章「本書の目的とスコープ」、第 2 章「Bridge 層の概要」、第 3 章「初期化とフレームワーク検出」、第 4 章「サーバーサイド API（sv_bridge.lua）」、第 5 章「クライアントサイド API（cl_bridge.lua）」、第 6 章「共有 API（_init.lua および両側）」、第 7 章「フレームワーク対応マトリクス」、第 8 章「呼び出し元マップ」、第 9 章「改善候補（v1.1 検討対象）」、第 10 章「関連ドキュメント」、第 11 章「改訂履歴」。

### 4.3 文体規約

`.cursorrules` に準拠。見出しは `##` `###`。表は Markdown table。コードフェンスは `lua`。日本語と英数字の間に半角スペースを入れる（例: 「Bridge 層の API」）。

---

## 5. 各章のテンプレート

### 5.1 第 1 章 テンプレート

```markdown
# Bridge API リファレンス（v1.0.0 スナップショット）

> **ファイル**: `docs/BRIDGE_API.md`  
> **対象バージョン**: v1.0.0（YYYY-MM-DD 時点のスナップショット）  
> **目的**: Bridge 層の現行 API を実装観察ベースで記録し、将来の差分追跡基盤とする  
> **関連**: `docs/DESIGN.md` §6、`docs/SEQUENCE_DIAGRAMS.md`、`bridge/_init.lua` ほか  
> **最終更新**: YYYY-MM-DD

## 1. 本書の目的とスコープ

（観察に基づき記述）
```

### 5.2 第 2 章 テンプレート

Bridge 層の責務、抽象化の意図、現行ファイル構成（`_init.lua` + `sv_bridge.lua` + `cl_bridge.lua`）を 1〜2 段落で説明する。`DESIGN.md` §6 の方針との対応を明記する。

### 5.3 第 3 章 テンプレート

`bridge/_init.lua` の動作（検出ロジック、`Bridge` 初期化、ロード順序、未検出時の挙動）。重要部分は **10 行以内** のコード引用でよい。

### 5.4 第 4〜6 章（API リファレンス本体）

各 API を次のフォーマットで記述する。

```markdown
### Bridge.関数名

**シグネチャ**: `Bridge.関数名(...) -> 戻り値`

**説明**: （観察ベース）

**引数**:
- `name` (type): ...

**戻り値**: ...

**フレームワーク別実装**:
| FW | 内部呼び出し | 備考 |
|---|---|---|
| ESX | ... | ... |
| ... | ... | ... |

**呼び出し元**: `path:line`（grep 結果）

**副作用**: あり / なし（観察）

**定義**: `bridge/sv_bridge.lua` または `cl_bridge.lua`（行番号）
```

### 5.5 第 7 章（フレームワーク対応マトリクス）

全 API を行、FW を列とした表。セルは `○` `×` `△`（部分実装）。

### 5.6 第 8 章（呼び出し元マップ）

ファイル単位で「使用している Bridge API」を一覧にする逆引き表。

### 5.7 第 9 章（改善候補）

観察で気付いた点を**候補のみ**列挙。実装変更はしない。サブ見出し例: 命名、非対称、ドキュメント不足、重複・未使用。

### 5.8 第 10〜11 章

関連ドキュメントへのリンク表、改訂履歴（初版のみでよい）。

---

## 6. 関連ドキュメントの更新

`docs/BRIDGE_API.md` 作成後、以下を更新する。

- `docs/DESIGN.md` の §6（フレームワーク抽象化）に、「現行 API のリファレンスは `docs/BRIDGE_API.md`」の 1 行を追加。
- `README.md` のドキュメント表に `BRIDGE_API.md` を追加。**位置**: `EVENT_HOOKS.md` の直後、`CONFIG_GUIDE.md` の直前。説明:「Bridge 層の API リファレンス（フレームワーク抽象化のスナップショット）」。
- `CHANGELOG.md` の `[Unreleased]` の `### Added` に「`docs/BRIDGE_API.md` — v1.0.0 時点の Bridge 層 API スナップショット」を追加。
- **開発日記**: 当日の `docs/YYYY-MM-DD_開発日記.md` の末尾に「追記」。例: `docs/2026-05-04_開発日記.md`。本作業の概要・所要時間・気付きを 3〜5 行で記録。

---

## 7. 作業の進め方（推奨手順）

1. **観察と下書き**: 3 ファイルを読み、§3.2 の項目をメモ。  
2. **grep**: `Bridge\.` で呼び出し元を洗い出し、§8 用に整理。  
3. **文書化**: §5 に従い `docs/BRIDGE_API.md` を章順に執筆。  
4. **関連更新**: §6 を実施。  
5. **セルフチェック**: §9 のチェックリスト。  
6. **コミット**: §10。

---

## 8. 「要確認」マーカーの扱い

確定できない箇所には例として次を残す。

```markdown
> **要確認**: （内容）
```

grep で一覧できるよう文言は「**要確認**」で統一。

---

## 9. セルフチェックリスト

- `docs/BRIDGE_API.md` が新規作成され、第 1〜11 章が埋まっている。  
- 全 Bridge API が §5.4 形式で記されている。  
- 第 7 章マトリクス・第 8 章呼び出し元マップがある。  
- 第 9 章は候補のみで、実装変更と混同しない。  
- `DESIGN.md` `README.md` `CHANGELOG.md` 日記が更新されている。  
- UTF-8（BOM なし）、LF、表とフェンスが妥当。  
- 実装にない API を捏造していない。推測は「要確認」に寄せた。

---

## 10. コミット手順

```bash
git status
```

期待される変更（例）:

- `new file: docs/BRIDGE_API.md`
- `modified: docs/DESIGN.md` `README.md` `CHANGELOG.md` `docs/YYYY-MM-DD_開発日記.md`

**モノレポ**でルートが `fivem-mods_ja` のときはパスに `jp-UnderworldBounty/` を付ける。

`docs/` が親 `.gitignore` で除外されている場合:

```bash
git add -f jp-UnderworldBounty/docs/BRIDGE_API.md
git add -f jp-UnderworldBounty/docs/YYYY-MM-DD_開発日記.md
# ほか modified ファイルも同様に必要なら -f
```

```bash
git commit -m "docs(jp-UnderworldBounty): add BRIDGE_API.md as v1.0.0 snapshot

PHASE 1a deliverable: snapshot the current Bridge layer API as a reference
for future refactoring (PHASE 1c+) and v1.1 planning.

Contents:
- Initialization and framework detection behavior
- Server-side and client-side API references with signatures
- Framework support matrix (ESX/QBCore/Qbox/Standalone)
- Caller map (which files use which Bridge APIs)
- Improvement candidates listed for v1.1 consideration

Cross-links added to DESIGN.md, README.md, CHANGELOG.md, and the
development log.

This commit makes no functional code changes."

git push origin main
```

タグは付けない（PHASE 1 全体完了まで保留）。

---

## 11. 完了報告のフォーマット

作業完了後、ユーザーへ次の形式で報告する。

```
## PHASE 1a 完了報告

### 作成・更新したファイル
- 新規: docs/BRIDGE_API.md (XXX 行、XX 個の API を記録)
- 更新: docs/DESIGN.md (§6 に相互参照追加)
- 更新: README.md (ドキュメント表に追加)
- 更新: CHANGELOG.md ([Unreleased] に追記)
- 更新: docs/YYYY-MM-DD_開発日記.md

### 観察した API 数
- Server-side: XX 個
- Client-side: XX 個
- Shared: XX 個
- 合計: XX 個

### フレームワーク対応状況サマリ
（簡潔に）

### 「要確認」マーカーの数
- XX 箇所

### 改善候補として列挙した項目数
（カテゴリ別）

### Git
- コミット: （ハッシュまたはメッセージ）
- プッシュ済み (main)

### 次のアクション提案
- (a) 「要確認」を人間レビューで確定
- (b) PHASE 1b（改善候補の評価）
- (c) PHASE 1a 追補（使用例の追加など）
```

---

## 12. 禁止事項（重要）

以下は本作業では行わない。

- `bridge/*.lua` `server/*.lua` `client/*.lua` `config/*.lua` の**実装変更**。  
- `fxmanifest.lua`・`LICENSE` の変更。  
- 新規 Bridge API の追加（観察・記録のみ）。  
- `git tag`、force push、履歴書き換え rebase。  
- `.gitignore` 対象（秘匿情報など）の誤コミット。

---

## 13. 不明点・例外発生時の対応

想定と異なる構成、API 数の異常、`docs/BRIDGE_API.md` が既に大量に存在する、重大なバグ発見などは**中断してユーザーに報告**。判断肢 (a)(b) と推奨を提示する。

---

## 14. 関連ドキュメント

- `.cursorrules`  
- `docs/DESIGN.md` §6  
- `docs/RETALIATION_FSM.md`  
- `docs/SEQUENCE_DIAGRAMS.md`

---

## 15. 改訂履歴（本指示書）

| 日付 | 版 | 変更内容 |
|------|-----|----------|
| 2026-05-04 | v1.0 | 初版（PHASE 1a 用作業指示書）。日記ファイルは `YYYY-MM-DD` 運用に合わせて記載 |

---

## Cursor への投げ方（ユーザー向け補足）

`docs/INSTRUCTIONS_PHASE_1A.md` を保存したうえで、チャットで例えば次のように指示する。

```
@docs/INSTRUCTIONS_PHASE_1A.md に従って PHASE 1a を実施してください。

進める前に「§2 作業前の前提確認」をすべてチェックし、結果を報告してから本作業に入ってください。
不明点があれば §13 のフォーマットで報告してください。
完了したら §11 のフォーマットで完了報告をしてください。
```

`@docs/INSTRUCTIONS_PHASE_1A.md` でファイルをコンテキストに載せると取り込みやすい。

実装変更を伴う判断は §12 に抵触しないか確認する。誤ってコードが変わった場合は `git checkout -- <file>` で戻せる。

---

## 16. レビュー時の注意

「要確認」マーカーが残った箇所は、人間が実装・実機で確認して確定させる。完了報告後、問題なければ PHASE 1b など次タスクへ進む。
