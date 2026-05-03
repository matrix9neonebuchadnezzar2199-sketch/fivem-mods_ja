# CURSOR 作業指示書: モンスターカード 21 枚の追加と name/description 生成

## 実装メモ（コード側の確定事項）

- **`type` フィールド**: 現行のデッキ検証・コレクション UI は **`shitei` / `free`** のみ解釈する。下記 Step 2 の **`type: monster` は論理仕様の表記**であり、`shared/cards.lua` 実装では **UR・SS → `shitei`、S〜C → `free`** にマッピング済み。モンスター系の識別は **`card_id` の `tcg_m_*` プレフィックス**で行う。
- **`fxmanifest.lua`**: `'html/assets/cards/**/*.jpg'` を追加済み（`character/`・`monster/` 両方）。
- **リポジトリ**: `shared/cards.lua` の 21 件追記と上記 `fxmanifest` はコミット **`58a6323`** で反映済み。残作業は主に **Step 1（画像リネーム）**・**Commit A（画像コミット）**・**Step 4（Seed 一時 ON と検証）**。

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

**画像とファイル名の対応はユーザーが目視判断する**。CURSOR 側で自動判定はしない。リネーム後に **Commit A（画像のみ）** を行う。**Lua / fxmanifest はコミット `58a6323` で先行済みなら Step 2〜3 の実装作業は不要**（追記・差し替えがあればそのときだけ Step 2 を参照）。

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

各ブロックの **`type: monster` は論理仕様の表記**。リポジトリ実装では **UR・SS → `shitei`、S〜C → `free`**（デッキ／コレクション UI 互換）。

#### 追加内容（21 件）

##### 21. tcg_m_ur_reaper (UR)

- card_id: `tcg_m_ur_reaper`
- rank: `UR`
- type: `monster`（実装: `shitei`）
- stat_top: 9, stat_right: 8, stat_bottom: 9, stat_left: 9
- no: 21
- image_path: `assets/cards/monster/tcg_m_ur_reaper.jpg`
- name: `冥府の死神司祭ターナトス`
- name_en: `Thanatos, High Priest of the Underworld`
- description: `紫炎を纏う大鎌で魂を刈り取る冥府の使徒。彼の通った跡には霊魂すら残らない。`
- description_en: `An emissary of the underworld who reaps souls with a violet-flamed scythe. Not even spirits remain in his wake.`

##### 22. tcg_m_ur_moon_goddess (UR)

- card_id: `tcg_m_ur_moon_goddess`
- rank: `UR`
- type: `monster`（実装: `shitei`）
- stat_top: 9, stat_right: 9, stat_bottom: 8, stat_left: 8
- no: 22
- image_path: `assets/cards/monster/tcg_m_ur_moon_goddess.jpg`
- name: `月夜の女神セレネ`
- name_en: `Selene, Goddess of the Moonlit Night`
- description: `三日月の冠を戴き、銀の月杖で潮汐と夢を司る女神。月光の下で全ての傷は癒される。`
- description_en: `A goddess crowned with the crescent, ruling tides and dreams with her silver moon-staff. All wounds are healed beneath her moonlight.`

##### 23. tcg_m_ss_thunder_god (SS)

- card_id: `tcg_m_ss_thunder_god`
- rank: `SS`
- type: `monster`（実装: `shitei`）
- stat_top: 9, stat_right: 7, stat_bottom: 7, stat_left: 7
- no: 23
- image_path: `assets/cards/monster/tcg_m_ss_thunder_god.jpg`
- name: `雷霆神トールヴァル`
- name_en: `Thorvall, God of Thunder`
- description: `白髭をなびかせ黄金鎧を纏う雷神。振り下ろす雷鎚は山を割り、嵐を呼ぶ。`
- description_en: `A thunder god in golden armor with a billowing white beard. His descending hammer cleaves mountains and summons storms.`

##### 24. tcg_m_ss_phoenix (SS)

