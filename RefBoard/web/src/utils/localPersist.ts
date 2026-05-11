/**
 * ローカル永続化の薄いラッパ。
 * 各ストアからは `loadLocal('matches', [])` のように使い、
 * watch + saveLocal で自動保存する想定。
 *
 * SCHEMA_VERSION を上げると旧データは fallback に置き換わる（migration は今のところ実装しない）。
 */

import { i18n } from '../i18n'
import { useToast } from '../composables/useToast'

const KEY_PREFIX = 'refboard_local_'
const SCHEMA_VERSION = 1

interface PersistedShape<T> {
  version: number
  data: T
}

let lastQuotaToastAt = 0
const QUOTA_TOAST_COOLDOWN_MS = 8000

function isQuotaExceeded(err: unknown): boolean {
  if (err instanceof DOMException && (err.name === 'QuotaExceededError' || err.code === 22)) {
    return true
  }
  return err instanceof Error && err.name === 'QuotaExceededError'
}

function notifyStorageQuotaExceeded(): void {
  const t = Date.now()
  if (t - lastQuotaToastAt < QUOTA_TOAST_COOLDOWN_MS) return
  lastQuotaToastAt = t
  try {
    const msg = i18n.global.t('toast.local_storage_quota')
    useToast().push(msg, 'error', 9000)
  } catch {
    /* i18n / toast 未初期化時 */
  }
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
  } catch (err) {
    if (isQuotaExceeded(err)) {
      notifyStorageQuotaExceeded()
      return
    }
    if (import.meta.env.DEV) {
      console.warn('[RefBoard] saveLocal failed:', key, err)
    }
  }
}

/** 複数キーを連続 `setItem`（Vue watch を挟まない疑似データ投入など向け） */
export function saveLocalBatch(entries: Record<string, unknown>): void {
  if (typeof localStorage === 'undefined') return
  for (const [key, data] of Object.entries(entries)) {
    try {
      const payload: PersistedShape<unknown> = { version: SCHEMA_VERSION, data }
      localStorage.setItem(KEY_PREFIX + key, JSON.stringify(payload))
    } catch (err) {
      if (isQuotaExceeded(err)) notifyStorageQuotaExceeded()
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

export const LOCAL_PERSIST_KEY_PREFIX = KEY_PREFIX
export const LOCAL_PERSIST_SCHEMA_VERSION = SCHEMA_VERSION
