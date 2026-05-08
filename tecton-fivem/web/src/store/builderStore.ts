// SPDX-License-Identifier: LGPL-3.0-or-later

import { create } from 'zustand'

export type BuilderMode = 'furniture' | 'door' | 'parking' | 'stash'

type BuilderState = {
  open: boolean
  mode: BuilderMode
  sceneId: string
  selected: number | null
  /** カテゴリツリー選択: `furniture` または `furniture/residential` */
  selectedCategory: string | null
  setOpen: (v: boolean) => void
  setMode: (m: BuilderMode) => void
  setSceneId: (id: string) => void
  setSelected: (id: number | null) => void
  setSelectedCategory: (path: string | null) => void
}

export const useBuilderStore = create<BuilderState>((set) => ({
  open: false,
  mode: 'furniture',
  sceneId: 'default',
  selected: null,
  selectedCategory: null,
  setOpen: (v) => set({ open: v }),
  setMode: (m) => set({ mode: m }),
  setSceneId: (id) => set({ sceneId: id }),
  setSelected: (id) => set({ selected: id }),
  setSelectedCategory: (path) => set({ selectedCategory: path }),
}))
