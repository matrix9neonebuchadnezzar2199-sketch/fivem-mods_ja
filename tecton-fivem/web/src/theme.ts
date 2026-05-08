// SPDX-License-Identifier: LGPL-3.0-or-later

/** 等倍時のルート想定（px）。`rem` はこの 16px を 1rem として換算している。 */
export const BASE_FONT_PX = 16

/** 1.0 で等倍、1.5 で 1.5 倍。`App` が `document.documentElement.style.fontSize` に反映する。 */
export const uiScale = 1.5

export const theme = {
  bg: '#0F172A',
  panel: '#1E293B',
  accent: '#4FC3F7',
  text: '#E2E8F0',
  textDim: '#94A3B8',
  danger: '#F87171',
  /** いずれも「16px = 1rem」基準。ルート `font-size` を変えると一括スケール。 */
  fontSize: {
    small: '0.75rem',
    body: '0.875rem',
    /** カテゴリツリー等（従来 1.75rem から約 75% に縮小して密度調整） */
    bodyLarge: '1.3125rem',
    /** ツリー右の件数バッジ（従来 1.5rem の約 75%） */
    treeBadge: '1.125rem',
    h2: '1.125rem',
    h1: '1.25rem',
  },
} as const
