// SPDX-License-Identifier: LGPL-3.0-or-later

import { useBuilderStore } from '../store/builderStore'
import { ja } from '../i18n/ja'
import { theme } from '../theme'
import styles from './SearchBar.module.css'

export function SearchBar() {
  const searchQuery = useBuilderStore((s) => s.searchQuery)
  const setSearchQuery = useBuilderStore((s) => s.setSearchQuery)

  return (
    <div className={styles.wrap}>
      <input
        type="search"
        className={styles.input}
        value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
        placeholder={ja.search.placeholder}
        aria-label={ja.search.ariaLabel}
        autoComplete="off"
        spellCheck={false}
      />
      <div className={styles.hint} style={{ color: theme.textDim }}>
        {ja.search.hint}
      </div>
      <div className={styles.hint} style={{ color: theme.textDim, opacity: 0.8, marginTop: '0.125rem', fontSize: '0.8125rem' }}>
        {ja.search.cameraLookHint}
      </div>
    </div>
  )
}
