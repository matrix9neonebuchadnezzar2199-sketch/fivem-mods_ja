// SPDX-License-Identifier: LGPL-3.0-or-later

/**
 * `config/props.lua` の `thumb` はファイル名（例: `prop_chair_01a.webp`）。
 * 実体はリソース直下 `assets/thumbnails/`（fxmanifest `files`）。
 *
 * NUI のドキュメントは通常 `.../web/dist/index.html` のため `../../assets/thumbnails/` で解決。
 * Vite 開発時は `public/assets/thumbnails/` を `/assets/thumbnails/` で参照。
 */
export function resolveThumbnailUrl(thumbFile: string): string | null {
  const name = thumbFile.trim()
  if (!name) {
    return null
  }
  if (typeof window === 'undefined') {
    return null
  }
  const enc = encodeURIComponent(name)
  const { hostname, href } = window.location
  const isLocalDev = hostname === 'localhost' || hostname === '127.0.0.1'
  if (isLocalDev) {
    return `/assets/thumbnails/${enc}`
  }
  try {
    return new URL(`../../assets/thumbnails/${enc}`, href).href
  } catch {
    return null
  }
}
