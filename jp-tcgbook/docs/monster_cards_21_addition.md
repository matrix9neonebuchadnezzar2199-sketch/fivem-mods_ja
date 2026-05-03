# CURSOR 作業指示書: モンスターカード 21 枚の追加と name/description 生成

## 実装メモ（コード側の確定事項）

- **`type` フィールド**: 現行のデッキ検証・コレクション UI は **`shitei` / `free`** のみ解釈する。指示書の `type = 'monster'` はエンジン未対応のため、追加 21 枚は **UR・SS → `shitei`、S〜C → `free`** とする。モンスター系の識別は **`card_id` の `tcg_m_*` プレフィックス**で行う。
- **`fxmanifest.lua`**: `'html/assets/cards/**/*.jpg'` を追加し、`character/`・`monster/` の JPG を配布パッケージに含める。

---

## 背景

新規にモンスター系カード 21 枚を追加する。画像は自作 AI 生成（MIT 配布可）で、`H:\CURSOR\Dev\jp-tcgbook\html\assets\cards\monster\` にランダム英数字名（例: `1gbBX4lQ.jpg`）で配置済み。`shared/cards.lua` には新規 21 件のエントリを追加し、`name` / `name_en` / `description` / `description_en` を画像のキャラクター設定に合わせて生成する。`card_id` は `tcg_m_*` プレフィックスで命名空間を分離。既存 20 件（`character/` 配下）には一切変更を加えない。

## 前提条件

- 新画像 21 枚は `html/assets/cards/monster/` に AI 生成のランダム英数ファイル名（`.jpg` 形式、白背景）で配置済み。
- 既存 20 件のキャラクターカードは `html/assets/cards/character/` に配置済み（前回作業で完了）。
- 旧 cogabushi 様素材は前回作業で `git filter-repo` 履歴削除済み。**今回は履歴削除作業は不要**。
- `monster/` 配下は今回が初コンテンツ投入。すべて自作のため通常コミットで OK。
- card_id プレフィックス `tcg_m_*` を新規導入し、既存キャラ系（`tcg_ur_*`, `tcg_ss_*`, `tcg_s_*`, `tcg_a_*`, `tcg_b_*`, `tcg_c_*`）と名前空間を分離する。
- ランク配分: UR 2 / SS 3 / S 4 / A 5 / B 4 / C 3 = 21 枚。
- `no` 番号は既存 20 の続きで 21〜41。

## 作業内容

### Step 1: 画像ファイルのリネームと配置

`html/assets/cards/monster/` 内の 21 枚を、card_id に対応するファイル名にリネームする。**拡張子は `.jpg` のまま維持**（PNG 変換不要）。

リネーム後のファイル名は以下の 21 個になる:

```
tcg_m_ur_reaper.jpg
tcg_m_ur_moon_goddess.jpg
tcg_m_ss_thunder_god.jpg
tcg_m_ss_phoenix.jpg
tcg_m_ss_sea_goddess.jpg
tcg_m_s_sun_priest.jpg
tcg_m_s_pharaoh_mummy.jpg
tcg_m_s_dark_witch.jpg
tcg_m_s_forest_spirit.jpg
tcg_m_a_demon_warlord.jpg
tcg_m_a_blood_berserker.jpg
tcg_m_a_flame_valkyrie.jpg
tcg_m_a_medusa.jpg
tcg_m_a_minotaur.jpg
tcg_m_b_stone_golem.jpg
tcg_m_b_war_bear.jpg
tcg_m_b_werewolf.jpg
tcg_m_b_crystal_golem.jpg
tcg_m_c_carrion_raven.jpg
tcg_m_c_armored_slime.jpg
tcg_m_c_rot_zombie.jpg
```

**画像とファイル名の対応はユーザーが目視判断する**。CURSOR 側で自動判定はしない。ユーザーがファイラーで 1 枚ずつリネームするのを待つこと。リネーム完了後、ユーザーから「リネーム完了」の合図を受けてから Step 2 に進む。

参考として、画像特徴と card_id のマッピングを再掲：

| 画像特徴 | ファイル名 |
|---------|-----------|
| 黒髪・大鎌・紫炎の死神司祭 | `tcg_m_ur_reaper.jpg` |
| 銀髪・三日月冠・月杖の月女神 | `tcg_m_ur_moon_goddess.jpg` |
| 白髭・黄金鎧・雷鎚の雷神 | `tcg_m_ss_thunder_god.jpg` |
| 炎翼・黒鎧・鎖装飾の不死鳥 | `tcg_m_ss_phoenix.jpg` |
| 水髪・サンゴ三叉戟の海女神 | `tcg_m_ss_sea_goddess.jpg` |
| 金髪・金鎧・炎槍の太陽神官 | `tcg_m_s_sun_priest.jpg` |
| ファラオ頭飾り・アンク杖のミイラ | `tcg_m_s_pharaoh_mummy.jpg` |
| 黒髪・角・髑髏杖の闇魔女 | `tcg_m_s_dark_witch.jpg` |
| 緑髪・花冠・蔦杖の森精 | `tcg_m_s_forest_spirit.jpg` |
| 赤肌・巻角・双刃槍の魔将 | `tcg_m_a_demon_warlord.jpg` |
| 双剣・烏旗・赤鎧の戦鬼 | `tcg_m_a_blood_berserker.jpg` |
| 赤髪・双炎刀・紅鎧の戦姫 | `tcg_m_a_flame_valkyrie.jpg` |
| 蛇髪・緑ドレス・曲刀のメドゥーサ | `tcg_m_a_medusa.jpg` |
| 黒角・棘鎧・両手戦斧の牛頭 | `tcg_m_a_minotaur.jpg` |
| 苔生し・青ルーン・巨大の石巨人 | `tcg_m_b_stone_golem.jpg` |
| 骨鎧・赤戦化粧の戦熊 | `tcg_m_b_war_bear.jpg` |
| 灰毛・革ベルト・傷跡の人狼 | `tcg_m_b_werewolf.jpg` |
| 青紫結晶・胸の核の結晶巨人 | `tcg_m_b_crystal_golem.jpg` |
| 黒羽・赤眼・皮装具のカラス人 | `tcg_m_c_carrion_raven.jpg` |
| 緑スライム・錆鉄鎧片 | `tcg_m_c_armored_slime.jpg` |
| 緑灰肌・腫物・垂れ腕のゾンビ | `tcg_m_c_rot_zombie.jpg` |

### Step 2: shared/cards.lua への 21 件追加

`shared/cards.lua` の既存 20 件の末尾に、以下の 21 件を**新規追加**する。**既存エントリは一切変更しない**こと。

（各カードの `name` / `name_en` / `description` / `description_en` / `stat_*` / `no` / `image_path` はチャットで共有した仕様書どおり。実装では **`type` を `shitei`（UR・SS）または `free`（S〜C）にマッピング**する。）

#### 注意事項

既存 20 件は一切変更しないこと。`tcg_m_*` プレフィックスは新規追加なので、`shared/cards.lua` の末尾に追記する形で OK。

`description` は既存の `Database.UpsertAllCards` で DB に反映される。実機反映には Step 4 が必要。

### Step 3: fxmanifest.lua への files エントリ追加

`files` に **`html/assets/cards/**/*.jpg`** を追加する（`monster/`・`character/` 両方をカバー）。

### Step 4: 動作確認用の Config 一時変更

実機で新しい 21 件のカードを反映させるため、`config.lua` で `Config.SeedCardsFromLua` を `true` に変更する。**作業完了後に必ず元の `false` に戻す**。

### Step 5: コミット

**Commit A**: 画像追加（Step 1 完了後）  
**Commit B**: `shared/cards.lua` + `fxmanifest.lua`（Step 2–3）  
**Commit C**: `SeedCardsFromLua` 一時 true → 検証後 false に戻す別コミット  

### Step 6: プッシュと確認

通常の `git push`。今回は **`git filter-repo` 不要**。

## 完了条件

- [ ] `html/assets/cards/monster/` に `tcg_m_*.jpg` 21 枚配置（リネーム済み）
- [ ] `shared/cards.lua` に 21 件追加（既存 20 件は変更なし）
- [ ] `fxmanifest.lua` の files に JPG ワイルドカードが含まれる
- [ ] `Config.SeedCardsFromLua = true` で再起動 → `/book` で確認
- [ ] `Config.SeedCardsFromLua = false` に戻して再コミット
- [ ] `git push` 完了

## 想定所要時間

合計約 50 分。

## 失敗時のロールバック

`git revert` または個別ファイル復元。DB は `SeedCardsFromLua = true` で UPSERT 再実行で修正可能。

## 次のステップ（M7 以降）

stats バランス、`tcg_m_*` フィルタ UI、モンスター専用ルール等は別マイルストーンで検討。