- card_id: `tcg_m_ss_phoenix`
- rank: `SS`
- type: `monster`（実装: `shitei`）
- stat_top: 8, stat_right: 8, stat_bottom: 7, stat_left: 7
- no: 24
- image_path: `assets/cards/monster/tcg_m_ss_phoenix.jpg`
- name: `鎖縛の不死鳥イグニス`
- name_en: `Ignis, the Chained Phoenix`
- description: `黒鎧と鎖で力を封じられた炎の霊鳥。死しても灰から蘇り、千年の業火を撒き散らす。`
- description_en: `A flame-spirit bird whose power is sealed by black armor and chains. Though slain, she rises from ashes to scatter a thousand-year inferno.`

##### 25. tcg_m_ss_sea_goddess (SS)

- card_id: `tcg_m_ss_sea_goddess`
- rank: `SS`
- type: `monster`（実装: `shitei`）
- stat_top: 7, stat_right: 8, stat_bottom: 7, stat_left: 8
- no: 25
- image_path: `assets/cards/monster/tcg_m_ss_sea_goddess.jpg`
- name: `珊瑚の海神アクアリーネ`
- name_en: `Aquarine, Goddess of the Coral Seas`
- description: `珊瑚の冠と貝殻の鎧を纏い、サンゴ三叉戟で潮流を操る海の女神。船乗りの祈りを聞き届ける。`
- description_en: `A sea goddess in coral crown and shell armor, commanding currents with her coral trident. She heeds the prayers of sailors.`

##### 26. tcg_m_s_sun_priest (S)

- card_id: `tcg_m_s_sun_priest`
- rank: `S`
- type: `monster`（実装: `free`）
- stat_top: 8, stat_right: 6, stat_bottom: 7, stat_left: 7
- no: 26
- image_path: `assets/cards/monster/tcg_m_s_sun_priest.jpg`
- name: `黄金の太陽神官ソルアレス`
- name_en: `Solares, Priest of the Golden Sun`
- description: `黄金の鎧と白マントを纏い炎槍を掲げる神官。彼が槍を天に向ければ太陽が応える。`
- description_en: `A priest in golden armor and white mantle, raising a flame-spear. When he points it skyward, the sun answers his call.`

##### 27. tcg_m_s_pharaoh_mummy (S)

- card_id: `tcg_m_s_pharaoh_mummy`
- rank: `S`
- type: `monster`（実装: `free`）
- stat_top: 7, stat_right: 7, stat_bottom: 7, stat_left: 6
- no: 27
- image_path: `assets/cards/monster/tcg_m_s_pharaoh_mummy.jpg`
- name: `古王国のファラオ・ミイラ`
- name_en: `Pharaoh Mummy of the Old Kingdom`
- description: `青き炎の眼でアンク杖を握る王のミイラ。聖刻文字の呪いは三千年の時を超えて生者を縛る。`
- description_en: `A royal mummy with eyes of blue flame, gripping an ankh-staff. His hieroglyphic curse binds the living across three millennia.`

##### 28. tcg_m_s_dark_witch (S)

- card_id: `tcg_m_s_dark_witch`
- rank: `S`
- type: `monster`（実装: `free`）
- stat_top: 8, stat_right: 7, stat_bottom: 6, stat_left: 6
- no: 28
- image_path: `assets/cards/monster/tcg_m_s_dark_witch.jpg`
- name: `暗黒の角持ち魔女モルガナ`
- name_en: `Morgana, the Horned Dark Witch`
- description: `黒髪に角を生やし髑髏杖を振るう魔女。紫炎の呪文は敵の影を縫い止め、抜け出させない。`
- description_en: `A witch with black hair and horns, brandishing a skull-staff. Her violet-flame hex pins enemies by their own shadows.`

##### 29. tcg_m_s_forest_spirit (S)

- card_id: `tcg_m_s_forest_spirit`
- rank: `S`
- type: `monster`（実装: `free`）
- stat_top: 6, stat_right: 7, stat_bottom: 7, stat_left: 8
- no: 29
- image_path: `assets/cards/monster/tcg_m_s_forest_spirit.jpg`
- name: `深森の樹霊フローラ`
- name_en: `Flora, Spirit of the Deep Forest`
- description: `緑髪に花冠、蝶を従える森の精霊。彼女が踏みしめた地には一夜で花が咲き乱れる。`
- description_en: `A forest spirit with green hair, a flower crown, and butterflies in her train. Where she steps, blossoms bloom in a single night.`

##### 30. tcg_m_a_demon_warlord (A)

