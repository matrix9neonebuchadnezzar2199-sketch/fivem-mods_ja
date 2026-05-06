/**
 * 日付・時刻はピッカー中心。欄クリックでも showPicker（readonly は付けない — 非 mutable で showPicker が失敗するため）。
 */
const PASS_THROUGH_KEYS = new Set([
  'Tab',
  'Escape',
  'Enter',
  'ArrowLeft',
  'ArrowRight',
  'ArrowUp',
  'ArrowDown',
  'Home',
  'End',
  'PageUp',
  'PageDown',
])

/** キーボードからの直接編集を抑止（ピッカー・Tab 等は許可） */
export function blockDateTimeFieldKeydown(ev: KeyboardEvent) {
  if (PASS_THROUGH_KEYS.has(ev.key)) return
  if (ev.ctrlKey || ev.metaKey || ev.altKey) return
  ev.preventDefault()
}

export function openNativeDateTimePicker(ev: Event) {
  const el = ev.currentTarget as HTMLInputElement | null
  if (!el || el.disabled) return
  if (typeof el.showPicker === 'function') {
    try {
      void el.showPicker()
    } catch {
      /* 非ユーザー操作等 */
    }
  }
}
