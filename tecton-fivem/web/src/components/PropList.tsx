// SPDX-License-Identifier: LGPL-3.0-or-later

import type { CSSProperties } from 'react'
import { useCallback, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { List } from 'react-window'
import { fetchNui } from '../lib/nui'
import { ja } from '../i18n/ja'
import { theme } from '../theme'
import { listModelsForCategory, usePropsStore } from '../store/propsStore'
import { useBuilderStore } from '../store/builderStore'
import styles from '../pages/Builder.module.css'

/** 3rem を px に近似的に（ルート font-size 連動） */
function itemSizePx(): number {
  const root = typeof document !== 'undefined' ? parseFloat(getComputedStyle(document.documentElement).fontSize) : 16
  return 3 * root
}

type RowProps = {
  models: string[]
  dictionary: Record<string, { label: string; category: string }>
  onPick: (model: string) => void
}

type RowComponentProps = RowProps & {
  index: number
  style: CSSProperties
  ariaAttributes: {
    'aria-posinset': number
    'aria-setsize': number
    role: 'listitem'
  }
}

function Row({ index, style, ariaAttributes, models, dictionary, onPick }: RowComponentProps) {
  const model = models[index]
  const def = dictionary[model]
  return (
    <div style={style} {...ariaAttributes}>
      <button type="button" className={styles.propRow} style={{ color: theme.text }} onClick={() => onPick(model)}>
        <span className={styles.propRowLabel}>{def?.label ?? model}</span>
        <span className={styles.propRowModel} style={{ color: theme.textDim }}>
          {model}
        </span>
      </button>
    </div>
  )
}

type PropListProps = {
  onPlaced: (ok: boolean, id?: number, reason?: string) => void
}

export function PropList({ onPlaced }: PropListProps) {
  const dictionary = usePropsStore((s) => s.dictionary)
  const selectedCategory = useBuilderStore((s) => s.selectedCategory)
  const wrapRef = useRef<HTMLDivElement>(null)
  const [listHeight, setListHeight] = useState(320)
  const [listWidth, setListWidth] = useState(400)
  const [itemSize, setItemSize] = useState(() => itemSizePx())

  useLayoutEffect(() => {
    const el = wrapRef.current
    if (!el) {
      return
    }
    const ro = new ResizeObserver(() => {
      setListHeight(Math.max(120, el.clientHeight))
      setListWidth(Math.max(200, el.clientWidth))
      setItemSize(itemSizePx())
    })
    ro.observe(el)
    setListHeight(Math.max(120, el.clientHeight))
    setListWidth(Math.max(200, el.clientWidth))
    setItemSize(itemSizePx())
    return () => ro.disconnect()
  }, [selectedCategory])

  const models = useMemo(() => listModelsForCategory(selectedCategory, dictionary), [selectedCategory, dictionary])

  const onPick = useCallback(
    async (model: string) => {
      const cat = dictionary[model]?.category ?? selectedCategory ?? 'furniture'
      const res = await fetchNui<{ ok?: boolean; id?: number; reason?: string }>('createObject', {
        mode: 'furniture' as const,
        model,
        category: cat,
      })
      if (res?.ok && typeof res.id === 'number') {
        onPlaced(true, res.id)
      } else {
        const reason = typeof res?.reason === 'string' ? res.reason : 'unknown'
        onPlaced(false, undefined, reason)
      }
    },
    [onPlaced, dictionary, selectedCategory],
  )

  const rowProps: RowProps = useMemo(
    () => ({
      models,
      dictionary,
      onPick,
    }),
    [models, dictionary, onPick],
  )

  if (!selectedCategory) {
    return (
      <div className={styles.propListPlaceholder} style={{ color: theme.textDim, fontSize: theme.fontSize.body }}>
        {ja.props.selectCategory}
      </div>
    )
  }

  if (models.length === 0) {
    return (
      <div className={styles.propListPlaceholder} style={{ color: theme.textDim, fontSize: theme.fontSize.body }}>
        {ja.props.emptyCategory}
      </div>
    )
  }

  return (
    <div ref={wrapRef} className={styles.propListWrap}>
      <List<RowProps>
        rowCount={models.length}
        rowHeight={itemSize}
        rowProps={rowProps}
        rowComponent={Row}
        overscanCount={10}
        style={{ height: listHeight, width: listWidth }}
      />
    </div>
  )
}
