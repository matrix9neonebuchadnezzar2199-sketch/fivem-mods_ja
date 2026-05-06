import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { useNui } from '../composables/useNui'

export type LockHolder = { license?: string; name?: string; serverId?: number; since?: number }

/** 既定値は server の config.lua `Config.EditPassword` と一致させる */
export const DEFAULT_EDIT_PASSWORD = 'ref'

export const useSessionStore = defineStore('session', () => {
  const { send, on } = useNui()

  const mode = ref<'edit' | 'view' | null>(null)
  const lockHolder = ref<LockHolder | null>(null)
  const myLicense = ref('')
  const myName = ref('')
  /** 編集モード入室用（ランチャーで入力。試合一覧からの編集入室でも再利用） */
  const editPassword = ref(DEFAULT_EDIT_PASSWORD)

  const isEditor = computed(() => mode.value === 'edit')

  function bindServerMessages() {
    on('refboard:lock:update', (p: { holder?: LockHolder | null }) => {
      lockHolder.value = p?.holder ?? null
    })
  }

  async function enterEdit(matchId?: number, passwordOverride?: string) {
    const pw = ((passwordOverride ?? editPassword.value) as string).trim() || DEFAULT_EDIT_PASSWORD
    editPassword.value = pw

    const sessionStep = await new Promise<'ok' | 'bad_password' | 'timeout' | 'fail'>((resolve) => {
      const ms = 5000
      const to = window.setTimeout(() => resolve('timeout'), ms)
      const un = on('refboard:session:ack', (p: { ok?: boolean; mode?: string; error?: string }) => {
        clearTimeout(to)
        un()
        if (p?.ok === true && p?.mode === 'edit') {
          resolve('ok')
          return
        }
        if (p?.error === 'bad_password') {
          resolve('bad_password')
          return
        }
        resolve('fail')
      })
      void send('session_enter', { mode: 'edit', editPassword: pw })
    })

    if (sessionStep !== 'ok') {
      if (sessionStep === 'bad_password') return { ok: false as const, error: 'bad_password' as const }
      if (sessionStep === 'timeout') return { ok: false as const, error: 'session_timeout' as const }
      return { ok: false as const, error: 'session_failed' as const }
    }

    return new Promise<{ ok: true } | { ok: false; error?: string; holder?: LockHolder }>((resolve) => {
      const ms = 8000
      let off: (() => void) | null = null
      const to = window.setTimeout(() => {
        off?.()
        void (async () => {
          await send('session_enter', { mode: 'view' })
          mode.value = 'view'
          resolve({ ok: false, error: 'timeout' })
        })()
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
      void send('lock_acquire', { matchId })
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
    editPassword.value = DEFAULT_EDIT_PASSWORD
  }

  return {
    mode,
    lockHolder,
    myLicense,
    myName,
    editPassword,
    isEditor,
    bindServerMessages,
    enterEdit,
    enterView,
    downgradeToView,
    leave,
  }
})
