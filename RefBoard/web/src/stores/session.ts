import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { useNui } from '../composables/useNui'

export const useSessionStore = defineStore('session', () => {
  const { send, on } = useNui()

  const mode = ref<'edit' | 'view' | null>(null)
  const lockHolder = ref<{ license: string; name: string; serverId: number; since: number } | null>(null)
  const myLicense = ref('')
  const myName = ref('')

  const isEditor = computed(() => mode.value === 'edit')

  function bindServerMessages() {
    on<{ ok?: boolean; mode?: string }>('refboard:session:ack', (p) => {
      if (p?.mode === 'edit' || p?.mode === 'view') {
        mode.value = p.mode as 'edit' | 'view'
      }
    })
    on('refboard:lock:ack', (_payload: unknown) => {
      /* ロック詳細は後続スプリント */
    })
  }

  async function enterEdit() {
    await send('session_enter', { mode: 'edit' })
    mode.value = 'edit'
  }

  async function enterView() {
    await send('session_enter', { mode: 'view' })
    mode.value = 'view'
  }

  async function leave() {
    await send('session_leave', {})
    mode.value = null
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
    leave,
  }
})
