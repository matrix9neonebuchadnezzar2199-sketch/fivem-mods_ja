# jp-card

`/card` でトランプを1枚ランダムに引く、スタンドアロンの FiveM リソースです。  
NUI でカードの 3D 回転演出を表示し、周囲プレイヤーにチャット共有できます。

## 特徴

- NUI の 3D フリップ演出でカード表示
- 54枚デッキ対応（52枚 + ジョーカー2枚）
- 周囲プレイヤーへのローカル範囲チャット通知
- フレームワーク依存なし（standalone）

## インストール

1. `resources/[jp-mods]/jp-card/` に配置
2. `server.cfg` に以下を追加

```cfg
ensure jp-card
```

## 設定（config.lua）

- `Config.Command`  
  カードを引くコマンド名です（既定: `card`）。
- `Config.DisplayTime`  
  カード演出の表示時間（ミリ秒）です。
- `Config.Cooldown`  
  連打防止のクールダウン秒数です。
- `Config.ChatRange`  
  結果チャットを共有する半径（メートル）です。
- `Config.ShowChatMessage`  
  `true` で周囲チャット通知を有効にします。

## 使い方

チャットで `/card` と入力するだけです。  
クールダウン中に再実行すると「少し待ってください」が表示されます。

## 活用例

- ちんちろ代わりの簡易ランダム判定
- 罰ゲーム決め
- 順番決め

## ライセンス

MIT
