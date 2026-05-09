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

  /**
   * F6 閉鎖直前に試合詳細で編集中だった場合、再オープン時に enterEdit でロック・match_id を取り直す。
   * （閉じたあと mode が null になり、MatchDetail の lock_acquire ガードが通らない問題の対策）
   */
  const pendingRelockMatchId = ref<number | null>(null)

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
    // pendingRelock は App.vue の refboard:setOpen(false) ウォッチで立てる。ここで先に消すと Close 直後の再ロック意図が潰れる。
    try {
      await send('session_leave', {})
    } catch {
      /* fetch 失敗時も lock 掃除を続ける */
    }
    try {
      await send('lock_release', {})
    } catch {
      /* session_leave で解放済みのことが多い */
    }
    mode.value = null
    lockHolder.value = null
    editPassword.value = DEFAULT_EDIT_PASSWORD
  }

  /**
   * Lua が NUI を閉じた直後の Pinia 同期。
   * @param matchId 試合詳細ルート上で閉じたときのみ渡す（再オープン時の自動ロック取り直し用）
   */
  function syncAfterNuiShellClosedByClient(matchId?: number) {
    if (mode.value === 'edit' && typeof matchId === 'number' && matchId > 0) {
      pendingRelockMatchId.value = matchId
    } else {
      pendingRelockMatchId.value = null
    }
    mode.value = null
    lockHolder.value = null
  }

  /** NUI 再表示後、試合詳細で pending があれば session_enter + lock_acquire をやり直す */
  async function tryRelockAfterShellOpen(matchId: number): Promise<void> {
    const pending = pendingRelockMatchId.value
    if (pending == null) return
    if (pending !== matchId) {
      pendingRelockMatchId.value = null
      return
    }
    pendingRelockMatchId.value = null
    await enterEdit(matchId)
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
    syncAfterNuiShellClosedByClient,
    tryRelockAfterShellOpen,
  }
})
