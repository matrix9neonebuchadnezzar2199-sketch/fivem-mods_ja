# jp-glitch28 — Glitch Minigames 日本語版

> 元リソース: [Gl1tchStudios/glitch-minigames](https://github.com/Gl1tchStudios/glitch-minigames) v2.1.1  
> ライセンス: GPL-3.0（本日本語化版も同ライセンスを継承）

FiveM 向けの **28種類以上のミニゲーム集** を日本語化したものです。スキルチェック、ハッキング、メモリゲーム、リズム、ロックピックなど、ロールプレイ・強盗・整備など多用途に使えるミニゲームを単一のエクスポート呼び出しで起動できます。

## リポジトリ上のパスと本番名

- **開発用フォルダ名**: `jp-glitch28`（本モノレポ内のディレクトリ名）
- **このリソース単体**: `jp-glitch28` のまま `ensure jp-glitch28` でも **内部のデバッグコマンド・NUI・同一リソース内の export 連携は動作** します（`GetCurrentResourceName()` / `GetParentResourceName()` で実名を解決）。
- **他リソースから `exports['glitch-minigames']` で呼んでいる場合**: フォルダを **`glitch-minigames` にリネーム**し、`ensure` 名もそれに合わせてください。外部スクリプトは **`exports['server.cfg に書いた名前']`** のリソースを参照するため、名前が一致しないと `No such export` になります。

## 特徴

- **28+ ミニゲーム**: ハッキング・記憶・精度・リズムなど多彩なジャンル
- **簡単な統合**: `exports['glitch-minigames']:Start...()` 一発で起動
- **UIテキストを日本語化**: タイトル・指示文・結果メッセージ（`wordCrack` の英単語リストはゲーム性のため英語のまま）
- **テーマ切替対応**: cyan / monochrome、classic / modern
- **音声フィードバック**: 成功・失敗・操作音を内蔵

## 動作要件

- FiveM Server (cerulean以降)
- Lua 5.4
- フレームワーク非依存（standalone）

## 導入方法

1. 本リポジトリの `jp-glitch28` フォルダをコピーし、**名前を `glitch-minigames` に変更**して `resources/` 配下に配置する
2. `server.cfg` に追加:

   ```
   ensure glitch-minigames
   ```

3. （任意）`shared/config.lua` で `config.ActiveTheme` / `config.ActiveVisualTheme` を変更

> **外部連携**: 既存の強盗スクリプト等が `exports['glitch-minigames']` 固定なら、配置名も `glitch-minigames` にしてください。自作だけなら `exports[GetCurrentResourceName()]` や実際の `ensure` 名（例: `jp-glitch28`）で呼び出せます。

## 既知の制限

一部のミニゲームは GTA V 純正のスケールフォーム（HUD 描画）を使用しており、**エンジンのフォント仕様により日本語非対応の画面**があります。次の **HACKING_PC 系** のラベルやメッセージは **英語のまま** 残しています（空白・豆腐になる事例を避けるため）。

| 表示例 | 意味（参考） |
|---|---|
| `My Computer` / `Power Off` | マイコンピュータ／電源オフ |
| `Local Disk (C:)` 等 | ローカルディスク |
| `BRUTEFORCE SUCCESSFUL!` / `BRUTEFORCE FAILED!` | ブルートフォース成功／失敗 |
| `MEMORY LEAK DETECTED, DEVICE SHUTTING DOWN` 等 | メモリリーク検知・デバイス停止 |

**Circuit Breaker**（`client/circuitBreaker/circuit.lua`）の結果表示は `HACKING_MESSAGE` 系で **日本語化済み** ですが、環境によっては CJK が表示されない場合があります。その場合は当該 `showDisplayScaleform` の引数を英語に戻すか、短いローマ字表記に差し替えてください。

**Data Crack / Brute Force** の PC 画面ラベルは上記のとおり英語据え置きです。Fleeca／Plasma ドリルの操作説明は `glitch-notifications` 経由のため日本語表示が期待できます（当リソース側の `ShowNotification` 文言は日本語化済み）。

## 使い方（基本）

```lua
-- スキルチェックの例
local success = exports['glitch-minigames']:StartSkillCheckGame(
    {'E', 'F', 'R'},  -- 各ラウンドのキー
    65,               -- バー速度（%/秒）
    15000,            -- 制限時間 (ms)
    18,               -- 通常ゾーンの幅 (%)
    5,                -- パーフェクトゾーンの幅 (%)
    1,                -- 失敗許容回数
    true              -- ゾーン位置をランダム化
)

if success then
    -- 成功時の処理
else
    -- 失敗時の処理
end
```

詳細は [`docs/USAGE_JA.md`](docs/USAGE_JA.md) を参照してください。

## 運営向け: 犯罪・強盗RPへの組み込み方

このリソースは **ミニゲームの表示と成否（boolean）だけ** を提供します。金庫が開く・現金が入る・警察に通報される、といった **RP上の結果は、必ず別の自作リソース（強盗スクリプト・ジョブ・ターゲット連携など）側で処理** してください。`exports['glitch-minigames']` の戻り値を **そのまま信用してサーバーで報酬を出すとチートに弱い** ので、クライアントは「プレイした」事実の通知に留め、**報酬・ドア状態・アイテム削除はサーバーで権威を持たせる** 設計を推奨します。

### 典型的な流れ

1. プレイヤーがドア・PC・金庫などに相互作用（`ox_target` / `qb-target` / `E` キー等は運営の既存スクリプトに依存）。
2. **クライアント**で `local ok = exports['glitch-minigames']:Start○○Game(...)` を実行（同期で完了までブロックする動きが基本）。
3. `if ok then` のときだけ `TriggerServerEvent('あなたのリソース:heistMinigamePassed', 金庫ID, 'lockpick')` のように **サーバーへ通知**（イベント名は自分で定義）。
4. **サーバー**で「そのプレイヤーは今その金庫のそばにいるか」「クールダウン中か」「必要アイテムを持っているか」を検証したうえで、ドア開放・ルート状態更新・報酬付与を実行。

ミニゲーム中は NUI やカメラが使われるため、**同時に別のフルスクリーン UI を出さない**・**死亡・リログでキャンセル** される前提でシナリオを組むと安全です。

### 設定・ファイルの見どころ（運営が触る場所）

| 場所 | 何をするか |
|------|------------|
| **`shared/config.lua`** | 全サーバー共通の見た目・挙動。`config.DebugCommands`（本番は `false`）、`config.usingGlitchNotifications`（後述）、テーマ・背景の不透明度。 |
| **`server.cfg`** | `ensure glitch-minigames` と、あなたの強盗リソースの `ensure`。**先に `glitch-minigames` を起動**しておくと export が安定しやすいです。 |
| **自作リソース（推奨）** | 座標・段階・難易度・報酬テーブル。ここで「どの段階でどの `Start...` を呼ぶか」を決める。**難易度の数値は export の引数で調整**（[`docs/USAGE_JA.md`](docs/USAGE_JA.md)・[公式ドキュメント](https://minigames.glitchstudios.dev/)参照）。 |
| **`client/` 配下の直接編集** | 上級者向け。演出文・色の微調整は可能だが、**`exports` 名とリソース名は変えないこと**（他MOD・既存連携が壊れるため）。 |

### シナリオ例とミニゲームの対応（目安）

| RPシチュエーション | 使いやすい export（例） | メモ |
|-------------------|-------------------------|------|
| 扉・手錠・簡易錠前 | `StartLockpickGame` / `StartSkillCheckGame` / `StartBarHitGame` | 短時間で区切りやすい |
| PC・サーバーハッキング（多段階） | `StartFirewallPulse` → `StartBackdoorSequence` → `StartDataCrack` など | 段階を分けるとドラマチック |
| ターミナル風・総当たり | `StartBruteForce` | スケールフォーム内ラベルは英語据え置き（README「既知の制限」） |
| 回路・ブレーカー | `StartCircuitBreaker` | CJK 表示は環境要確認 |
| 金庫ドリル（ Fleeca 系アニメ） | `StartDrilling` | 操作説明は `glitch-notifications` 利用時のみ表示 |
| プラズマ／レーザー風ドリル | `StartPlasmaDrilling` | 同上 |
| 指紋・身分認証 | `StartFingerprintGame` | |
| PIN・暗証 | `StartCodeCrackGame` | |
| 軽い「作業」チェック | `StartWireConnectGame` / `StartPipePressureGame` / `StartHoldZoneGame` | 工場・整備風にも流用可 |

公式のパラメータ一覧・ブラウザ試用は [Glitch Minigames ドキュメント](https://minigames.glitchstudios.dev/) が便利です（英語）。日本語版の引数サンプルは [`docs/USAGE_JA.md`](docs/USAGE_JA.md) にあります。

### コード例（クライアント → サーバー）

```lua
-- 例: 自作リソース client.lua（リソース名は仮）
RegisterNetEvent('my-heist:client:tryVaultLockpick', function(vaultId)
    local ok = exports['glitch-minigames']:StartLockpickGame(3, 28, 2, 40, 500)
    if ok then
        TriggerServerEvent('my-heist:server:vaultLockpickSuccess', vaultId)
    else
        -- 失敗時は通知のみ、報酬はサーバーでは一切触らない
        TriggerServerEvent('my-heist:server:vaultLockpickFailed', vaultId)
    end
end)
```

```lua
-- 例: 自作リソース server.lua（必ず検証すること）
RegisterNetEvent('my-heist:server:vaultLockpickSuccess', function(vaultId)
    local src = source
    if type(vaultId) ~= 'string' then return end
    -- 距離・状態・クールダウン・アイテムの検証をここに書く
    -- 問題なければドア開放や次フェーズへ
end)
```

### glitch-notifications について

Fleeca ドリル・プラズマドリルの **操作説明テキスト** は、`config.usingGlitchNotifications = true` のとき **`glitch-notifications`** の `ShowNotification` で出します。**未導入のサーバーでは `false` にしてください**（エラー回避。ただし操作説明は表示されません）。導入する場合は `server.cfg` で当該リソースを `ensure` し、`glitch-minigames` より前に起動できるようにしておくと安心です。

## デバッグコマンド

`shared/config.lua` で `config.DebugCommands = true` にすると、以下のテストコマンドが有効になります（`/testskillcheck` など、各ミニゲームに対応）。

| コマンド | ミニゲーム |
|---|---|
| `/testfirewall` | ファイアウォール・パルス |
| `/testsequence` | バックドアシーケンス |
| `/testrhythm` | サーキット・リズム |
| `/testsurge` | サージオーバーライド |
| `/testvarhack` | VARハック |
| `/testmemory` | メモリーパターン |
| `/testsequencememory` | シーケンスメモリ |
| `/testverbalmemory` | 言語記憶 |
| `/testnumberedsequence` | 数列記憶 |
| `/testsymbolsearch` | シンボルスキャン |
| `/testpipepressure` | パイプ圧 |
| `/testpairs` | ペアマッチ |
| `/testmemorycolors` | カラーメモリ |
| `/testuntangle` | 線ほどき |
| `/testfingerprint` | 指紋スキャナ |
| `/testcodecrack` | コード解析 |
| `/testwordcrack` | 単語解析 |
| `/testbalance` | バランス |
| `/testaim` | エイムテスト |
| `/testcircleclick` | サークルクリック |
| `/testlockpick` | ロックピック |
| `/testbarhit` | バーヒット |
| `/testskillcheck` | スキルチェック |
| `/testnumberup` | ナンバーアップ |
| `/testcomboinput` | コンボ入力 |
| `/testholdzone` | ホールドゾーン |
| `/testwireconnect` | ワイヤー接続 |
| `/testsimonsays` | シグナル同期 |

## ミニゲーム一覧（28種）

| 英語名 | 日本語表記 | エクスポート |
|---|---|---|
| Firewall Pulse | ファイアウォール・パルス | `StartFirewallPulse` |
| Backdoor Sequence | バックドアシーケンス | `StartBackdoorSequence` |
| Circuit Rhythm | サーキット・リズム | `StartCircuitRhythm` |
| Surge Override | サージオーバーライド | `StartSurgeOverride` |
| Var Hack | VARハック（記憶） | `StartVarHack` |
| Memory | ニューラルパターン | `StartMemoryGame` |
| Sequence Memory | シーケンス記憶 | `StartSequenceMemoryGame` |
| Verbal Memory | 言語記憶 | `StartVerbalMemoryGame` |
| Numbered Sequence | 数列記憶 | `StartNumberedSequenceGame` |
| Symbol Search | シンボルスキャン | `StartSymbolSearchGame` |
| Pipe Pressure | パイプ圧（流路接続） | `StartPipePressureGame` |
| Pairs | ペアマッチ（神経衰弱） | `StartPairsGame` |
| Memory Colors | カラーメモリ | `StartMemoryColorsGame` |
| Untangle | 線ほどき | `StartUntangleGame` |
| Fingerprint | 指紋スキャナ | `StartFingerprintGame` |
| Code Crack | コード解析（PIN） | `StartCodeCrackGame` |
| Word Crack | 単語解析（Wordle系） | `StartWordCrackGame` |
| Balance | バランス | `StartBalanceGame` |
| Aim Test | エイムテスト | `StartAimTestGame` |
| Circle Click | サークルクリック | `StartCircleClickGame` |
| Lockpick | ロックピック | `StartLockpickGame` |
| Bar Hit | バーヒット | `StartBarHitGame` |
| Skill Check | スキルチェック | `StartSkillCheckGame` |
| Number Up | ナンバーアップ | `StartNumberUpGame` |
| Combo Input | コンボ入力 | `StartComboInputGame` |
| Hold Zone | ホールドゾーン | `StartHoldZoneGame` |
| Wire Connect | ワイヤー接続 | `StartWireConnectGame` |
| Simon Says | シグナル同期（サイモン） | `StartSimonSaysGame` |
| + Circuit Breaker / Data Crack / Brute Force / Drilling 系 | 回路遮断・データクラック・総当たり・ドリル | （Lua側） |

## ライセンス

GPL-3.0。元の Gl1tchStudios/glitch-minigames の派生物として、本日本語化版も GPL-3.0 で配布します。

## 謝辞

- 元作者: [Gl1tchStudios](https://github.com/Gl1tchStudios) / Luma
- 各ミニゲームの基礎を提供した utkuali, BerkieBb, TimothyDexter, TransitNode, MxttDev, SezayK の各氏

不具合報告・改善提案は GitHub Issues へ。
