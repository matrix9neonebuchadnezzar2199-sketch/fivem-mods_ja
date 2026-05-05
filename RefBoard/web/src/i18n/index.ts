import { createI18n } from 'vue-i18n'
import ja from './ja.json'
import en from './en.json'

const saved = typeof localStorage !== 'undefined' ? localStorage.getItem('refboard-locale') : null

export const i18n = createI18n({
  legacy: false,
  locale: saved === 'en' ? 'en' : 'ja',
  fallbackLocale: 'en',
  messages: { ja, en },
})
