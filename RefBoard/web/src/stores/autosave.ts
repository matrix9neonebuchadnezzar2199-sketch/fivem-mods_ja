import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useAutosaveStore = defineStore('autosave', () => {
  const lastSavedAt = ref<number | null>(null)
  const status = ref<'idle' | 'saving' | 'saved' | 'error'>('idle')
  const elapsedSeconds = ref(0)
  let tick: ReturnType<typeof setInterval> | null = null

  function clearTick() {
    if (tick) {
      clearInterval(tick)
      tick = null
    }
  }

  function markSaving() {
    status.value = 'saving'
  }

  function markSaved(timestamp: number) {
    lastSavedAt.value = timestamp
    status.value = 'saved'
    clearTick()
    elapsedSeconds.value = 0
    tick = window.setInterval(() => {
      if (lastSavedAt.value) {
        elapsedSeconds.value = Math.floor((Date.now() - lastSavedAt.value) / 1000)
      }
    }, 1000)
  }

  function markError() {
    status.value = 'error'
    clearTick()
  }

  return { lastSavedAt, status, elapsedSeconds, markSaved, markSaving, markError, clearTick }
})
