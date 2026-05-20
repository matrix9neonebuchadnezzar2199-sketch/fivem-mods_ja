# jp-peak-trucking

[Peak Trucking](https://github.com/Peak-Studios/peak-trucking)（MIT）の**完全日本語版**フォークです。  
ドライバー成長・企業信頼・デイリーミッション・ランキング・合法/闇貨物・React NUI 配車タブレットを、日本語サーバー向けにそのまま使えます。

## クレジット

- 原作: [Peak-Studios/peak-trucking](https://github.com/Peak-Studios/peak-trucking)（Peak Studios, MIT License）
- 日本語化・配布: `fivem-mods_ja` / jp-mods

## 主な機能

- トラックレベルに応じたミッション・ルート選択
- 企業ごとの信頼ポイントとミッション解放
- ドライバー XP・レベル・完了数・収入・履歴
- デイリーミッション（リセット対応）
- SQL ランキング
- 闇貨物（ox_target / qb-target 等）
- `/truckhud` で移動できるジョブ HUD
- QBCore / ESX、各種インベントリ・インタラクション対応

## 依存関係

- `oxmysql`
- QBCore または ESX（`shared/config.lua` で設定）
- 必要に応じて ox_target、ox_inventory など

## インストール

1. フォルダを `resources/[jp-mods]/jp-peak-trucking/` に配置
2. `install/install.sql` をデータベースにインポート
3. `shared/config.lua` と `server/server-config.lua` をサーバー環境に合わせて編集
4. `server.cfg` に追加:

```cfg
ensure oxmysql
ensure jp-peak-trucking
```

座標・報酬・ジョブ制限は `shared/config.lua` で変更してください。

## UI の再ビルド

NUI ソースは `ui/` です。文言を変えた場合:

```powershell
cd ui
npm install
npm run build
```

FiveM は `ui/dist/index.html` を読み込みます。配布時は `ui/dist` を含め、`ui/node_modules` は含めないでください。

## 設定ファイル

| ファイル | 内容 |
|----------|------|
| `shared/config.lua` | フレームワーク、ミッション、車両、燃料、XP など |
| `shared/locales.lua` | ゲーム内・NUI 用の日本語文字列（デフォルト `ja`） |
| `server/server-config.lua` | Discord トークン等（サーバー専用） |

## 日本語化の範囲

- `shared/locales.lua` … 操作テキスト・通知・タブレット UI ラベル
- `shared/config.lua` … ミッション名、ルート名、デイリー、車両表示名、ブリップ名
- `ui/src` … タブレット内の固定文言（ビルド済み `ui/dist` に反映）

## ライセンス

原作の MIT License を継承します。`LICENSE` を参照してください。  
再配布・改変時は Peak Studios の著作表示を残してください。

## 関連リンク

- 原作リポジトリ: https://github.com/Peak-Studios/peak-trucking
