// SPDX-License-Identifier: LGPL-3.0-or-later

import { create } from 'zustand'

type HelpState = {
  reverseOpen: boolean
  setReverseOpen: (v: boolean) => void
}

export const useHelpStore = create<HelpState>((set) => ({
  reverseOpen: false,
  setReverseOpen: (v) => set({ reverseOpen: v }),
}))
