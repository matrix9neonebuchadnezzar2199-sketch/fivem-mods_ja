# 画像生成プロンプト集 - jp-lunar_fishing

このドキュメントは、jp-lunar_fishing で使用する 15 個のアイテムアイコン
（魚 10 種 + 釣り竿 3 種 + 餌 2 種）の AI 画像生成プロンプトをまとめたものです。

- 対象生成サービス：Midjourney / Stable Diffusion (SDXL) / DALL·E 3 / FLUX 等
- 出力仕様：1024×1024 → リサイズして 100×100 透過 PNG
- 配置先：`assets/fish_images/` および `ox_inventory/web/images/`
- ファイル名：アイテムキー名 + `.png`（例：`maguro.png`）

---

## 1. 共通スタイル方針（全アイテム必須）

全アイコンで視覚的統一を取るため、以下の要素を全プロンプトに含めます。
個別プロンプトでは末尾の `[SUBJECT]` 部分のみ差し替えます。

### 共通ベース（魚用）

```
top-down side view of [SUBJECT],
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, no watermark,
square 1:1 composition, 1024x1024
```

### 共通ネガティブプロンプト（SD/SDXL用）

```
text, watermark, signature, logo, multiple subjects,
blurry, low quality, jpeg artifacts, cropped,
human hand, fishing rod in frame (for fish),
background scenery, water splash, bubbles,
shadow on background, frame, border
```

### スタイル微調整キーワード（任意・統一性向上のため推奨）

| サービス | 追加推奨パラメータ |
|---|---|
| Midjourney | `--style raw --ar 1:1 --v 6` |
| SDXL | `Steps: 30, CFG: 7, Sampler: DPM++ 2M Karras` |
| DALL·E 3 | プロンプト末尾に `, isolated on pure transparent background` |
| FLUX | `guidance_scale: 3.5, steps: 28` |

### 透過処理のコツ

DALL·E と Midjourney は完全透過 PNG を直接出力できないことが多いため、
生成後に以下のいずれかで背景除去します。

