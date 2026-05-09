import { reactive } from 'vue'

export type ToastItem = {
  id: number
  message: string
  type?: 'info' | 'success' | 'error'
  errorCode?: string
  errorKey?: string
}

export type ToastPushMeta = { ms?: number; errorCode?: string; errorKey?: string }

const MAX_VISIBLE = 8

const state = reactive({
  items: [] as ToastItem[],
  seq: 1,
})

/** 同一配列を維持するため dismiss は splice。タイマーは id で管理 */
const dismissTimers = new Map<number, ReturnType<typeof window.setTimeout>>()

function clearDismissTimer(id: number) {
  const t = dismissTimers.get(id)
  if (t != null) {
    window.clearTimeout(t)
    dismissTimers.delete(id)
  }
}

function scheduleDismiss(id: number, ms: number) {
  clearDismissTimer(id)
  const t = window.setTimeout(() => {
    dismissTimers.delete(id)
    const idx = state.items.findIndex((x) => x.id === id)
    if (idx >= 0) {
      state.items.splice(idx, 1)
    }
  }, ms)
  dismissTimers.set(id, t)
}

function evictOldestIfFull() {
  while (state.items.length >= MAX_VISIBLE) {
    const victim = state.items[0]
    if (!victim) break
    clearDismissTimer(victim.id)
    state.items.splice(0, 1)
  }
}

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
    if (!Number.isFinite(ms) || ms < 800) {
      ms = 800
    } else if (ms > 120_000) {
      ms = 120_000
    }

    const tail = state.items[state.items.length - 1]
    if (tail && tail.message === message && tail.type === type) {
      clearDismissTimer(tail.id)
      scheduleDismiss(tail.id, ms)
      return
    }

    evictOldestIfFull()

    const id = state.seq++
    state.items.push({
      id,
      message,
      type,
      errorCode: meta?.errorCode,
      errorKey: meta?.errorKey,
    })
    scheduleDismiss(id, ms)
  }

  /** 手動で閉じる（ルート遷移時など） */
  function dismiss(id: number) {
    clearDismissTimer(id)
    const idx = state.items.findIndex((x) => x.id === id)
    if (idx >= 0) {
      state.items.splice(idx, 1)
    }
  }

  function clearAll() {
    for (const id of dismissTimers.keys()) {
      clearDismissTimer(id)
    }
    state.items.splice(0, state.items.length)
  }

  return { items: state.items, push, dismiss, clearAll }
}
