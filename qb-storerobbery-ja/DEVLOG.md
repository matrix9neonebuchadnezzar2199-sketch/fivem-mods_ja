# 開発日記 (DEVLOG)

qb-storerobbery-ja の開発記録。日本語化＆バグ修正の進捗、調査メモ、判断理由などを残します。

---

## 2026-05-03

### 調査・特定
- ユーザ報告のバグ「店外で配電盤を壊すギミックがある強盗MOD」は **5Crime Gabz Store Robbery**（有料・escrow暗号化）と特定。改変不可のため対象外に。
- 代替として QBCore 公式 `qb-storerobbery`（GPL-3.0）をフォークする方針に決定。

### フォーク作成
- 本家: https://github.com/qbcore-framework/qb-storerobbery (Copyright © 2021 Joshua Eger)
- ローカル作業ディレクトリ: `H:\CURSOR\Dev\qb-storerobbery-ja`
- ライセンス: GNU GPL-3.0（派生物も同ライセンスで公開）

### 完了した作業
- `fxmanifest.lua` 更新（author追記、version `1.2.0-ja.1`、repository URL追加）
- `locales/ja.lua` 新規作成（`setr qb_locale "ja"` で有効化）
- `CHANGELOG.md` 作成
- `git init` + 初期コミット完了

### バグ原因の特定
**「1件目強盗後に2件目が開始できない、再起動で直る」バグの根本原因**

`server/main.lua` のクールダウン解除通知ループで:
```lua
toSend[#toSend + 1] = Config.Registers[k]  -- 配列形式で送信
```
クライアントがこれをIDキーとして扱うため、配列インデックス（1, 2…）でクライアントの `Config.Registers` が上書きされ破壊。サーバ再起動でクライアント側が再読込されるため一時復活していた。

副次原因:
- `currentRegister` / `currentSafe` がキャンセル時リセットされず次回ID参照ズレ
- `copsCalled` フラグのリセット漏れ
- `SetTimeout` ベースのクールダウンがサーバ再起動で消失

### コミットプラン確定
1. ✅ ja locale追加
2. ✅ fxmanifest更新
3. ✅ register cooldown同期バグ修正（`pairs`化＋IDキー化）← **連続強盗バグの本丸**
4. ✅ register cooldownのKVP永続化
5. ✅ safe cooldownのKVP永続化
6. ✅ safeコード周期再生成バグ修正
7. ✅ copsCalled / currentRegister 状態リセット統一化

ブランチ `fix/cooldown-persistence` に上記修正を積み、`CHANGELOG.md` を更新済み。

### 対応店舗の確認
`config.lua` から、対応はレジ32箇所＋金庫19箇所と確定。レジ・金庫は独立クールダウンで、同店舗のレジ→金庫連続強盗も可能（10%でコードメモ入手）。

### 競合バグ：`currentRegister` リセット競合（コミット da23d10）

**症状（推測含む）**: 強盗成功直後にプレイヤーがサーバから exploit abuse で kick される、または2件目強盗で `currentRegister` がズレる。

**原因**: `LockpickDoorAnim` 内の独立スレッドが `currentRegister = 0` をセットするタイミングと、Progressbar Done コールバックが `takeMoney(currentRegister, true)` を呼ぶタイミングが競合し、最終 `takeMoney` が `currentRegister == 0` で送信される可能性があった。

**修正**: success コールバックで `local registerId = currentRegister` に退避し、`setRegisterStatus` と `takeMoney` 双方で `registerId` を使用。Done 内でさらに `ResetRobberyState()` を追加して `copsCalled` / `currentRegister` / `currentSafe` を確実に初期化。

**本家PR優先度**: 高（潜在的な exploit kick 問題）

### インベントリ抽象化（コミット 323919d ほか）

#### 経緯
本家 `qb-storerobbery` は `exports['qb-inventory']:AddItem` を直接呼ぶため、`ox_inventory` のみのサーバではエクスポート不存在で報酬・削除が動かない。国内サーバでは ox が事実上の標準のため対応を必須と判断。

#### 設計
`server/bridge/inventory.lua` に抽象化レイヤーを追加。

- `AddItemCompat(src, item, count, info, reason)` — ox / qb / qs に振り分け（qb のみ `reason` を利用）
- `RemoveItemCompat(src, item, count, reason)`
- `NotifyItemAdded(src, itemName)` / `NotifyItemRemoved(src, itemName)` — **qb-inventory の ItemBox のみ**（ox はインベントリ側の通知に任せる）

