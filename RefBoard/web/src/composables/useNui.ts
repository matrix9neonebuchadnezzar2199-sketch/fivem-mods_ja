export function getResourceName(): string {
  const w = window as unknown as { GetParentResourceName?: () => string }
  if (typeof w.GetParentResourceName === 'function') {
    return w.GetParentResourceName()
  }
  return 'RefBoard'
}

export function useNui() {
  async function send<TRes>(path: string, data?: unknown): Promise<TRes> {
    if (typeof (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName !== 'function') {
      return { ok: true, mock: true } as TRes
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
