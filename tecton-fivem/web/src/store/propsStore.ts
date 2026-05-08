// SPDX-License-Identifier: LGPL-3.0-or-later

import { create } from 'zustand'

export type PropDef = {
  label: string
  category: string
  thumb: string
  tags: string[]
  tintable: boolean
  tint_palette: string[] | null
}

/** `config/props.lua` の categories 配列の要素（Lua→JSON） */
export type ServerCategoryRaw = {
  id: string
  label: string
  children?: { id: string; label: string }[]
}

export type CategoryNode = {
  id: string
  label: string
  /** フィルタ用パス: `furniture` または `furniture/residential` */
  path: string
  children?: CategoryNode[]
  count?: number
}

function countExact(path: string, dict: Record<string, PropDef>): number {
  let n = 0
  for (const model of Object.keys(dict)) {
    if (dict[model].category === path) {
      n += 1
    }
  }
  return n
}

export function buildCategoryNodes(categories: ServerCategoryRaw[], dict: Record<string, PropDef>): CategoryNode[] {
  return categories.map((root) => {
    const children: CategoryNode[] = (root.children ?? []).map((ch) => {
      const path = `${root.id}/${ch.id}`
      return {
        id: ch.id,
        label: ch.label,
        path,
        count: countExact(path, dict),
      }
    })
    const rootCount = children.reduce((s, c) => s + (c.count ?? 0), 0)
    return {
      id: root.id,
      label: root.label,
      path: root.id,
      children,
      count: rootCount,
    }
  })
}

/** 選択カテゴリパスに一致するモデル名（ソート済み） */
export function listModelsForCategory(path: string | null, dict: Record<string, PropDef>): string[] {
  if (!path) {
    return []
  }
  const out: string[] = []
  const hasSlash = path.includes('/')
  for (const model of Object.keys(dict)) {
    const c = dict[model].category
    if (hasSlash) {
      if (c === path) {
        out.push(model)
      }
    } else if (c === path || c.startsWith(`${path}/`)) {
      out.push(model)
    }
  }
  out.sort((a, b) => dict[a].label.localeCompare(dict[b].label, 'ja'))
  return out
}

type PropsState = {
  dictionary: Record<string, PropDef>
  categories: CategoryNode[]
  loaded: boolean
  loadError: boolean
  lastCount: number
  setProps: (dict: Record<string, PropDef>, rawCategories: ServerCategoryRaw[]) => void
  setLoadFailed: () => void
}

export const usePropsStore = create<PropsState>((set) => ({
  dictionary: {},
  categories: [],
  loaded: false,
  loadError: false,
  lastCount: 0,
  setProps: (dict, rawCategories) => {
    const tree = buildCategoryNodes(rawCategories, dict)
    const lastCount = Object.keys(dict).length
    set({
      dictionary: dict,
      categories: tree,
      loaded: true,
      loadError: false,
      lastCount,
    })
  },
  setLoadFailed: () =>
    set({
      loadError: true,
      loaded: false,
      dictionary: {},
      categories: [],
      lastCount: 0,
    }),
}))
