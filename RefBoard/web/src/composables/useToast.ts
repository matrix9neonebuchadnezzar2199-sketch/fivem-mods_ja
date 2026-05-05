import { reactive } from 'vue'

export type ToastItem = { id: number; message: string; type?: 'info' | 'success' | 'error' }

const state = reactive({
  items: [] as ToastItem[],
  seq: 1,
})

export function useToast() {
  function push(message: string, type: ToastItem['type'] = 'info', ms = 2000) {
    const id = state.seq++
    state.items.push({ id, message, type })
    window.setTimeout(() => {
      state.items = state.items.filter((x) => x.id !== id)
    }, ms)
  }
  return { items: state.items, push }
}
