# 日本語化棚卸し（リストのみ・未翻訳）

集計（2026-05-08 時点・`jp-ps-housing` 直下のみ）:

| 区分 | 件数・備考 |
|------|------------|
| `Config.Furnitures` アイテム `label` | **886**（`docs/ja/_furniture_labels.tsv`） |
| 家具カテゴリ名 `category` | **16**（英語、TSV の第1列ユニーク） |
| `Config.Apartments` / `Config.Shells` の `label`（行ベース） | **約 89**（`shared/config.lua` 先頭ブロック、`label =` 行のうち家具テーブル外） |
| `locales/` | **なし**（ディレクトリ未同梱） |
| クライアント・サーバー通知文字列 | **約 55+**（動的連結除く・目視 grep ベース） |
| NUI 静的文言（`ui/src`） | **約 35〜45**（カテゴリ名・家具ラベルは上表と重複） |
| `html/index.js` | ビルド済みバンドル。**翻訳は `ui` を直し再ビルド**が正道 |

---

## `locales/`

- [ ] （英語ロケールファイルなし — 本リソースは Lua / NUI 直書きが中心）

---

## `shared/config.lua` — Apartments / Shells（`label`）

アパート名・シェル名・ギャラリー用 `label` の代表例（重複語は翻訳時に統一可）。

- [ ] Integrity Way → （日本語案: ）
- [ ] South Rockford Drive → （日本語案: ）
- [ ] Morningwood Blvd → （日本語案: ）
- [ ] Tinsel Towers → （日本語案: ）
- [ ] Fantastic Plaza → （日本語案: ）
- [ ] Modern 1 Apartment → （日本語案: ）
- [ ] Outside → （日本語案: ）
- [ ] Mlo → （日本語案: ）
- [ ] Motel → （日本語案: ）
- [ ] Standard Motel → （日本語案: ）
- [ ] Modern Hotel → （日本語案: ）
- [ ] Angle 1 / Angle 2 → （日本語案: ）
- [ ] Apartment Furnished / Apartment Unfurnished / Apartment 2 Unfurnished → （日本語案: ）
- [ ] Bathroom / Bedroom / Entrance / Kitchen / Kitchen and Dining / Living Room / Living Room Angle 1 / Living Room Angle 2 → （日本語案: ）
- [ ] Garage / Office / Store / Warehouse / Container / 2 Floor House / House 1 / House 2 / House 3 / House 4 / Trailer → （日本語案: ）
- [ ] Room 1 / Room 2 / Room 3 / Room 3 Dresser / Hallway / Main Area / Main / Room / Entrance and Kitchen / Entance（typo）→ （日本語案: ）

（省略: 残りは `shared/config.lua` の `Config.Apartments` / `Config.Shells` を開いて `label =` を順に確認）

---

## `shared/config.lua` — 家具カテゴリ名（`category`）

データ駆動でヘッダボタンに出るため、**英語のままならそのまま表示**されます。

- [ ] Prerequisites → （日本語案: ）
- [ ] Couches → （日本語案: ）
- [ ] Chairs → （日本語案: ）
- [ ] Beds → （日本語案: ）
- [ ] Tables → （日本語案: ）
- [ ] Storage → （日本語案: ）
- [ ] Electronics → （日本語案: ）
- [ ] Kitchen → （日本語案: ）
- [ ] Bathroom → （日本語案: ）
- [ ] Lighthing（原文スペル）→ （日本語案: ）
- [ ] Wall Decorations → （日本語案: ）
- [ ] Walls → （日本語案: ）
- [ ] Doors → （日本語案: ）
- [ ] Detailing → （日本語案: ）
- [ ] Plants → （日本語案: ）
- [ ] Misc → （日本語案: ）

### Furniture Labels（アイテム `label`）

全 **886** 行。マスタは TSV（カテゴリ TAB 英語ラベル）: `_furniture_labels.tsv`  
バッチ作業時は TSV をスプレッドシートに貼り、3列目に日本語案を足すと安全です。

サンプル（CSV 風・チェックリスト）:

- [ ] Prerequisites / Storage Unit → （日本語案: ）
- [ ] Prerequisites / Wardrobe → （日本語案: ）
- [ ] Couches / Old couch → （日本語案: ）
- [ ] Couches / Threesits couch → （日本語案: ）
- [ ] Couches / Old chair → （日本語案: ）
- [ ] Couches / corner sofa → （日本語案: ）
- [ ] Couches / White Couch → （日本語案: ）
- [ ] Couches / Black Couch → （日本語案: ）
- [ ] Chairs / High chair → （日本語案: ）
- [ ] Chairs / officeChair → （日本語案: ）
- [ ] Beds / … → （以下 `_furniture_labels.tsv` 参照）

---

## `shared/framework.lua`（ox / qb ターゲット・通知）

- [ ] Property（notify title）→ （日本語案: ）
- [ ] Enter Property → （日本語案: ）
- [ ] Showcase Property → （日本語案: ）
- [ ] Property Info → （日本語案: ）
- [ ] Ring Doorbell → （日本語案: ）
- [ ] Raid Property → （日本語案: ）
- [ ] Enter Apartment → （日本語案: ）
- [ ] See all apartments → （日本語案: ）
- [ ] Raid Apartment → （日本語案: ）
- [ ] Leave Property → （日本語案: ）
- [ ] Check Door → （日本語案: ）
- [ ] Leave → （日本語案: ）

