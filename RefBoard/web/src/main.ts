import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import { router } from './router'
import { i18n } from './i18n'
import { useSettingsStore } from './stores/settings'
import { useToast } from './composables/useToast'
import { vMarquee } from './directives/marquee'
import { setNuiShellOpenFromLua } from './nuiShellVisibility'
import './styles/main.css'
import './styles/marquee.css'
import './styles/score-flash.css'

/** Lua client/main.lua の SendNUIMessage({ type: 'refboard:setOpen', ... }) と同期 */
window.addEventListener('message', (e: MessageEvent) => {
  const d = e.data as { type?: string; payload?: { open?: boolean } } | undefined
  if (d?.type === 'refboard:setOpen') {
    setNuiShellOpenFromLua(Boolean(d.payload?.open))
  }
})

const app = createApp(App)
const pinia = createPinia()
app.use(pinia)
useSettingsStore().load()
app.directive('marquee', vMarquee)
app.use(router)
app.use(i18n)
app.config.errorHandler = (err, _instance, info) => {
  // eslint-disable-next-line no-console
  console.error('[RefBoard NUI]', info, err)
  try {
    useToast().push(`[RefBoard] ${String((err as Error)?.message ?? err)}`, 'error', 4000)
  } catch {
    /* ignore */
  }
}
app.mount('#app')

window.addEventListener('error', (event) => {
  // eslint-disable-next-line no-console
  console.error('[RefBoard] window error:', event.error)
  try {
    useToast().push(`予期しないエラー: ${event.message}`, 'error', 4000)
  } catch {
    /* ignore */
  }
})

window.addEventListener('unhandledrejection', (event) => {
  // eslint-disable-next-line no-console
  console.error('[RefBoard] unhandled rejection:', event.reason)
  try {
    useToast().push('通信処理でエラーが発生しました', 'error', 4000)
  } catch {
    /* ignore */
  }
})

/** DEV のみ: フェーズ2b 目視（Toast 長文・ticker）用。本番ビルドでは import.meta.env.DEV が false のためバンドルから除去される想定 */
if (import.meta.env.DEV) {
  const w = window as unknown as {
    __refboardToastPush?: (msg: string, kind?: 'error' | 'success' | 'info', durationMs?: number) => void
  }
  w.__refboardToastPush = (msg, kind = 'error', durationMs = 30000) => {
    useToast().push(msg, kind, durationMs)
  }
}
