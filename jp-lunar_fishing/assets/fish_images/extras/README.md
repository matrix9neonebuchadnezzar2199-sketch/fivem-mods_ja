# extras — 未採用アイコン（将来活用用）

本ディレクトリには、jp-lunar_fishing v1.0.1-ja1 の**正式採用 15 枚セットには含まれない**
予備アイコンを保管しています。いずれも Stable Diffusion で生成済みで、
ライセンスは親ディレクトリの [`LICENSE_IMAGES.md`](../LICENSE_IMAGES.md)（CC0 1.0）に従います。

## 収録ファイル

| ファイル | 和名 | 英名 | 備考 |
|---|---|---|---|
| `salmon.png` | サーモン | Salmon | 原作 MOD の `salmon` アイテムに相当。日本魚 10 種への置換では未使用 |
| `cod.png` | タラ | Cod | 同上。将来の魚種追加候補 |

## 将来の活用シナリオ

### 1. 魚種追加 MOD 拡張

`Config.fish` に新キーを追加する際、対応する PNG を本ディレクトリから昇格できます。

```lua
-- config/config.lua への追加例
['sake'] = { price = { min = 300, max = 400 }, chance = 15, skillcheck = { 'easy', 'medium' } },
```

```powershell
# salmon.png を sake キー用にコピー（必要に応じてリネーム）
Copy-Item extras\salmon.png ..\sake.png
```

### 2. 季節イベント・限定魚

秋のサンマ祭、冬のタラシラコイベントなど、期間限定魚種のアイコンとして流用可能です。

### 3. 他 MOD への転用

CC0 1.0 のため、FiveM 以外のゲーム MOD や UI 素材としても自由に利用できます。
帰属表示は不要です。

## 採用セットへの昇格手順

1. `config/config.lua` の `Config.fish` にキーを追加
2. `install/items_ox_ja.lua` / `install/items_qb_ja.lua` にアイテム定義を追記
3. PNG を `assets/fish_images/<key>.png` に配置（`extras/` から移動またはコピー）
4. インベントリの `web/images/`（ox_inventory 等）へ同名ファイルをコピー
5. `CHANGELOG.md` に魚種追加を記録

詳細なプロンプト追加方法は [`docs/IMAGE_PROMPTS.md`](../../docs/IMAGE_PROMPTS.md) §7 を参照してください。
