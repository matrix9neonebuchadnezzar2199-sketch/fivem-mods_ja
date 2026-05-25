# jp-lunar_fishing

[Lunar-Scripts/lunar_fishing](https://github.com/Lunar-Scripts/lunar_fishing) の
日本語化＋日本魚種対応版です。FiveM サーバーで日本らしい釣り体験を提供します。

- **ベース MOD**：Lunar-Scripts/lunar_fishing v1.0.1
- **ライセンス**：GNU GPL-3.0（ベース MOD を継承）
- **配布形態**：非商用・無償
- **対応フレームワーク**：ESX / QBCore（ox_lib 必須）

---

## 主な変更点

- UI 文字列を完全日本語化（`locales/ja.json`）
- 魚種を日本の代表的な 10 種に置換（イワシ／アジ／サバ／マダイ／ヒラメ／ウナギ／ブリ／カツオ／クロマグロ／リュウグウノツカイ）
- ゾーン名・NPC 名・通知メッセージを日本語化
- インベントリ用アイテム定義を日本語ラベルで提供（ox_inventory / QBCore）
- AI 生成の魚アイコン画像を同梱予定（STEP 7 で追加）

---

## 必要な依存リソース

| リソース | 役割 |
|---|---|
| [`ox_lib`](https://github.com/overextended/ox_lib) | UI・ロケール・ユーティリティ |
| [`ox_target`](https://github.com/overextended/ox_target) または `qb-target` / `qtarget` | NPC・水面とのインタラクション |
| `oxmysql` | DB アクセス |
| `es_extended` または `qb-core` | フレームワーク |
| `ox_inventory` または `qb-inventory` | アイテム管理（推奨：`ox_inventory`） |

---

## インストール

詳細は [`docs/INSTALL_JA.md`](docs/INSTALL_JA.md) を参照してください。

簡略手順：

1. `lunar_fishing/` ディレクトリをサーバーの `resources/` 配下にコピー
2. `server.cfg` に `ensure lunar_fishing` と `setr ox:locale ja` を追加
3. `install/items_ox_ja.lua`（または `items_qb_ja.lua`）の内容を
   各インベントリのアイテム定義ファイルに追記
4. 魚アイコン PNG を `ox_inventory/web/images/` 等に配置
5. サーバー再起動

---

## ディレクトリ構成

```
jp-lunar_fishing/
├─ README.md                   ← このファイル
├─ LICENSE                     ← GNU GPL-3.0 全文
├─ CHANGELOG.md                ← 改変履歴
├─ CREDITS.md                  ← 原作者・謝辞
├─ docs/
│  ├─ INSTALL_JA.md            ← 日本語インストールガイド
│  ├─ IMAGE_PROMPTS.md         ← 画像生成プロンプト集
│  ├─ WORK_INSTRUCTIONS.md     ← 開発作業指示書
│  └─ （開発日記は lunar_fishing/docs/）
├─ assets/
│  └─ fish_images/             ← 生成済み魚アイコン（STEP 7 で追加）
└─ lunar_fishing/              ← FiveM リソース本体
   ├─ fxmanifest.lua
   ├─ LICENSE
   ├─ README.md
   ├─ locales/
   │  ├─ en.json                (オリジナル)
   │  ├─ de.json                (オリジナル)
   │  └─ ja.json                ★日本語ロケール
   ├─ config/
   │  ├─ config.lua             ★日本魚種10種に書換
   │  ├─ cl_edit.lua
   │  └─ sv_config.lua
   ├─ client/
   ├─ server/
   ├─ framework/
   ├─ utils/
   └─ install/
      ├─ items_ox_ja.lua        ★ox_inventory 用アイテム定義
      └─ items_qb_ja.lua        ★QBCore 用アイテム定義
```

---

## 魚種一覧

| アイテムキー | 表示名 | 価格 | 出現ゾーン | レア度 |
|---|---|---|---|---|
| `iwashi`  | イワシ           | 25-50     | 沿岸全域 | ★☆☆☆☆ |
| `aji`     | アジ             | 50-100    | 沿岸全域 | ★☆☆☆☆ |
| `saba`    | サバ             | 150-200   | 沿岸全域 | ★★☆☆☆ |
| `tai`     | マダイ           | 200-250   | 沿岸全域 | ★★☆☆☆ |
| `hirame`  | ヒラメ           | 300-350   | サンゴ礁 | ★★★☆☆ |
| `unagi`   | ウナギ           | 350-450   | 沼地     | ★★★☆☆ |
| `buri`    | ブリ             | 400-450   | サンゴ礁 | ★★★☆☆ |
| `katsuo`  | カツオ           | 450-500   | 深海域   | ★★★★☆ |
| `maguro`  | クロマグロ       | 1250-1500 | 深海域   | ★★★★☆ |
| `ryugu`   | リュウグウノツカイ | 2250-2750 | 深海域 | ★★★★★ |

---

## ライセンス

本プロジェクトは **GNU General Public License v3.0** のもとで配布されます。
ベース MOD のライセンスを継承するため、派生物も GPL-3.0 で配布する必要があります。

- 完全なライセンス文書：[`LICENSE`](LICENSE)
- 改変履歴：[`CHANGELOG.md`](CHANGELOG.md)
- 原作者クレジット：[`CREDITS.md`](CREDITS.md)

画像アセット（`assets/fish_images/`）は CC0 1.0 で配布します。
詳細は [`assets/fish_images/LICENSE_IMAGES.md`](assets/fish_images/LICENSE_IMAGES.md) を参照してください。

---

## コントリビュート

バグ報告・翻訳改善・魚種追加の提案は GitHub Issues / Pull Request でお願いします。

---

## 関連リンク

- 原作リポジトリ：https://github.com/Lunar-Scripts/lunar_fishing
- 原作プレビュー動画：https://youtu.be/XUfPRGEm9_I
- 原作 Discord：https://discord.gg/zDK4CHQ56N
- 本リポジトリ：https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja
