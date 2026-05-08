// SPDX-License-Identifier: LGPL-3.0-or-later

import type { CSSProperties } from 'react'
import { useCallback, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { Grid } from 'react-window'
import { SEARCH_DEBOUNCE_MS } from '../lib/constants'
import { useDebounce } from '../lib/useDebounce'
import { ja } from '../i18n/ja'
import { theme } from '../theme'
import {
  filterModelsBySearch,
  filterModelsByTags,
  listModelsForCategory,
  type PropDef,
  usePropsStore,
} from '../store/propsStore'
import { useBuilderStore } from '../store/builderStore'
import { PropThumb } from './PropThumb'
import styles from '../pages/Builder.module.css'
import gridStyles from './PropGrid.module.css'

/** グリッド行の高さ（rem 相当を px に）。サムネ + ラベル2行 + 余白 */
function gridRowHeightPx(): number {
  const root = typeof document !== 'undefined' ? parseFloat(getComputedStyle(document.documentElement).fontSize) : 16
  return 7 * root + 8
}

/** 最小幅（px）。狭いときは列数が 1〜3 に縮退 */
const MIN_COL_PX = 140
/** 広いときの列数上限（固定 4 列まで） */
const MAX_PROP_GRID_COLUMNS = 4

type CellProps = {
  models: string[]
  dictionary: Record<string, PropDef>
  onPick: (model: string, category: string) => void
  columnCount: number
  pendingModel: string | null
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

function GridCell({
  rowIndex,
  columnIndex,
  style,
  ariaAttributes,
  models,
  dictionary,
  onPick,
  columnCount,
  pendingModel,
}: GridCellProps) {
  const index = rowIndex * columnCount + columnIndex
  if (index >= models.length) {
    return <div style={style} className={gridStyles.cellEmpty} />
  }
  const model = models[index]
  const def = dictionary[model]
  const label = def?.label ?? model
  const category = def?.category ?? 'furniture'
  const thumbFile = def?.thumb ?? ''
  const cat = def?.category ?? 'furniture'

  const isPendingPick = pendingModel === model

  return (
    <div style={style} {...ariaAttributes} className={gridStyles.cellPad}>
      <button
        type="button"
        className={`${gridStyles.card} ${isPendingPick ? gridStyles.cardSelected : ''}`}
        style={{ color: theme.text }}
        onClick={() => onPick(model, cat)}
      >
        <PropThumb key={model} model={model} thumbFile={thumbFile} label={label} category={category} />
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

export function PropList() {
  const dictionary = usePropsStore((s) => s.dictionary)
  const selectedCategory = useBuilderStore((s) => s.selectedCategory)
  const setPendingCatalog = useBuilderStore((s) => s.setPendingCatalog)
  const pendingModel = useBuilderStore((s) => s.pendingCatalog?.model ?? null)
  const searchQuery = useBuilderStore((s) => s.searchQuery)
  const debouncedQuery = useDebounce(searchQuery, SEARCH_DEBOUNCE_MS)
  const selectedTags = usePropsStore((s) => s.selectedTags)
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
    const fromWidth = Math.max(1, Math.floor(listWidth / MIN_COL_PX))
    return Math.min(MAX_PROP_GRID_COLUMNS, fromWidth)
  }, [listWidth])

  const columnWidth = useMemo(() => Math.max(1, Math.floor(listWidth / columnCount)), [listWidth, columnCount])

  const gridWidth = useMemo(() => columnWidth * columnCount, [columnWidth, columnCount])

  const baseModels = useMemo(() => listModelsForCategory(selectedCategory, dictionary), [selectedCategory, dictionary])

  const models = useMemo(() => {
    const afterSearch = filterModelsBySearch(baseModels, dictionary, debouncedQuery)
    return filterModelsByTags(afterSearch, dictionary, selectedTags)
  }, [baseModels, dictionary, debouncedQuery, selectedTags])

  const rowCount = useMemo(() => Math.ceil(models.length / columnCount), [models.length, columnCount])

  const onPick = useCallback(
    (model: string, category: string) => {
      const cat = dictionary[model]?.category ?? category ?? selectedCategory ?? 'furniture'
      setPendingCatalog({ model, category: cat })
    },
    [dictionary, selectedCategory, setPendingCatalog],
  )

  const cellProps: CellProps = useMemo(
    () => ({
      models,
      dictionary,
      onPick,
      columnCount,
      pendingModel,
    }),
    [models, dictionary, onPick, columnCount, pendingModel],
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
        {ja.search.noResults}
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
        key={`${selectedCategory}|${debouncedQuery}|${selectedTags.join('\u0001')}`}
        columnCount={columnCount}
        columnWidth={columnWidth}
        rowCount={rowCount}
        rowHeight={rowHeightPx}
        cellComponent={GridCell}
        cellProps={cellProps}
        overscanCount={2}
        style={{ height: listHeight, width: gridWidth }}
      />
    </div>
  )
}
