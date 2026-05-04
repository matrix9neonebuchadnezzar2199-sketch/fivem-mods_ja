# INSTRUCTIONS_PHASE_1A_LIVE_TEST

PHASE 1a 実機テスト手順書（手動実施・完全版）

- 最終更新: 2026-05-04
- バージョン: v1.2
- 対象リポジトリ: `fivem-mods_ja/jp-UnderworldBounty/`
- 想定所要時間: 60〜90分（環境準備込み）
- 実施者: ユーザー（手動）
- Cursor 担当: 結果記録ファイルの整形のみ
- 前提指示書: `docs/INSTRUCTIONS_PHASE_1A.md`、`docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md`、`docs/INSTRUCTIONS_PHASE_1B.md`（すべて完了済み）

---

## 1. 目的

PHASE 1a / フォローアップで「要実機確認」マーカーが残った2項目、および PHASE 1b で v1.1 採用確定した IMP-A3 / IMP-D2 を実機で確定させる。テスト結果は `docs/BRIDGE_API_LIVE_TEST_RESULTS.md` に記録し、PHASE 1c（リファクタ）の入力とする。

実装コードは一切変更しない。観察と記録のみ。

---

## 2. テスト対象項目

| 項目ID | 内容 | 関連 IMP-* | 関連設計書 |
|---|---|---|---|
| LT-1 | Qbox 環境（qb-core 不在）で `exports['qb-core']:GetCoreObject()` が成功するか | IMP-A3 | BRIDGE_API.md §4 |
| LT-2 | `Bridge.AddItem` の各分岐で実際の戻り値の型と意味 | IMP-D2 | BRIDGE_API.md §4 |
| LT-3 | `Bridge.GetCopCount` が `qbx_core` 環境で正しい人数を返すか | （フォローアップ要確認分） | BRIDGE_API.md §4 |
| LT-4 | 強盗トリガーゾーン進入から報復NPCスポーンまでの全フローが動作するか | （統合動作確認） | PLAYER_FLOW.md |

LT-1〜LT-3 は Bridge 層単体テスト。LT-4 は統合テスト。

---

## 3. 実機環境前提

| 項目 | 内容 |
|---|---|
| OS | Windows（開発機） |
| サーバ起動方法 | txAdmin |
| フレームワーク | Qbox（qbx_core）のみ起動。qb-core 不在 |
| データベース | MariaDB（oxmysql 経由） |
| プレイヤー | テスト実施者1名のみ |
| クライアント | FiveM（同一マシン推奨） |

---

## 4. 環境準備（テスト実施前に1回だけ実施）

### 4.1 リソース動作確認

サーバ起動ログで以下を確認:

- `Started resource jp-UnderworldBounty` が出ている
- エラーログ（`SCRIPT ERROR`、`Error loading script`）が `jp-UnderworldBounty` に対して出ていない

エラーが出ている場合は、テスト中断し §10 形式で報告。

### 4.2 短縮Configの作成

実機テスト用に時間設定を短縮する。**バックアップを取った上で** 以下を実施。

```bash
cd H:\CURSOR\Dev\jp-UnderworldBounty
copy config\config.lua config\config.lua.bak
copy config\retaliation.lua config\retaliation.lua.bak
```

`config/config.lua` の以下を一時変更（テスト後に元に戻す）:

```lua
Config.Debug = true                    -- 元: false
Config.LocationCooldownSec = 10        -- 元: 120
Config.BountyScanIntervalMs = 5000     -- 元: 30000
Config.PoliceDispatchEnabled = false   -- そのまま
Config.MinOnDutyCops = 0               -- そのまま
```

`config/retaliation.lua` の各パターン内（grep 結果から確定済みのキー名を使用）:

```lua
duration_sec = 300                     -- 元: 7200（default は2h → 5min 目安）
max_strikes = 1                        -- default は 2。テスト短縮のため 1 にしてもよい
strike_interval_min_sec = 30           -- 元: default 90（`light` パターンは 60）
strike_interval_max_sec = 60           -- 元: default 180（`light` パターンは 120）
clear_bounty_on_player_death = true    -- テスト容易性のため
```

