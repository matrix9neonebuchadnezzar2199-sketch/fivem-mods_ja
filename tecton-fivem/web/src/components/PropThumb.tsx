// SPDX-License-Identifier: LGPL-3.0-or-later

import { useMemo, useState } from 'react'
import { resolveThumbnailUrl } from '../utils/thumbnailUrl'
import { categoryHue } from '../utils/categoryHue'
import styles from './PropThumb.module.css'

type PropThumbProps = {
  thumbFile: string
  label: string
  category: string
}

export function PropThumb({ thumbFile, label, category }: PropThumbProps) {
  const [imgFailed, setImgFailed] = useState(false)
  const src = useMemo(() => resolveThumbnailUrl(thumbFile), [thumbFile])
  const hue = useMemo(() => categoryHue(category), [category])
  const letter = useMemo(() => {
    const t = label.trim()
    if (t.length > 0) {
      return t.charAt(0)
    }
    return '?'
  }, [label])

  const showImg = Boolean(src) && !imgFailed

  return (
    <div className={styles.thumbBox}>
      <div
        className={styles.placeholder}
        style={{ background: `linear-gradient(145deg, hsl(${hue} 42% 28%) 0%, hsl(${hue} 36% 18%) 100%)` }}
        aria-hidden
      >
        {letter}
      </div>
      {showImg ? (
        <img
          src={src!}
          className={styles.thumbImg}
          alt=""
          loading="lazy"
          decoding="async"
          onError={() => setImgFailed(true)}
        />
      ) : null}
    </div>
  )
}
