# CURSOR 作業指示書: カードアート全 20 枚の差し替えと name/description 再生成

## 背景

旧カード画像は BOOTH 購入素材（cogabushi 様）を使用していたが、利用規約上の懸念により全 20 枚を自作 AI 生成画像に差し替える。同時に `shared/cards.lua` の `name` / `name_en` / `description` / `description_en` を画像のキャラクター設定に合わせて再生成する。`stat_top` / `stat_right` / `stat_bottom` / `stat_left` / `rank` / `type` / `card_id` / `no` は既存値を維持（ゲームバランス維持のため）。

## 前提条件

- 新画像 20 枚は `H:\CURSOR\Dev\jp-tcgbook\html\assets\cards\character\` に AI 生成のランダム英数ファイル名（例: `1O7ysQ8d.jpg`）で配置済み。
- すべて `.jpg` 形式、白背景、人物半身〜全身のキャラクターアート。
- `monster/` ディレクトリは将来のモンスター追加用に**保持する**（今回は変更しない）。
- 既存 `shared/cards.lua` には `tcg_a_rust_golem` 以下 9 枚に `assets/cards/monster/...` の image_path があるが、今回の差し替えで全て `assets/cards/character/...` に変更する。

## 作業内容

### Step 1: 画像ファイルのリネームと配置

`H:\CURSOR\Dev\jp-tcgbook\html\assets\cards\character\` 内の 20 枚を、card_id に対応するファイル名にリネームする。**拡張子は `.jpg` のまま維持**（PNG 変換は不要、白背景のため透過処理不要、ファイルサイズ削減になる）。

リネーム後のファイル名は以下の 20 個になる:

```
tcg_ur_antares.jpg
tcg_ur_void_edge.jpg
tcg_ss_silver_knight.jpg
tcg_ss_moon_sage.jpg
tcg_s_flame_fist.jpg
tcg_s_aqua_shield.jpg
tcg_s_wind_runner.jpg
tcg_s_stone_wall.jpg
tcg_a_iron_spike.jpg
tcg_a_shadow_cat.jpg
tcg_a_holy_moth.jpg
tcg_a_rust_golem.jpg
tcg_b_moss_sprite.jpg
tcg_b_cave_bat.jpg
tcg_b_mud_frog.jpg
tcg_b_coal_imp.jpg
tcg_c_slime.jpg
tcg_c_rat.jpg
tcg_c_mushroom.jpg
tcg_c_ghost_jelly.jpg
```

**画像とファイル名の対応はユーザーが目視判断する。** CURSOR 側で自動判定はしない。ユーザーがファイラーで 1 枚ずつリネームするのを待つこと。リネーム完了後、ユーザーから「リネーム完了」の合図を受けてから Step 2 に進む。

### Step 2: shared/cards.lua の更新

20 枚分の `image_path` / `name` / `name_en` / `description` / `description_en` を以下の対応表で書き換える。**他フィールド（card_id, rank, type, stat_*, no）は既存値を絶対に変更しないこと**。

#### 更新内容（20 件）

##### 1. tcg_ur_antares (UR 9/9/8/8)

- image_path: `assets/cards/character/tcg_ur_antares.jpg`
- name: `星詠みの女神アンタレス`
- name_en: `Antares, Goddess of the Stars`
- description: `星座を司る盲目の女神。星々の声を聴き、運命を紡ぎ直す力を持つ。`
- description_en: `A blind goddess who governs the constellations, hearing the voices of the stars and reweaving fate itself.`

##### 2. tcg_ur_void_edge (UR 9/8/9/8)

- image_path: `assets/cards/character/tcg_ur_void_edge.jpg`
- name: `虚空の刃姫`
- name_en: `Void Blade Princess`
- description: `黒紅の双剣を操る暗殺者の頂点。標的に気付かれる前に決着がついている。`
- description_en: `The peak of assassins, wielding crimson-and-black twin blades. The duel ends before the target even notices.`

##### 3. tcg_ss_silver_knight (SS 8/7/6/7)

- image_path: `assets/cards/character/tcg_ss_silver_knight.jpg`
- name: `銀翼の聖騎士`
- name_en: `Silverwing Paladin`
- description: `翼の意匠を持つ重鎧を纏う守護騎士。傷ついた者を背に負って戦場を渡る。`
- description_en: `A guardian knight clad in winged heavy armor, crossing the battlefield with the wounded on her back.`

##### 4. tcg_ss_moon_sage (SS 7/8/7/6)

- image_path: `assets/cards/character/tcg_ss_moon_sage.jpg`
- name: `黄金聖騎士アウローラ`
- name_en: `Aurora, the Golden Paladin`
- description: `白金の鎧と翼飾りで剣を授かった聖女騎士。光の刃が闇を切り裂く。`
- description_en: `A holy maiden knight bearing a sword in platinum armor and winged crest. Her blade of light cleaves the darkness.`

##### 5. tcg_s_flame_fist (S 8/6/5/5)

- image_path: `assets/cards/character/tcg_s_flame_fist.jpg`
- name: `烈火の戦斧使い`
- name_en: `Berserker of the Crimson Axe`
- description: `橙の燃え立つ髪と棘鎧を纏う戦士。両手大斧の一振りで戦線を割る。`
- description_en: `A warrior with flaming orange hair and spiked armor. A single swing of his great axe splits the battle line.`

##### 6. tcg_s_aqua_shield (S 6/8/5/6)

- image_path: `assets/cards/character/tcg_s_aqua_shield.jpg`
- name: `蒼鋼の二丁拳銃`
- name_en: `Steelblue Gunslinger`
- description: `歯車仕掛けの義腕に二丁拳銃を構える銃使い。装填速度は誰にも追随を許さない。`
- description_en: `A gunslinger with clockwork prosthetics dual-wielding revolvers. Her reload speed has no equal.`

##### 7. tcg_s_wind_runner (S 7/6/7/6)

- image_path: `assets/cards/character/tcg_s_wind_runner.jpg`
- name: `蒼穹の魔導書使い`
- name_en: `Skybound Tome-Bearer`
- description: `星空を織り込んだ法衣を纏い古魔導書を携える賢者。風の精霊と契約を結ぶ。`
- description_en: `A sage in starlit robes carrying an ancient grimoire, bound by pact to the wind spirits.`

##### 8. tcg_s_stone_wall (S 5/6/8/7)

- image_path: `assets/cards/character/tcg_s_stone_wall.jpg`
- name: `白銀の近衛騎士`
- name_en: `Silver Guard Captain`
- description: `王城の近衛を務める若き騎士隊長。装飾鎧の堅さは城壁にも比肩する。`
- description_en: `A young captain of the royal guard. His ornate armor rivals the strength of the castle walls.`

##### 9. tcg_a_iron_spike (A 5/6/4/5)

- image_path: `assets/cards/character/tcg_a_iron_spike.jpg`
- name: `碧海の海賊船長`
- name_en: `Azure Sea Captain`
- description: `羽根飾りの海賊帽を被る快活な船長。剣の腕も交渉術も一級品。`
- description_en: `A cheerful captain in a feathered tricorn. His swordsmanship and silver tongue are both first-rate.`

##### 10. tcg_a_shadow_cat (A 6/5/4/3)

- image_path: `assets/cards/character/tcg_a_shadow_cat.jpg`
- name: `紅刃の暗殺姫`
- name_en: `Crimson Blade Assassin`
- description: `黒赤の髪に紫装束、双剣を背負う影渡りの娘。月のない夜に現れる。`
- description_en: `A shadow-walker in violet garb with crimson-streaked hair, twin blades on her back. She appears only on moonless nights.`

##### 11. tcg_a_holy_moth (A 4/5/6/7)

- image_path: `assets/cards/character/tcg_a_holy_moth.jpg`
- name: `緋紅の宮廷魔女`
- name_en: `Crimson Court Witch`
- description: `紫衣に黄金紋様、ルーン刻印の杖を握る宮廷魔女。古代語で世界を編み直す。`
- description_en: `A court witch in violet robes with golden patterns, gripping a rune-inscribed staff. She reweaves the world in ancient tongues.`

##### 12. tcg_a_rust_golem (A 5/4/6/5)

- image_path: `assets/cards/character/tcg_a_rust_golem.jpg`
- name: `深緑の弓使い`
- name_en: `Deepwood Archer`
- description: `森緑のマントを翻す熟練の狩人。彫刻が施された長弓は祖父譲り。`
- description_en: `A veteran hunter in a deep-green cloak. His ornately carved longbow was passed down from his grandfather.`

##### 13. tcg_b_moss_sprite (B 4/4/4/4)

- image_path: `assets/cards/character/tcg_b_moss_sprite.jpg`
- name: `白百合の聖女見習い`
- name_en: `Lily Saintess Apprentice`
- description: `淡紫の髪に純白のドレスを纏う若き聖女。結晶杖から零れる光は癒しの祈り。`
- description_en: `A young saintess with pale violet hair in a pristine white dress. The light from her crystal staff is a prayer of healing.`

##### 14. tcg_b_cave_bat (B 3/5/3/4)

- image_path: `assets/cards/character/tcg_b_cave_bat.jpg`
- name: `桜花の舞踏姫`
- name_en: `Cherry Blossom Dancer`
- description: `桃色の髪をなびかせ二本の扇で舞う踊り子。観客の足元から幻惑が広がる。`
- description_en: `A dancer with flowing pink hair, twirling twin fans. Illusions spread from the floor where her audience stands.`

##### 15. tcg_b_mud_frog (B 4/3/4/4)

- image_path: `assets/cards/character/tcg_b_mud_frog.jpg`
- name: `森の獣耳ドルイド`
- name_en: `Beastkin Druid of the Wilds`
- description: `獣耳と毛皮装束の少女。栗鼠と梟を肩に乗せ、蔓鞭で獣たちを束ねる。`
- description_en: `A beastkin girl in fur garb. With a squirrel and owl on her shoulders, she leads beasts with a vine-woven whip.`

##### 16. tcg_b_coal_imp (B 4/4/3/3)

- image_path: `assets/cards/character/tcg_b_coal_imp.jpg`
- name: `木霊の若き樹術師`
- name_en: `Young Treecrafter`
- description: `緑の髪と木甲冑を纏う若き樹術師。水晶の宿る杖で樹々と語らう。`
- description_en: `A young treecrafter in green hair and wooden armor. His crystal-tipped staff converses with the trees.`

##### 17. tcg_c_slime (C 3/3/3/3)

- image_path: `assets/cards/character/tcg_c_slime.jpg`
- name: `見習い吟遊詩人`
- name_en: `Apprentice Bard`
- description: `紅と金の宮廷服を纏い小型琴を抱える吟遊詩人。歌で士気を上げる程度の腕前。`
- description_en: `An apprentice bard in crimson-and-gold court attire holding a small lute. His songs lift morale, if only modestly.`

##### 18. tcg_c_rat (C 3/4/2/3)

- image_path: `assets/cards/character/tcg_c_rat.jpg`
- name: `見習い鍵師`
- name_en: `Apprentice Locksmith`
- description: `黒髪に黒革装束、鍵束と短剣を腰に下げる夜の少年。盗みではなく解錠を生業にする。`
- description_en: `A youth in black hair and dark leather, keys and a dagger at his belt. His trade is lockpicking, not thievery.`

##### 19. tcg_c_mushroom (C 2/3/3/4)

- image_path: `assets/cards/character/tcg_c_mushroom.jpg`
- name: `見習い錬金術師`
- name_en: `Apprentice Alchemist`
- description: `赤毛に二つ結びの少女錬金術師。手のひらに光る薬瓶は最近やっと安定した自信作。`
- description_en: `A red-haired alchemist girl with twin braids. The glowing flask in her palm is her latest, finally-stable creation.`

##### 20. tcg_c_ghost_jelly (C 3/3/4/2)

- image_path: `assets/cards/character/tcg_c_ghost_jelly.jpg`
- name: `蒼氷の星詠み巫女`
- name_en: `Iceblue Star-Reading Priestess`
- description: `蒼氷色の髪と星座のドレスを纏う巫女。古魔導書を片手に星の運行を読み解く。`
- description_en: `A priestess with ice-blue hair and a constellation-patterned dress. With an ancient tome in hand, she reads the courses of the stars.`

#### 注意事項

- **`monster/` を参照していた 9 枚（rust_golem 以降）も、すべて `character/` に変更**する。`monster/` ディレクトリ自体は残すが、現在は空になる。
- 上記の name / description はキャラクター画像（人物アート）に合わせており、既存の「モンスター」設定（スライム・ネズミ・キノコ・ゴーストゼリー等）から大きく変更されている。card_id は内部キーとして既存名（`tcg_c_slime` 等）を維持するが、表示上は完全にキャラクターカードになる。
- description は既存の `Database.UpsertAllCards` で DB に反映される。実機反映には Step 4 が必要。

### Step 3: 動作確認用の Config 一時変更

実機で新しい name / description / image を反映させるため、`config.lua` で `Config.SeedCardsFromLua` を `true` に変更する。**作業完了後に必ず元の `false` に戻す**。

```lua
-- 一時的に true（マスタ更新後 false に戻すこと）
Config.SeedCardsFromLua = true
```

### Step 4: コミット

3 つに分割してコミットする。

**Commit A: 画像差し替え（Step 1 完了後）**

```
feat(jp-tcgbook): replace card artwork with original AI-assisted illustrations
- Remove BOOTH-purchased card images (cogabushi character pack)
- Add 20 self-generated character illustrations under html/assets/cards/character/
- All images consolidated to character/ directory; monster/ retained for future use
```

**Commit B: shared/cards.lua 更新（Step 2 完了後）**

```
feat(jp-tcgbook): update card names and descriptions to match new artwork
- Rewrite name, name_en, description, description_en for all 20 cards
- Migrate image_path from monster/ to character/ for 9 cards
- Preserve card_id, rank, type, stats, no (gameplay balance unchanged)
```

**Commit C: Config 一時変更（Step 3、検証後 false に戻すコミットを別途）**

```
chore(jp-tcgbook): temporarily enable SeedCardsFromLua for master refresh
```

検証完了後に `Config.SeedCardsFromLua = false` に戻して追加コミット:

```
chore(jp-tcgbook): restore SeedCardsFromLua=false after card master refresh
```

### Step 5: 旧カード画像の Git 履歴削除（最重要）

旧 cogabushi 様素材が Git 履歴に残ったままだと利用規約上の二次配布リスクが残る。Commit A 〜 C 完了後、**履歴ごと削除する**。

**事前バックアップ（必須）:**

```powershell
Copy-Item -Recurse H:\CURSOR\Dev\jp-tcgbook H:\CURSOR\Dev\jp-tcgbook_backup_before_filter_<日付>
```

GitHub のリモートクローンも別途取得しておく:

```powershell
git clone --mirror https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja.git H:\CURSOR\Dev\jp-tcgbook_mirror_backup
```

**git filter-repo 実行:**

```powershell
pip install git-filter-repo

