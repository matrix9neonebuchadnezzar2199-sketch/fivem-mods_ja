import { nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore, DEFAULT_EDIT_PASSWORD } from '../stores/session'
import { fetchRefboardCloseNui } from './refboardCloseLua'

/** NUI を閉じてランチャーへ戻る（F6 / Close 共通） */
export function useRefboardClose() {
  const router = useRouter()
  const session = useSessionStore()

  async function closeApp() {
    // 先に Lua で必ず session:leave + lock:release（session.leave の fetch が遅延・固着してもサーバ解放が先に走る）
    await fetchRefboardCloseNui()
    await nextTick()
    await nextTick()
    try {
      await session.leave()
    } catch {
      /* NUI 送信失敗時も続行 */
    }
    session.editPassword = DEFAULT_EDIT_PASSWORD
    await router.push({ name: 'launcher' })
  }

  return { closeApp }
}