`pre_warning_sec` キーは v1.0.0 実装に存在しないため**設定しない**（設計上は RETALIATION_FSM.md §5 に記述があるが、実装ギャップ）。

変更後、サーバを `restart jp-UnderworldBounty` でリロード。エラーログが出ないことを確認。

### 4.3 テストキャラクター準備

ゲーム内 F8 コンソールで以下を実行:

```
/setjob unemployed 0
```

または qbx_core の管理コマンドで現在のキャラクターを `unemployed` に設定。`Config.BlacklistedJobs` に該当しないことを確認。

所持金を十分に確保（強盗失敗時の罰金等に備える）。`/giveitem` または `/addmoney` で現金を 100,000 程度。

---

## 5. テスト手順

### 5.1 LT-1: Qbox 環境での GetCoreObject 動作確認

**目的**: `bridge/sv_bridge.lua` L24 の `exports['qb-core']:GetCoreObject()` が、qb-core 不在の Qbox 環境で何を返すか観察する。

**手順**:

1. サーバコンソールでサーバ起動ログを確認。`jp-UnderworldBounty` 起動時に Qbox 検出が走るはず。
2. F8 コンソールで以下を実行:

   ```
   /jpub_debug_bridge_check
   ```

   このコマンドが存在しない場合は手順3に進む。

3. ゲーム内でキャラクターを操作し、`config/locations.lua` に定義された強盗ロケーションのトリガーゾーン座標へ移動。
4. ゾーン進入時のサーバコンソール出力を観察。

**期待されるログパターン（3パターンのいずれか）**:

| パターン | ログ内容 | LT-1 結果 |
|---|---|---|
| α | エラーなく強盗開始可能 | qb-core 不要、qbx_core で互換動作 |
| β | `attempt to index a nil value (field '?')` 等のエラーが GetCoreObject 行で発生 | qb-core 必須、Qbox単体では動作不能 |
| γ | エラーは出ないが、その後の処理（GetPlayerData 等）で失敗 | GetCoreObject は通るが Player API が異なる |

**記録項目**: 観察したパターン（α/β/γ）、サーバコンソール出力の関連行（最大10行）、エラー発生箇所（ファイル:行）。

### 5.2 LT-2: AddItem 戻り値契約の確認

**目的**: `Bridge.AddItem` を Qbox 経由で呼び出した際の戻り値の型と意味を確定する。

**手順**:

1. デバッグコマンド `ub_test`（サーバコンソール）または `/ub_test`（ゲーム内）を実行可能なら使用する。詳細は §16 実装メモを参照。
2. デバッグコマンドで AddItem を直接呼べない場合、強盗成功フローを完了させて `server/rewards.lua` 経由で `Bridge.AddItem` が呼ばれる場面を作る:
   a. LT-1 と同じ手順で強盗ロケーションに進入
   b. 強盗を完了（金庫ハックミニゲーム→退出ゾーン到達）
   c. 報酬付与時のサーバログで `AddItem` 呼び出しと戻り値を観察
3. `server/rewards.lua` には現状 Debug 分岐のログが**実装されていない**ため、戻り値を直接観察するには一時的に `print()` を追加する必要がある。追加する場合は:
   - 追加位置: `Bridge.AddItem` 呼び出し直後の1行のみ
   - フォーマット例: `print(('[ub-livetest] AddItem ret=%s type=%s'):format(tostring(ret), type(ret)))`
   - **テスト終了後に必ず削除**し、コミットしないこと（`git diff server/rewards.lua` で確認）
   - 削除確認は §7.4 環境復元時に併せて実施

**記録項目**:

- AddItem 呼び出し時の引数（item, count）
- 戻り値の型（boolean / nil / number / table）
- 戻り値の値
- インベントリへの実反映（追加された / されなかった）
- ox_inventory 経由か qbx_core 経由かの判別

