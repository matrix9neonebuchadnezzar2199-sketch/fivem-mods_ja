import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export type MarqueeMode = 'always' | 'hover-only' | 'off'

export type RefboardSettings = {
  locale: 'ja' | 'en'
  timeFormat: 'mm:ss' | 'mm.ss'
  timezone: string
  defaultHalfMinutes: number
  showStoppageHint: boolean
  goalConfirmDialog: boolean
  scoreEditReasonMin: number
  showHero: boolean
  /** 全体背景にスタジアム写真を敷く（既定 OFF・負荷と視認性のため） */
  showBackgroundImage: boolean
  cardOpacity: number
  avatarHue: number
  nuiMock: boolean
  showTestCommandsHint: boolean
  marqueeMode: MarqueeMode
}

const STORAGE_KEY = 'refboard_settings'

function prefersReducedMotion(): boolean {
  try {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  } catch {
    return false
  }
}

const defaults: RefboardSettings = {
  locale: 'ja',
  timeFormat: 'mm:ss',
  timezone: 'Asia/Tokyo',
  defaultHalfMinutes: 45,
  showStoppageHint: true,
  goalConfirmDialog: true,
  scoreEditReasonMin: 5,
  showHero: true,
  showBackgroundImage: false,
  cardOpacity: 80,
  avatarHue: 210,
  nuiMock: false,
  showTestCommandsHint: false,
  marqueeMode: 'always',
}

export const useSettingsStore = defineStore('settings', () => {
  const settings = ref<RefboardSettings>({ ...defaults })

  function load() {
    try {
      const saved = localStorage.getItem(STORAGE_KEY)
      const pr = prefersReducedMotion()
      if (saved) {
        const parsed = JSON.parse(saved) as Partial<RefboardSettings>
        settings.value = { ...defaults, ...parsed }
        if (pr && !Object.prototype.hasOwnProperty.call(parsed, 'marqueeMode')) {
          settings.value.marqueeMode = 'off'
        }
      } else {
        settings.value = {
          ...defaults,
          ...(pr ? { marqueeMode: 'off' as const } : {}),
        }
      }
    } catch {
      settings.value = {
        ...defaults,
        ...(prefersReducedMotion() ? { marqueeMode: 'off' as const } : {}),
      }
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
