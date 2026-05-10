import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useMatchesStore } from './matches'
import { useTeamsStore } from './teams'
import { resetIdCounters } from '../utils/localId'

beforeEach(() => {
  setActivePinia(createPinia())
  resetIdCounters()
})

describe('useMatchesStore addEvent', () => {
  it('rejects goal when teamId is neither home nor away', () => {
    const teams = useTeamsStore()
    const home = teams.createTeam({ name: 'Home' })
    const away = teams.createTeam({ name: 'Away' })
    const matches = useMatchesStore()
    const m = matches.createMatch({ title: 'Test', homeTeamId: home.id, awayTeamId: away.id })
    const ev = matches.addEvent(m.id, {
      kind: 'goal',
      half: '1H',
      minute: 1,
      stoppage: null,
      teamId: 999_999,
      playerId: 1,
      assistPlayerId: null,
      subInPlayerId: null,
      subOutPlayerId: null,
      note: null,
      voided: false,
    })
    expect(ev).toBeNull()
    expect(matches.find(m.id)?.events.length).toBe(0)
    expect(matches.find(m.id)?.homeScore).toBe(0)
  })

  it('rejects pk_goal when teamId is missing', () => {
    const teams = useTeamsStore()
    const home = teams.createTeam({ name: 'Home' })
    const away = teams.createTeam({ name: 'Away' })
    const matches = useMatchesStore()
    const m = matches.createMatch({ title: 'Test', homeTeamId: home.id, awayTeamId: away.id })
    const ev = matches.addEvent(m.id, {
      kind: 'pk_goal',
      half: 'PK',
      minute: 0,
      stoppage: null,
      teamId: null,
      playerId: 1,
      assistPlayerId: null,
      subInPlayerId: null,
      subOutPlayerId: null,
      note: null,
      voided: false,
    })
    expect(ev).toBeNull()
  })

  it('accepts goal for home team', () => {
    const teams = useTeamsStore()
    const home = teams.createTeam({ name: 'Home' })
    const away = teams.createTeam({ name: 'Away' })
    const matches = useMatchesStore()
    const m = matches.createMatch({ title: 'Test', homeTeamId: home.id, awayTeamId: away.id })
    const p = matches.addPlayer(m.id, { teamId: home.id, name: 'S', number: 9 })
    expect(p).not.toBeNull()
    const ev = matches.addEvent(m.id, {
      kind: 'goal',
      half: '1H',
      minute: 10,
      stoppage: null,
      teamId: home.id,
      playerId: p!.id,
      assistPlayerId: null,
      subInPlayerId: null,
      subOutPlayerId: null,
      note: null,
      voided: false,
    })
    expect(ev).not.toBeNull()
    expect(matches.find(m.id)?.homeScore).toBe(1)
  })
})

describe('useMatchesStore clockNowMs', () => {
  afterEach(() => {
    vi.useRealTimers()
  })

  it('does not subtract elapsed when system clock goes backwards', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-06-01T14:00:00.000Z').getTime())
    const teams = useTeamsStore()
    const home = teams.createTeam({ name: 'Home' })
    const away = teams.createTeam({ name: 'Away' })
    const matches = useMatchesStore()
    const m = matches.createMatch({ title: 'Test', homeTeamId: home.id, awayTeamId: away.id })
    matches.clockStart(m.id)
    vi.setSystemTime(new Date('2026-06-01T13:59:00.000Z').getTime())
    const cur = matches.find(m.id)!
    expect(matches.clockNowMs(cur)).toBe(cur.clockAccumulatedMs)
  })
})
