import { loadLocal, saveLocal } from './localPersist'

export type IdKind = 'match' | 'team' | 'player' | 'rosterMember' | 'event' | 'scoreHistory'

interface IdCounters {
  match: number
  team: number
  player: number
  rosterMember: number
  event: number
  scoreHistory: number
}

const COUNTER_KEY = 'id_counters'

const defaults: IdCounters = {
  match: 1000,
  team: 1000,
  player: 9000,
  rosterMember: 9000,
  event: 1000,
  scoreHistory: 1000,
}

let counters: IdCounters = { ...defaults, ...loadLocal<Partial<IdCounters>>(COUNTER_KEY, {}) }

/** `nextId` / `resetIdCounters` のディスク書き込みを抑止（疑似データ一括投入など） */
let idCounterPersistDepth = 0

export function beginIdCounterBatch(): void {
  idCounterPersistDepth += 1
}

export function endIdCounterBatch(): void {
  idCounterPersistDepth = Math.max(0, idCounterPersistDepth - 1)
  if (idCounterPersistDepth === 0) {
    saveLocal(COUNTER_KEY, counters)
  }
}

function persistCountersIfNeeded(): void {
  if (idCounterPersistDepth === 0) {
    saveLocal(COUNTER_KEY, counters)
  }
}

/** merge インポート等の前に、ディスク上の id_counters をメモリへ同期する */
export function hydrateCountersFromDisk(): void {
  counters = { ...defaults, ...loadLocal<Partial<IdCounters>>(COUNTER_KEY, {}) }
}

export function nextId(kind: IdKind): number {
  counters[kind] = (counters[kind] ?? defaults[kind]) + 1
  persistCountersIfNeeded()
  return counters[kind]
}

export function peekIdCounters(): Readonly<IdCounters> {
  return { ...counters }
}

export function resetIdCounters(): void {
  counters = { ...defaults }
  persistCountersIfNeeded()
}

/** バッチ中のみ。ディスクには `endIdCounterBatch` まで書かない */
export function resetCountersMemoryOnly(): void {
  counters = { ...defaults }
}
