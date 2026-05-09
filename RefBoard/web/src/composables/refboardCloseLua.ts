import { getResourceName } from './useNui'

/**
 * Lua `RegisterNUICallback('refboard:close')` → `setOpen(false)` を呼ぶ。
 * サーバへの `refboard:session:leave` / `refboard:lock:release` はクライアント Lua が必ず発行する（NUI の fetch が固着しても先に済ませる）。
 */
export async function fetchRefboardCloseNui(): Promise<void> {
  if (typeof (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName !== 'function') {
    return
  }
  try {
    await fetch(`https://${getResourceName()}/refboard:close`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: '{}',
    })
  } catch {
    /* ブラウザ単体開発時の 404 等 */
  }
}