- card_id: `tcg_m_a_demon_warlord`
- rank: `A`
- type: `monster`（実装: `free`）
- stat_top: 7, stat_right: 6, stat_bottom: 6, stat_left: 5
- no: 30
- image_path: `assets/cards/monster/tcg_m_a_demon_warlord.jpg`
- name: `赤肌の魔将バルガス`
- name_en: `Balgus, the Crimson Warlord`
- description: `巻角と赤い肌を持つ魔族の将。双刃槍の一撃は鋼鎧を紙のように切り裂く。`
- description_en: `A demon warlord with curling horns and crimson skin. A single strike of his double-bladed glaive shears steel armor like paper.`

##### 31. tcg_m_a_blood_berserker (A)

- card_id: `tcg_m_a_blood_berserker`
- rank: `A`
- type: `monster`（実装: `free`）
- stat_top: 7, stat_right: 5, stat_bottom: 5, stat_left: 5
- no: 31
- image_path: `assets/cards/monster/tcg_m_a_blood_berserker.jpg`
- name: `血染めの戦鬼ガルム`
- name_en: `Garm, the Blood-Soaked Berserker`
- description: `烏旗を背負い双剣で踊るように戦う狂戦士。返り血を浴びるほど剣速が増す。`
- description_en: `A berserker who dances with twin blades beneath a raven banner. The more blood he is bathed in, the faster his swords become.`

##### 32. tcg_m_a_flame_valkyrie (A)

- card_id: `tcg_m_a_flame_valkyrie`
- rank: `A`
- type: `monster`（実装: `free`）
- stat_top: 7, stat_right: 6, stat_bottom: 5, stat_left: 5
- no: 32
- image_path: `assets/cards/monster/tcg_m_a_flame_valkyrie.jpg`
- name: `紅蓮の戦姫イグニフィア`
- name_en: `Ignifia, the Crimson Valkyrie`
- description: `赤髪と紅鎧を纏い双炎刀を振るう戦姫。彼女の通った戦場は灰しか残らない。`
- description_en: `A valkyrie in crimson armor with flowing red hair, wielding twin flame-blades. Only ashes remain on the battlefield she crosses.`

##### 33. tcg_m_a_medusa (A)

- card_id: `tcg_m_a_medusa`
- rank: `A`
- type: `monster`（実装: `free`）
- stat_top: 6, stat_right: 6, stat_bottom: 5, stat_left: 6
- no: 33
- image_path: `assets/cards/monster/tcg_m_a_medusa.jpg`
- name: `蛇髪の魔女メデューサ`
- name_en: `Medusa, the Serpent-Haired Witch`
- description: `蛇の髪を蠢かせ青銅の曲刀を持つ呪われた美女。その眼を見た者は石となる。`
- description_en: `A cursed beauty with writhing serpents for hair, gripping a bronze curved blade. Those who meet her gaze are turned to stone.`

##### 34. tcg_m_a_minotaur (A)

- card_id: `tcg_m_a_minotaur`
- rank: `A`
- type: `monster`（実装: `free`）
- stat_top: 7, stat_right: 5, stat_bottom: 6, stat_left: 4
- no: 34
- image_path: `assets/cards/monster/tcg_m_a_minotaur.jpg`
- name: `迷宮の牛頭ミノタウロス`
- name_en: `Minotaur of the Labyrinth`
- description: `黒角と棘鎧を纏い両手戦斧を振るう半人半牛の怪物。怒れば迷宮の壁すら砕く。`
- description_en: `A half-bull beast in black horns and spiked armor, wielding a great battle-axe. In rage, even the labyrinth walls shatter before him.`

##### 35. tcg_m_b_stone_golem (B)

- card_id: `tcg_m_b_stone_golem`
- rank: `B`
- type: `monster`（実装: `free`）
- stat_top: 4, stat_right: 5, stat_bottom: 6, stat_left: 6
- no: 35
- image_path: `assets/cards/monster/tcg_m_b_stone_golem.jpg`
- name: `古代遺跡のストーンゴーレム`
- name_en: `Ancient Ruin Stone Golem`
- description: `苔生した岩肌に青いルーンを刻まれた巨人。命令を忘れ、千年遺跡を守り続ける。`
- description_en: `A giant of mossy stone inscribed with glowing blue runes. Long having forgotten its orders, it has guarded the ruins for a thousand years.`

