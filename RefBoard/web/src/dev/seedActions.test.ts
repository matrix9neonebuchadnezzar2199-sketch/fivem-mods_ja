import { describe, it, expect, beforeEach, afterAll } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useMatchesStore } from '../stores/matches'
import { useTeamsStore } from '../stores/teams'
import { clearAllData } from './seedActions'
import { resetIdCounters, resetCountersMemoryOnly, peekIdCounters, nextId, hydrateCountersFromDisk } from '../utils/localId'

/** node 環境向けの最小 localStorage モック */
function installLocalStorageMock(): void {
  const storage = new Map<string, string>()
  const ls = {
    get length() {
      return storage.size
    },
    key(i: number) {
      return Array.from(storage.keys())[i] ?? null
    },
    getItem(k: string) {
      return storage.get(k) ?? null
    },
    setItem(k: string, v: string) {
      storage.set(k, String(v))
    },
    removeItem(k: string) {
      storage.delete(k)
    },
    clear() {
      storage.clear()
    },
  }
  ;(globalThis as unknown as { localStorage: typeof ls }).localStorage = ls
}

function uninstallLocalStorageMock(): void {
  delete (globalThis as unknown as { localStorage?: unknown }).localStorage
}

describe('clearAllData (H-2)', () => {
  beforeEach(() => {
    installLocalStorageMock()
    setActivePinia(createPinia())
  })

  it('clearAllData 後、Pinia の teams と matches が空になり（rehydrate）、ノンプレフィックスキーも削除される', () => {
    const teams = useTeamsStore()
    const matches = useMatchesStore()
    const home = teams.createTeam({ name: 'H' })
    const away = teams.createTeam({ name: 'A' })
    matches.createMatch({ title: 't', homeTeamId: home.id, awayTeamId: away.id })

    localStorage.setItem('refboard_settings', JSON.stringify({ selfName: 'eiho' }))
    localStorage.setItem('refboard-locale', 'ja')

    expect(teams.teams.length).toBeGreaterThan(0)
    expect(matches.matches.length).toBeGreaterThan(0)
    expect(localStorage.getItem('refboard_settings')).not.toBeNull()
    expect(localStorage.getItem('refboard-locale')).not.toBeNull()

    clearAllData()

    expect(teams.teams.length).toBe(0)
    expect(matches.matches.length).toBe(0)
    expect(localStorage.getItem('refboard_settings')).toBeNull()
    expect(localStorage.getItem('refboard-locale')).toBeNull()
  })

  it('clearAllData 後、id_counters はディスクから消去されメモリは defaults に戻る', () => {
    const matches = useMatchesStore()
    const teams = useTeamsStore()
    const home = teams.createTeam({ name: 'H' })
    teams.createTeam({ name: 'A' })
    matches.createMatch({ title: 't', homeTeamId: home.id, awayTeamId: teams.teams[1].id })

    expect(localStorage.getItem('refboard_local_id_counters')).not.toBeNull()

    clearAllData()

    expect(localStorage.getItem('refboard_local_id_counters')).toBeNull()
    const c = peekIdCounters()
    expect(c.match).toBe(1000)
    expect(c.team).toBe(1000)
  })
})

describe('resetIdCounters / resetCountersMemoryOnly セマンティクス', () => {
  beforeEach(() => {
    installLocalStorageMock()
    setActivePinia(createPinia())
  })

  it('resetIdCounters はディスクに defaults を書き戻すが、resetCountersMemoryOnly は書き戻さない', () => {
    nextId('match')
    nextId('team')
    expect(localStorage.getItem('refboard_local_id_counters')).not.toBeNull()

    resetIdCounters()
    const persisted = localStorage.getItem('refboard_local_id_counters')
    expect(persisted).not.toBeNull()
    const parsed = JSON.parse(persisted!) as { data: Record<string, number> }
    expect(parsed.data.match).toBe(1000)
    expect(peekIdCounters().match).toBe(1000)

    nextId('match')
    expect(peekIdCounters().match).toBe(1001)
    localStorage.removeItem('refboard_local_id_counters')

    resetCountersMemoryOnly()
    expect(peekIdCounters().match).toBe(1000)
    expect(localStorage.getItem('refboard_local_id_counters')).toBeNull()

    hydrateCountersFromDisk()
    expect(peekIdCounters().match).toBe(1000)
  })
})

/** 他テストファイルへ localStorage の存在を漏らさないよう、ファイル単位で必ず後始末する */
afterAll(() => {
  uninstallLocalStorageMock()
})
