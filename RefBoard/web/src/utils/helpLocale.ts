/** Help コンテンツのロケール（記事・index・reverse_index・Fuse インデックス）。 */
export type HelpLocale = 'ja' | 'en'

export function resolveHelpLocale(i18nLocale: string): HelpLocale {
  return i18nLocale === 'en' ? 'en' : 'ja'
}
