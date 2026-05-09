import { useRouter } from 'vue-router'
import { useSessionStore, DEFAULT_EDIT_PASSWORD } from '../stores/session'
import { getResourceName } from './useNui'

/** NUI を閉じてランチャーへ戻る（F6 / Close 共通） */
export function useRefboardClose() {
  const router = useRouter()
  const session = useSessionStore()

  async function closeApp() {
    try {
      await session.leave()
    } catch {
      /* NUI 送信失敗時もフォーカス解除は続行 */
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
    session.editPassword = DEFAULT_EDIT_PASSWORD
    await router.push({ name: 'launcher' })
  }

  return { closeApp }
}
