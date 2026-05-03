# カードマスタ命名・i18n規約（jp-tcgbook）

将来カードを増やすときは **このファイルと `shared/cards.lua` 先頭コメント** を必ず参照する。

## 識別子・ファイル割当

- **`card_id`**: `tcg_{ランク小文字}_{スラッグ}`（例: `tcg_ur_antares`, `tcg_c_slime`）。既存 ID と重複しないこと。
- **`image_path`**: NUI 基準で `html/` からの相対。実体は `html/assets/cards/{character|monster}/`。
- **番号割当（20 枚時点の慣例）**: 人物・英雄寄り `tcg_ch_001`〜`010`、モンスター寄り `tcg_m_001`〜`010`。素材差し替え時は **番号と rank/type の対応だけ維持**すればよい。

## テキストフィールド（必須）

| フィールド | 用途 |
|-----------|------|
| `name` | 日本語カード名（マスタ・既定表示） |
| `name_en` | 英語カード名（**BOOK の言語が EN のとき**・DB `tcg_cards_master.name_en` にシード） |
| `description` | 日本語フレーバーテキスト |
| `description_en` | 英語フレーバーテキスト（トーンは `name_en` と揃え、ファンタジー TCG 向けの自然な英語） |

- **`description_en` が既にあるカードでは、`name_en` は同じトーン・レジスタで揃える**（直訳より TCG としての聞こえよさを優先）。
- 英語名のスタイル判断（例）:
  - 「鬼」→ **`Oni`** は日本産 TCG の個性として許容。**`Demon`** でもよい。
  - 「アンタレス」→ 実在天体名 **`Antares`** を維持し、肩書で「覇星」を補う（例: `Antares the Sovereign Star`）。
- 代替案のメモ（差し替え時の参考）:
  - `Silverwing Paladin` ↔ `Silver Spirit Knight`（銀翼 vs 銀霊の読み取り）
  - `Witchfire Holy Moth` ↔ `Phosphor Holy Moth`（燐火の言い換え）
  - `Antares the Sovereign Star` ↔ `Antares the Conqueror`（短縮）

## 現在マスタの `name_en` 一覧（20 種・叩き台）

| card_id | name（JA） | name_en |
|---------|------------|---------|
| tcg_ur_antares | 覇星アンタレス | Antares the Sovereign Star |
| tcg_ur_void_edge | 虚空の刃鬼 | Void Blade Oni |
| tcg_ss_silver_knight | 銀翼の聖騎士 | Silverwing Paladin |
| tcg_ss_moon_sage | 月虹の賢者 | Moonbow Sage |
| tcg_s_flame_fist | 烈火の拳士 | Blazing Pugilist |
| tcg_s_aqua_shield | 深水の盾艇 | Deepwater Bulwark |
| tcg_s_wind_runner | 疾風の斥候 | Galewind Scout |
| tcg_s_stone_wall | 磐石の守人 | Bedrock Warden |
| tcg_a_iron_spike | 鉄棘の番人 | Iron Thorn Sentinel |
| tcg_a_shadow_cat | 影歩きの猫盗賊 | Shadowstep Cat Thief |
| tcg_a_holy_moth | 燐火の聖蛾 | Witchfire Holy Moth |
| tcg_a_rust_golem | 錆鉄の小ゴーレム | Rustiron Golemling |
| tcg_b_moss_sprite | 苔森のスプライト | Mossgrove Sprite |
| tcg_b_cave_bat | 洞窟コウモリ | Cavern Bat |
| tcg_b_mud_frog | 泥沼ガエル | Mire Frog |
| tcg_b_coal_imp | 炭坑インプ | Colliery Imp |
| tcg_c_slime | 緋衣の吟遊詩人 | Crimson Troubadour |
| tcg_c_rat | 紺鉄の若侍 | Indigo Steel Samurai |
| tcg_c_mushroom | 翠瓶の錬金術師 | Emerald Flask Alchemist |
| tcg_c_ghost_jelly | 碧珀の獅子騎士 | Sapphire Lion Knight |

## DB・UPSERT（実装時の確定方針）

**`tcg_cards_master`**

```sql
ALTER TABLE tcg_cards_master ADD COLUMN name_en VARCHAR(64) DEFAULT NULL AFTER name;
```

**`tcg_players`**

```sql
ALTER TABLE tcg_players ADD COLUMN display_name VARCHAR(64) DEFAULT NULL;
```

- 既存サーバーを壊さないため、**`Database.ApplyOptionalSchemaPatches`** で duplicate を無視できる形の `ALTER` を発行する。
- 新規 **`install.sql`** では、`name VARCHAR(64) NOT NULL` の直後に `name_en`、`pvp_win_streak ... DEFAULT 0` の直後に `display_name` を追加する。
- **`UpsertAllCards`** の `INSERT ... ON DUPLICATE KEY UPDATE` に **`name_en`** を含める。

## ランキング表示名（関連）

- セレクト系は **`display_name`** を返す。ペイロードでは **`display_name` が NULL のとき**ライセンス等から短いフォールバックを組み立てる（詳細は実装時に `server/main.lua` / `shared/identity.lua`）。
- プレイヤー表示名の取得は **`GetPlayerDisplayName(src)`**（フレームワークは optional・Standalone は `GetPlayerName` 系）で統一し、`openBook`・対戦終了フローなどで **`UpsertPlayerDisplayName`** を呼ぶ。

## UI（関連）

- ランキング Name 列: **`display_name`** をエスケープして表示。長い名前は **マーキー（約 15s 一周）** で overflow のみアニメーション（ホバーで一時停止）。
- コレクション・履歴のカード名: UI 言語に応じて **`name` / `name_en`** を切り替え（マスタまたは DB から渡された値を使用）。

## 新規カード追加チェックリスト

1. `shared/cards.lua` に `card_id`, `name`, **`name_en`**, `rank`, `type`, ステータス, `image_path`, `description`, **`description_en`**, `no` を追加。
2. 画像を `html/assets/cards/...` に配置し、`fxmanifest.lua` の `files` に必要なら追加。
3. DB UPSERT 経路で `name_en` が流れることを確認（起動ログまたは DB 直接確認）。
4. BOOK で JA/EN 切替しカード名・説明が期待どおりか確認。

---

更新履歴: 2026-05-03 — 命名・`name_en` 一覧・DB/UI 方針を文書化。
