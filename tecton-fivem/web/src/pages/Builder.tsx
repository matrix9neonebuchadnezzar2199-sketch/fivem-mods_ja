// SPDX-License-Identifier: LGPL-3.0-or-later

import { useCallback, useMemo, useState } from 'react'
import { fetchNui } from '../lib/nui'
import { ja, tf } from '../i18n/ja'
import { theme } from '../theme'
import { useBuilderStore, type BuilderMode } from '../store/builderStore'
import { usePropsStore } from '../store/propsStore'
import { CategoryTree } from '../components/CategoryTree'
import { PropList } from '../components/PropList'
import { SearchBar } from '../components/SearchBar'
import { PropThumb } from '../components/PropThumb'
import styles from './Builder.module.css'

type ToastState = { kind: 'ok' | 'err'; text: string } | null

export function Builder() {
  const sceneId = useBuilderStore((s) => s.sceneId)
  const mode = useBuilderStore((s) => s.mode)
  const setMode = useBuilderStore((s) => s.setMode)
  const pendingCatalog = useBuilderStore((s) => s.pendingCatalog)
  const setPendingCatalog = useBuilderStore((s) => s.setPendingCatalog)
  const dictionary = usePropsStore((s) => s.dictionary)
  const propsLoaded = usePropsStore((s) => s.loaded)
  const propsError = usePropsStore((s) => s.loadError)
  const [toast, setToast] = useState<ToastState>(null)

  const pendingDef = useMemo(() => {
    if (!pendingCatalog) {
      return null
    }
    return dictionary[pendingCatalog.model] ?? null
  }, [pendingCatalog, dictionary])

  const showToast = useCallback((next: ToastState) => {
    setToast(next)
    if (next) {
      window.setTimeout(() => setToast(null), 4500)
    }
  }, [])

  const onClose = useCallback(() => {
    void fetchNui('close')
  }, [])

  const onPlacePending = useCallback(async () => {
    const p = pendingCatalog
    if (!p) {
      return
    }
    const res = await fetchNui<{ ok?: boolean; id?: number; reason?: string }>('createObject', {
      mode: 'furniture' as const,
      model: p.model,
      category: p.category,
    })
    if (res?.ok && typeof res.id === 'number') {
      setPendingCatalog(null)
      showToast({ kind: 'ok', text: tf(ja.toast.placeSuccess, { id: res.id }) })
    } else {
      const r = typeof res?.reason === 'string' ? res.reason : 'unknown'
      showToast({ kind: 'err', text: tf(ja.toast.placeFailed, { reason: r }) })
    }
  }, [pendingCatalog, setPendingCatalog, showToast])

  const onCancelPending = useCallback(() => {
    setPendingCatalog(null)
  }, [setPendingCatalog])

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
            {propsLoaded && !propsError && (
              <>
                <SearchBar />
                <PropList />
              </>
            )}
          </main>
          <aside className={styles.right}>
            <div className={styles.rightTitle} style={{ color: theme.text }}>
              {ja.panel.selection}
            </div>
            {pendingCatalog ? (
              <>
                <div className={styles.pendingThumbWrap}>
                  <div className={styles.pendingThumbInner}>
                    <PropThumb
                      key={pendingCatalog.model}
                      model={pendingCatalog.model}
                      thumbFile={pendingDef?.thumb ?? ''}
                      label={pendingDef?.label ?? pendingCatalog.model}
                      category={pendingDef?.category ?? pendingCatalog.category}
                    />
                  </div>
                </div>
                <div className={styles.pendingLabel} style={{ color: theme.text }}>
                  {pendingDef?.label ?? pendingCatalog.model}
                </div>
                <div className={styles.pendingModel} style={{ color: theme.textDim }}>
                  {pendingCatalog.model}
                </div>
                <div className={styles.panelActions}>
                  <button type="button" className={styles.placeBtn} onClick={() => void onPlacePending()}>
                    {ja.panel.place}
                  </button>
                  <button type="button" className={styles.panelSecondaryBtn} onClick={onCancelPending}>
                    {ja.panel.cancelPick}
                  </button>
                </div>
              </>
            ) : (
              <>
                <p className={styles.panelHint} style={{ color: theme.textDim }}>
                  {ja.panel.catalogPickHint}
                </p>
                <p className={styles.panelHintDim} style={{ color: theme.textDim }}>
                  {ja.panel.placedSelectionHint}
                </p>
              </>
            )}
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
