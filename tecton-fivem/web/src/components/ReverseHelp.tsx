// SPDX-License-Identifier: LGPL-3.0-or-later

import reverseIndex from '../data/reverse-index.json'

export function ReverseHelp() {
  const n = reverseIndex.items?.length ?? 0
  return (
    <div className="tecton-reverse-help">
      <p>逆引きヘルプ（データ {n} 件）</p>
      <p className="tecton-reverse-help__hint">検索 UI は今後のマイルストーンで実装予定です。</p>
    </div>
  )
}
