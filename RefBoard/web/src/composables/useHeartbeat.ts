import { watchEffect } from 'vue'
import { useSessionStore } from '../stores/session'
import { useNui } from './useNui'

export function useHeartbeat() {
  const session = useSessionStore()
  const { send } = useNui()
  let timer: ReturnType<typeof setInterval> | null = null

  watchEffect(() => {
    if (timer) {
      clearInterval(timer)
      timer = null
    }
    if (session.isEditor) {
      timer = setInterval(() => {
        void send('lock_heartbeat', {})
      }, 10000)
    }
  })
}
