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

/** merge インポート等の前に、ディスク上の id_counters をメモリへ同期する */
export function hydrateCountersFromDisk(): void {
  counters = { ...defaults, ...loadLocal<Partial<IdCounters>>(COUNTER_KEY, {}) }
}

export function nextId(kind: IdKind): number {
  counters[kind] = (counters[kind] ?? defaults[kind]) + 1
  saveLocal(COUNTER_KEY, counters)
  return counters[kind]
}

export function peekIdCounters(): Readonly<IdCounters> {
  return { ...counters }
}

export function resetIdCounters(): void {
  counters = { ...defaults }
  saveLocal(COUNTER_KEY, counters)
}
