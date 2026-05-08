// SPDX-License-Identifier: LGPL-3.0-or-later

import { useCallback, useState } from 'react'
import { usePropsStore, type CategoryNode } from '../store/propsStore'
import { useBuilderStore } from '../store/builderStore'
import { theme } from '../theme'
import styles from './CategoryTree.module.css'

export function CategoryTree() {
  const categories = usePropsStore((s) => s.categories)
  const selectedPath = useBuilderStore((s) => s.selectedCategory)
  const setSelectedCategory = useBuilderStore((s) => s.setSelectedCategory)
  const clearTags = usePropsStore((s) => s.clearTags)
  const [expandedIds, setExpandedIds] = useState<Set<string>>(() => new Set())

  const toggleExpanded = useCallback((id: string) => {
    setExpandedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
  }, [])

  const onSelectRoot = useCallback(
    (node: CategoryNode) => {
      toggleExpanded(node.id)
      clearTags()
      setSelectedCategory(node.path)
    },
    [setSelectedCategory, toggleExpanded, clearTags],
  )

  const onSelectChild = useCallback(
    (path: string) => {
      clearTags()
      setSelectedCategory(path)
    },
    [setSelectedCategory, clearTags],
  )

  return (
    <div className={styles.root} style={{ fontSize: theme.fontSize.bodyLarge }} role="tree" aria-label="categories">
      {categories.map((root) => {
        const expanded = expandedIds.has(root.id)
        const rootSelected = selectedPath === root.path
        return (
          <div key={root.id}>
            <button
              type="button"
              className={`${styles.nodeRow} ${rootSelected ? styles.nodeSelected : ''}`}
              style={{ color: theme.text }}
              onClick={() => onSelectRoot(root)}
              aria-expanded={expanded}
            >
              <span className={styles.chevron} aria-hidden>
                {expanded ? '▼' : '▶'}
              </span>
              <span className={styles.label}>{root.label}</span>
              <span className={styles.badge} style={{ color: theme.textDim, fontSize: theme.fontSize.treeBadge }}>
                ({root.count ?? 0})
              </span>
            </button>
            {expanded &&
              root.children?.map((ch) => {
                const sel = selectedPath === ch.path
                return (
                  <button
                    key={ch.path}
                    type="button"
                    className={`${styles.nodeRow} ${styles.childIndent} ${sel ? styles.nodeSelected : ''}`}
                    style={{ color: theme.text }}
                    onClick={() => onSelectChild(ch.path)}
                  >
                    <span className={styles.chevron} aria-hidden />
                    <span className={styles.label}>{ch.label}</span>
                    <span className={styles.badge} style={{ color: theme.textDim, fontSize: theme.fontSize.treeBadge }}>
                      ({ch.count ?? 0})
                    </span>
                  </button>
                )
              })}
          </div>
        )
      })}
    </div>
  )
}
