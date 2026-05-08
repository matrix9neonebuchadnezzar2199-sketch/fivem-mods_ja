// SPDX-License-Identifier: LGPL-3.0-or-later

import { create } from 'zustand'

type BuilderState = {
  open: boolean
  setOpen: (v: boolean) => void
}

export const useBuilderStore = create<BuilderState>((set) => ({
  open: false,
  setOpen: (v) => set({ open: v }),
}))
