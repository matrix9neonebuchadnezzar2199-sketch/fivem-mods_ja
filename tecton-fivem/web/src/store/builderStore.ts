// SPDX-License-Identifier: LGPL-3.0-or-later

import { create } from 'zustand'

export type BuilderMode = 'furniture' | 'door' | 'parking' | 'stash'

type BuilderState = {
  open: boolean
  mode: BuilderMode
  sceneId: string
  selected: number | null
  setOpen: (v: boolean) => void
  setMode: (m: BuilderMode) => void
  setSceneId: (id: string) => void
  setSelected: (id: number | null) => void
}

export const useBuilderStore = create<BuilderState>((set) => ({
  open: false,
  mode: 'furniture',
  sceneId: 'default',
  selected: null,
  setOpen: (v) => set({ open: v }),
  setMode: (m) => set({ mode: m }),
  setSceneId: (id) => set({ sceneId: id }),
  setSelected: (id) => set({ selected: id }),
}))
