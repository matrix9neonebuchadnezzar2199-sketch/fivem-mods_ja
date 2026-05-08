// SPDX-License-Identifier: LGPL-3.0-or-later

import { useMemo } from 'react'
import { SEARCH_DEBOUNCE_MS } from '../lib/constants'
import { useDebounce } from '../lib/useDebounce'
import { useBuilderStore } from '../store/builderStore'
import { filterModelsBySearch, filterModelsByTags, listModelsForCategory, usePropsStore } from '../store/propsStore'
import { ja, tf } from '../i18n/ja'
import { theme } from '../theme'
import styles from './CatalogHitCount.module.css'

export function CatalogHitCount() {
  const selectedCategory = useBuilderStore((s) => s.selectedCategory)
  const searchQuery = useBuilderStore((s) => s.searchQuery)
  const debouncedQuery = useDebounce(searchQuery, SEARCH_DEBOUNCE_MS)
  const selectedTags = usePropsStore((s) => s.selectedTags)
  const dictionary = usePropsStore((s) => s.dictionary)

  const count = useMemo(() => {
    if (!selectedCategory) {
      return 0
    }
    const base = listModelsForCategory(selectedCategory, dictionary)
    const afterSearch = filterModelsBySearch(base, dictionary, debouncedQuery)
    return filterModelsByTags(afterSearch, dictionary, selectedTags).length
  }, [selectedCategory, dictionary, debouncedQuery, selectedTags])

  if (!selectedCategory) {
    return null
  }

  return (
    <div className={styles.line} style={{ color: theme.textDim }}>
      {tf(ja.search.hitCount, { count })}
    </div>
  )
}
