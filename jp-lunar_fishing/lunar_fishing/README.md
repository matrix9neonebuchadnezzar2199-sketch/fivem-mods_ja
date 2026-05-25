# lunar_fishing (Japanese Localization)

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![FiveM Resource](https://img.shields.io/badge/FiveM-Resource-111111?logo=fivem)](https://fivem.net/)
[![Version](https://img.shields.io/badge/version-1.0.1--ja1-orange)](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/releases/tag/v1.0.1-ja1)
[![Based on](https://img.shields.io/badge/Based%20on-lunar__fishing%20v1.0.1-lightgrey)](https://github.com/Lunar-Scripts/lunar_fishing)
[![Framework](https://img.shields.io/badge/Framework-ESX%20%7C%20QBCore-green)](https://github.com/overextended/ox_lib)
[![i18n](https://img.shields.io/badge/i18n-Japanese-red)](locales/ja.json)

**日本語化 + 日本魚種対応** の FiveM 釣りリソースです。  
[Lunar-Scripts/lunar_fishing](https://github.com/Lunar-Scripts/lunar_fishing) v1.0.1 をベースに、UI・魚種・ゾーン・NPC を日本向けに差し替えています。

| 読者 | リンク |
|---|---|
| 管理者（インストール） | [クイックスタート](#クイックスタート) · [親プロジェクト INSTALL](../docs/INSTALL_JA.md) |
| 改変履歴 | [CHANGELOG](../CHANGELOG.md) |
| 完全版 README | [jp-lunar_fishing](../README.md) |

---

## 目次

- [クイックスタート](#クイックスタート)
- [機能](#機能)
- [依存関係](#依存関係)
- [設定ファイル](#設定ファイル)
- [魚種（抜粋）](#魚種抜粋)
- [クレジット・ライセンス](#クレジットライセンス)
- [GitHub Topics](#github-topics)

---

## クイックスタート

1. 本フォルダ `lunar_fishing/` を `resources/` 配下に配置（フォルダ名は **`lunar_fishing` 固定**）
2. `server.cfg` に追記:

```cfg
setr ox:locale ja
ensure lunar_fishing
```

3. アイテム定義を追記:
   - ox_inventory → [`install/items_ox_ja.lua`](install/items_ox_ja.lua)
   - QBCore → [`install/items_qb_ja.lua`](install/items_qb_ja.lua)
4. 魚アイコン PNG（15 枚）を [`../assets/fish_images/`](../assets/fish_images/) からインベントリ `images/` へコピー
5. `refresh` → 再起動

詳細: **[`../docs/INSTALL_JA.md`](../docs/INSTALL_JA.md)**

---

## 機能

- ESX / QBCore 対応
- 複数釣りゾーン（サンゴ礁・深海域・沼地）+ 沿岸全域
- レベル & XP システム
- 魚売却・釣り竿 / 餌購入（シートレード商会）
- ボートレンタル
- ox_target / qb-target 対応
- 低 resmon（アイドル 0.0ms 目安）

原作プレビュー: https://youtu.be/XUfPRGEm9_I

---

## 依存関係

`ensure lunar_fishing` **より前** に起動:

| リソース | 必須 |
|---|---|
| `oxmysql` | ✅ |
| `ox_lib` | ✅ |
| `ox_target` / `qb-target` / `qtarget` | ✅ |
| `es_extended` / `qb-core` | ✅ |
| `ox_inventory` / `qb-inventory` | 推奨 |

---

## 設定ファイル

| ファイル | 内容 |
|---|---|
| [`config/config.lua`](config/config.lua) | 魚種・ゾーン・竿・餌（日本魚 10 種） |
| [`locales/ja.json`](locales/ja.json) | UI 日本語（42 キー） |
| [`config/sv_config.lua`](config/sv_config.lua) | Webhook（任意） |

---

## 魚種（抜粋）

| キー | 表示名 | レア度 |
|---|---|---|
| `iwashi` | イワシ | ★☆☆☆☆ |
| `maguro` | クロマグロ | ★★★★☆ |
| `ryugu` | リュウグウノツカイ | ★★★★★ |

全 10 種 + 竿 3 + 餌 2: [`../README.md`](../README.md#魚種一覧)

---

## クレジット・ライセンス

| 項目 | 内容 |
|---|---|
| **原作** | [Lunar Scripts / lunar_fishing v1.0.1](https://github.com/Lunar-Scripts/lunar_fishing) |
| **日本語化** | matrix9neonebuchadnezzar2199-sketch |
| **コード** | GNU GPL-3.0 — [`LICENSE`](LICENSE) |
| **画像** | CC0 1.0 — [`../assets/fish_images/LICENSE_IMAGES.md`](../assets/fish_images/LICENSE_IMAGES.md) |
| **タグ / Release** | [`v1.0.1-ja1`](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/releases/tag/v1.0.1-ja1) |
| **Issues** | https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/issues |

---

## GitHub Topics

```
fivem fivem-resource fishing japanese i18n esx qbcore ox_lib jp-mods lunar-scripts gpl-3.0
```

Settings → Topics に貼り付けてください。
