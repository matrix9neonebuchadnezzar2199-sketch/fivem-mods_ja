import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { useNui } from '../composables/useNui'

export type LockHolder = { license?: string; name?: string; serverId?: number; since?: number }

export const useSessionStore = defineStore('session', () => {
  const { send, on } = useNui()

  const mode = ref<'edit' | 'view' | null>(null)
  const lockHolder = ref<LockHolder | null>(null)
  const myLicense = ref('')
  const myName = ref('')

  const isEditor = computed(() => mode.value === 'edit')

  function bindServerMessages() {
    on('refboard:lock:update', (p: { holder?: LockHolder | null }) => {
      lockHolder.value = p?.holder ?? null
    })
  }

  async function enterEdit(matchId?: number) {
    return new Promise<{ ok: true } | { ok: false; error?: string; holder?: LockHolder }>((resolve) => {
      const ms = 8000
      let off: (() => void) | null = null
      const to = window.setTimeout(() => {
        off?.()
        resolve({ ok: false, error: 'timeout' })
      }, ms)
      off = on('refboard:lock:acquire:result', (r: { ok?: boolean; error?: string; holder?: LockHolder }) => {
        clearTimeout(to)
        off?.()
        void (async () => {
          if (r?.ok) {
            mode.value = 'edit'
            lockHolder.value = null
            resolve({ ok: true })
          } else {
            await send('session_enter', { mode: 'view' })
            mode.value = 'view'
            lockHolder.value = r?.holder ?? null
            resolve({ ok: false, error: r?.error, holder: r?.holder })
          }
        })()
      })
      void (async () => {
        await send('session_enter', { mode: 'edit' })
        await send('lock_acquire', { matchId })
      })()
    })
  }

  async function enterView() {
    await send('session_enter', { mode: 'view' })
    mode.value = 'view'
  }

  async function downgradeToView() {
    await send('lock_release', {})
    await send('session_enter', { mode: 'view' })
    mode.value = 'view'
  }

  async function leave() {
    await send('lock_release', {})
    await send('session_leave', {})
    mode.value = null
    lockHolder.value = null
  }

  return {
    mode,
    lockHolder,
    myLicense,
    myName,
    isEditor,
    bindServerMessages,
    enterEdit,
    enterView,
    downgradeToView,
    leave,
  }
})
