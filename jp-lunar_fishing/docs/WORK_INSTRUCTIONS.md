# 📋 Cursor 作業指示書：jp-lunar_fishing（lunar_fishing 日本語化＋日本魚MOD）

## 0. プロジェクト概要

```yaml
プロジェクト名: jp-lunar_fishing
ベースMOD:    Lunar-Scripts/lunar_fishing (GPL-3.0)
作業ディレクトリ: H:\CURSOR\Dev\fivem-mods_ja\jp-lunar_fishing\lunar_fishing
管理リポジトリ:   https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja
目的:
  - UIテキストの完全日本語化
  - 日本の魚種への置き換え／追加
  - AI生成した魚アイコン画像の同梱
  - 非商業の無償配布（GPL-3.0継承）
```

## 1. 重要事項（最初に必ず読む）

**ライセンス**：元のlunar_fishingは **GNU GPL-3.0**。派生物も**必ずGPL-3.0で配布**する必要がある。改変箇所には日付と改変者を明記すること（GPL-3.0 §5a）。商用化はしないが、配布時はソース完全公開が義務。

**親リポジトリ構成**：管理用GitHub `fivem-mods_ja` 配下に **`jp-lunar_fishing/`** サブディレクトリを作成し、その中に作業物を置く（将来他MODの日本語化も同居できるモノレポ構造）。

**ロケールの実装方式**：lunar_fishingは `ox_lib` のlocale機構を使用。`locales/*.json` がUIテキスト、`locales/*.lua` がサーバー側アイテム名等。**両方とも日本語化対象**。

---

## 2. ディレクトリ構成（最終形）

```
H:\CURSOR\Dev\fivem-mods_ja\
└─ jp-lunar_fishing\
   ├─ README.md                    # プロジェクトトップREADME（日本語）
   ├─ LICENSE                      # GPL-3.0（元のままコピー）
   ├─ CHANGELOG.md                 # 改変履歴（GPL §5a準拠）
   ├─ CREDITS.md                   # 原作者クレジット
   ├─ docs\
   │  ├─ INSTALL_JA.md             # 日本語インストール手順
   │  ├─ FISH_LIST_JA.md           # 日本魚種リスト・価格・出現ゾーン仕様
   │  └─ IMAGE_PROMPTS.md          # 画像生成プロンプト集
   ├─ assets\
   │  └─ fish_images\              # 生成済み魚画像 (100x100 透過PNG)
   │     ├─ maguro.png
   │     ├─ buri.png
   │     └─ ...
   └─ lunar_fishing\               # FiveMリソース本体（ここをserverのresourcesへ）
      ├─ fxmanifest.lua            # version文字列を 1.0.1-ja1 等に変更
      ├─ LICENSE
      ├─ README.md                 # 元READMEに日本語注記追加
      ├─ locales\
      │  ├─ en.json                # 既存（残す）
      │  ├─ en.lua                 # 既存（残す）
      │  ├─ ja.json                # ★新規：UIテキスト日本語版
      │  └─ ja.lua                 # ★新規：アイテムラベル日本語版
      ├─ config\
      │  ├─ config.lua             # ★編集：日本魚種・ゾーン・価格に書換え
      │  ├─ cl_edit.lua            # 必要に応じ編集
      │  └─ sv_config.lua          # Webhook設定（任意）
      ├─ client\
      ├─ server\
      ├─ framework\
      ├─ utils\
      └─ install\                  # アイテム定義サンプル等
```

---

## 3. 作業フロー（Cursorで順に実行）

### STEP 1：初期セットアップ

作業ディレクトリで PowerShell を開き以下を実行。

```powershell
cd H:\CURSOR\Dev\fivem-mods_ja
git clone https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja.git .
# すでにcloneしている場合はpullするだけ
git pull

# jp-lunar_fishingディレクトリ作成
mkdir jp-lunar_fishing\lunar_fishing -Force
cd jp-lunar_fishing

# 元MODをsubtree的に取り込む（履歴は分離してコピー）
git clone --depth=1 https://github.com/Lunar-Scripts/lunar_fishing.git _tmp_src
Copy-Item -Recurse -Force _tmp_src\* .\lunar_fishing\
Remove-Item -Recurse -Force _tmp_src
Remove-Item -Recurse -Force .\lunar_fishing\.git -ErrorAction SilentlyContinue
```

Cursorで `H:\CURSOR\Dev\fivem-mods_ja` をワークスペースとして開く。

### STEP 2：日本語ロケールファイルの作成

**ファイル：`lunar_fishing/locales/ja.json`**（新規作成、UTF-8 BOMなし）

元 `en.json` の全キーを翻訳。`%s` のプレースホルダは順序を維持。雛形：