---

## `shared/config.lua` — `Config.FurnitureTypes` ターゲットラベル

- [ ] Storage → （日本語案: ）
- [ ] Clothing → （日本語案: ）

---

## `client/*.lua` 通知・文言

- [ ] Your cart is empty → （日本語案: ）
- [ ] You don't have enough money! → （日本語案: ）
- [ ] Stash is not empty → （日本語案: ）
- [ ] You dont have an apartment here. → （日本語案: ）
- [ ] There are no apartments here. → （日本語案: ）
- [ ] Only the owner can do this. → （日本語案: ）
- [ ] Give Access → （日本語案: ）
- [ ] No one is in the property → （日本語案: ）
- [ ] Remove Access → （日本語案: ）
- [ ] No one has access to this property → （日本語案: ）
- [ ] No one is at the door → （日本語案: ）
- [ ] Luxury Apartments!（ブリップ説明）→ （日本語案: ）

---

## `server/*.lua` 通知（固定文の代表）

動的に `$` や名前・ID を埋め込む行は、翻訳テンプレ化が必要。

- [ ] Open radial menu for furniture menu and place down your stash and clothing locker. → （日本語案: ）
- [ ] You are already in this apartment / This person is already in this apartment → （日本語案: ）
- [ ] Your apartment is now at … → （日本語案: ）
- [ ] You have added … to apartment … → （日本語案: ）
- [ ] Player not found. → （日本語案: ）
- [ ] Someone is at the door. → （日本語案: ）
- [ ] You rang the doorbell. Just wait... → （日本語案: ）
- [ ] No one answered the door. → （日本語案: ）
- [ ] This Property is being Raided. → （日本語案: ）
- [ ] Go far away and come back for the door to update and open/close. → （日本語案: ）
- [ ] You already own this property / Client already owns this property → （日本語案: ）
- [ ] You did not confirm the purchase / Client did not confirm the purchase → （日本語案: ）
- [ ] You do not have enough money in your bank account / Client does not have enough money in their bank account → （日本語案: ）
- [ ] Sold Property: … → （日本語案: ）
- [ ] You have bought the property for $… / Client has bought the property for $… → （日本語案: ）
- [ ] Changed Apartment of property … / Changed Apartment to … → （日本語案: ）
- [ ] Property with id: … has been removed. → （日本語案: ）
- [ ] Raid started / Raid in progress → （日本語案: ）
- [ ] You need a stormram to perform a raid → （日本語案: ）
- [ ] Only police officers are permitted to perform raids → （日本語案: ）
- [ ] You must be onduty before performing a raid → （日本語案: ）
- [ ] You must be a higher rank before performing a raid → （日本語案: ）
- [ ] You do not have enough money! → （日本語案: ）
- [ ] You bought furniture for $… → （日本語案: ）
- [ ] You are not the owner of this property! → （日本語案: ）
- [ ] You added access to … / You got access to this property! / This person already has access… → （日本語案: ）
- [ ] You removed access from … / You lost access to … / This person does not have access… → （日本語案: ）

---

## NUI — `ui/src`（静的文言）

カテゴリ名・`furniture.label` は `config.lua` と共通。

- [ ] html `title`: ps-housing → （日本語案: ）
- [ ] Search（placeholder）→ （日本語案: ）
- [ ] All Objects → （日本語案: ）
- [ ] Search Results → （日本語案: ）
- [ ] Owned Furniture → （日本語案: ）
- [ ] YOUR SHOPPING CART → （日本語案: ）
- [ ] Price: → （日本語案: ）
- [ ] SUBTOTAL: → （日本語案: ）
- [ ] Purchase → （日本語案: ）
- [ ] Owned Items → （日本語案: ）
- [ ] Are you sure you want to exit? You have items in your cart. → （日本語案: ）
- [ ] No / Yes（確認ダイアログ共通）→ （日本語案: ）
- [ ] Are you sure you want to stop placing this current furniture? → （日本語案: ）
- [ ] You can only have ${n} of this item!（テンプレ）→ （日本語案: ）
- [ ] Reset Rotation / Reset Position → （日本語案: ）
- [ ] Translation Snap / Rotation Snap → （日本語案: ）
- [ ] Place On Ground → （日本語案: ）
- [ ] Object Alpha → （日本語案: ）
- [ ] Stop Placement → （日本語案: ）
- [ ] Add To Cart → （日本語案: ）

---

## 次の一手（効率）

1. **NUI（`ui/src`）+ `shared/framework.lua` の短いラベル** — ユーザーに最も見える面が早い。  
2. **`server` / `client` の Notify 文** — 件数は中程度だがゲームプレイ中頻出。  
3. **`Config.Furnitures` 886 行** — ボリューム最大。TSV で一括し、最後に `config.lua` へ反映するか、将来ロケール層に逃がす設計を検討。