### 5.3 LT-3: GetCopCount の動作確認

**目的**: `Bridge.GetCopCount` が qbx_core 環境で正しいオンデューティ警官数を返すか確認。

**手順**:

1. ゲーム内 F8 コンソールで現在のキャラクター職業を確認:

   ```
   /myjob
   ```

   （qbx_core のコマンド名と異なる場合は適宜読み替え）

2. テストキャラクターを `unemployed` に設定し、警官数 = 0 を期待。
3. F8 コンソールまたはサーバコンソールで `Bridge.GetCopCount()` の結果を出力するデバッグコマンドを実行（存在しない場合は強盗トリガーゾーン進入時の `Config.MinOnDutyCops` チェックログから推測）。
4. キャラクターを警察職に変更:

   ```
   /setjob police 0
   ```

5. 再度 GetCopCount を呼び、値が 1 に増えるか観察。
6. テスト終了後、`unemployed` に戻す。

**記録項目**:

- unemployed 時の GetCopCount 戻り値
- police 時の GetCopCount 戻り値
- 戻り値の型（number / nil / その他）
- `Config.PoliceJobs` に `police` が含まれているか確認

### 5.4 LT-4: 強盗→報復統合フロー

**目的**: トリガーゾーン進入から報復NPCスポーン・撃退・指名手配解除までの全フローが動作するか確認。

**手順（理想フロー）**:

1. 強盗ロケーション（`config/locations.lua` の最初のエントリ）座標へ移動
2. トリガーゾーン進入。期待: 強盗開始通知
3. シナリオ進行（NPC配置、ミニゲーム、ボス制圧、金庫ハック）
4. 退出ゾーン到達。期待: 報酬付与＋指名手配開始通知
5. 短縮Configの `strike_interval_min_sec/max_sec` (30〜60秒) 経過後、報復NPCスポーン通知
6. 報復NPC到着、戦闘
7. 報復NPC全滅。期待: 指名手配解除通知
8. `duration_sec` (300秒) 経過確認。期待: 自然解除通知（ただし手順7で1ストライク消費済みなら既に解除）

**各ステップで失敗が発生した場合**:

失敗ステップ番号、エラーログ、観察したFSM状態（DEBUG ログから読み取り可能なら）を記録。失敗時点でテスト中断してよい。

**記録項目**:

- 各ステップ（1〜8）の成功/失敗
- 失敗ステップのエラーログ
- 報酬の実反映（金額、アイテム）
- 指名手配HUDの表示有無
- 報復NPC のモデル・人数（`config/retaliation.lua` の `ped_models` と一致するか）

---

## 6. テスト実施中の禁止事項

- 実装コードの変更（`bridge/`、`server/`、`client/`、`shared/`）。観察のみ。
- `print()` 追加した場合、テスト終了後に必ず削除し、コミットしない。
- バックアップ（`*.bak`）を取らずに `config/` 変更しない。
- 他プレイヤーが接続している環境での実施（テスト実施者1名のみ前提）。
- 結果記録ファイルへの主観的評価の混入。観察事実のみ記述。
- 実機テスト中の git commit / push（テスト中はコミット禁止）。
- データベースの直接編集（oxmysql 経由のスクリプト動作のみ観察）。

---

## 7. 結果記録

### 7.1 結果ファイル作成

テスト完了後、以下を Cursor に依頼して `docs/BRIDGE_API_LIVE_TEST_RESULTS.md` を作成する。

Cursor への依頼文（コピー用）:

```
@docs/INSTRUCTIONS_PHASE_1A_LIVE_TEST.md §7 に従い、以下のテスト結果をもとに docs/BRIDGE_API_LIVE_TEST_RESULTS.md を新規作成してください。テスト本文は実施済みです。

[ここに LT-1〜LT-4 の観察結果を貼り付け]

完了したら §8 のフォーマットで完了報告をお願いします。
```

### 7.2 結果ファイルの構造

