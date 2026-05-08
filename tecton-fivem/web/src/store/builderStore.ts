// SPDX-License-Identifier: LGPL-3.0-or-later

import { create } from 'zustand'

export type BuilderMode = 'furniture' | 'door' | 'parking' | 'stash'

/** 一覧で選んだだけの状態（設置ボタンでワールドへ出すまで未確定） */
export type PendingCatalogPick = {
  model: string
  category: string
}

/** ワールドで選択中の配置オブジェクト（DB 同期・トランスフォーム用） */
export type SelectedEntity = {
  id: number
  category: string
  model: string
  pos: { x: number; y: number; z: number }
  rot: { x: number; y: number; z: number }
  scene_id?: string
}

type BuilderState = {
  open: boolean
  mode: BuilderMode
  sceneId: string
  /** Lua `TectonClient.selected`（DB id） */
  selected: number | null
  /** `tecton:object:get` の結果 */
  selectedEntity: SelectedEntity | null
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
  /** Lua / NUI から渡る object を正規化して保持 */
  setWorldSelection: (entity: SelectedEntity | null) => void
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
  selectedEntity: null,
  selectedCategory: null,
  searchQuery: '',
  pendingCatalog: null,
  showPlacementGuide: false,
  setOpen: (v) =>
    set((s) => ({
      open: v,
      pendingCatalog: v ? s.pendingCatalog : null,
      showPlacementGuide: v ? s.showPlacementGuide : false,
      selected: v ? s.selected : null,
      selectedEntity: v ? s.selectedEntity : null,
    })),
  setMode: (m) => set({ mode: m }),
  setSceneId: (id) => set({ sceneId: id }),
  setWorldSelection: (entity) => {
    if (!entity || typeof entity.id !== 'number') {
      set({ selected: null, selectedEntity: null })
      return
    }
    const n = (v: unknown) => {
      const x = Number(v)
      return Number.isFinite(x) ? x : 0
    }
    set({
      selected: entity.id,
      selectedEntity: {
        id: entity.id,
        category: String(entity.category ?? ''),
        model: String(entity.model ?? ''),
        pos: {
          x: n(entity.pos?.x),
          y: n(entity.pos?.y),
          z: n(entity.pos?.z),
        },
        rot: {
          x: n(entity.rot?.x),
          y: n(entity.rot?.y),
          z: n(entity.rot?.z),
        },
        scene_id: entity.scene_id,
      },
    })
  },
  setSelectedCategory: (path) => set({ selectedCategory: path, searchQuery: '', pendingCatalog: null }),
  setSearchQuery: (q) => set({ searchQuery: q }),
  setPendingCatalog: (v) => set({ pendingCatalog: v }),
  setShowPlacementGuide: (v) => set({ showPlacementGuide: v }),
}))
