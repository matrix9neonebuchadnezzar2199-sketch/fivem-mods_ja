// SPDX-License-Identifier: LGPL-3.0-or-later

import { useCallback, useState } from 'react'
import { fetchNui } from '../lib/nui'
import { ja, tf } from '../i18n/ja'
import { theme } from '../theme'
import { useBuilderStore, type BuilderMode } from '../store/builderStore'
import { usePropsStore } from '../store/propsStore'
import { CategoryTree } from '../components/CategoryTree'
import { PropList } from '../components/PropList'
import styles from './Builder.module.css'

type ToastState = { kind: 'ok' | 'err'; text: string } | null

export function Builder() {
  const sceneId = useBuilderStore((s) => s.sceneId)
  const mode = useBuilderStore((s) => s.mode)
  const setMode = useBuilderStore((s) => s.setMode)
  const propsLoaded = usePropsStore((s) => s.loaded)
  const propsError = usePropsStore((s) => s.loadError)
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

  const onPlaced = useCallback(
    (ok: boolean, id?: number, reason?: string) => {
      if (ok && typeof id === 'number') {
        showToast({ kind: 'ok', text: tf(ja.toast.placeSuccess, { id }) })
      } else {
        const r = reason ?? 'unknown'
        showToast({ kind: 'err', text: tf(ja.toast.placeFailed, { reason: r }) })
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
        <header className={styles.topbar} style={{ borderBottom: '0.0625rem solid rgba(255,255,255,0.08)' }}>
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
          <aside className={styles.sidebar}>{propsLoaded && !propsError ? <CategoryTree /> : null}</aside>
          <main className={styles.centerMain}>
            {!propsLoaded && !propsError && (
              <div className={styles.propListPlaceholder} style={{ color: theme.textDim, fontSize: theme.fontSize.body }}>
                {ja.props.loading}
              </div>
            )}
            {propsError && (
              <div className={styles.propListPlaceholder} style={{ color: theme.danger, fontSize: theme.fontSize.body }}>
                {ja.props.failed}
              </div>
            )}
            {propsLoaded && !propsError && <PropList onPlaced={onPlaced} />}
          </main>
          <aside className={styles.right}>
            <div style={{ fontSize: theme.fontSize.h2, fontWeight: 600, marginBottom: '0.5rem' }}>{ja.panel.selection}</div>
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
