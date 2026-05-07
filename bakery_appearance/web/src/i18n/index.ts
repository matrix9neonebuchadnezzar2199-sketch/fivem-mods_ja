import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import ja from '../../../shared/locale/ja.json';
import en from '../../../shared/locale/en.json';
import de from '../../../shared/locale/de.json';

void i18n.use(initReactI18next).init({
  resources: {
    ja: { translation: ja as Record<string, string> },
    en: { translation: en as Record<string, string> },
    de: { translation: de as Record<string, string> },
  },
  lng: 'ja',
  fallbackLng: 'en',
  interpolation: { escapeValue: false },
});

export default i18n;