##### 36. tcg_m_b_war_bear (B)

- card_id: `tcg_m_b_war_bear`
- rank: `B`
- type: `monster`（実装: `free`）
- stat_top: 6, stat_right: 4, stat_bottom: 5, stat_left: 4
- no: 36
- image_path: `assets/cards/monster/tcg_m_b_war_bear.jpg`
- name: `戦化粧の熊神獣ウルサ`
- name_en: `Ursa, the War-Painted Bear-Beast`
- description: `骨鎧と赤い戦化粧を纏う熊の神獣。北方部族の守護獣として崇められる。`
- description_en: `A divine bear-beast in bone armor and red war-paint. The northern tribes revere her as their guardian beast.`

##### 37. tcg_m_b_werewolf (B)

- card_id: `tcg_m_b_werewolf`
- rank: `B`
- type: `monster`（実装: `free`）
- stat_top: 5, stat_right: 5, stat_bottom: 4, stat_left: 4
- no: 37
- image_path: `assets/cards/monster/tcg_m_b_werewolf.jpg`
- name: `満月の人狼ファング`
- name_en: `Fang, the Full-Moon Werewolf`
- description: `灰毛に革ベルト、無数の傷跡を持つ獣人。満月の夜のみ理性を失い、最も速くなる。`
- description_en: `A beastman of grey fur, leather harness, and countless scars. Only on full-moon nights does he lose reason and become his swiftest.`

##### 38. tcg_m_b_crystal_golem (B)

- card_id: `tcg_m_b_crystal_golem`
- rank: `B`
- type: `monster`（実装: `free`）
- stat_top: 4, stat_right: 5, stat_bottom: 5, stat_left: 5
- no: 38
- image_path: `assets/cards/monster/tcg_m_b_crystal_golem.jpg`
- name: `蒼晶の核ゴーレム`
- name_en: `Azure Crystal Core Golem`
- description: `胸の青き核から虹色の光を放つ結晶巨人。砕かれた破片すら攻撃する意志を持つ。`
- description_en: `A crystal golem emitting rainbow light from the azure core in its chest. Even its shattered shards retain the will to attack.`

##### 39. tcg_m_c_carrion_raven (C)

- card_id: `tcg_m_c_carrion_raven`
- rank: `C`
- type: `monster`（実装: `free`）
- stat_top: 4, stat_right: 4, stat_bottom: 3, stat_left: 3
- no: 39
- image_path: `assets/cards/monster/tcg_m_c_carrion_raven.jpg`
- name: `腐肉漁りの大鴉人`
- name_en: `Carrion-Feasting Ravenfolk`
- description: `赤く濁った眼と皮革の装具を身に着けた鴉人。死体の山を漁って生きる墓場の守人。`
- description_en: `A ravenfolk with cloudy red eyes and leather harness. He scavenges among corpses, a graveyard's unwelcome custodian.`

##### 40. tcg_m_c_armored_slime (C)

- card_id: `tcg_m_c_armored_slime`
- rank: `C`
- type: `monster`（実装: `free`）
- stat_top: 3, stat_right: 3, stat_bottom: 4, stat_left: 4
- no: 40
- image_path: `assets/cards/monster/tcg_m_c_armored_slime.jpg`
- name: `錆鎧をまとった巨大スライム`
- name_en: `Rust-Armored Greater Slime`
- description: `戦死者の錆びた鎧片を体内に取り込んだ緑色の粘体。柔らかい体は刃を弾き、鎧片は牙となる。`
- description_en: `A green ooze that has absorbed the rusted armor of fallen warriors. Its soft body deflects blades while the armor shards become its fangs.`

##### 41. tcg_m_c_rot_zombie (C)

- card_id: `tcg_m_c_rot_zombie`
- rank: `C`
- type: `monster`（実装: `free`）
- stat_top: 3, stat_right: 3, stat_bottom: 4, stat_left: 3
- no: 41
- image_path: `assets/cards/monster/tcg_m_c_rot_zombie.jpg`
- name: `腐肉の屍喰鬼ロット`
- name_en: `Rot, the Putrid Ghoul`
- description: `緑灰の腐肉と腫物だらけの屍。垂れ下がった腕で獲物を引き寄せ、伝染性の毒を撒き散らす。`
- description_en: `A corpse covered in green-grey rot and pustules. With his dangling arms he drags victims close, spreading contagious venom.`

