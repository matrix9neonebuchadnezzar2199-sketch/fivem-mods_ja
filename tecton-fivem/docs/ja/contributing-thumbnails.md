<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->

# サムネイル提供ガイド

TECTON のプロップグリッドは **WebP サムネイル**を前提にしています。未提供のモデルは NUI でプレースホルダ（`PropGrid.tsx` 側の実装予定）が表示されます。

## 仕様

| 項目 | 推奨 |
|------|------|
| 形式 | **WebP** |
| 解像度 | **256×256** px |
| 色 | RGB。背景は **透過推奨**（角丸マスクと相性がよい） |

## 命名規則

- ファイル名: **`<model_name>.webp`**（小文字・`prop_` プレフィックスはモデル名に合わせる）
- 例: モデル `prop_chair_01a` → `prop_chair_01a.webp`

## 配置先

リソース内の **`assets/thumbnails/`** に置きます。`fxmanifest.lua` の `files` で `assets/thumbnails/*.webp` を配信します。

## 生成手順の例

### 方法 A: CodeWalker 等

1. モデルを正面から表示しスクリーンショット取得。
2. ImageMagick 等で **256×256** にリサイズ。
3. `cwebp` で WebP 化。

### 方法 B: GTA V 内（MapEditor / Menyoo）

1. 空マップにプロップを単体配置。
2. スクショ取得 → 上記と同様にリサイズ・`cwebp`。

### 方法 C（将来）

`tools/thumb_gen/` に FiveM 内でカメラ固定＋NUI キャプチャする自動化を置く予定です。

## 一括変換の例（PNG → WebP）

```bash
for f in *.png; do cwebp -q 85 -resize 256 256 "$f" -o "${f%.png}.webp"; done
```

（Windows では Git Bash や WSL が便利です。）

## 貢献について

**Pull Request** で `assets/thumbnails/` への画像追加を歓迎します。モデル名とファイル名の対応が取れるよう、コミットメッセージまたは PR 本文に範囲（カテゴリや件数）を書いてください。

## ライセンス

サムネ画像は **あなたが撮影・加工した著作物**であること、または **再配布可能なライセンス**であることを確認してください。ゲーム内キャプチャの取り扱いはサーバー運営ポリシーに従ってください。
