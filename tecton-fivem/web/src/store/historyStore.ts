// SPDX-License-Identifier: LGPL-3.0-or-later

import { create } from 'zustand'

type HistoryState = {
  entries: unknown[]
  push: (e: unknown) => void
}

export const useHistoryStore = create<HistoryState>((set, get) => ({
  entries: [],
  push: (e) => set({ entries: [...get().entries, e] }),
}))