- [remove.bg](https://www.remove.bg/)（無料・高品質）
- Photoshop の「被写体を選択」→ レイヤーマスク
- `rembg` (Python CLI, ローカル無料)：`rembg i input.png output.png`

SDXL/FLUX をローカル実行する場合は、`Stable Diffusion WebUI Forge` の
「ABG Remover」拡張機能を使うと生成と同時に透過化されます。

---

## 2. 個別プロンプト（魚 10 種）

### 2-1. `iwashi.png` — イワシ

```
top-down side view of a Japanese sardine (iwashi),
small slender fish about 15cm, silver-blue back with shiny white belly,
small scales reflecting light, single dorsal fin, forked tail,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 2-2. `aji.png` — アジ

```
top-down side view of a Japanese horse mackerel (aji),
medium fish about 25cm, olive-green back with silver belly,
distinctive yellow lateral line scutes,
forked tail, two dorsal fins,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 2-3. `saba.png` — サバ

```
top-down side view of a Pacific mackerel (saba),
streamlined fish about 35cm, metallic blue-green back
with dark wavy stripes, silver-white belly,
forked tail, sleek torpedo shape,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 2-4. `tai.png` — マダイ

```
top-down side view of a Japanese red sea bream (madai),
elegant pink-red fish about 40cm, vivid crimson scales
with subtle blue spots near the dorsal fin,
large round eye, prominent forehead, fan-shaped tail,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 2-5. `hirame.png` — ヒラメ

```
top-down view of a Japanese flounder (hirame),
flatfish with both eyes on the left side, dark brown
mottled upper surface for camouflage, oval flat body,
long continuous dorsal and anal fins surrounding the body,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

注：ヒラメは側面ではなく真上からの「平たい姿」の方がアイコンとして識別しやすいため、
`top-down side view` ではなく `top-down view` に変更しています。

### 2-6. `unagi.png` — ウナギ

```
top-down side view of a Japanese eel (unagi),
long slender snake-like fish about 60cm,
dark olive-brown back with pale yellow belly,
smooth glossy skin, small pectoral fins,
continuous dorsal-tail-anal fin running along the body,
coiled in a gentle S-shape to fit square frame,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

注：ウナギは横長すぎてアイコン化しにくいため、`coiled in a gentle S-shape`
を追加してフレーム内に収めます。

### 2-7. `buri.png` — ブリ

```
top-down side view of a Japanese amberjack (buri / yellowtail),
large powerful fish about 80cm, steel-blue back
with bright golden-yellow horizontal stripe along the side,
silver-white belly, deeply forked yellow tail,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 2-8. `katsuo.png` — カツオ

```
top-down side view of a skipjack tuna (katsuo),
sleek torpedo-shaped fish about 60cm,
dark steel-blue back, silver belly with
4-6 distinctive dark horizontal stripes on the lower side,
crescent-shaped tail, small finlets near tail,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 2-9. `maguro.png` — クロマグロ

```
top-down side view of a Pacific bluefin tuna (kuromaguro),
massive torpedo-shaped fish, deep metallic blue-black back,
silver-white belly with subtle iridescent shimmer,
bright yellow finlets along back and belly near tail,
large crescent-shaped powerful tail, small eye, sharp pointed snout,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 2-10. `ryugu.png` — リュウグウノツカイ

```
top-down side view of an oarfish (ryugu no tsukai),
extremely long ribbon-like silver fish,
brilliant iridescent silver body with subtle blue tinge,
striking bright red dorsal fin running the entire length,
red elongated rays on the head like a crown,
small mouth, large round eye,
coiled in a gentle wave shape to fit square frame,
mythical deep sea creature appearance,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

注：リュウグウノツカイは現実では数メートル級の超長尺なので、
ウナギ同様に `coiled in a gentle wave shape` でフレーム内に収めます。
レア度最高なので、`mythical deep sea creature appearance` を追加して
他の魚より幻想的な雰囲気を出します。

---

## 3. 個別プロンプト（釣り竿 3 種）

魚と異なり、釣り竿は構造物なので **斜め45度の俯瞰** の方がアイコンとして
視認性が高くなります。`top-down side view` ではなく
`isometric 3/4 view` を使います。

### 3-1. `basic_rod.png` — 初心者の釣り竿

```
isometric 3/4 view of a simple wooden fishing rod,
short bamboo rod about 1.5 meters, basic black reel,
thin nylon line with small hook,
beginner equipment with worn appearance,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 3-2. `graphite_rod.png` — グラファイト竿

```
isometric 3/4 view of a modern graphite fishing rod,
sleek dark gray composite rod about 2 meters,
mid-range spinning reel with silver accents,
braided line, polished cork grip,
intermediate quality equipment, professional appearance,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 3-3. `titanium_rod.png` — チタン竿

```
isometric 3/4 view of a high-end titanium fishing rod,
gleaming silver-titanium rod with metallic luster,
premium high-tech reel with gold accents,
glowing slight blue tint indicating advanced material,
expert-grade fishing equipment, luxurious appearance,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

---

## 4. 個別プロンプト（餌 2 種）

餌は小さいものなので、フレーム内で大きく見せるために
`close-up` を追加します。

### 4-1. `worms.png` — ミミズ

```
close-up top-down view of a small pile of earthworms,
3 to 5 reddish-brown earthworms coiled together,
moist segmented bodies, realistic texture,
natural fishing bait,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

### 4-2. `artificial_bait.png` — ルアー

```
close-up isometric 3/4 view of a fishing lure,
shiny metallic minnow-shaped lure with rainbow holographic finish,
two treble hooks attached, small red eye,
realistic plastic and metal materials,
modern artificial fishing bait,
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

---

## 5. 生成→配置ワークフロー

### 5-1. 推奨手順

1. **プロンプト実行**：本ドキュメントの個別プロンプトをコピーして
   各画像生成サービスで実行（1アイテムにつき 2〜4 枚生成して最良を選択）
2. **背景除去**：透過 PNG でない場合、`remove.bg` または `rembg` で
   背景を完全透過に変換
3. **リサイズ**：1024×1024 → 100×100（または 128×128）に縮小
   - ox_inventory 標準は 100×100 推奨、QBCore は 128×128 が多い
4. **ファイル名**：アイテムキー名と完全一致させる（例：`maguro.png`）
5. **配置**：
   - `assets/fish_images/<key>.png`（リポジトリ管理用、オリジナル品質）
   - リリース時のサンプル：`lunar_fishing/install/images_ox/<key>.png`

### 5-2. リサイズコマンド例（ImageMagick）

```bash
# 1024×1024 → 100×100 透過維持
magick input.png -resize 100x100 -background none -gravity center -extent 100x100 output.png

# 全PNGを一括処理（bash）
for f in assets/fish_images/raw/*.png; do
    name=$(basename "$f")
    magick "$f" -resize 100x100 -background none -gravity center -extent 100x100 "assets/fish_images/$name"
done
```

PowerShell 版：

```powershell
Get-ChildItem assets\fish_images\raw\*.png | ForEach-Object {
    $out = "assets\fish_images\$($_.Name)"
    magick $_.FullName -resize 100x100 -background none -gravity center -extent 100x100 $out
}
```

### 5-3. 品質チェックリスト（各画像）

- [ ] 背景が完全透過（白や灰色が残っていない）
- [ ] 被写体が中央に配置されている
- [ ] 100×100 にリサイズしても識別可能
- [ ] ファイル名がアイテムキーと完全一致（小文字、`.png`）
- [ ] 影や水しぶきが入っていない
- [ ] 他のアイコンとスタイルが揃っている（写実度・彩度・光源方向）

---

## 6. ライセンスと配布上の注意

### 6-1. 生成画像のライセンス

| サービス | 商用利用 | 本MOD（非商用）配布 | 備考 |
|---|---|---|---|
| Midjourney（有料プラン） | 可 | 可 | 生成者に商用権あり |
| DALL·E 3（ChatGPT Plus） | 可 | 可 | OpenAI規約で生成者帰属 |
| Stable Diffusion（ローカル） | 可 | 可 | モデルライセンスに従う |
| FLUX.1 [dev]（ローカル） | **非商用のみ** | 可 | 商用は別途ライセンス必要 |
| FLUX.1 [schnell] | 可 | 可 | Apache 2.0 |

本MODは非商用配布のため、いずれのサービスでも問題ありません。
ただし、配布する画像が**他者の著作物に酷似**しないよう注意してください
（特定キャラクター名・ブランド名はプロンプトから除外済み）。

### 6-2. GPL-3.0 との関係

本MODは GPL-3.0 で配布されます。**コード**は GPL の対象ですが、
**画像アセット**については以下のように扱います。

- 画像は「Aggregate（集積物）」として GPL-3.0 と共に配布
- 画像個別のライセンスは `assets/fish_images/LICENSE_IMAGES.md` に明記
- 推奨ライセンス：**CC0 1.0**（パブリックドメイン）または **CC BY 4.0**
  （生成元サービス規約で許容される範囲で）

`LICENSE_IMAGES.md` の雛形：

```markdown
# 画像アセットのライセンス

本ディレクトリ内のすべての PNG ファイルは、AI 画像生成サービスにより
生成され、Creative Commons Zero v1.0 (CC0 1.0) のもとで配布されます。

著作権者：jp-lunar_fishing プロジェクト
生成サービス：[使用したサービス名]
生成日：2026-05-XX

これらの画像は商用・非商用を問わず自由に使用、改変、再配布できます。
帰属表示は不要ですが、jp-lunar_fishing へのリンクを記載いただけると
励みになります。
```

---

## 7. 拡張：将来の魚種追加用テンプレート

将来、日本魚種を追加する場合に使えるテンプレートです。
新魚種は `Config.fish`, `items_ox_ja.lua`, `items_qb_ja.lua` の
3 箇所に追記が必要なことを忘れずに。

```
top-down side view of a [魚の和名 (学名/英名)],
[体長と体型], [体色の特徴], [特徴的な部位],
[尾びれの形], [その他の識別ポイント],
realistic illustration, soft uniform lighting,
clean transparent background, centered composition,
game inventory icon style, no text, no border,
no drop shadow, square 1:1 composition, 1024x1024
```

追加候補例：

| 候補 | キー名 | 特徴 |
|---|---|---|
| サンマ | `sanma` | 細長い銀色、秋の代表 |
| サケ | `sake` | 銀色に黒斑、産卵期は赤化 |
| アユ | `ayu` | 川魚、淡緑色、香魚 |
| マンボウ | `manbou` | 円盤型、奇怪な形状、希少 |
| イカ | `ika` | 軟体動物、触手 |
| タコ | `tako` | 8本足、吸盤 |
| シーラカンス | `coelacanth` | 古代魚、超レア |

---

**更新履歴**

- 2026-05-24：初版作成（15 アイテムの個別プロンプト、共通スタイル方針、配布ライセンスガイド）
