# インベントリアイコン用・画像生成プロンプト案

前提: **128×128 px**、**PNG**、**背景透過**、ゲームインベントリ用の読みやすいアイコン。

以下は AI 画像生成（DALL·E / Midjourney / SDXL / Ideogram 等）や外注時の指示文のたたき台です。ツールに合わせて英語のみ・日本語のみに寄せてください。

---

## ポラロイドカメラ（`polaroid_camera.png`）

**日本語（短く）**

> ゲームUI用アイコン、128x128、背景透明、正面向きのインスタントカメラ、クリーム色と黒のボディ、フラッシュ付き、太めのアウトライン、フラット寄りのイラスト、可愛すぎない、RP向け

**英語（コピペ用）**

> Game inventory icon, 128x128 pixels, transparent background, front-facing instant polaroid camera, cream white and black plastic body, small flash cube, bold clean outline, flat shaded illustration, readable at small size, not cute chibi, subtle shadow, centered, no text

**ネガティブ例**

> photorealistic, 3D render, blurry, watermark, text, busy background, full scene, hands, low contrast

---

## チェキ・写真（`polaroid_photo.png`）

**日本語（短く）**

> ゲームUI用アイコン、128x128、背景透明、手に持ったチェキ写真1枚、白い枠が厚め、中央は淡いグレーのプレースホルダ（風景は入れない）、斜め構図、フラット寄り、RP向け

**英語（コピペ用）**

> Game inventory icon, 128x128 pixels, transparent background, single polaroid photo print with thick white border, center area is soft neutral gray placeholder (no landscape), slight tilt, clean vector-like shading, bold outline, readable silhouette, no text, no watermark

**ネガティブ例**

> realistic photo inside frame, faces, NSFW, cluttered, tiny details, watermark, frameless

---

## 仕上げのコツ

- 生成後に **128×128 にリサイズ**し、必要なら **アウトラインを 1px 強調**するとスロットで潰れにくいです。
- ox_inventory 2.4x Web: `web/images/polaroid_camera.png` を置く場合は `items.lua` で **`client.image = 'polaroid_camera.png'`**（.png 付き）か **`client.image` 省略**（`アイテム名.png` が自動）を推奨。`polaroid_camera` だけだと表示されないことがあります。