#### 注意事項

- 既存 20 件は一切変更しないこと。`tcg_m_*` は末尾に追記。
- `type` をエンジンに **`monster` として追加する改修**は将来オプション（コレクションの「モンスターのみ」フィルタ等）。現状は **`card_id` プレフィックス**で識別する。
- `description` は `Database.UpsertAllCards` で DB に反映される。実機反映には Step 4（`SeedCardsFromLua = true` → 検証後 `false`）が必要。

### Step 3: fxmanifest.lua への files エントリ追加

`files` に **`html/assets/cards/**/*.jpg`** を追加する（`monster/`・`character/` を一括カバー）。**既に含まれていれば追加不要**。

### Step 4: 動作確認用の Config 一時変更

実機で新しい 21 件をマスタに反映するため、`config.lua` で **`Config.SeedCardsFromLua = true`** にする。**検証後は必ず `false` に戻す**。

```lua
-- 一時的に true（マスタ更新後 false に戻すこと）
Config.SeedCardsFromLua = true
```

サーバー再起動後、`/book` で **21 枚がコレクションに出ること・画像ロード・JA/EN 文言**を目視確認する。

### Step 5: コミット

**Commit A: 画像（Step 1 完了後）**

```
feat(jp-tcgbook): add 21 monster card illustrations
- Add 21 self-generated monster artworks under html/assets/cards/monster/
- All images licensed under MIT (AI-assisted generation)
- Filenames follow tcg_m_<rank>_<slug>.jpg convention
```

**Commit B: Lua + fxmanifest（Step 2–3）** — *先行済みなら省略*

```
feat(jp-tcgbook): add 21 monster card entries to cards.lua
- Append tcg_m_* entries (UR×2, SS×3, S×4, A×5, B×4, C×3)
- Logical "monster" line; deck engine uses shitei/free mapping
- fxmanifest: html/assets/cards/**/*.jpg
- Card no 21–41
```

**Commit C: Seed 一時 ON**

```
chore(jp-tcgbook): temporarily enable SeedCardsFromLua for monster cards refresh
```

検証後、`SeedCardsFromLua = false` に戻して:

```
chore(jp-tcgbook): restore SeedCardsFromLua=false after monster cards seeded
```

### Step 6: プッシュと確認

```powershell
git push origin main
```

**今回は `git filter-repo` 不要**（自作画像のみ）。GitHub で画像コミットと差分を目視確認。

## 完了条件

- [ ] `html/assets/cards/monster/` に `tcg_m_*.jpg` 21 枚（リネーム済み）
- [ ] `shared/cards.lua` に 21 件追加（既存 20 件は変更なし）※`58a6323` 済ならチェックのみ
- [ ] `fxmanifest.lua` に JPG グロブが含まれる
- [ ] `Config.SeedCardsFromLua = true` で再起動 → `/book` で表示・画像・name/description 確認
- [ ] `Config.SeedCardsFromLua = false` に戻して再コミット
- [ ] `git push` 完了

## 想定所要時間

- Step 1（リネーム）: 約 20 分
- Step 2（cards.lua）: 約 10 分（済なら 0）
- Step 3（fxmanifest）: 約 2 分（済なら 0）
- Step 4（Config + 確認）: 約 10 分
- Step 5–6（コミット・push）: 約 10 分  

合計約 50 分（先行実装済みなら Step 1 + Seed + push のみで短縮）。

## 失敗時のロールバック

```powershell
git revert <Commit B のハッシュ>
```

画像のみやり直す場合:

```powershell
git revert <Commit A のハッシュ>
# または
git checkout HEAD~1 -- jp-tcgbook/html/assets/cards/monster/
```

DB は `SeedCardsFromLua = true` のまま `cards.lua` を直して再起動すれば UPSERT で上書き可能。

## 次のステップ（M7 以降）

stats 調整、`type`/フィルタ UI（モンスターのみ表示）、モンスター専用デッキルール、ドロップ等は別マイルストーンで検討。今回はカード追加と表示確認まで。
