/**
 * ローカル永続化の薄いラッパ。
 * 各ストアからは `loadLocal('matches', [])` のように使い、
 * watch + saveLocal で自動保存する想定。
 *
 * SCHEMA_VERSION を上げると旧データは fallback に置き換わる（migration は今のところ実装しない）。
 */

const KEY_PREFIX = 'refboard_local_'
const SCHEMA_VERSION = 1

interface PersistedShape<T> {
  version: number
  data: T
}

export function loadLocal<T>(key: string, fallback: T): T {
  if (typeof localStorage === 'undefined') return fallback
  try {
    const raw = localStorage.getItem(KEY_PREFIX + key)
    if (!raw) return fallback
    const parsed = JSON.parse(raw) as PersistedShape<T>
    if (!parsed || parsed.version !== SCHEMA_VERSION) return fallback
    return parsed.data
  } catch {
    return fallback
  }
}

export function saveLocal<T>(key: string, data: T): void {
  if (typeof localStorage === 'undefined') return
  try {
    const payload: PersistedShape<T> = { version: SCHEMA_VERSION, data }
    localStorage.setItem(KEY_PREFIX + key, JSON.stringify(payload))
  } catch {
    /* quota / private mode は黙殺 */
  }
}

/** 複数キーを連続 `setItem`（Vue watch を挟まない疑似データ投入など向け） */
export function saveLocalBatch(entries: Record<string, unknown>): void {
  if (typeof localStorage === 'undefined') return
  for (const [key, data] of Object.entries(entries)) {
    try {
      const payload: PersistedShape<unknown> = { version: SCHEMA_VERSION, data }
      localStorage.setItem(KEY_PREFIX + key, JSON.stringify(payload))
    } catch {
      /* ignore */
    }
  }
}

export function removeLocal(key: string): void {
  if (typeof localStorage === 'undefined') return
  try {
    localStorage.removeItem(KEY_PREFIX + key)
  } catch {
    /* ignore */
  }
}

export function clearAllLocal(): void {
  if (typeof localStorage === 'undefined') return
  try {
    const keys: string[] = []
    for (let i = 0; i < localStorage.length; i += 1) {
      const k = localStorage.key(i)
      if (k && k.startsWith(KEY_PREFIX)) keys.push(k)
    }
    keys.forEach((k) => localStorage.removeItem(k))
  } catch {
    /* ignore */
  }
}

export function dumpAllLocal(): Record<string, unknown> {
  if (typeof localStorage === 'undefined') return {}
  const out: Record<string, unknown> = {}
  try {
    for (let i = 0; i < localStorage.length; i += 1) {
      const k = localStorage.key(i)
      if (!k || !k.startsWith(KEY_PREFIX)) continue
      try {
        out[k] = JSON.parse(localStorage.getItem(k) || 'null')
      } catch {
        out[k] = null
      }
    }
  } catch {
    /* ignore */
  }
  return out
}

export const LOCAL_PERSIST_KEY_PREFIX = KEY_PREFIX
export const LOCAL_PERSIST_SCHEMA_VERSION = SCHEMA_VERSION
