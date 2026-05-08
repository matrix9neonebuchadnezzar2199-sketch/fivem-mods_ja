// SPDX-License-Identifier: LGPL-3.0-or-later

import { useMemo } from 'react'
import { useBuilderStore, type PendingCatalogPick } from '../store/builderStore'
import { usePropsStore, type PropDef } from '../store/propsStore'
import { PropThumb } from './PropThumb'
import { ja } from '../i18n/ja'
import { theme } from '../theme'
import styles from './SelectionFooter.module.css'

type SelectionFooterProps = {
  onPlace: () => void
  onCancel: () => void
}

function pendingDefFor(p: PendingCatalogPick | null, dict: Record<string, PropDef>) {
  if (!p) {
    return null
  }
  return dict[p.model] ?? null
}

export function SelectionFooter({ onPlace, onCancel }: SelectionFooterProps) {
  const pendingCatalog = useBuilderStore((s) => s.pendingCatalog)
  const dictionary = usePropsStore((s) => s.dictionary)

  const def = useMemo(() => pendingDefFor(pendingCatalog, dictionary), [pendingCatalog, dictionary])

  if (!pendingCatalog) {
    return null
  }

  const label = def?.label ?? pendingCatalog.model
  const category = def?.category ?? pendingCatalog.category

  return (
    <div className={styles.inner}>
      <div className={styles.footerThumb}>
        <PropThumb
          key={pendingCatalog.model}
          model={pendingCatalog.model}
          thumbFile={def?.thumb ?? ''}
          label={label}
          category={category}
        />
      </div>
      <div className={styles.footerMeta}>
        <span className={styles.footerLabel} style={{ color: theme.text, fontSize: theme.fontSize.h2 }}>
          {label}
        </span>
        <span className={styles.footerModel} style={{ color: theme.textDim, fontSize: theme.fontSize.small }}>
          {pendingCatalog.model}
        </span>
      </div>
      <div className={styles.footerActions}>
        <div className={styles.footerActionsRow}>
          <button type="button" className={styles.placeBtn} onClick={onPlace}>
            {ja.panel.place}
          </button>
          <button type="button" className={styles.secondaryBtn} onClick={onCancel}>
            {ja.panel.cancelPick}
          </button>
        </div>
        <span className={styles.cameraHint} style={{ color: theme.textDim, fontSize: theme.fontSize.small }}>
          {ja.selection.cameraHint}
        </span>
      </div>
    </div>
  )
}
