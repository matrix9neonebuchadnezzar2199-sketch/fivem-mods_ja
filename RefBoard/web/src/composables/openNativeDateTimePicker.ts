/**
 * type=date / time / datetime-local はピッカーからのみ変更（キー直打ちしない運用）。
 * 入力欄クリックでもアイコンと同様に showPicker を試みる（Chromium / 新しめの Firefox）。
 */
export function openNativeDateTimePicker(ev: Event) {
  const el = ev.currentTarget as HTMLInputElement | null
  if (!el || el.disabled) return
  if (typeof el.showPicker === 'function') {
    try {
      void el.showPicker()
    } catch {
      /* 非ユーザー操作やブラウザ制限 */
    }
  }
}
