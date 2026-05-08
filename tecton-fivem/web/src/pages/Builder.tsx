// SPDX-License-Identifier: LGPL-3.0-or-later

import { useCallback, useState } from 'react'
import { fetchNui } from '../lib/nui'
import { ja, tf } from '../i18n/ja'
import { theme } from '../theme'
import { useBuilderStore, type BuilderMode } from '../store/builderStore'
import styles from './Builder.module.css'

const CHAIRS: { model: string; label: string }[] = [
  { model: 'prop_chair_01a', label: '椅子（鉄パイプ）' },
  { model: 'prop_chair_02', label: '椅子（木製）' },
  { model: 'prop_chair_04a', label: '椅子（オフィス）' },
]

type ToastState = { kind: 'ok' | 'err'; text: string } | null

export function Builder() {
  const sceneId = useBuilderStore((s) => s.sceneId)
  const mode = useBuilderStore((s) => s.mode)
  const setMode = useBuilderStore((s) => s.setMode)
  const [toast, setToast] = useState<ToastState>(null)

  const showToast = useCallback((next: ToastState) => {
    setToast(next)
    if (next) {
      window.setTimeout(() => setToast(null), 4500)
    }
  }, [])

  const onClose = useCallback(() => {
    void fetchNui('close')
  }, [])

  const onChairClick = useCallback(
    async (chairModel: string) => {
      const res = await fetchNui<{ ok?: boolean; id?: number; reason?: string }>('createObject', {
        mode: 'furniture' as const,
        model: chairModel,
      })
      if (res?.ok && typeof res.id === 'number') {
        showToast({ kind: 'ok', text: tf(ja.toast.placeSuccess, { id: res.id }) })
      } else {
        const reason = typeof res?.reason === 'string' ? res.reason : 'unknown'
        showToast({ kind: 'err', text: tf(ja.toast.placeFailed, { reason }) })
      }
    },
    [showToast],
  )

  const onTab = (m: BuilderMode) => {
    if (m === 'furniture') {
      setMode(m)
    }
  }

  return (
    <div className={styles.overlay} role="presentation">
      <div
        className={styles.panel}
        style={{ backgroundColor: theme.panel, color: theme.text }}
        onClick={(e) => e.stopPropagation()}
        onKeyDown={(e) => e.stopPropagation()}
      >
        <header className={styles.topbar} style={{ borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
          <div className={styles.brand}>
            <span style={{ fontSize: theme.fontSize.h1, fontWeight: 700 }}>{ja.app.title}</span>
            <span style={{ fontSize: theme.fontSize.small, color: theme.textDim }}>{ja.app.tagline}</span>
          </div>
          <div className={styles.scene} style={{ color: theme.textDim }}>
            {sceneId}
          </div>
          <button type="button" className={styles.closeBtn} style={{ background: theme.bg, color: theme.text }} onClick={onClose}>
            {ja.action.close}
          </button>
        </header>

        <nav className={styles.tabs} aria-label="mode">
          {(['furniture', 'door', 'parking', 'stash'] as const).map((m) => {
            const active = mode === m
            const disabled = m !== 'furniture'
            return (
              <button
                key={m}
                type="button"
                className={`${styles.tab} ${disabled ? styles.tabDisabled : ''}`}
                style={{
                  background: active ? 'rgba(79,195,247,0.15)' : 'transparent',
                  color: active ? theme.accent : theme.textDim,
                }}
                disabled={disabled}
                onClick={() => onTab(m)}
              >
                {ja.mode[m]}
              </button>
            )
          })}
        </nav>

        <div className={styles.body}>
          <aside className={styles.sidebar}>
            {CHAIRS.map((c) => (
              <button key={c.model} type="button" className={styles.card} onClick={() => void onChairClick(c.model)}>
                <div className={styles.cardTitle} style={{ color: theme.text }}>
                  {c.label}
                </div>
                <div className={styles.cardModel} style={{ color: theme.textDim }}>
                  {c.model}
                </div>
              </button>
            ))}
          </aside>
          <main className={styles.center} style={{ color: theme.textDim }}>
            {ja.placeholder.selectFromLeft}
          </main>
          <aside className={styles.right}>
            <div style={{ fontSize: theme.fontSize.h2, fontWeight: 600, marginBottom: 8 }}>{ja.panel.selection}</div>
            <div style={{ fontSize: theme.fontSize.small, color: theme.textDim }}>{ja.panel.selectionHint}</div>
          </aside>
        </div>
      </div>

      {toast && (
        <div
          className={`${styles.toast} ${toast.kind === 'ok' ? styles.toastOk : styles.toastErr}`}
          style={{
            backgroundColor: theme.panel,
            color: toast.kind === 'ok' ? theme.text : theme.danger,
          }}
          role="status"
        >
          {toast.text}
        </div>
      )}
    </div>
  )
}
