import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import { router } from './router'
import { i18n } from './i18n'
import { useSettingsStore } from './stores/settings'
import './styles/main.css'

const app = createApp(App)
const pinia = createPinia()
app.use(pinia)
useSettingsStore().load()
app.use(router)
app.use(i18n)
app.config.errorHandler = (err, _instance, info) => {
  // eslint-disable-next-line no-console
  console.error('[RefBoard NUI]', info, err)
}
app.mount('#app')