`docs/BRIDGE_API_LIVE_TEST_RESULTS.md`:

```markdown
# BRIDGE_API 実機テスト結果

- 最終更新: 2026-05-04
- バージョン: v1.0
- 実施環境: Qbox（qbx_core のみ、qb-core 不在）、ローカル開発機、テスター1名
- 実施者: （ユーザー名または匿名）
- 関連: docs/INSTRUCTIONS_PHASE_1A_LIVE_TEST.md, docs/BRIDGE_API.md, docs/BRIDGE_API_IMPROVEMENTS.md

## 1. テスト概要

（実施日時、所要時間、結果サマリ）

## 2. LT-1: Qbox 環境での GetCoreObject 動作確認

- 結果: [α / β / γ]
- 観察ログ:
  ```
  （関連ログ最大10行）
  ```
- 結論: （1〜3行）
- 関連 IMP-A3 への影響: （リファクタ方針が確定するか）

## 3. LT-2: AddItem 戻り値契約

- 引数: item=?, count=?
- 戻り値の型: ?
- 戻り値の値: ?
- インベントリ反映: ?
- 経由: ox_inventory / qbx_core
- 結論: （1〜3行）
- 関連 IMP-D2 への影響: （ドキュメント記述が確定するか）

## 4. LT-3: GetCopCount

- unemployed 時: ?
- police 時: ?
- 戻り値の型: ?
- 結論: （1〜3行）

## 5. LT-4: 強盗→報復統合フロー

| ステップ | 成功/失敗 | 備考 |
|---|---|---|
| 1. 移動 | ? | |
| 2. ゾーン進入 | ? | |
| 3. シナリオ進行 | ? | |
| 4. 退出ゾーン | ? | |
| 5. 報復スポーン | ? | |
| 6. 戦闘 | ? | |
| 7. NPC全滅 | ? | |
| 8. 自然解除 | ? | |

- 失敗ステップのエラーログ: （あれば）
- 報酬実反映: （金額、アイテム）
- 指名手配HUD: （表示/非表示）
- 報復NPC モデル: （`ped_models` との一致確認）

## 6. PHASE 1c への入力

- IMP-A3 リファクタ方針の確定度: 高/中/低
- IMP-D2 ドキュメント記述の確定度: 高/中/低
- 追加発見された問題: （あれば箇条書き）

## 7. 改訂履歴

- 2026-05-04 v1.0: 初版作成。
```

### 7.3 関連ドキュメント更新

Cursor が以下を併せて更新:

- `docs/BRIDGE_API.md`: 「要実機確認」マーカー2件を、結果に応じて「v1.1 で IMP-A3 として対応」「v1.1 で IMP-D2 として対応」等に書き換え。
- `docs/BRIDGE_API_IMPROVEMENTS.md`: IMP-A3 と IMP-D2 の「優先度判定根拠」「対応方針」を実機結果で更新。
- `CHANGELOG.md` `[Unreleased]` `### Added`: `docs/BRIDGE_API_LIVE_TEST_RESULTS.md` の追加を記載。
- `docs/2026-05-04_開発日記.md`: PHASE 1a 実機テスト実施記録を追記。

### 7.4 環境復元（テスト後の必須作業）

```bash
cd H:\CURSOR\Dev\jp-UnderworldBounty
copy config\config.lua.bak config\config.lua /Y
copy config\retaliation.lua.bak config\retaliation.lua /Y
del config\config.lua.bak
del config\retaliation.lua.bak
```

サーバを `restart jp-UnderworldBounty` でリロードし、本番設定に戻ったことを確認。

`config/` に `*.bak` が残っていないことを `git status` で確認。

---

## 8. 完了報告フォーマット

Cursor に貼り付けてもらう完了報告は以下:

