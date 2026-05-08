// SPDX-License-Identifier: LGPL-3.0-or-later

/** カテゴリパスからプレースホルダ背景用の色相（0–359）を決める */
export function categoryHue(category: string): number {
  let h = 0
  for (let i = 0; i < category.length; i += 1) {
    h = (h * 31 + category.charCodeAt(i)) | 0
  }
  return Math.abs(h) % 360
}

/** 同一カテゴリ内でもモデルごとに色がばらけるようカテゴリとモデル名を混ぜる */
export function placeholderHue(category: string, model: string): number {
  return (categoryHue(category) + categoryHue(model)) % 360
}
