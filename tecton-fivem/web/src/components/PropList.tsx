// SPDX-License-Identifier: LGPL-3.0-or-later

import type { CSSProperties } from 'react'
import { useCallback, useDeferredValue, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { Grid } from 'react-window'
import { fetchNui } from '../lib/nui'
import { ja } from '../i18n/ja'
import { theme } from '../theme'
import { filterModelsBySearch, listModelsForCategory, type PropDef, usePropsStore } from '../store/propsStore'
import { useBuilderStore } from '../store/builderStore'
import { PropThumb } from './PropThumb'
import styles from '../pages/Builder.module.css'
import gridStyles from './PropGrid.module.css'

/** グリッド行の高さ（rem 相当を px に）。サムネ + ラベル2行 + 余白 */
function gridRowHeightPx(): number {
  const root = typeof document !== 'undefined' ? parseFloat(getComputedStyle(document.documentElement).fontSize) : 16
  return 7 * root + 8
}

const MIN_COL_PX = 92

type CellProps = {
  models: string[]
  dictionary: Record<string, PropDef>
  onPick: (model: string) => void
  columnCount: number
}

type GridCellProps = CellProps & {
  columnIndex: number
  rowIndex: number
  style: CSSProperties
  ariaAttributes: {
    'aria-colindex': number
    role: 'gridcell'
  }
}

function GridCell({ rowIndex, columnIndex, style, ariaAttributes, models, dictionary, onPick, columnCount }: GridCellProps) {
  const index = rowIndex * columnCount + columnIndex
  if (index >= models.length) {
    return <div style={style} className={gridStyles.cellEmpty} />
  }
  const model = models[index]
  const def = dictionary[model]
  const label = def?.label ?? model
  const category = def?.category ?? 'furniture'
  const thumbFile = def?.thumb ?? ''

  return (
    <div style={style} {...ariaAttributes} className={gridStyles.cellPad}>
      <button type="button" className={gridStyles.card} style={{ color: theme.text }} onClick={() => onPick(model)}>
        <PropThumb key={model} thumbFile={thumbFile} label={label} category={category} />
        <div className={gridStyles.meta}>
          <span className={gridStyles.label}>{label}</span>
          <span className={gridStyles.model} style={{ color: theme.textDim }}>
            {model}
          </span>
        </div>
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
  const searchQuery = useBuilderStore((s) => s.searchQuery)
  const deferredQuery = useDeferredValue(searchQuery)
  const wrapRef = useRef<HTMLDivElement>(null)
  const [listHeight, setListHeight] = useState(320)
  const [listWidth, setListWidth] = useState(400)
  const [rowHeightPx, setRowHeightPx] = useState(() => gridRowHeightPx())

  useLayoutEffect(() => {
    const el = wrapRef.current
    if (!el) {
      return
    }
    const ro = new ResizeObserver(() => {
      setListHeight(Math.max(120, el.clientHeight))
      setListWidth(Math.max(200, el.clientWidth))
      setRowHeightPx(gridRowHeightPx())
    })
    ro.observe(el)
    setListHeight(Math.max(120, el.clientHeight))
    setListWidth(Math.max(200, el.clientWidth))
    setRowHeightPx(gridRowHeightPx())
    return () => ro.disconnect()
  }, [selectedCategory])

  const columnCount = useMemo(() => {
    if (listWidth <= 0) {
      return 1
    }
    return Math.max(1, Math.floor(listWidth / MIN_COL_PX))
  }, [listWidth])

  const columnWidth = useMemo(() => Math.max(1, Math.floor(listWidth / columnCount)), [listWidth, columnCount])

  const baseModels = useMemo(() => listModelsForCategory(selectedCategory, dictionary), [selectedCategory, dictionary])

  const models = useMemo(
    () => filterModelsBySearch(baseModels, dictionary, deferredQuery),
    [baseModels, dictionary, deferredQuery],
  )

  const rowCount = useMemo(() => Math.ceil(models.length / columnCount), [models.length, columnCount])

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

  const cellProps: CellProps = useMemo(
    () => ({
      models,
      dictionary,
      onPick,
      columnCount,
    }),
    [models, dictionary, onPick, columnCount],
  )

  if (!selectedCategory) {
    return (
      <div className={styles.propListPlaceholder} style={{ color: theme.textDim, fontSize: theme.fontSize.body }}>
        {ja.props.selectCategory}
      </div>
    )
  }

  if (baseModels.length === 0) {
    return (
      <div className={styles.propListPlaceholder} style={{ color: theme.textDim, fontSize: theme.fontSize.body }}>
        {ja.props.emptyCategory}
      </div>
    )
  }

  if (models.length === 0) {
    return (
      <div className={styles.propListPlaceholder} style={{ color: theme.textDim, fontSize: theme.fontSize.body }}>
        {ja.props.searchNoResults}
      </div>
    )
  }

  return (
    <div
      ref={wrapRef}
      className={styles.propListWrap}
      role="region"
      aria-label={ja.props.propGridAria}
    >
      <Grid<CellProps>
        key={`${selectedCategory}|${deferredQuery}`}
        columnCount={columnCount}
        columnWidth={columnWidth}
        rowCount={rowCount}
        rowHeight={rowHeightPx}
        cellComponent={GridCell}
        cellProps={cellProps}
        overscanCount={2}
        style={{ height: listHeight, width: listWidth }}
      />
    </div>
  )
}