```markdown
## PHASE 1a 実機テスト 完了報告

### 1. 結果ファイル作成
- 新規: docs/BRIDGE_API_LIVE_TEST_RESULTS.md（v1.0）

### 2. テスト結果サマリ
| 項目 | 結果 |
|---|---|
| LT-1 (GetCoreObject) | α / β / γ |
| LT-2 (AddItem 戻り値) | 確定 / 部分確定 / 未確定 |
| LT-3 (GetCopCount) | 確定 / 未確定 |
| LT-4 (統合フロー) | 全成功 / 部分成功 / 失敗 |

### 3. PHASE 1c への入力
- IMP-A3 確定度: 高/中/低
- IMP-D2 確定度: 高/中/低
- 追加発見: （あれば）

### 4. ドキュメント更新
- 新規: docs/BRIDGE_API_LIVE_TEST_RESULTS.md
- 更新: docs/BRIDGE_API.md（要実機確認マーカー解消）、docs/BRIDGE_API_IMPROVEMENTS.md（IMP-A3/D2 更新）、CHANGELOG.md、開発日記

### 5. 環境復元
- config/config.lua: 復元済み
- config/retaliation.lua: 復元済み
- *.bak ファイル: 削除済み
- git status: jp-UnderworldBounty/ 配下に config/ の差分なし

### 6. Git
- コミットハッシュ: xxxxxxx
- 変更ファイル数: 5（config/* は変更なし）
- bridge/ 配下の変更: なし
- `git diff HEAD~1 --stat`:
  ```
  （ここに stat を貼る）
  ```

### 7. 残課題・次アクション提案
- PHASE 1c 着手可否
- 設計ドキュメントギャップ（情報屋未実装、PRE_WARNING未実装）の扱い
```

---

## 9. テスト中断・例外発生時の報告フォーマット

```markdown
## PHASE 1a 実機テスト 中断報告

### 発生事象
（何が想定と違ったか、1〜3行）

### 発生ステップ
LT-? のステップ ?

### サーバ/クライアントログ
```
（関連ログ最大20行）
```

### 環境状態
- config/*.bak: 残存 / 削除済み
- 短縮Config: 復元済み / 未復元
- jp-UnderworldBounty: 起動中 / 停止

### 提案
- A案: （対応案1）
- B案: （対応案2）

### 判断を仰ぐ事項
（ユーザーに確認したい1〜2点）
```

中断条件の例:

- §4.1 のリソース起動確認で `jp-UnderworldBounty` がエラー
- LT-1 で β または γ パターンが確定し、かつ後続テストが続行不能
- 短縮Config の反映が効いていない（時間が短縮されない）
- 環境復元前に Cursor が config/ を編集してしまった

---

## 10. 設計ドキュメントギャップの扱い（PHASE 1a 実機テスト範囲外）

実機テスト中に以下のギャップが判明している（PHASE 1b 報告時点で確定）。**本テストの範囲外**だが、テスト後の別タスクで対応する。

| ギャップ | 設計記述 | 実装状態 | 対応タスク |
|---|---|---|---|
| 情報屋NPC | PLAYER_FLOW.md #1〜#4 | 未実装 | 別途 INSTRUCTIONS_PHASE_DOC_SYNC.md |
| PRE_WARNING状態 | RETALIATION_FSM.md §5, §6.1 | 未実装 | 同上 |

実機テスト結果記録時にこれらをドキュメント側にTODOマーカーとして追記してよい（v1.1 実装候補として）。ただし、設計ドキュメント本文の大規模修正は別タスクで実施する。

---

## 11. 関連ドキュメント

- `docs/INSTRUCTIONS_PHASE_1A.md`（PHASE 1a 本体・完了済み）
- `docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md`（PHASE 1a フォローアップ・完了済み）
- `docs/INSTRUCTIONS_PHASE_1B.md`（PHASE 1b・完了済み）
- `docs/BRIDGE_API.md`（要実機確認マーカー2件）
- `docs/BRIDGE_API_IMPROVEMENTS.md`（IMP-A3, IMP-D2）
- `docs/RETALIATION_FSM.md`（LT-4 統合フロー参照）
- `docs/PLAYER_FLOW.md`（LT-4 統合フロー参照）

