// SPDX-License-Identifier: LGPL-3.0-or-later

import { theme } from '../theme'
import styles from './ConfirmDialog.module.css'

export type ConfirmDialogProps = {
  open: boolean
  title?: string
  message: string
  confirmLabel?: string
  cancelLabel?: string
  /** true のとき確定ボタンを danger 色にする */
  danger?: boolean
  onConfirm: () => void
  onCancel: () => void
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'OK',
  cancelLabel = 'キャンセル',
  danger,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  if (!open) {
    return null
  }
  return (
    <div className={styles.overlay} role="presentation">
      <div
        className={styles.card}
        style={{ backgroundColor: theme.panel, color: theme.text }}
        role="dialog"
        aria-modal="true"
        aria-labelledby={title ? 'confirm-dialog-title' : undefined}
        onClick={(e) => e.stopPropagation()}
        onKeyDown={(e) => e.stopPropagation()}
      >
        {title ? (
          <h2 id="confirm-dialog-title" className={styles.title}>
            {title}
          </h2>
        ) : null}
        <p className={styles.message}>{message}</p>
        <div className={styles.actions}>
          <button type="button" className={styles.cancelBtn} style={{ color: theme.text }} onClick={onCancel}>
            {cancelLabel}
          </button>
          <button
            type="button"
            className={danger ? styles.confirmDanger : styles.confirm}
            style={
              danger
                ? { background: theme.danger, color: '#0f172a' }
                : { background: 'rgba(79, 195, 247, 0.35)', color: theme.text }
            }
            onClick={onConfirm}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
