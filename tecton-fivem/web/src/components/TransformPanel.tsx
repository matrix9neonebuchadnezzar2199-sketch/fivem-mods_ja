// SPDX-License-Identifier: LGPL-3.0-or-later

import { useCallback, useMemo, useState } from 'react'
import { fetchNui } from '../lib/nui'
import { ja, tf } from '../i18n/ja'
import { theme } from '../theme'
import type { SelectedEntity } from '../store/builderStore'
import { useBuilderStore } from '../store/builderStore'
import { ConfirmDialog } from './ConfirmDialog'
import styles from './TransformPanel.module.css'

type TransformPanelProps = {
  entity: SelectedEntity
  onToast: (kind: 'ok' | 'err', text: string) => void
}

const POS_STEPS = [0.01, 0.1, 1.0] as const
const ROT_STEPS = [1, 5, 15, 90] as const

function fmt(n: number): string {
  const s = Number.isFinite(n) ? String(n) : '0'
  if (s.includes('e') || s.includes('E')) {
    return n.toFixed(4)
  }
  return s
}

function norm360(v: number): number {
  return ((v % 360) + 360) % 360
}

function bumpStr(s: string, delta: number): string {
  const n = Number(s.trim().replace(',', '.'))
  if (!Number.isFinite(n)) {
    return s
  }
  return fmt(n + delta)
}

