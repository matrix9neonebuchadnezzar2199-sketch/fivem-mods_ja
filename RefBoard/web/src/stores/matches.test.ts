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

describe('setPkFirstTeam', () => {
  it('PK イベントが 0 件のとき先攻チームを設定できる', () => {
    const teams = useTeamsStore()
    const home = teams.createTeam({ name: 'H' })
    const away = teams.createTeam({ name: 'A' })
    const store = useMatchesStore()
    const m = store.createMatch({ title: 't', homeTeamId: home.id, awayTeamId: away.id })
    expect(store.setPkFirstTeam(m.id, away.id)).toBe(true)
    expect(store.find(m.id)?.pkFirstTeamId).toBe(away.id)
  })

  it('PK イベントが 1 件以上あれば設定を拒否する', () => {
    const teams = useTeamsStore()
    const home = teams.createTeam({ name: 'H' })
    const away = teams.createTeam({ name: 'A' })
    const store = useMatchesStore()
    const m = store.createMatch({ title: 't', homeTeamId: home.id, awayTeamId: away.id })
    store.setPkFirstTeam(m.id, home.id)
    store.addEvent(m.id, {
      kind: 'pk_goal',
      half: 'PK',
      minute: 0,
      stoppage: null,
      teamId: home.id,
      playerId: null,
      assistPlayerId: null,
      subInPlayerId: null,
      subOutPlayerId: null,
      note: null,
      voided: false,
    })
    expect(store.setPkFirstTeam(m.id, away.id)).toBe(false)
    expect(store.find(m.id)?.pkFirstTeamId).toBe(home.id)
  })

  it('不正なチーム ID は拒否する', () => {
    const teams = useTeamsStore()
    const home = teams.createTeam({ name: 'H' })
    const away = teams.createTeam({ name: 'A' })
    const store = useMatchesStore()
    const m = store.createMatch({ title: 't', homeTeamId: home.id, awayTeamId: away.id })
    expect(store.setPkFirstTeam(m.id, 99_999)).toBe(false)
    expect(store.find(m.id)?.pkFirstTeamId).toBeNull()
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