```json
{
    "no_water": "目の前に水がありません。",
    "cancel": "[E] - キャンセル",
    "felt_bite": "魚が餌に食いつきました！引き上げる準備をしてください！",
    "catch_failed": "力が足りず、魚を逃がしてしまいました。",
    "sell_fish_heading": "1x %s = %s$",
    "sell_fish_heading2": "1x %s = %s - %s$",
    "amount": "数量",
    "selling": "売却中...",
    "sold_fish": "魚を売却しました。",
    "not_enough_fish": "魚の数量が不正です。",
    "fish_price": "クリックして %s$ で魚を売却します。",
    "fish_price2": "クリックして %s - %s$ で魚を売却します。",
    "sell_fish": "魚を売る",
    "buy_heading": "1x %s = %s$",
    "buying": "購入中...",
    "bought_item": "アイテムを購入しました。",
    "not_enough_money": "所持金が足りません。",
    "not_enough_bank": "銀行残高が足りません。",
    "rod_price": "クリックしてこの釣り竿を %s$ で購入します。",
    "buy_rods": "釣り竿を購入",
    "fisherman": "シートレード商会",
    "level": "現在のレベル: %s",
    "level_desc": "次のレベルまで %s XP 必要です。",
    "buy_rods_desc": "クリックして釣り竿を購入します。",
    "sell_fish_desc": "クリックして釣った魚を売却します。",
    "open_fisherman": "話しかける",
    "rent_heading": "ボートをレンタル",
    "rent_content": "本当にこのボートを %s$ でレンタルしますか？",
    "rent_price": "クリックしてこのボートを %s$ でレンタルします。",
    "rent_boat": "ボートをレンタル",
    "unlocked_level": "新しいレベルを解放しました！",
    "no_bait": "餌を持っていません。",
    "rod_broke": "釣り竿が負荷に耐え切れず折れてしまいました。",
    "nothing_to_sell": "売却できる魚がありません。",
    "anchor_boat": "[%s] - 錨を下ろす",
    "raise_anchor": "[%s] - 錨を上げる",
    "buy_baits": "餌を購入",
    "buy_baits_desc": "クリックして新しい餌を購入します。",
    "bait_price": "クリックしてこの餌を %s$ で購入します。",
    "return_boat": "[%s] - ボートを返却",
    "return_content": "本当にこのボートを返却しますか？\n  返却すると %s$ が払い戻されます。",
    "returned_boat": "ボートを返却しました。"
}
```

**`locales/ja.lua` は不要**（v1.0.1 に `en.lua` 実体なし）。アイテム表示名は **`install/items_ox_ja.lua` / `install/items_qb_ja.lua` の `label`** に集約する（STEP 5）。

### STEP 3：ロケール切替の確認（ja.lua はスキップ）

lunar_fishingは `ox_lib` の locale 機能で言語を選択。サーバーcfgで以下を設定するよう **`docs/INSTALL_JA.md` に明記**：

```cfg
setr ox:locale ja
```

`fxmanifest.lua` の `files { 'locales/*.json' }` 行はそのままでOK（`ja.json` も自動的に拾われる）。  
`server_scripts` の `'locales/*.lua'` は **実体が無くても無害**（将来 `ja.lua` を追加する余地として変更不要）。

### STEP 4：日本魚種への置き換え（config.lua）

**ファイル：`lunar_fishing/config/config.lua`** を以下方針で書き換え。

魚種一覧（10種、元の希少度バランスを踏襲）：

| item_name | 表示名 | 価格(min-max) | chance% | スキルチェック | 出現ゾーン |
|---|---|---|---|---|---|
| iwashi | イワシ | 25-50 | 35 | easy,medium | outside |
| aji | アジ | 50-100 | 35 | easy,medium | outside |
| saba | サバ | 150-200 | 20 | easy,medium | outside |
| tai | マダイ | 200-250 | 10 | easy,medium,medium | outside |
| hirame | ヒラメ | 300-350 | 25 | easy,medium,medium,medium | coral_reef |
| unagi | ウナギ | 350-450 | 25 | easy,medium,hard | swamp |
| buri | ブリ | 400-450 | 20 | easy,medium,medium,medium | coral_reef |
| katsuo | カツオ | 450-500 | 20 | easy,medium,medium,medium | deep_waters |
| maguro | クロマグロ | 1250-1500 | 5 | easy,medium,hard | deep_waters |
| ryugu | リュウグウノツカイ | 2250-2750 | 1 | easy,medium,hard | deep_waters |

ゾーンメッセージも日本語化（**en.json/ja.jsonには入っていないハードコード文字列なので注意**）：

```lua
-- coral_reef
message = { enter = 'サンゴ礁に入りました。', exit = 'サンゴ礁を離れました。' }
-- deep_waters
message = { enter = '深海域に入りました。', exit = '深海域を離れました。' }
-- swamp
message = { enter = '沼地に入りました。', exit = '沼地を離れました。' }
```

