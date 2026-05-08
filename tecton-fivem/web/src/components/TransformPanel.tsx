// SPDX-License-Identifier: LGPL-3.0-or-later

import { useCallback, useState } from 'react'
import { fetchNui } from '../lib/nui'
import { ja } from '../i18n/ja'
import { theme } from '../theme'
import type { SelectedEntity } from '../store/builderStore'
import styles from './TransformPanel.module.css'

type TransformPanelProps = {
  entity: SelectedEntity
  onToast: (kind: 'ok' | 'err', text: string) => void
}

function fmt(n: number): string {
  const s = Number.isFinite(n) ? String(n) : '0'
  if (s.includes('e') || s.includes('E')) {
    return n.toFixed(4)
  }
  return s
}

export function TransformPanel({ entity, onToast }: TransformPanelProps) {
  const [px, setPx] = useState(() => fmt(entity.pos.x))
  const [py, setPy] = useState(() => fmt(entity.pos.y))
  const [pz, setPz] = useState(() => fmt(entity.pos.z))
  const [rx, setRx] = useState(() => fmt(entity.rot.x))
  const [ry, setRy] = useState(() => fmt(entity.rot.y))
  const [rz, setRz] = useState(() => fmt(entity.rot.z))
  const [busy, setBusy] = useState(false)

  const parseVec = useCallback((sx: string, sy: string, sz: string) => {
    const x = Number(sx.trim().replace(',', '.'))
    const y = Number(sy.trim().replace(',', '.'))
    const z = Number(sz.trim().replace(',', '.'))
    if (![x, y, z].every((v) => Number.isFinite(v))) {
      return null
    }
    return { x, y, z }
  }, [])

  const onApply = useCallback(async () => {
    const pos = parseVec(px, py, pz)
    const rot = parseVec(rx, ry, rz)
    if (!pos || !rot) {
      onToast('err', ja.transform.invalidNumber)
      return
    }
    setBusy(true)
    const res = await fetchNui<{ ok?: boolean }>('updateObject', {
      id: entity.id,
      after: { pos, rot },
    })
    setBusy(false)
    if (res?.ok) {
      onToast('ok', ja.transform.applyOk)
    } else {
      onToast('err', ja.transform.applyFailed)
    }
  }, [entity.id, px, py, pz, rx, ry, rz, parseVec, onToast])

  const onClear = useCallback(async () => {
    await fetchNui('selectObject', {})
  }, [])

  return (
    <div className={styles.root}>
      <div className={styles.meta} style={{ color: theme.textDim }}>
        <span className={styles.metaId}>ID {entity.id}</span>
        <span className={styles.metaModel} title={entity.model}>
          {entity.model}
        </span>
      </div>

      <fieldset className={styles.fieldset}>
        <legend className={styles.legend} style={{ color: theme.text }}>
          {ja.transform.position}
        </legend>
        <div className={styles.row3}>
          <label className={styles.cell}>
            <span className={styles.axis} style={{ color: theme.danger }}>
              X
            </span>
            <input className={styles.input} value={px} onChange={(e) => setPx(e.target.value)} inputMode="decimal" />
          </label>
          <label className={styles.cell}>
            <span className={styles.axis} style={{ color: '#4ade80' }}>
              Y
            </span>
            <input className={styles.input} value={py} onChange={(e) => setPy(e.target.value)} inputMode="decimal" />
          </label>
          <label className={styles.cell}>
            <span className={styles.axis} style={{ color: theme.accent }}>
              Z
            </span>
            <input className={styles.input} value={pz} onChange={(e) => setPz(e.target.value)} inputMode="decimal" />
          </label>
        </div>
      </fieldset>

      <fieldset className={styles.fieldset}>
        <legend className={styles.legend} style={{ color: theme.text }}>
          {ja.transform.rotation}
        </legend>
        <div className={styles.row3}>
          <label className={styles.cell}>
            <span className={styles.axis} style={{ color: theme.danger }}>
              X
            </span>
            <input className={styles.input} value={rx} onChange={(e) => setRx(e.target.value)} inputMode="decimal" />
          </label>
          <label className={styles.cell}>
            <span className={styles.axis} style={{ color: '#4ade80' }}>
              Y
            </span>
            <input className={styles.input} value={ry} onChange={(e) => setRy(e.target.value)} inputMode="decimal" />
          </label>
          <label className={styles.cell}>
            <span className={styles.axis} style={{ color: theme.accent }}>
              Z
            </span>
            <input className={styles.input} value={rz} onChange={(e) => setRz(e.target.value)} inputMode="decimal" />
          </label>
        </div>
      </fieldset>

      <p className={styles.hint} style={{ color: theme.textDim }}>
        {ja.transform.hint}
      </p>

      <div className={styles.actions}>
        <button type="button" className={styles.applyBtn} disabled={busy} onClick={() => void onApply()}>
          {busy ? ja.transform.applying : ja.transform.apply}
        </button>
        <button type="button" className={styles.secondaryBtn} onClick={() => void onClear()}>
          {ja.transform.clearSelection}
        </button>
      </div>
    </div>
  )
}
