# Changelog

本ファイルは GNU GPL-3.0 §5(a) に基づき、改変の日付・改変者・改変内容を記録します。

形式は [Keep a Changelog](https://keepachangelog.com/) に準拠します。

---

## [1.0.1-ja1.1] - 2026-05-25

### Fixed

- **C-1**: `client/main.lua` の `setCanRagdoll` 関数内タイポ `statefalse` を `state, false` に修正。釣り開始時の native 呼び出しエラーを解消。
- **C-2**: `client/main.lua` の `lunar_fishing:itemUsed` callback でゾーン参照を `Config.fishingZones[currentZone]` から `Config.fishingZones[currentZone.index]` に修正。深海域・沼地の `waitTime` 設定が正しく適用されるようになった。
- **C-3**: `client/main.lua` の zone `onEnter` における比較式 `currentZone?.locationIndex == index` を `currentZone?.locationIndex == locationIndex` に修正。同一ゾーン内の地点切替判定の不具合を解消。
- **A-2**: `server/ped.lua` の `lunar_fishing:sellFish` callback で nil チェックを price 計算より前に移動。不正な `fishName` 渡された際のサーバーエラーを防止。
- **A-4**: `server/rent.lua` の `lunar_fishing:rentVehicle` callback に `boat` の nil チェックを追加。範囲外 `index` でのサーバーエラーを防止。
- **C-5**: `config/cl_edit.lua` の `SetVehicleFuel` で `ox_fuel` 状態チェックを `GetResourceState('ox_fuel') == 'started'` に統一。ox_fuel 未導入環境での意図しない state 書き込みを防止。

### Changed

- **E-2**: `fxmanifest.lua` から不要な `'locales/*.lua'` 参照を削除。locales ディレクトリは JSON のみで運用されているため。

### Notes

- C-1〜C-5 は上流 `Lunar-Scripts/lunar_fishing` v1.0.1 から継承されたバグ。upstream への報告予定。
- E-2 は本派生プロジェクト固有の整理。
- 詳細なコードレビューは内部実施（L2 標準レベル、20 ファイル確認）。

---

## [1.0.1-ja1] - 2026-05-24

### Modified by
matrix9neonebuchadnezzar2199-sketch
（https://github.com/matrix9neonebuchadnezzar2199-sketch）

### Based on
Lunar-Scripts/lunar_fishing v1.0.1
（https://github.com/Lunar-Scripts/lunar_fishing）

### Added
- 日本語ロケールファイル `locales/ja.json`（UI 文字列 42 キー全て翻訳）
- インベントリ用アイテム定義 `install/items_ox_ja.lua`（ox_inventory 向け）
- インベントリ用アイテム定義 `install/items_qb_ja.lua`（QBCore 向け）
- 日本語インストールガイド `docs/INSTALL_JA.md`
- 画像生成プロンプト集 `docs/IMAGE_PROMPTS.md`
- 開発作業指示書 `docs/WORK_INSTRUCTIONS.md`
- プロジェクト README（日本語）
- 改変履歴ファイル（本ファイル）
- 原作者クレジットファイル `CREDITS.md`

### Changed
- `config/config.lua` の魚種を日本魚 10 種へ置換
  （イワシ／アジ／サバ／マダイ／ヒラメ／ウナギ／ブリ／カツオ／クロマグロ／リュウグウノツカイ）
- `config/config.lua` のゾーン名・NPC 名・通知メッセージを日本語化
  （サンゴ礁／深海域／沼地／シートレード商会／ボートレンタル）
- `fxmanifest.lua` の `version` を `'1.0.1'` から `'1.0.1-ja1'` に変更
- `fxmanifest.lua` の `description` に "(Japanese Localization)" を追記

### Preserved
- ベース MOD のすべてのゲームロジックコード（client/server/framework/utils）
- 元のロケールファイル `locales/en.json` / `locales/de.json`
- 元のライセンス `LICENSE`（GNU GPL-3.0）
- 元のゾーン座標・出現確率・スキルチェック難易度の数値バランス

### Added (2026-05-25)
- AI 生成魚アイコン画像 15 枚（`assets/fish_images/`，Stable Diffusion / CC0 1.0）
- 画像ライセンス文書 `assets/fish_images/LICENSE_IMAGES.md`
- 予備アイコン退避 `assets/fish_images/extras/`（salmon.png, cod.png）

---

## [Original 1.0.1] - Lunar Scripts

ベース MOD のオリジナルバージョン。
詳細は https://github.com/Lunar-Scripts/lunar_fishing/releases を参照。
