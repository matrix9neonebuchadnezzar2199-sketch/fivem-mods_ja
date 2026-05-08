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

/**
 * カテゴリで絞った `models` に対し、クエリで再フィルタ。
 * 空白区切りトークンは AND（各トークンがモデル名・ラベル・いずれかのタグに部分一致）。
 */
/** 選択タグがすべて `def.tags` に含まれるモデルのみ（大文字小文字無視・AND） */
export function filterModelsByTags(
  models: string[],
  dict: Record<string, PropDef>,
  selectedTags: string[],
): string[] {
  if (selectedTags.length === 0) {
    return models
  }
  const required = selectedTags.map((t) => t.trim().toLowerCase()).filter(Boolean)
  if (required.length === 0) {
    return models
  }
  return models.filter((model) => {
    const def = dict[model]
    if (!def) {
      return false
    }
    const tagSet = new Set((def.tags ?? []).map((x) => String(x).toLowerCase()))
    return required.every((r) => tagSet.has(r))
  })
}

export function filterModelsBySearch(
  models: string[],
  dict: Record<string, PropDef>,
  query: string,
): string[] {
  const raw = query.trim().toLowerCase()
  if (!raw) {
    return models
  }
  const tokens = raw.split(/\s+/).filter(Boolean)
  if (tokens.length === 0) {
    return models
  }
  return models.filter((model) => {
    const def = dict[model]
    if (!def) {
      return false
    }
    const label = (def.label ?? '').toLowerCase()
    const name = model.toLowerCase()
    const tagStr = (def.tags ?? [])
      .map((t) => String(t).toLowerCase())
      .join(' ')
    const hay = `${name} ${label} ${tagStr}`
    return tokens.every((t) => hay.includes(t))
  })
}

/** カテゴリ内のタグ頻度（チップ用） */
export function getTopTagsForModels(models: string[], dict: Record<string, PropDef>, limit: number): { tag: string; count: number }[] {
  const counter = new Map<string, number>()
  for (const model of models) {
    const def = dict[model]
    if (!def) {
      continue
    }
    for (const t of def.tags ?? []) {
      const key = String(t)
      counter.set(key, (counter.get(key) ?? 0) + 1)
    }
  }
  return [...counter.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, Math.max(0, limit))
    .map(([tag, count]) => ({ tag, count }))
}

type PropsState = {
  dictionary: Record<string, PropDef>
  categories: CategoryNode[]
  loaded: boolean
  loadError: boolean
  lastCount: number
  /** タグチップ AND フィルタ（カテゴリ変更時は CategoryTree から clear） */
  selectedTags: string[]
  setProps: (dict: Record<string, PropDef>, rawCategories: ServerCategoryRaw[]) => void
  setLoadFailed: () => void
  toggleTag: (tag: string) => void
  clearTags: () => void
}

export const usePropsStore = create<PropsState>((set) => ({
  dictionary: {},
  categories: [],
  loaded: false,
  loadError: false,
  lastCount: 0,
  selectedTags: [],
  toggleTag: (tag) =>
    set((s) => {
      const t = tag.trim()
      if (!t) {
        return s
      }
      const lower = t.toLowerCase()
      const has = s.selectedTags.some((x) => x.toLowerCase() === lower)
      if (has) {
        return { selectedTags: s.selectedTags.filter((x) => x.toLowerCase() !== lower) }
      }
      return { selectedTags: [...s.selectedTags, t] }
    }),
  clearTags: () => set({ selectedTags: [] }),
  setProps: (dict, rawCategories) => {
    const tree = buildCategoryNodes(rawCategories, dict)
    const lastCount = Object.keys(dict).length
    set({
      dictionary: dict,
      categories: tree,
      loaded: true,
      loadError: false,
      lastCount,
      selectedTags: [],
    })
  },
  setLoadFailed: () =>
    set({
      loadError: true,
      loaded: false,
      dictionary: {},
      categories: [],
      lastCount: 0,
      selectedTags: [],
    }),
}))
