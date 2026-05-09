/** 試合時計の経過・残り（一覧・詳細で共通の数式） */

/** oxmysql / JSON 経由の BIGINT・秒単位の値を epoch ms に正規化（解釈不能なら null）。 */
export function parseEpochMsFromServer(v: unknown): number | null {
  if (v == null) return null
  if (typeof v === 'bigint') {
    const bn = Number(v)
    if (!Number.isFinite(bn)) return null
    if (bn > 1e12) return Math.floor(bn)
    if (bn > 1e9) return Math.floor(bn * 1000)
    return null
  }
  let n: number
  if (typeof v === 'number') {
    n = v
  } else {
    const s = String(v).trim()
    if (s === '') return null
    n = Number(s)
  }
  if (!Number.isFinite(n)) return null
  if (n > 1e12) return Math.floor(n)
  if (n > 1e9) return Math.floor(n * 1000)
  return null
}

export function formatClockMs(ms: number): string {
  const totalSec = Math.floor(Math.max(0, ms) / 1000)
  const mm = Math.floor(totalSec / 60)
  const ss = totalSec % 60
  return `${mm}:${String(ss).padStart(2, '0')}`
}

export function getElapsedMsFromClockState(
  accumulatedMs: number,
  clockRunning: boolean,
  clockStartedAtMs: number | null,
  nowMs: number,
): number {
  const acc = Math.max(0, Number(accumulatedMs) || 0)
  if (clockRunning && clockStartedAtMs != null) {
    const st = Number(clockStartedAtMs)
    if (Number.isFinite(st)) {
      return acc + Math.max(0, nowMs - st)
    }
  }
  return acc
}

/** 定尺いっぱいからの残り（カウントダウン表示用） */
export function remainingMsFromClock(
  fullMatchDurationMs: number,
  accumulatedMs: number,
  clockRunning: boolean,
  clockStartedAtMs: number | null,
  nowMs: number,
): number {
  const full = Math.max(60_000, fullMatchDurationMs)
  const elapsed = getElapsedMsFromClockState(accumulatedMs, clockRunning, clockStartedAtMs, nowMs)
  return Math.max(0, Math.min(full, full - elapsed))
}
