# fivem-mods（JP-Mods）

日本語 FiveM RP 向けの**スタンドアロン**リソース用開発リポジトリです。

作成者: [@eiho_tsukuyomi](https://x.com/eiho_tsukuyomi)

使用する際は、フォロー＆リツイートで応援よろしくお願いします！

## リポジトリ構成とドキュメント

このリポジトリは**複数 MOD を同一ルートに並べるモノレポ型**の開発レイアウトです（各フォルダが独立リソース）。MOD を追加するときは、次を基準にすると見通しが良くなります。

- **翻訳・表記の統一**: [`docs/STYLEGUIDE.md`](docs/STYLEGUIDE.md)（用語・文体・UTF-8 の注意）
- **各 MOD**: フォルダ直下の `README.md`・必要に応じて `CHANGELOG.md`・インストール手順（例: `INSTALLATION_JP.txt`）

既存のフォルダ名・`ensure` 名・依存関係を変えずにドキュメントだけ足す運用を推奨します。

## 収録 MOD（各フォルダの README を参照）

| フォルダ | 概要 |
|----------|------|
| [RefBoard](RefBoard/README.md) | サッカー試合管理（oxmysql・編集ロック・スコア履歴・Vue NUI・JA/EN・MIT） |
| [jp-110](jp-110/README.md) | `/110` 警察向け無線風一斉通知 |
| [jp-b2b_documents](jp-b2b_documents/README.md) | Quill ベースのドキュメント／メモエディター（日本語 UI・ESX/QB/Qbox・ox / qb / ESX インベントリ抽象化・原作 alnd029 系） |
| [jp-blackmarket/matkez_blackmarket_ja](jp-blackmarket/matkez_blackmarket_ja/README.md) | ブラックマーケット（日本語化・QBCore 対応・ox_inventory 前提・原作 GPL-3.0） |
| [jp-card](jp-card/README.md) | `/card` 3D回転付きトランプ抽選 |
| [jp-coin](jp-coin/README.md) | `/coin` 3D回転付きコイントス |
| [jp-ddm](jp-ddm/README.md) | モーション連続再生 + YouTube 音楽同期（クライアント・KVS） |
| [jp-gacha](jp-gacha/README.md) | ガチャ（NUI・1連/10連・現金支払い） |
| [jp-gacha2](jp-gacha2/README.md) | ガチャ v2（ox_inventory・管理・NUI カプセル） |
| [jp-glitch28](jp-glitch28/README.md) | Glitch Minigames 日本語 UI（28+ ミニゲーム・`glitch-minigames` 名で配置・GPL-3.0） |
| [jp-hospital](jp-hospital/README.md) | 病院カルテ整理・薬梱包（NUI 内職・Qbox） |
| [jp-v-farming](jp-v-farming/README.md) | 農業・青果売却（ox_target / ox_lib / ox_inventory・日本語 i18n・原作 MIT） |
| [pls_jobsystem](pls_jobsystem/README.md) | PLS Job System 日本語化（動的ジョブ管理・React NUI・フォルダ名 `pls_jobsystem` 固定・原作 MIT） |
| [jp-koban](jp-koban/README.md) | 警察向け住宅地巡回パトロール（Qbox・完遂ボーナス） |
| [jp-LetterCarrier](jp-LetterCarrier/README.md) | 配達ジョブ（NUI・配送車・報酬） |
| [jp-losmon](jp-losmon/README.md) | 育成型 Los-Mon（クライアント完結・サーバー負荷ほぼなし） |
| [jp-mch](jp-mch/README.md) | ミニマルクリーン HUD（クライアント完結・ESX/QB/Qbox/standalone・日本語 UI・Munlay HUD 系フォーク） |
| [jp-mbt_emote_menu](jp-mbt_emote_menu/README.ja.md) | MBT Emote Menu 日本語対応（rpemotes-reborn・NUI・`README.ja.md` 参照・原作は PolyForm Noncommercial） |
| [jp-mechanic](jp-mechanic/README.md) | 整備工場 伝票整理内職（NUI・部品照合・Qbox） |
| [jp-sentinel](jp-sentinel/README.md) | 警察向け Sentinel Ball（追尾ドローン・マップ共有・ESX/QB/Qbox/ACE） |
| [jp-slot](jp-slot/README.md) | カジノスロット（着席 NUI・抽選/現金はサーバー権威） |
| [jp-tcgbook](jp-tcgbook/README.md) | スタンドアロン TCG・BOOK（コレクション／デッキ編成／CPU・PvP・Elo・対戦履歴・ランキング・段位徽章・JA/EN UI・oxmysql） |
| [jp-timer](jp-timer/README.md) | 画面カウントダウン（`/min`・RP 向け軽量） |
| [jp-UnderworldBounty](jp-UnderworldBounty/README.md) | 闇の指名手配（裏賭場シナリオ・報復ウェーブ・設定駆動・ESX/QB/Standalone） |
| [qb-storerobbery-ja](qb-storerobbery-ja/README.md) | `qb-storerobbery` 日本語化フォーク（コンビニ強盗・KVP クールダウン・ox_inventory ブリッジ） |

## ツール

| ツール | パス | 説明 |
|---|---|---|
| 汎用 NUI 日本語化適用ツール | [`tools/apply_nui_i18n.ps1`](./tools/apply_nui_i18n.ps1) | 各 MOD の `web/dist/assets/index.js` を翻訳マップに従って日本語化します。詳細は [`tools/README_JA.md`](./tools/README_JA.md)。 |

クイック実行例:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode preview
```

[ライセンス（MIT）](LICENSE)
