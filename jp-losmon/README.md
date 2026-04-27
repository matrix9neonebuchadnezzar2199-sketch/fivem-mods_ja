# jp-losmon (Los-Mon)

FiveM 用の育成型 NUI ミニゲーム（Los-Mon）。チャットで `/losmon`（`config.lua` の `Config.Command` で変更可）を実行して起動し、ミニ表示は常駐します。

## 配置

`server-data/resources/[jp-mods]/jp-losmon/` にコピーし、`server.cfg` で `ensure jp-losmon` 等で起動します。

## 画像

スプライトは `html/img/` 内の `01_`〜`10_` プレフィックス命名（4 コマ横 512×128 推奨）に合わせて `config.lua` の `Config.Sprites` を割り当てています。

## 進化分岐について

Los-Mon は育て方によって最終進化先が変わります。

### 成長期（幼体→成長期）

- A ルートと B ルートのどちらに進化するかはランダムです（`Config.ChildBranchRandom`）。

### 成熟期（成長期→成熟期）

- careScore = (実際のお世話回数 ÷ 理想お世話回数) × 100 で判定（成長期の経過時間と `Config.IdealCareIntervalSec` から理想回数を算出）。
- 80 以上: 良育成ルート（強く美しい姿）
- 40〜79: 普通育成ルート（バランスの取れた姿）
- 39 以下: 悪育成ルート（荒んだ姿）

### コツ

- こまめにごはん・遊ぶ・寝かせる・掃除をしてあげましょう。
- 空腹が `Config.SickThreshold` % 以下になると病気になります。
- 病気を `Config.DeathTime` 秒放置すると死亡します。空腹を戻す（ごはん）で回復できます。

## 設定

`config.lua` に日本語コメント付きで数値（孵化・成長間隔・減少率・クールダウン等）をまとめています。本番前に `Config.HatchTime` や `Config.GrowthInterval` を調整してください。

## 保存

クライアント KVS キー `losmon_v1` に JSON で保存します（図鑑・ミニ表示位置含む）。**このリソースに `server_scripts` はなく、データはサーバーへ送りません。**

## 操作と NUI フォーカス

- **常駐**: ミニ表示のみのときは `SetNuiFocus(false, false)` のためマウスは出ず、ゲーム操作の邪魔になりにくいです。
- **拡大**: `/losmon` で拡大画面を開くとフォーカスが当たりマウスでお世話・図鑑・旅立ちを操作できます。
- **ミニの位置**: 拡大表示を開いている間だけ、画面端のミニ表示をドラッグして移動できます。位置は KVS に保存され、次回以降も維持されます。
