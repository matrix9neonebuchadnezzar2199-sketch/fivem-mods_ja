import type { Match } from '../types/local'

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

/**
 * タイムライン等。`stoppage == null` または `0` → `45'`（規定内の 0 ロスタイムは +0 を付けない）。
 * `stoppage >= 1` → `45+2'`。
 */
export function formatMinute(minute: number, stoppage: number | null | undefined): string {
  const m = Math.max(0, Math.floor(minute))
  if (stoppage == null || stoppage === 0) return `${m}'`
  return `${m}+${Math.max(0, Math.floor(stoppage))}'`
}

/** CSV 用（アポストロフィなし）。PK 行などは呼び出し側で `'PK'` を渡す想定 */
export function formatMinuteForCsv(minute: number, stoppage: number | null | undefined): string {
  if (stoppage == null) return String(Math.max(0, Math.floor(minute)))
  return `${Math.max(0, Math.floor(minute))}+${Math.max(0, Math.floor(stoppage))}`
}

/**
 * 試合時計（経過 ms）からイベント記録用の分・ロスタイム初期値を求める。
 * 経過分はハーフに応じて 45+α / 90+β に分離（PK 中は 0 / null）。
 */
export function eventMinutePresetFromClock(match: Match, clockNowMs: number): ParsedMinute {
  const totalSec = Math.floor(Math.max(0, clockNowMs) / 1000)
  const totalMin = Math.min(120, Math.floor(totalSec / 60))

  if (match.currentHalf === 'PK') {
    return { minute: 0, stoppage: null }
  }

  const h = match.halfMinutes ?? 45
  const regEnd = h * 2

  if (match.currentHalf === '1H' || match.currentHalf === 'HT') {
    if (totalMin <= h) return { minute: totalMin, stoppage: 0 }
    return { minute: h, stoppage: totalMin - h }
  }

  if (totalMin <= regEnd) return { minute: totalMin, stoppage: 0 }
  return { minute: regEnd, stoppage: totalMin - regEnd }
}
