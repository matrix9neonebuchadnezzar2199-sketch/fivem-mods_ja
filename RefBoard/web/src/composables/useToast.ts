import { reactive } from 'vue'

export type ToastItem = {
  id: number
  message: string
  type?: 'info' | 'success' | 'error'
  errorCode?: string
  errorKey?: string
}

export type ToastPushMeta = { ms?: number; errorCode?: string; errorKey?: string }

const state = reactive({
  items: [] as ToastItem[],
  seq: 1,
})

export function useToast() {
  /** 第3引数が number のときは表示時間（ms）。オブジェクトのときは { ms, errorCode, errorKey }。 */
  function push(message: string, type: ToastItem['type'] = 'info', third: number | ToastPushMeta = 2000) {
    let ms = 2000
    let meta: ToastPushMeta | undefined
    if (typeof third === 'number') {
      ms = third
    } else if (third && typeof third === 'object') {
      ms = third.ms ?? 2000
      meta = third
    }
    const id = state.seq++
    state.items.push({
      id,
      message,
      type,
      errorCode: meta?.errorCode,
      errorKey: meta?.errorKey,
    })
    window.setTimeout(() => {
      state.items = state.items.filter((x) => x.id !== id)
    }, ms)
  }
  return { items: state.items, push }
}
