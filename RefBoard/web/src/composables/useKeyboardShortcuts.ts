import { onMounted, onUnmounted } from 'vue'

export type ShortcutHandlers = {
  onGoal?: () => void
  onSub?: () => void
  onSave?: () => void
  onCloseModals?: () => void
  /** true の間だけショートカット有効 */
  enabled?: () => boolean
}

export function useKeyboardShortcuts(h: ShortcutHandlers) {
  function onKey(ev: KeyboardEvent) {
    if (!h.enabled || !h.enabled()) return
    const tag = (ev.target as HTMLElement | null)?.tagName
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return
    if (ev.key === 'g' || ev.key === 'G') {
      ev.preventDefault()
      h.onGoal?.()
    } else if (ev.key === 's' || ev.key === 'S') {
      if (ev.ctrlKey || ev.metaKey) return
      ev.preventDefault()
      h.onSub?.()
    } else if (ev.key === 'Escape') {
      h.onCloseModals?.()
    } else if ((ev.ctrlKey || ev.metaKey) && ev.key.toLowerCase() === 's') {
      ev.preventDefault()
      h.onSave?.()
    }
  }
  onMounted(() => window.addEventListener('keydown', onKey))
  onUnmounted(() => window.removeEventListener('keydown', onKey))
}