ブリップ名も日本語化（`name = 'サンゴ礁'` 等）。`Config.ped.blip.name = 'シートレード商会'` 、`Config.renting.blip.name = 'ボートレンタル'` も同様。

竿・餌の名前も日本語コンセプトに変更：

```lua
Config.fishingRods = {
    { name = 'basic_rod',    price = 1000, minLevel = 1, breakChance = 20 },
    { name = 'graphite_rod', price = 2500, minLevel = 2, breakChance = 10 },
    { name = 'titanium_rod', price = 5000, minLevel = 3, breakChance = 1  },
}
-- item_nameは英語ローマ字のまま（例: maguro, buri）。表示名は items_ox_ja.lua / items_qb_ja.lua の label で定義。

Config.baits = {
    { name = 'worms',           price = 5,  minLevel = 1, waitDivisor = 1.0 },
    { name = 'artificial_bait', price = 50, minLevel = 2, waitDivisor = 3.0 },
}
```

⚠ **アイテム名（`item_name`）はインベントリのキーになるため、英語ローマ字を維持**。表示名のみ `ja.lua` で日本語化する。

### STEP 5：インベントリへのアイテム登録

`lunar_fishing/install/` 配下のインストールファイルを確認し、以下を作成・更新：

**ox_inventory用**（`install/items_ox_ja.lua` 新規）：

```lua
-- ox_inventory/data/items.lua に追加する内容（サンプル）
['iwashi']  = { label = 'イワシ',           weight = 100, stack = true, close = true, client = { image = 'iwashi.png' } },
['aji']     = { label = 'アジ',             weight = 150, stack = true, close = true, client = { image = 'aji.png' } },
['saba']    = { label = 'サバ',             weight = 200, stack = true, close = true, client = { image = 'saba.png' } },
['tai']     = { label = 'マダイ',           weight = 500, stack = true, close = true, client = { image = 'tai.png' } },
['hirame']  = { label = 'ヒラメ',           weight = 600, stack = true, close = true, client = { image = 'hirame.png' } },
['unagi']   = { label = 'ウナギ',           weight = 400, stack = true, close = true, client = { image = 'unagi.png' } },
['buri']    = { label = 'ブリ',             weight = 800, stack = true, close = true, client = { image = 'buri.png' } },
['katsuo']  = { label = 'カツオ',           weight = 1000, stack = true, close = true, client = { image = 'katsuo.png' } },
['maguro']  = { label = 'クロマグロ',       weight = 3000, stack = true, close = true, client = { image = 'maguro.png' } },
['ryugu']   = { label = 'リュウグウノツカイ', weight = 2000, stack = true, close = true, client = { image = 'ryugu.png' } },
-- 釣り竿・餌
['basic_rod']       = { label = '初心者の釣り竿', weight = 1500, stack = false, close = true, client = { image = 'basic_rod.png' } },
['graphite_rod']    = { label = 'グラファイト竿', weight = 1200, stack = false, close = true, client = { image = 'graphite_rod.png' } },
['titanium_rod']    = { label = 'チタン竿',       weight = 1000, stack = false, close = true, client = { image = 'titanium_rod.png' } },
['worms']           = { label = 'ミミズ',         weight = 50, stack = true, close = true, client = { image = 'worms.png' } },
['artificial_bait'] = { label = 'ルアー',         weight = 30, stack = true, close = true, client = { image = 'artificial_bait.png' } },
```

QBCore用（`install/items_qb_ja.lua` 新規）も同様に作成（QBの `qb-core/shared/items.lua` 形式に合わせる）。

### STEP 6：画像生成（assets/fish_images）

**ファイル：`docs/IMAGE_PROMPTS.md`** を作成。各魚ごとに以下の統一プロンプトテンプレートを記載：

```
Style baseline (全アイコン共通):
"top-down side view of a [魚名], realistic illustration, 
clean transparent background, centered composition, 
soft uniform lighting, game inventory icon style, 
no text, no border, no shadow on background, 
square 1024x1024"

個別:
- iwashi:  "a Japanese sardine (iwashi), silver scales..."
- maguro:  "a bluefin tuna (kuromaguro), dark blue back..."
- ryugu:   "an oarfish (ryugu no tsukai), long ribbon-like silver body, red dorsal fin..."
（以下10種＋竿3種＋餌2種）
```

**出力仕様**：
- 1024×1024 で生成 → 100×100 透過PNG にリサイズして `assets/fish_images/` に配置
- ファイル名は `item_name` と完全一致（例：`maguro.png`）
- 配布時は `lunar_fishing/install/images_ox/` にもコピー（ユーザーがox_inventoryへ流し込む用）