export function TransformPanel({ entity, onToast }: TransformPanelProps) {
  const setWorldSelection = useBuilderStore((s) => s.setWorldSelection)
  const [px, setPx] = useState(() => fmt(entity.pos.x))
  const [py, setPy] = useState(() => fmt(entity.pos.y))
  const [pz, setPz] = useState(() => fmt(entity.pos.z))
  const [rx, setRx] = useState(() => fmt(entity.rot.x))
  const [ry, setRy] = useState(() => fmt(entity.rot.y))
  const [rz, setRz] = useState(() => fmt(entity.rot.z))
  const [posStep, setPosStep] = useState(0.1)
  const [rotStep, setRotStep] = useState(5)
  const [busy, setBusy] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)

  const dirty = useMemo(
    () =>
      px !== fmt(entity.pos.x) ||
      py !== fmt(entity.pos.y) ||
      pz !== fmt(entity.pos.z) ||
      rx !== fmt(entity.rot.x) ||
      ry !== fmt(entity.rot.y) ||
      rz !== fmt(entity.rot.z),
    [px, py, pz, rx, ry, rz, entity.pos, entity.rot],
  )

  const parseVec = useCallback((sx: string, sy: string, sz: string) => {
    const x = Number(sx.trim().replace(',', '.'))
    const y = Number(sy.trim().replace(',', '.'))
    const z = Number(sz.trim().replace(',', '.'))
    if (![x, y, z].every((v) => Number.isFinite(v))) {
      return null
    }
    return { x, y, z }
  }, [])

  const resetFromEntity = useCallback(() => {
    setPx(fmt(entity.pos.x))
    setPy(fmt(entity.pos.y))
    setPz(fmt(entity.pos.z))
    setRx(fmt(entity.rot.x))
    setRy(fmt(entity.rot.y))
    setRz(fmt(entity.rot.z))
  }, [entity.pos, entity.rot])

  const onApply = useCallback(async () => {
    const pos = parseVec(px, py, pz)
    const rawRot = parseVec(rx, ry, rz)
    if (!pos || !rawRot) {
      onToast('err', ja.transform.invalidNumber)
      return
    }
    if (!checkRange(pos) || !checkRange(rawRot)) {
      onToast('err', ja.transform.rangeError)
      return
    }
    const rot = {
      x: norm360(rawRot.x),
      y: norm360(rawRot.y),
      z: norm360(rawRot.z),
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

  const onDeleteConfirm = useCallback(async () => {
    setDeleteOpen(false)
    setBusy(true)
    const res = await fetchNui<{ ok?: boolean }>('deleteObject', { id: entity.id })
    setBusy(false)
    if (res?.ok) {
      onToast('ok', ja.transform.deleteOk)
      setWorldSelection(null)
    } else {
      onToast('err', ja.transform.deleteFailed)
    }
  }, [entity.id, onToast, setWorldSelection])

  const bodyFs = theme.fontSize.body

  return (
    <div className={styles.root}>
      <ConfirmDialog
        open={deleteOpen}
        message={tf(ja.transform.deleteConfirm, { id: entity.id, label: entity.model })}
        confirmLabel={ja.transform.delete}
        cancelLabel={ja.transform.cancelDialog}
        danger
        onCancel={() => setDeleteOpen(false)}
        onConfirm={() => void onDeleteConfirm()}
      />

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
        <div className={styles.stepChips} role="group" aria-label={ja.transform.posStep}>
          {POS_STEPS.map((s) => (
            <button
              key={s}
              type="button"
              className={`${styles.chip} ${posStep === s ? styles.chipActive : ''}`}
              style={{ fontSize: bodyFs }}
              aria-pressed={posStep === s}
              onClick={() => setPosStep(s)}
            >
              {s}
            </button>
          ))}
        </div>
        <div className={styles.row3}>
          <AxisField
            axis="X"
            axisColor={theme.danger}
            value={px}
            onChange={setPx}
            onMinus={() => setPx((v) => bumpStr(v, -posStep))}
            onPlus={() => setPx((v) => bumpStr(v, posStep))}
            bodyFs={bodyFs}
          />
          <AxisField
            axis="Y"
            axisColor="#4ade80"
            value={py}
            onChange={setPy}
            onMinus={() => setPy((v) => bumpStr(v, -posStep))}
            onPlus={() => setPy((v) => bumpStr(v, posStep))}
            bodyFs={bodyFs}
          />
          <AxisField
            axis="Z"
            axisColor={theme.accent}
            value={pz}
            onChange={setPz}
            onMinus={() => setPz((v) => bumpStr(v, -posStep))}
            onPlus={() => setPz((v) => bumpStr(v, posStep))}
            bodyFs={bodyFs}
          />
        </div>
      </fieldset>

      <fieldset className={styles.fieldset}>
        <legend className={styles.legend} style={{ color: theme.text }}>
          {ja.transform.rotation}
        </legend>
        <div className={styles.stepChips} role="group" aria-label={ja.transform.rotStep}>
          {ROT_STEPS.map((s) => (
            <button
              key={s}
              type="button"
              className={`${styles.chip} ${rotStep === s ? styles.chipActive : ''}`}
              style={{ fontSize: bodyFs }}
              aria-pressed={rotStep === s}
              onClick={() => setRotStep(s)}
            >
              {s}°
            </button>
          ))}
        </div>
        <div className={styles.row3}>
          <AxisField
            axis="X"
            axisColor={theme.danger}
            value={rx}
            onChange={setRx}
            onMinus={() => setRx((v) => bumpStr(v, -rotStep))}
            onPlus={() => setRx((v) => bumpStr(v, rotStep))}
            bodyFs={bodyFs}
          />
          <AxisField
            axis="Y"
            axisColor="#4ade80"
            value={ry}
            onChange={setRy}
            onMinus={() => setRy((v) => bumpStr(v, -rotStep))}
            onPlus={() => setRy((v) => bumpStr(v, rotStep))}
            bodyFs={bodyFs}
          />
          <AxisField
            axis="Z"
            axisColor={theme.accent}
            value={rz}
            onChange={setRz}
            onMinus={() => setRz((v) => bumpStr(v, -rotStep))}
            onPlus={() => setRz((v) => bumpStr(v, rotStep))}
            bodyFs={bodyFs}
          />
        </div>
      </fieldset>

      <p className={styles.hint} style={{ color: theme.textDim, fontSize: bodyFs }}>
        {ja.transform.hint}
      </p>

      <div className={styles.actions}>
        <button type="button" className={styles.applyBtn} disabled={busy || !dirty} onClick={() => void onApply()}>
          {busy ? ja.transform.applying : ja.transform.apply}
        </button>
        {dirty ? (
          <button type="button" className={styles.secondaryBtn} style={{ fontSize: bodyFs }} onClick={resetFromEntity}>
            {ja.transform.cancelEdit}
          </button>
        ) : null}
        <button type="button" className={styles.secondaryBtn} style={{ fontSize: bodyFs }} onClick={() => void onClear()}>
          {ja.transform.clearSelection}
        </button>
        <button
          type="button"
          className={styles.deleteBtn}
          style={{ fontSize: bodyFs, borderColor: theme.danger, color: theme.danger }}
          disabled={busy}
          onClick={() => setDeleteOpen(true)}
        >
          {ja.transform.delete}
        </button>
      </div>
    </div>
  )
}

function checkRange(v: { x: number; y: number; z: number }): boolean {
  return [v.x, v.y, v.z].every((n) => Math.abs(n) <= 1e6)
}

type AxisFieldProps = {
  axis: string
  axisColor: string
  value: string
  onChange: (v: string) => void
  onMinus: () => void
  onPlus: () => void
  bodyFs: string
}

function AxisField({ axis, axisColor, value, onChange, onMinus, onPlus, bodyFs }: AxisFieldProps) {
  return (
    <div className={styles.cell}>
      <span className={styles.axis} style={{ color: axisColor }}>
        {axis}
      </span>
      <div className={styles.axisRow}>
        <button type="button" className={styles.stepBtn} style={{ fontSize: bodyFs }} onClick={onMinus} aria-label={`${axis} −`}>
          −
        </button>
        <input
          className={styles.input}
          style={{ fontSize: bodyFs }}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          inputMode="decimal"
        />
        <button type="button" className={styles.stepBtn} style={{ fontSize: bodyFs }} onClick={onPlus} aria-label={`${axis} +`}>
          +
        </button>
      </div>
    </div>
  )
}
