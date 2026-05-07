import { useTranslation } from 'react-i18next';

/** 新規文言は shared/locale/*.json にキーを追加し、ここから `t('KEY')` で参照 */
export function useAppTranslation() {
  return useTranslation();
}
