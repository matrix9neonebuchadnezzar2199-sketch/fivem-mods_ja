/**
 * DB / FiveM / oxmysql 経由で日付が数値・オブジェクト・ISO 文字列など混在する場合に
 * UI で一貫した表示・`<input type="date">` 用の YYYY-MM-DD に揃える。
 */

function pad2(n: number): string {
  return String(n).padStart(2, '0')
}

/** `{ year, month, day }`（Lua テーブル等の JSON 化） */
function fromYmdObject(v: Record<string, unknown>): string | null {
  const y = Number(v.year)
  const mo = Number(v.month)
  const d = Number(v.day)
  if (![y, mo, d].every((x) => Number.isFinite(x))) return null
  if (y < 1970 || y > 2100) return null
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null
  return `${y}-${pad2(mo)}-${pad2(d)}`
}

/**
 * `<input type="date">` の v-model 用。解釈できなければ空文字。
 */
export function toDateInputString(v: unknown): string {
  if (v == null || v === '') return ''
  if (typeof v === 'object' && v !== null && 'year' in v && 'month' in v && 'day' in v) {
    const s = fromYmdObject(v as Record<string, unknown>)
    return s ?? ''
  }
  if (typeof v === 'number' && Number.isFinite(v)) {
    const ms = v > 1e12 ? v : v * 1000
    const d = new Date(ms)
    if (Number.isNaN(d.getTime())) return ''
    return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`
  }
  const s = String(v).trim()
  if (/^\d{4}-\d{2}-\d{2}/.test(s)) return s.slice(0, 10)
  if (/^\d{10,13}$/.test(s)) {
    return toDateInputString(Number(s))
  }
  const d = new Date(s)
  if (!Number.isNaN(d.getTime())) {
    return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`
  }
  return ''
}

/** 一覧・ラベル用（日付のみ）。解釈不能は — */
export function formatDateJa(v: unknown): string {
  const inner = toDateInputString(v)
  if (!inner) return '—'
  const [y, m, d] = inner.split('-')
  return `${y}/${m}/${d}`
}

/** 日時（履歴・ログ）。解釈不能は文字列化のフォールバック */
export function formatDateTimeJa(v: unknown): string {
  if (v == null || v === '') return '—'
  if (typeof v === 'number' && Number.isFinite(v)) {
    const ms = v > 1e12 ? v : v * 1000
    const d = new Date(ms)
    if (Number.isNaN(d.getTime())) return String(v)
    return formatDateTimeFromDate(d)
  }
  const s = String(v).trim()
  const d = new Date(s)
  if (!Number.isNaN(d.getTime())) {
    return formatDateTimeFromDate(d)
  }
  if (/^\d{10,13}$/.test(s)) {
    return formatDateTimeJa(Number(s))
  }
  return s
}

function formatDateTimeFromDate(d: Date): string {
  const y = d.getFullYear()
  const mo = pad2(d.getMonth() + 1)
  const day = pad2(d.getDate())
  const hh = pad2(d.getHours())
  const mm = pad2(d.getMinutes())
  const ss = pad2(d.getSeconds())
  return `${y}/${mo}/${day} ${hh}:${mm}:${ss}`
}
