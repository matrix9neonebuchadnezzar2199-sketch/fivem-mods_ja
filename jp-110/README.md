# jp-110

`/110` で警察全員に無線風通知を送信するスタンドアロンリソースです。  
警察側には右上NUI通知と、通報地点の赤い点滅ブリップを表示します。

## 特徴

- NUI無線風演出（赤ランプ点滅、タイプライター表示）
- マップ上に赤い点滅ブリップ（一定時間で自動消滅）
- ESX/QBCore自動判定、未使用時はACE Permissionで警察判定
- フレームワーク非依存で動作可能

## インストール

1. `resources/[jp-mods]/jp-110/` に配置
2. `server.cfg` に `ensure jp-110` を追加
3. ESX/QBCore未使用の場合、ACE設定を追加

```cfg
# jp-110 警察権限設定
add_ace group.police jp-110.police allow

# 警察メンバー登録（FiveM IDで指定）
add_principal identifier.fivem:18943003 group.police
# add_principal identifier.fivem:XXXXXXX group.police
```

## 設定ガイド（config.lua）

- `Config.Command`  
  通報コマンド名（デフォルト: `110`）。
- `Config.Cooldown`  
  連打防止秒数。
- `Config.BlipDuration`  
  マップ上の赤点滅ブリップ表示時間（秒）。
- `Config.BlipFlashInterval`  
  ブリップの点滅間隔（ミリ秒）。
- `Config.BlipSprite` / `Config.BlipColor` / `Config.BlipScale`  
  ブリップ見た目の設定。
- `Config.NotificationDuration`  
  NUI通知表示時間（ミリ秒）。
- `Config.PoliceJobNames`  
  警察として判定するジョブ名リスト。
- `Config.AcePermission`  
  ACE Permission名（デフォルト: `jp-110.police`）。

## 使い方

- 市民: チャットで `/110` と入力して通報
- 警察: 右上通知を確認し、マップの赤点滅ポイントへ向かう

## トラブルシューティング

- 通報しても通知が出ない  
  `server.cfg` の ACE 設定、またはESX/QBCoreのジョブ名を確認してください。
- ブリップが長すぎる/短すぎる  
  `Config.BlipDuration` を調整してください。

## txAdmin コマンド例

- `refresh`
- `ensure jp-110`

## ライセンス

MIT
