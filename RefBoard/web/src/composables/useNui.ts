import { mockResponse, queueMockSideEffects } from '../mocks/nuiMock'

export function getResourceName(): string {
  const w = window as unknown as { GetParentResourceName?: () => string }
  if (typeof w.GetParentResourceName === 'function') {
    return w.GetParentResourceName()
  }
  return 'RefBoard'
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
    if (useBrowserMock()) {
      const res = mockResponse(path, data) as TRes
      queueMockSideEffects(path, data)
      return res
    }
    if (typeof (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName !== 'function') {
      return { ok: false, error: 'no_nui' } as TRes
    }
    const res = await fetch(`https://${getResourceName()}/${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    })
    return (await res.json()) as TRes
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
