# jp-gacha

FiveM 用ガチャポン。マシン付近で **E** キーを押すとフルスクリーン NUI で
カプセル落下 → ヒビ → 割れ → 背景変化 → カットイン（SR 以上）→ 結果表示の流れが再生されます。

## 特徴

- フルスクリーン NUI 演出（N / R / SR / SSR / UR）
- SR 以上はカットイン、SSR/UR は画面揺れ＋星パーティクル
- フレームワーク自動検出（ESX / QBCore）＋ スタンドアロン
- 排出物・重み・座標・演出時間は `config.lua` で調整

## インストール

1. 本フォルダを `resources/[jp-mods]/jp-gacha/` に置く
2. `server.cfg` に `ensure jp-gacha` を追加
3. `config.lua` で `Config.Machines`・`Config.Cost`・`Config.Items` 等を編集
4. 任意: `html/sounds/` に下表の MP3 を入れる（無くても動作する）

## 効果音（任意）

| ファイル名 | 用途 |
|------------|------|
| gacha_roll.mp3 | カプセル落下 |
| crack.mp3 | ヒビ |
| break_open.mp3 | 割れ |
| cutin.mp3 | カットイン |
| result_normal.mp3 | N/R 結果 |
| result_rare.mp3 | SR 以上 結果 |

NUI では再生前に存在確認（`fetch` HEAD 等）を行い、ファイルが無い場合にコンソールエラーを出さないようにしてあります。

## 主な設定（config.lua）

- `Config.Machines` – マシン座標・向き
- `Config.Cost` / `Config.Cooldown` – 1 回の料金（現金）とクールダウン
- `Config.Rarities` / `Config.Items` – 確率と景品
- `Config.Timing` – 演出タイムライン（ms）
- `Config.Blip` – 地図アイコン
- `Config.Debug` – デバッグ出力

## 使い方

1. マップのガチャアイコンへ向かう  
2. マシンに近づく（プロップ＋NUI 用 `machine.png`）  
3. E でガチャ  
4. SR 以上は全体チャット、N/R は本人チャット

## ライセンス

MIT
