// SPDX-License-Identifier: LGPL-3.0-or-later

import { useMemo } from 'react'
import { useBuilderStore } from '../store/builderStore'
import { getTopTagsForModels, listModelsForCategory, usePropsStore } from '../store/propsStore'
import { ja } from '../i18n/ja'
import { theme } from '../theme'
import styles from './TagFilter.module.css'

const TAG_CHIP_LIMIT = 18

export function TagFilter() {
  const selectedCategory = useBuilderStore((s) => s.selectedCategory)
  const dictionary = usePropsStore((s) => s.dictionary)
  const selectedTags = usePropsStore((s) => s.selectedTags)
  const toggleTag = usePropsStore((s) => s.toggleTag)
  const clearTags = usePropsStore((s) => s.clearTags)

  const baseModels = useMemo(
    () => listModelsForCategory(selectedCategory, dictionary),
    [selectedCategory, dictionary],
  )

  const topTags = useMemo(
    () => getTopTagsForModels(baseModels, dictionary, TAG_CHIP_LIMIT),
    [baseModels, dictionary],
  )

  if (!selectedCategory || baseModels.length === 0 || topTags.length === 0) {
    return null
  }

  return (
    <div className={styles.root}>
      <div className={styles.head}>
        <span className={styles.title} style={{ color: theme.textDim }}>
          {ja.tagFilter.title}
        </span>
        {selectedTags.length > 0 && (
          <button type="button" className={styles.clearAll} onClick={() => clearTags()}>
            {ja.tagFilter.clearAll}
          </button>
        )}
      </div>
      <div className={styles.chips} role="group" aria-label={ja.tagFilter.title}>
        {topTags.map(({ tag, count }) => {
          const on = selectedTags.some((t) => t.toLowerCase() === tag.toLowerCase())
          return (
            <button
              key={tag}
              type="button"
              className={`${styles.chip} ${on ? styles.chipOn : ''}`}
              style={{
                color: on ? theme.text : theme.textDim,
                borderColor: on ? 'rgba(79, 195, 247, 0.55)' : 'rgba(255, 255, 255, 0.12)',
                background: on ? 'rgba(79, 195, 247, 0.2)' : 'rgba(255, 255, 255, 0.04)',
              }}
              onClick={() => toggleTag(tag)}
            >
              {tag}
              <span className={styles.chipCount}>({count})</span>
            </button>
          )
        })}
      </div>
    </div>
  )
}