# リポジトリのトップで実行（jp-tcgbook サブディレクトリの上のディレクトリ）
cd H:\CURSOR\Dev\fivem-mods_ja  # または該当パス

# 過去の card 画像 PNG/JPG を全履歴から削除（character/ と monster/ の両方）
git filter-repo --path-glob 'jp-tcgbook/html/assets/cards/character/*.png' --invert-paths --force
git filter-repo --path-glob 'jp-tcgbook/html/assets/cards/monster/*.png' --invert-paths --force
git filter-repo --path-glob 'jp-tcgbook/html/assets/cards/character/*.jpg' --invert-paths --force
git filter-repo --path-glob 'jp-tcgbook/html/assets/cards/monster/*.jpg' --invert-paths --force
```

**注意**: `git filter-repo` 実行後、現在の HEAD には新しい AI 生成画像 (`tcg_*.jpg`) が**含まれた状態**で残る。`--invert-paths` で削除されるのは「マッチした PNG/JPG が過去にコミットされた履歴」のみで、ファイル名が `tcg_*.jpg` の現在の画像は新規ファイルとして保持される。

**動作確認:**

```powershell
# 履歴に旧 PNG が残っていないか確認
git log --all --diff-filter=A --name-only -- 'jp-tcgbook/html/assets/cards/' | Select-String -Pattern '\.png$|\.jpg$'
```

出力に `tcg_*.jpg`（新画像）のみ表示され、旧素材のファイル名（cogabushi 様のオリジナルファイル名や、過去に `tcg_*.png` でコミットしていた場合はそのファイル名）が含まれていなければ成功。

**force-push:**

```powershell
git remote add origin https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja.git
git push --force --all
git push --force --tags
```

### Step 6: GitHub のキャッシュ・フォーク削除依頼（推奨）

force-push しても GitHub 内部のフォーク・PR キャッシュには旧コミットが残る可能性がある。

- リポジトリのフォーク一覧を確認: `https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/network/members`
- フォークが存在しなければ追加対応不要。
- 存在する場合、GitHub Support に「Sensitive data removal」リクエストを出す: https://docs.github.com/en/site-policy/content-removal-policies/github-takedown-policy

リポジトリが完全 private 期間が長く、public 化後に旧素材コミットが含まれていなかった場合はこのステップ不要。

## 完了条件

- [ ] `html/assets/cards/character/` に `tcg_*.jpg` 20 枚配置（旧素材は全削除）
- [ ] `html/assets/cards/monster/` は空ディレクトリで保持
- [ ] `shared/cards.lua` の 20 件で name / name_en / description / description_en / image_path 更新済み
- [ ] `Config.SeedCardsFromLua = true` で再起動 → 全カードの DB が更新されたことを `/book` で目視確認
- [ ] `Config.SeedCardsFromLua = false` に戻して再コミット
- [ ] Git 履歴に旧 cogabushi 様素材が残っていないことを `git log --all --diff-filter=A --name-only` で確認
- [ ] force-push 後 GitHub Web で履歴を目視確認（旧 PNG が表示されないこと）

## 想定所要時間

- Step 1（リネーム）: 20 分（画像内容を見ながら手動）
- Step 2（cards.lua 更新）: 10 分（CURSOR 自動）
- Step 3（Config 変更）: 1 分
- Step 4（コミット）: 5 分
- Step 5（履歴削除 + force-push）: 15 分（バックアップ含む）
- Step 6（GitHub 確認）: 5 分

合計約 1 時間。

## 失敗時のロールバック

Step 5 で何か問題が起きた場合、バックアップから復元:

```powershell
# ローカル
Remove-Item -Recurse -Force H:\CURSOR\Dev\jp-tcgbook
Copy-Item -Recurse H:\CURSOR\Dev\jp-tcgbook_backup_before_filter_<日付> H:\CURSOR\Dev\jp-tcgbook

# リモート（mirror から復元）
cd H:\CURSOR\Dev\jp-tcgbook_mirror_backup
git push --mirror https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja.git
```
