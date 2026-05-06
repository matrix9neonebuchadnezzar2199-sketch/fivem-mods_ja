import { mockResponse, queueMockSideEffects } from '../mocks/nuiMock'

const TRACE_ENABLED = () =>
  Boolean(import.meta.env.DEV) || (typeof localStorage !== 'undefined' && localStorage.getItem('refboard_trace') === '1')

let requestSeq = 0

export function getResourceName(): string {
  const w = window as unknown as { GetParentResourceName?: () => string }
  if (typeof w.GetParentResourceName === 'function') {
    return w.GetParentResourceName()
  }
  return 'RefBoard'
}

/** 小窓→全画面復帰時など、クライアントで NUI マウス／キーボードフォーカスを取り直す */
export async function refboardRecaptureNuiFocus(): Promise<void> {
  if (typeof (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName !== 'function') {
    return
  }
  try {
    await fetch(`https://${getResourceName()}/refboard:nui_focus_cursor`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: '{}',
    })
  } catch {
    /* ブラウザ単体開発時の 404 等 */
  }
}

function isInFiveM(): boolean {
  const w = window as unknown as { invokeNative?: unknown; GetParentResourceName?: () => string }
  return typeof w.invokeNative !== 'undefined' || typeof w.GetParentResourceName === 'function'
}

function useBrowserMock(): boolean {
  return Boolean(import.meta.env.DEV) && !isInFiveM()
}

export function useNui() {
  async function send<TRes>(path: string, data?: unknown): Promise<TRes> {
    const id = ++requestSeq
    const start = typeof performance !== 'undefined' ? performance.now() : 0
    if (TRACE_ENABLED()) {
      // eslint-disable-next-line no-console
      console.groupCollapsed(`[NUI] → ${path} #${id}`)
      // eslint-disable-next-line no-console
      console.log('payload:', data)
      // eslint-disable-next-line no-console
      console.log('time:', new Date().toISOString())
      // eslint-disable-next-line no-console
      console.groupEnd()
    }
    if (useBrowserMock()) {
      const res = mockResponse(path, data) as TRes
      queueMockSideEffects(path, data)
      if (TRACE_ENABLED()) {
        const elapsed = (typeof performance !== 'undefined' ? performance.now() - start : 0).toFixed(1)
        const ok = (res as { ok?: boolean })?.ok !== false
        // eslint-disable-next-line no-console
        console.groupCollapsed(`[NUI] ← ${path} #${id} ${ok ? '✓' : '✗'} (${elapsed}ms) [mock]`)
        // eslint-disable-next-line no-console
        console.log('response:', res)
        // eslint-disable-next-line no-console
        console.groupEnd()
      }
      return res
    }
    if (typeof (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName !== 'function') {
      return { ok: false, error: 'no_nui' } as TRes
    }
    try {
      const res = await fetch(`https://${getResourceName()}/${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data ?? {}),
      })
      const json = (await res.json()) as TRes
      if (TRACE_ENABLED()) {
        const elapsed = (typeof performance !== 'undefined' ? performance.now() - start : 0).toFixed(1)
        const r = json as { ok?: boolean; code?: string }
        const ok = r?.ok !== false
        // eslint-disable-next-line no-console
        console.groupCollapsed(`[NUI] ← ${path} #${id} ${ok ? '✓' : '✗'} (${elapsed}ms)`)
        // eslint-disable-next-line no-console
        console.log('response:', json)
        if (r?.code) {
          // eslint-disable-next-line no-console
          console.warn(`error code: ${r.code}`)
        }
        // eslint-disable-next-line no-console
        console.groupEnd()
      }
      return json
    } catch (e) {
      const elapsed = (typeof performance !== 'undefined' ? performance.now() - start : 0).toFixed(1)
      // eslint-disable-next-line no-console
      console.error(`[NUI] ✗ ${path} #${id} EXCEPTION (${elapsed}ms)`, e)
      throw e
    }
  }

  function on<T>(event: string, handler: (payload: T) => void): () => void {
    const listener = (e: MessageEvent) => {
      const d = e.data
      if (d && d.type === event) {
        handler(d.payload as T)
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }

  return { send, on }
}
