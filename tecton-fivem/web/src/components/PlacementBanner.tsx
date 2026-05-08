// SPDX-License-Identifier: LGPL-3.0-or-later

import { ja } from '../i18n/ja'
import styles from './PlacementBanner.module.css'

export function PlacementBanner() {
  return (
    <div className={styles.banner} role="status" aria-live="polite">
      <p className={styles.line}>{ja.placement.dragHint}</p>
      <p className={styles.line}>{ja.placement.confirmHint}</p>
      <p className={styles.line}>{ja.placement.resumeHint}</p>
    </div>
  )
}
