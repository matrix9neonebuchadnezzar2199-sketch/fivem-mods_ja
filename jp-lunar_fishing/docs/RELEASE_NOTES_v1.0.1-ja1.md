# jp-lunar_fishing v1.0.1-ja1 (Beta)

[Lunar-Scripts/lunar_fishing](https://github.com/Lunar-Scripts/lunar_fishing) v1.0.1 の日本語化＋日本魚種対応版の初回リリースです。

## ✨ 主な変更点

- UI 文字列を完全日本語化（`locales/ja.json`、42 キー）
- 魚種を日本の代表的な 10 種に置換（イワシ／アジ／サバ／マダイ／ヒラメ／ウナギ／ブリ／カツオ／クロマグロ／リュウグウノツカイ）
- ゾーン名・NPC 名・通知メッセージを日本語化
- インベントリ用アイテム定義を日本語ラベルで提供（ox_inventory / QBCore）
- AI 生成（Stable Diffusion）の魚アイコン画像 15 種を同梱（100×100 透過 PNG、CC0 1.0）

## 📦 同梱内容

- `lunar_fishing/` — FiveM リソース本体（`resources/` 配下にコピー）
- `locales/ja.json` — UI 日本語ロケール
- `config/config.lua` — 日本魚種設定
- `install/items_ox_ja.lua` / `items_qb_ja.lua` — インベントリアイテム定義

## 🚀 インストール

詳細な手順は [`docs/INSTALL_JA.md`](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/blob/main/jp-lunar_fishing/docs/INSTALL_JA.md) を参照してください。

簡略手順：
1. ZIP を展開し `lunar_fishing/` を `resources/` にコピー
2. `server.cfg` に `ensure lunar_fishing` と `setr ox:locale ja` を追加
3. `install/items_ox_ja.lua` の内容を `ox_inventory/data/items.lua` に追記
4. 魚アイコン PNG を `ox_inventory/web/images/` に配置
5. サーバー再起動

## 📦 必要な依存リソース

- `ox_lib`
- `ox_target` または `qb-target` / `qtarget`
- `oxmysql`
- `es_extended` または `qb-core`
- `ox_inventory` または `qb-inventory`

## 📜 ライセンス

- コード：**GNU GPL-3.0**（ベース MOD から継承）
- 画像アセット：**CC0 1.0**（Stable Diffusion 生成、商用・改変自由）

## 🙏 クレジット

- 原作：[Lunar Scripts](https://github.com/Lunar-Scripts/lunar_fishing)
- 日本語化・魚種データ・画像生成プロンプト：[matrix9neonebuchadnezzar2199-sketch](https://github.com/matrix9neonebuchadnezzar2199-sketch)

## 🔗 関連

- 開発リポジトリ：https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja
- 原作リポジトリ：https://github.com/Lunar-Scripts/lunar_fishing
- 原作 Discord：https://discord.gg/zDK4CHQ56N

---

**Note**: 本リリースはベータ版です。動作確認のフィードバックを歓迎します。バグ報告は [Issues](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/issues) へお願いします。