### STEP 7：ドキュメント整備

**`jp-lunar_fishing/README.md`**：プロジェクト概要、ライセンス継承の明記、原作者リンク、インストール手順への導線。

**`docs/INSTALL_JA.md`**：依存関係（ox_lib, ox_target/qb-target, es_extended/qb-core, oxmysql）、resourcesへのコピー、`server.cfg` への `ensure lunar_fishing`、アイテム定義の追記、画像配置、`setr ox:locale ja` の設定、までを順番に。

**`CHANGELOG.md`**（GPL §5a 必須）：

```markdown
# Changelog

## [1.0.1-ja1] - 2026-05-24
### Modified by: [あなたのGitHubハンドル]
- Added Japanese locale (locales/ja.json, locales/ja.lua)
- Replaced fish species with Japanese variants in config/config.lua
- Added AI-generated fish icon images
- Added Japanese installation documentation

Based on: Lunar-Scripts/lunar_fishing v1.0.1
Original repository: https://github.com/Lunar-Scripts/lunar_fishing
License: GNU GPL-3.0
```

**`CREDITS.md`**：原作者 Lunar Scripts への謝辞と元リポジトリURL、ライセンスURL。

**`fxmanifest.lua`** の `version` を `'1.0.1-ja1'` に変更し、`description` に `' (Japanese Localization)'` を追記。

### STEP 8：Gitコミット＆プッシュ

```powershell
cd H:\CURSOR\Dev\fivem-mods_ja
git add jp-lunar_fishing
git commit -m "feat(jp-lunar_fishing): initial Japanese localization of lunar_fishing v1.0.1

- Add ja.json / ja.lua locale files
- Replace fish species with Japanese variants
- Add AI-generated fish icon assets
- Add installation docs in Japanese
- Preserve GPL-3.0 license"
git push origin main
```

リリース時は GitHub の Releases から `jp-lunar_fishing-v1.0.1-ja1.zip` をアップロード（`lunar_fishing/` ディレクトリのみを圧縮）。

---

## 4. Cursor へのプロンプト指示（コピペ用）

Cursor のチャットに最初にこれを貼り付けて作業を開始させる：

````
あなたはFiveM MODの日本語化作業を行うエンジニアです。

【プロジェクト】
ベース: Lunar-Scripts/lunar_fishing (GPL-3.0)
作業先: H:\CURSOR\Dev\fivem-mods_ja\jp-lunar_fishing\
リソース本体: 同上\lunar_fishing\

【必須ルール】
1. GPL-3.0 を継承する。LICENSE は維持しCHANGELOG.mdに改変履歴を書く。
2. アイテムキー(item_name)は英字ローマ字のまま。表示文字列のみ日本語化。
3. UI文字列は locales/ja.json。アイテムラベルは install/items_ox_ja.lua（および items_qb_ja.lua）の label に集約（ja.lua は不要）。
4. config.lua のハードコード英文（zone message等）も日本語化する。
5. ファイルは UTF-8 (BOMなし) で保存。Lua文字列内の日本語はそのままUTF-8でOK。
6. 元の en.json / de.json は削除せず保持する（フォールバック用）。

【作業順】
STEP1: ディレクトリとファイル雛形を作る
STEP2: locales/ja.json を作成（en.jsonの全キー翻訳）
STEP3: server.cfg に setr ox:locale ja を明記（ja.lua はスキップ）
STEP4: config/config.lua を日本魚種10種に書換え
STEP5: install/items_ox_ja.lua と install/items_qb_ja.lua を作成
STEP6: docs/IMAGE_PROMPTS.md を作成
STEP7: README / INSTALL_JA / CHANGELOG / CREDITS を作成
STEP8: fxmanifest.lua の version と description を更新

各STEP完了ごとに変更ファイルの一覧と差分要約を報告してください。
````

---

## 5. チェックリスト（リリース前）

- [ ] `locales/ja.json` の `%s` 数とプレースホルダ順が `en.json` と一致
- [ ] `config.lua` の `fishList` に存在する魚名が全て `Config.fish` に定義済み
- [ ] アイテム画像ファイル名が `item_name` と完全一致（拡張子小文字）
- [ ] `fxmanifest.lua` の version が `1.0.1-ja1`
- [ ] `LICENSE`（GPL-3.0全文）が `lunar_fishing/` と `jp-lunar_fishing/` 両方に存在
- [ ] `CHANGELOG.md` に改変日付と内容を記載
- [ ] `CREDITS.md` に原作者URL明記
- [ ] テストサーバーで `setr ox:locale ja` を設定し、釣り→売却→ボートレンタルの全フロー動作確認
- [ ] ox_inventory のアイコンが全種類表示される
- [ ] GitHub に push 済み、Releases 作成
