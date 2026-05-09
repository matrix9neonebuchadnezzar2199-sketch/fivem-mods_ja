import { ref } from 'vue'

/** Lua `RegisterNUICallback` にそのまま POST するパス（v0.1.0 クライアントに残っているもの） */
const LUA_NUI_CALLBACK_PATHS = new Set([
  'close',
  'compact_dock_state',
  'compact_toggle_input',
  'refboard:nui_focus_cursor',
])

/** Lua `SendNUIMessage` のみで届くイベント（サーバー push ではない） */
const LUA_WINDOW_MESSAGE_EVENTS = new Set(['refboard:compact_input_mode'])

/** ブラウザ単体開発か FiveM NUI 内か */
export function isInFiveM(): boolean {
  const w = window as unknown as { invokeNative?: unknown; GetParentResourceName?: () => string }
  return typeof w.invokeNative !== 'undefined' || typeof w.GetParentResourceName === 'function'
}

export function getResourceName(): string {
  const w = window as unknown as { GetParentResourceName?: () => string }
  if (typeof w.GetParentResourceName === 'function') {
    try {
      return w.GetParentResourceName()
    } catch {
      return 'RefBoard'
    }
  }
  return 'RefBoard'
}

async function postToLua(path: string, data?: unknown): Promise<unknown> {
  if (!isInFiveM()) {
    return { ok: true }
  }
  try {
    const res = await fetch(`https://${getResourceName()}/${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    })
    return await res.json().catch(() => ({ ok: true }))
  } catch {
    return { ok: false }
  }
}

/**
 * 旧版互換のシグネチャだけ残した薄いラッパ。
 * - `close` / 小窓系は Lua の RegisterNUICallback を叩く
 * - それ以外は `{ ok: true }`（実体はローカルストアが直接処理する想定）
 */
export function useNui() {
  async function send<TRes = { ok: boolean }>(path: string, data?: unknown): Promise<TRes> {
    if (LUA_NUI_CALLBACK_PATHS.has(path)) {
      return (await postToLua(path, data)) as TRes
    }
    if (import.meta.env.DEV) {
      // eslint-disable-next-line no-console
      console.warn(
        `[useNui] send('${path}') はローカル版では無効化されています。ストア直叩きに置き換えてください。`,
      )
    }
    return { ok: true } as TRes
  }

  function on<T>(_event: string, _handler: (payload: T) => void): () => void {
    if (!LUA_WINDOW_MESSAGE_EVENTS.has(_event)) {
      return () => {}
    }
    const listener = (e: MessageEvent) => {
      const d = e.data as { type?: string; payload?: T } | undefined
      if (d?.type === _event) {
        _handler((d.payload ?? d) as T)
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }

  return { send, on }
}

export const nuiReady = ref(true)
