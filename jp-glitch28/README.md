# jp-glitch28 — Glitch Minigames 日本語版

> 元リソース: [Gl1tchStudios/glitch-minigames](https://github.com/Gl1tchStudios/glitch-minigames) v2.1.1  
> ライセンス: GPL-3.0（本日本語化版も同ライセンスを継承）

FiveM 向けの **28種類以上のミニゲーム集** を日本語化したものです。スキルチェック、ハッキング、メモリゲーム、リズム、ロックピックなど、ロールプレイ・強盗・整備など多用途に使えるミニゲームを単一のエクスポート呼び出しで起動できます。

## リポジトリ上のパスと本番名

- **開発用フォルダ名**: `jp-glitch28`（本モノレポ内のディレクトリ名）
- **サーバー配置時**: フォルダ全体を **`glitch-minigames` にリネーム**して `resources/` 配下へ置いてください。他リソースが `exports['glitch-minigames']` で参照するためです。

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

> **リソース名は `glitch-minigames` のまま使用してください。** フォルダ名を変えると `exports['glitch-minigames']` との整合が取れなくなります。

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

## 日本語化担当

[@eiho_tsukuyomi](https://x.com/eiho_tsukuyomi)

不具合報告・改善提案は GitHub Issues または X（Twitter）へ。