`detectInventory()` は **`CreateThread` の単発判定ではなく**、上記関数の**初回呼び出し時**に `GetResourceState` で ox → qb → qs を決定。プレイヤーが強盗する時点では通常どれも `started` 済みのため、**server.cfg の ensure 順への依存は相対的に低い**（それでも `ensure ox_inventory` を先に書くのは推奨）。

#### 影響
- ox_inventory 主体のサーバで報酬・ロックピック削除が動作しうる状態に
- qb-inventory・qs-inventory のパスも維持

#### 注意点（ox）
- `markedbills` / `stickynote` は **ox の `data/items.lua` に定義が必要**。未定義時は `invalid_item` で失敗 → 以降のコミットでサーバログに失敗理由を出力、`optional/ox_inventory_items_snippet.lua` にコピー用定義を配置。
- `worth` や stickynote の `label` はメタデータとして渡す既存仕様のまま。

#### 本家PR優先度
最高（環境によっては実質プレイ不能の解消）

### 次回作業
- ゲーム内での通しテスト（連続強盗・KVP復元・sticky note コードの有効性など）← **A案（進行中）**
- 本家向け PR 用にコミットを cherry-pick / ブランチ整理
- `README.md`・本ログの追記・公開リポジトリへの push

### 通しテスト（A案）

#### Cursor / 開発マシンで実施した確認（2026-05-03）
- `fxmanifest.lua` が参照する `config.lua`, `client/main.lua`, `server/main.lua`, `html/index.html`, `html/script.js`, `html/style.css`, `html/reset.css`, `locales/*.lua` の存在を確認（問題なし）
- PATH 上に Lua 5.4 / `luac` が無く、ローカルでの構文コンパイルは未実施（`.github/workflows/lint.yml` の fivem-lua-lint はリモート push / PR で実行）

#### ゲーム内チェックリスト（ローカル txAdmin / FiveM で実施）

サーバコンソール: `refresh` → `ensure qb-storerobbery-ja` → F8 でクライアント、`qb-storerobbery` 関連のサーバエラーなしを確認。

`config.lua` は **shared_script** のため、変更後は **`restart qb-storerobbery-ja`（または `refresh; ensure …`）に加え、クライアントは `/disconnect` → 再接続**すると確実。

道具・ジョブはサーバの admin / inventory に合わせて調整（例: `lockpick`, `advancedlockpick`。`/giveitem` の有無は `qb-inventory` / `ox_inventory` 等で異なる）。

##### テスト用設定（戻し忘れ注意）

| 項目 | テスト（リポジトリ反映値） | 本番（推奨） |
|------|---------------------------|--------------|
| `Config.MinimumStoreRobberyPolice` | 0 | 2 |
| `Config.resetTime` | 1分 | 30分 `(60 * 1000) * 30` |
| `server/main.lua` 金庫クールダウン | `math.random(40, 80)` 分（現状コードのまま） | 同上。短縮検証する場合のみ一時的に 1〜2 分へ |

1. **レジ連続強盗**: サーバ起動 → レジ1を強盗完了 → クールダウン中表示 → （`Config.resetTime` は現状 1 分）解除後、同じレジ1を再強盗できること。
2. **別レジの座標**: クールダウン解除直後にレジ2を強盗し、正しい位置・報酬対象で進むこと（クライアント `Config.Registers` が破壊されていないこと）。
3. **非連続レジ ID**: `config.lua` からレジ `[3]` を削除して飛び番にした状態で再起動 → レジ1強盗 → 解除まで進むこと（`ipairs` 起因の取りこぼしが無いこと）。
4. **金庫 KVP**: 金庫を強盗成功 → サーバまたはリソース再起動 → 当該金庫がクールダウン（robbed）のまま維持され、残り時間経過後に解除されること。
5. **sticky note とコード**: レジからメモ取得後、30分以上経過しても（40分グローバル再生成が無いため）当該金庫のコードが無効化されないこと。金庫クールダウン終了後はその金庫だけコードが更新されること。
6. **状態リセット**: ロックピック失敗・exit・キーパッド閉じる・暗証失敗・プログレスバーキャンセル後、別レジで強盗開始し **警察通報が再度飛ぶ** こと（`copsCalled` / `currentRegister` のズレなし）。

結果欄（手書きメモ用）:
| # | OK / NG | メモ |
|---|---------|------|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |
| 6 | | |

問題なければリモートへ `push` → PR 用ブランチで upstream 合わせの rebase を検討（履歴整理はバグ再発時にやり直すことになるため、テスト完了後が無難）。

### 作業総括・変更ログ（セッション記録）

以下、本フォークで実施した作業を **ファイル／テーマ別**に一覧化する（詳細は上記各節および `CHANGELOG.md`）。

