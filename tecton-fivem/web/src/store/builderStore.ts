// SPDX-License-Identifier: LGPL-3.0-or-later

import { create } from 'zustand'

export type BuilderMode = 'furniture' | 'door' | 'parking' | 'stash'

/** 一覧で選んだだけの状態（設置ボタンでワールドへ出すまで未確定） */
export type PendingCatalogPick = {
  model: string
  category: string
}

type BuilderState = {
  open: boolean
  mode: BuilderMode
  sceneId: string
  selected: number | null
  /** カテゴリツリー選択: `furniture` または `furniture/residential` */
  selectedCategory: string | null
  /** プロップ一覧のインクリメンタル検索（モデル名・ラベル・タグ） */
  searchQuery: string
  /** グリッドで選んだモデル（ギズモ前のプレビュー用） */
  pendingCatalog: PendingCatalogPick | null
  /** 設置ギズモ中の操作案内（NUI は表示のまま） */
  showPlacementGuide: boolean
  setOpen: (v: boolean) => void
  setMode: (m: BuilderMode) => void
  setSceneId: (id: string) => void
  setSelected: (id: number | null) => void
  setSelectedCategory: (path: string | null) => void
  setSearchQuery: (q: string) => void
  setPendingCatalog: (v: PendingCatalogPick | null) => void
  setShowPlacementGuide: (v: boolean) => void
}

export const useBuilderStore = create<BuilderState>((set) => ({
  open: false,
  mode: 'furniture',
  sceneId: 'default',
  selected: null,
  selectedCategory: null,
  searchQuery: '',
  pendingCatalog: null,
  showPlacementGuide: false,
  setOpen: (v) =>
    set((s) => ({
      open: v,
      pendingCatalog: v ? s.pendingCatalog : null,
      showPlacementGuide: v ? s.showPlacementGuide : false,
    })),
  setMode: (m) => set({ mode: m }),
  setSceneId: (id) => set({ sceneId: id }),
  setSelected: (id) => set({ selected: id }),
  setSelectedCategory: (path) => set({ selectedCategory: path, searchQuery: '', pendingCatalog: null }),
  setSearchQuery: (q) => set({ searchQuery: q }),
  setPendingCatalog: (v) => set({ pendingCatalog: v }),
  setShowPlacementGuide: (v) => set({ showPlacementGuide: v }),
}))
