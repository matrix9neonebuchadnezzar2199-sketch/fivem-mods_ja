export interface ParsedMinute {
  minute: number
  stoppage: number | null
}

const MAX_MINUTE = 120
const MAX_STOPPAGE = 29

export type ParseMinuteError =
  | 'empty'
  | 'invalid_format'
  | 'minute_out_of_range'
  | 'stoppage_out_of_range'

/**
 * ゴール／カード等の「分」入力。`45` / `45+2` / `45＋2` / `45 + 2` を受理。
 * 空文字は呼び出し側で「時計から自動」と扱う（ここでは empty を返す）。
 */
export function parseMinuteInput(raw: string | null | undefined): { ok: true; value: ParsedMinute } | { ok: false; reason: ParseMinuteError } {
  if (raw == null) return { ok: false, reason: 'empty' }
  const s = String(raw)
    .replace(/＋/g, '+')
    .replace(/[\u3000\s]+/g, '')
    .trim()
  if (!s) return { ok: false, reason: 'empty' }

  const m = /^(\d{1,3})(?:\+(\d{1,2}))?$/.exec(s)
  if (!m) return { ok: false, reason: 'invalid_format' }

  const minute = Number(m[1])
  const stoppage = m[2] !== undefined ? Number(m[2]) : null

  if (!Number.isInteger(minute) || minute < 0 || minute > MAX_MINUTE) {
    return { ok: false, reason: 'minute_out_of_range' }
  }
  if (stoppage !== null && (!Number.isInteger(stoppage) || stoppage < 0 || stoppage > MAX_STOPPAGE)) {
    return { ok: false, reason: 'stoppage_out_of_range' }
  }

  return { ok: true, value: { minute, stoppage } }
}

/** タイムライン等。`stoppage == null` → `45'`、`stoppage >= 0` → `45+2'`（0 も明示） */
export function formatMinute(minute: number, stoppage: number | null | undefined): string {
  const m = Math.max(0, Math.floor(minute))
  if (stoppage == null) return `${m}'`
  return `${m}+${Math.max(0, Math.floor(stoppage))}'`
}

/** CSV 用（アポストロフィなし）。PK 行などは呼び出し側で `'PK'` を渡す想定 */
export function formatMinuteForCsv(minute: number, stoppage: number | null | undefined): string {
  if (stoppage == null) return String(Math.max(0, Math.floor(minute)))
  return `${Math.max(0, Math.floor(minute))}+${Math.max(0, Math.floor(stoppage))}`
}