#### ブランチ・履歴
- 作業ブランチ: `fix/cooldown-persistence`（`master` / import コミット `e33fbf2` から累積）
- ベース: QBCore 公式 `qb-storerobbery` v1.2.0 相当をフォークし日本語化・バグ修正・インベントリ対応まで拡張

#### メタデータ・ロケール
| 内容 | ファイル |
|------|----------|
| author / version `1.2.0-ja.1` / repository | `fxmanifest.lua` |
| 日本語ロケール（`qb_locale` が `ja` のときのみ） | `locales/ja.lua` |
| 変更履歴 | `CHANGELOG.md` |

#### サーバー `server/main.lua`
| テーマ | 内容 |
|--------|------|
| レジ同期バグ | `ipairs`→`pairs`、解除通知を `{[registerId]=data}` で送信 |
| レジ KVP | `SetRegisterCooldownEnd`、tick 終了時 `ClearRegisterCooldown`、`setRegisterStatus` に距離検証 |
| 金庫 KVP | `SetSafeCooldownEnd`、起動時復元スレッド、`setSafeStatus` に距離検証 |
| 金庫コード | 40分一括再生成を廃止、`GenerateSafeCode` / 起動時生成 / クールダウン終了時のみ該当 ID 再生成 |
| `takeMoney` | 無効レジ ID の早期 `return`（`Config.Registers[0]` nil クラッシュ防止） |
| インベントリ | 直接 `qb-inventory` 呼び出しをやめ、`server/bridge/inventory.lua` 経由 |

#### サーバー `server/bridge/inventory.lua`
| 内容 |
|------|
| ox_inventory / qb-inventory / qs-inventory を初回 `AddItemCompat` 等で自動検出 |
| ox 向け空メタ `{}`、失敗時サーバログ（例: `invalid_item`） |
| qb のみ ItemBox（`NotifyItemAdded` / `NotifyItemRemoved`） |

#### オプション・ドキュメント
| ファイル | 用途 |
|----------|------|
| `optional/ox_inventory_items_snippet.lua` | ox の `markedbills` / `stickynote` 定義コピー用・画像パスメモ |
| `README.md` | バグ説明、対応店舗、動作要件、インベントリ、`DEVLOG` リンク |

#### クライアント `client/main.lua`
| テーマ | 内容 |
|--------|------|
| 状態リセット | `ResetRobberyState()`（fail / exit / PadLockClose / キーパッド誤り / プログレスキャンセル） |
| NUI フォーカス | `fail`/`exit` で `SetNuiFocus(false,false)`、Backspace 緊急脱出スレッド |
| 競合対策 | `success` で `registerId` をローカル保持、`Done` で `takeMoney(registerId,true)` と `ResetRobberyState()` |
| アニメ競合 | `LockpickDoorAnim` 内の中間 `takeMoney` を `registerId` で送信（`currentRegister==0` のレース回避） |

#### NUI `html/script.js`
| 内容 |
|------|
| `outOfPins`: `#wrap` の `fadeOut`、`numPins` リセット |
| 全 NUI POST を `GetParentResourceName()` ベースの URL に変更（リソースフォルダ名変更対応） |

#### 設定 `config.lua`（テスト用・要本番戻し）
| 項目 | 備考 |
|------|------|
| `MinimumStoreRobberyPolice = 0` | 本番推奨 2 |
| `resetTime` 1分 | 本番 30分 |

#### Git コミットログ（新しい順・抜粋）
```
a71a246 docs: DEVLOG inventory bridge; richer ox item snippet; clarify lazy detect
f9be8e9 fix(bridge): ox AddItem empty metadata + failure log; add ox item snippet
40a8fd5 fix: guard takeMoney invalid register; LockpickDoorAnim uses captured registerId
65181b3 docs: inventory systems (ox/qb/qs) and CHANGELOG entry
323919d feat(server): inventory bridge for ox_inventory, qb-inventory, qs-inventory
c9bc485 docs: document currentRegister race fix for upstream PR (DEVLOG)
da23d10 fix(client): reset robbery state after register robbery completes
e6d01be fix(nui): use GetParentResourceName for NUI POST URLs
83f0e8f fix(nui): close lockpick UI on fail and reset pin count
b7cb3cc fix(client): release NUI focus on lockpick fail/exit; Backspace escape hatch
…（以降は register/safe KVP、レジ同期修正、import・初期コミットまで `git log` 参照）
```

#### 残タスク・運用メモ
- ゲーム内 **通しテスト** の結果を上記チェック表に記入
- **ox_inventory**: `markedbills` / `stickynote` を items に登録（snippet 参照）
- **本番**へ `config.lua` を戻す（DEVLOG のテスト用設定表）
- 本家 PR 向けに履歴整理（rebase）する場合はテスト完了後が無難

---
