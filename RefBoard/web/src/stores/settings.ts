import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export type MarqueeMode = 'always' | 'hover-only' | 'off'
export type RootFontScale = 100 | 150 | 200 | 250 | 300

export type RefboardSettings = {
  locale: 'ja' | 'en'
  /** 表示名（端末内のみ保存・通信なし） */
  selfName: string
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
  /** ルート font-size の倍率（%）。100 / 150 / 200 / 250 / 300。既定 200。 */
  rootFontScale: RootFontScale
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
  selfName: '',
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
  rootFontScale: 200,
}

const ALLOWED_ROOT_FONT_SCALES: ReadonlyArray<RootFontScale> = [100, 150, 200, 250, 300]

function sanitizeRootFontScale(v: unknown): RootFontScale {
  const n = Number(v)
  return (ALLOWED_ROOT_FONT_SCALES as ReadonlyArray<number>).includes(n)
    ? (n as RootFontScale)
    : defaults.rootFontScale
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
        // 旧バージョンの localStorage に rootFontScale が無い／不正値の場合の保護
        settings.value.rootFontScale = sanitizeRootFontScale(settings.value.rootFontScale)
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
