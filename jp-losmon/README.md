# jp-losmon (Los-Mon)

FiveM 用の育成型 NUI ミニゲーム（Los-Mon）。チャットで `/losmon`（`config.lua` の `Config.Command` で変更可）を実行して起動し、ミニ表示は常駐します。

## 配置

`server-data/resources/[jp-mods]/jp-losmon/` にコピーし、`server.cfg` で `ensure jp-losmon` 等で起動します。

## 画像

`config.lua` の `Config.Sprites` を参照。フォルダ例: `html/img/01_egg/`, `02_baby/`, `03_child/`, `04_adult/`。幼体〜成体・**卵**・**旅立ち**（`05_d/05_d.png`）は **横4コマ1枚** 前提（`SpriteStripFrames` / `EggSpriteStripFrames` / `GraveSpriteStripFrames` = 4。NUI は `background-size: 4×` + `steps(4)`）。

- 病気・墓: 従来通り `html/img/` 直下（`09_` / `10_`）想定。必要ならパスを `config.lua` で差し替え。

## 本体スキン追加ガイド

拡大UI・ミニ版の**筐体画像**（`--device-skin`）を差し替えるスキンは、グローバル設定 `Config.SkinList` と NUI のラジオで切り替えます（KVS キー `losmon_v1` の `skin` フィールド）。

本体スキン用 PNG は次の規格で作成すること。

- キャンバスは **`html/img/main.png` と同一**（解像度・本体・LCD・ボタン・アンテナの相対位置を揃える）
- 余白は透過可
- NUI では `aspect-ratio: 1024 / 559` 前提で `contain` 表示するため、基準画像と同じ取り方にすると位置ズレが出ない

規格を守れば、`Config.SkinList` への1行追加と、`html/index.html` のラジオ1つ＋`style.css` のスウォッチ用クラス（任意）追記程度で拡張できる。

## 進化分岐について

初回は**卵1種**から自動スタート。孵化 `Config.HatchTime` 秒（既定 30 分）のあと、幼年期は**ランダムで A または B**。

### 成長期（幼体→成長期）

- 幼体の**お世話度**（`IdealCareIntervalSec` から理想回数と `careCount` 比）が `Config.ChildToGoodChildThreshold`（既定 50）以上 → 成長期（良）`child_a`、未満 → 成長期（悪）`child_b`。

### 成熟期（成長期→成熟期）

- `adult_d`（レア）: 乱数 `AdultRarePercent`（%）。それ以外は `adult_a` / `b` / `c` を均等乱数で決定（照育スコアの概念は**未使用**）。

### コツ

- こまめにごはん・遊ぶ・寝かせる・掃除をしてあげましょう。
- 空腹が `Config.SickThreshold` % 以下になると病気になります。
- 病気を `Config.DeathTime` 秒放置すると死亡します。空腹を戻す（ごはん）で回復できます。

## 設定

`config.lua` に日本語コメント付きで数値（孵化・成長間隔・減少率・クールダウン等）をまとめています。本番前に `Config.HatchTime` や `Config.GrowthInterval` を調整してください。

## 保存

クライアント KVS キー `losmon_v1` に JSON で保存します（図鑑・ミニ表示位置含む）。**このリソースに `server_scripts` はなく、データはサーバーへ送りません。**

## 操作と NUI フォーカス

- **初回**: ペットが未作成なら **卵**が自動的に 1 体生成され、常駐ミニが表示されます。
- **常駐**: ミニ表示のみのときは `SetNuiFocus(false, false)` のためマウスは出ず、ゲーム操作の邪魔になりにくいです。
- **拡大**: `/losmon` で拡大画面を開くとフォーカスが当たりマウスでお世話・図鑑・旅立ちを操作できます。
- **ミニの位置**: 拡大表示を開いている間だけ、画面端のミニ表示をドラッグして移動できます。位置は KVS に保存され、次回以降も維持されます。

## UI サイズ

- 拡大パネル・文章・スプライト枠を実用上おおよそ **3 倍** 相当（`html { font-size: 48px; }` ベースの `rem` と 384px 枠等）にしています。

## ヘッダー・ティッカー

拡大画面のタイトル行右側に、状況に応じた文が流れるティッカー（CSS アニメーション＋7 秒ごとローテーション）を表示します。空腹・病気・満腹・成長直前（`hatchLeftSec` / `nextPhaseInSec` 参照）のほか、ミニ表示のドラッグ案内を含めます。しきい値の一部は `config.lua` の `Config.TickerNearHatchMaxSec` / `TickerNearPhaseMaxSec` で調整可能です。
