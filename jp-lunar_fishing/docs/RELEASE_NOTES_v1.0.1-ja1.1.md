# jp-lunar_fishing v1.0.1-ja1.1

[v1.0.1-ja1](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/releases/tag/v1.0.1-ja1) のパッチリリース。内部コードレビュー（L2 標準）に基づく 7 件のバグ修正です。

## 修正内容

### バグ修正（上流 lunar_fishing v1.0.1 から継承）

- **C-1**: `client/main.lua` の `setCanRagdoll` 関数内タイポ `statefalse` を修正。釣り開始時の native 呼び出しエラーを解消。
- **C-2**: 深海域・沼地の `waitTime` 設定が反映されないバグを修正。`Config.fishingZones[currentZone.index]` で正しくゾーンを参照するように変更。
- **C-3**: ゾーン `onEnter` の `locationIndex` 比較ミスを修正。同一ゾーン内の地点切替判定が正常化。
- **A-2**: `sellFish` callback の nil チェック順序を修正。不正な魚名渡された際のサーバーエラーを防止。
- **A-4**: `rentVehicle` callback に `boat` の nil チェックを追加。範囲外 `index` でのサーバーエラーを防止。
- **C-5**: `ox_fuel` の状態チェックを `== 'started'` で統一。ox_fuel 未導入環境での意図しない動作を防止。

### 整理（本派生固有）

- **E-2**: `fxmanifest.lua` から不要な `'locales/*.lua'` 参照を削除。

## アップグレード方法

1. 既存の `lunar_fishing/` リソースを ZIP の内容で上書き。
2. サーバー再起動（または `refresh && restart lunar_fishing`）。
3. 設定ファイル（`config/config.lua`, `config/sv_config.lua`）はカスタマイズ済みの場合は差分マージ推奨。本リリースで `config/` 配下の変更はないため、既存設定をそのまま流用可能。

## 既知の問題

以下は本リリースでは対応していません。Phase 2 で対応予定です。

- **A-1**: 釣り成功判定がクライアント権威。RP サーバーで本格運用する場合は anti-cheat 併用を推奨。
- **C-4**: QBCore + qb-inventory 環境でのインベントリ上限チェックが未実装。
- **E-1**: NPC インタラクションが `qtarget` 固定（README で ox_target 対応と記載しているが、実装は qtarget のみ）。ox_target 環境では qtarget 互換 export が必要。

## ライセンス

- コード: GPL-3.0（継承）
- 画像: CC0 1.0

## クレジット

- 原作: [Lunar Scripts](https://github.com/Lunar-Scripts/lunar_fishing)
- 日本語化・コードレビュー: [matrix9neonebuchadnezzar2199-sketch](https://github.com/matrix9neonebuchadnezzar2199-sketch)

## リンク

- [日本語化リポジトリ](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja)
- [原作リポジトリ](https://github.com/Lunar-Scripts/lunar_fishing)
- [前バージョン v1.0.1-ja1](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/releases/tag/v1.0.1-ja1)
