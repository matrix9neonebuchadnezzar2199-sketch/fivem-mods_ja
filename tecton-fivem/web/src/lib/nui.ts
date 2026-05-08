// SPDX-License-Identifier: LGPL-3.0-or-later

/**
 * 開発用ブラウザでは GetParentResourceName / invokeNative が無い。
 * 本番（FiveM NUI）ではリソースフォルダ名（例: tecton-fivem）が使われる。
 */
const RESOURCE_FALLBACK = 'tecton-fivem'

function getResourceName(): string {
  const w = window as unknown as { GetParentResourceName?: () => string }
  if (typeof w.GetParentResourceName === 'function') {
    return w.GetParentResourceName()
  }
  return RESOURCE_FALLBACK
}

function isNuiRuntime(): boolean {
  const w = window as unknown as { invokeNative?: unknown; GetParentResourceName?: unknown }
  return typeof w.invokeNative === 'function' || typeof w.GetParentResourceName === 'function'
}

export async function fetchNui<T>(event: string, data?: unknown): Promise<T> {
  if (!isNuiRuntime()) {
    return {} as T
  }
  const resource = getResourceName()
  const resp = await fetch(`https://${resource}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  })
  const text = await resp.text()
  if (!text || text === 'null' || text === 'undefined') {
    return {} as T
  }
  try {
    return JSON.parse(text) as T
  } catch {
    return text as unknown as T
  }
}

export type NuiMessage<T = unknown> = { action?: string } & T

export function onNuiMessage<T = unknown>(handler: (msg: NuiMessage<T>) => void): () => void {
  const listener = (ev: MessageEvent) => {
    handler(ev.data as NuiMessage<T>)
  }
  window.addEventListener('message', listener)
  return () => window.removeEventListener('message', listener)
}
