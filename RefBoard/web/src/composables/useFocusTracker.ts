import { useSessionStore } from '../stores/session'
import { useNui } from './useNui'

/** 編集者のフォーカスを presence へ 1 秒デバウンスで送る */
export function useFocusTracker() {
  const session = useSessionStore()
  const { send } = useNui()
  let timer: ReturnType<typeof setTimeout> | null = null

  function setFocus(section: string | null) {
    if (!session.isEditor) {
      return
    }
    if (timer) {
      clearTimeout(timer)
      timer = null
    }
    timer = window.setTimeout(() => {
      timer = null
      void send('presence_focus', { focus: section })
    }, 1000)
  }

  return { setFocus }
}
