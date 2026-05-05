import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export type RefboardSettings = {
  locale: 'ja' | 'en'
  timeFormat: 'mm:ss' | 'mm.ss'
  timezone: string
  defaultHalfMinutes: number
  showStoppageHint: boolean
  goalConfirmDialog: boolean
  scoreEditReasonMin: number
  showHero: boolean
  cardOpacity: number
  avatarHue: number
  nuiMock: boolean
  showTestCommandsHint: boolean
}

const STORAGE_KEY = 'refboard_settings'

const defaults: RefboardSettings = {
  locale: 'ja',
  timeFormat: 'mm:ss',
  timezone: 'Asia/Tokyo',
  defaultHalfMinutes: 45,
  showStoppageHint: true,
  goalConfirmDialog: true,
  scoreEditReasonMin: 5,
  showHero: true,
  cardOpacity: 80,
  avatarHue: 210,
  nuiMock: false,
  showTestCommandsHint: false,
}

export const useSettingsStore = defineStore('settings', () => {
  const settings = ref<RefboardSettings>({ ...defaults })

  function load() {
    try {
      const saved = localStorage.getItem(STORAGE_KEY)
      if (saved) {
        const parsed = JSON.parse(saved) as Partial<RefboardSettings>
        settings.value = { ...defaults, ...parsed }
      }
    } catch {
      settings.value = { ...defaults }
    }
  }

  watch(
    settings,
    (v) => {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(v))
      } catch {
        /* ignore */
      }
    },
    { deep: true },
  )

  function patch(p: Partial<RefboardSettings>) {
    settings.value = { ...settings.value, ...p }
  }

  return { settings, load, patch, defaults }
})
