# Changelog

本フォークは [qbcore-framework/qb-storerobbery](https://github.com/qbcore-framework/qb-storerobbery) の派生物です。
原著作権: Copyright (C) 2021 Joshua Eger / Kakarot
ライセンス: GNU General Public License v3.0

## [1.2.0-ja.1] - 2026-XX-XX

### Added
- 日本語ロケールファイル `locales/ja.lua` を追加
- `server/bridge/inventory.lua` による **ox_inventory / qb-inventory / qs-inventory** 互換（自動検出）
- `optional/ox_inventory_items_snippet.lua`（ox 向け `markedbills` / `stickynote` 定義のコピー用）

### Added (予定)
- README.md の日本語版

### Fixed
- ox_inventory で `AddItem` がメタデータ nil や未定義アイテムで失敗しても分かりにくかった問題を改善（空メタテーブル利用・失敗理由をサーバログへ）
- `takeMoney` が無効なレジ ID（例: `0`）で呼ばれたときサーバが nil 参照で落ちる問題を修正
  （中間取得で `currentRegister` が既に 0 の競合への耐性）
- レジクールダウン解除時にクライアント側 Config.Registers が破壊され、
  再強盗できなくなる致命バグを修正（連続強盗不可・要再起動症状の主因）
- レジクールダウンを KVP で永続化し、サーバー再起動を跨いで保持
- 金庫クールダウンを KVP で永続化し、サーバー再起動を跨いで保持
- 40分ごとに全金庫コードが強制リセットされ、進行中の強盗が
  妨げられるバグを修正（強奪後の該当金庫のみ再生成するよう変更）
- ロックピック失敗・キャンセル時に currentRegister/currentSafe/
  copsCalled がリセットされず、次回強盗が誤動作するバグを修正
- ロックピック失敗時に NUI が閉じずフォーカスが残る問題を修正
  （`html/script.js` の `outOfPins()` で UI を閉じ、`numPins` を初期化）
- NUI の `$.post` URL を `GetParentResourceName()` ベースに変更し、
  リソース名を `qb-storerobbery-ja` 等に変更してもコールバックが届くように修正
- レジ強盗のプログレスバー完了時に `ResetRobberyState()` を呼び、
  `copsCalled` 等が次回ロックピックまで残らないように修正（`registerId` をローカル保持して確実に `takeMoney` へ渡す）

### Security
- setRegisterStatus / setSafeStatus に座標距離検証を追加
  （イベントスプーフィング対策）

### Changed
- fxmanifest.lua のメタデータを派生版用に更新