---

## 12. .cursorrules への一時優先指定

実機テスト結果記録作業時に `.cursorrules` の優先指定セクションへ以下の1行を追加。完了報告後、§13 の手順で削除する。

```
- PHASE 1a 実機テスト結果記録作業中: `docs/INSTRUCTIONS_PHASE_1A_LIVE_TEST.md` を最優先で参照する。
```

---

## 13. 完了後のクリーンアップ

完了報告後、別コミットで以下を実施:

```bash
grep -E "INSTRUCTIONS_PHASE_1A_LIVE_TEST" .cursorrules
# ヒット行を削除

git add jp-UnderworldBounty/.cursorrules
git commit -m "chore(jp-UnderworldBounty): remove PHASE 1a live test priority directive after completion"
git push origin main
```

---

## 14. 改訂履歴

- 2026-05-04 v1.2: §5.2 手順を実装実態（rewards.lua に Debug ログ未実装、SQL手順なし）に合わせて修正。§16.4 補足を追加。
- 2026-05-04 v1.1: §4.2 の「元」注釈を現行 `config/retaliation.lua`（default 90〜180 秒等）に整合。§16 に v1.0.0 実装メモ（`ub_test`、locations 3 件、`/jpub_*` 未登録）を追加。
- 2026-05-04 v1.0: 初版作成。

---

## 15. ユーザーへの実施手順（コピー用）

実機テスト本体は手動実施です。以下の流れで進めてください。

1. 本指示書 §4 に従い環境準備（バックアップ、短縮Config、テストキャラ設定）。
2. §5 の LT-1 から LT-4 を順に実施し、観察結果をテキストで記録（メモ帳・テキストファイル可）。
3. テスト完了後、§7.4 の環境復元を**先に**実施。`*.bak` ファイル削除確認まで。
4. Cursor に §7.1 の依頼文を投げ、結果記録ファイルを作成させる。
5. Cursor が §8 形式で完了報告。
6. §13 のクリーンアップコミットを Cursor に依頼。

---

## 16. 実装メモ（v1.0.0 登録時点・コード観察）

以下は登録時のリポジトリ grep に基づく。**実機手順の代替・補足**として参照する。

| 項目 | 内容 |
|---|---|
| `/jpub_debug_bridge_check`、`/jpub_test_additem` | **`RegisterCommand` としては未定義**。代替: **サーバコンソール**で `ub_test`（先頭 `/` なし、`src==0`）を実行すると `Framework` と `VERSION` が出力される（`server/main.lua:20-24`）。**ゲーム内**では `/ub_test` で `Bridge.GetPlayerData` と **`Bridge.GetCopCount`** の結果が通知される（LT-3 の観察に利用可能）。 |
| `config/locations.lua` のエントリ数 | **3 件**（`loc_training_yard` / `loc_docks_gamblers` / `loc_vinewood_backroom`）。LT-4 で別エントリを使う場合は `id` を指定して記録する。 |
| 職業変更コマンド | `/setjob` は **qbx_core の実コマンド名と異なる場合がある**。運営環境のドキュメントに合わせて読み替えること。 |

### §16.4 §5.2 補足

- **SQL直接挿入手順は本文に記載なし**: §5.2 手順1の「SQL直接挿入に進む」表現は誤り。手順1のデバッグコマンド `ub_test` が使えない場合は、手順2の強盗成功フロー経由で観察するか、運営自身の oxmysql 手順で実施する。本指示書ではSQL手順を提供しない。
- **rewards.lua の Debug ログ未実装**: 現行 `server/rewards.lua` に `Config.Debug` 分岐のログは存在しない。AddItem 戻り値を観察するには一時 `print()` 追加が必須。修正済みの §5.2 手順3 を参照。
- **ub_test コマンドの所在**: `server/main.lua` に登録されており、サーバコンソールでは `ub_test`、ゲーム内 F8 では `/ub_test` で実行可能。引数仕様は実装を直接確認すること。
