import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useMatchesStore } from './matches'
import { useTeamsStore } from './teams'
import { resetIdCounters } from '../utils/localId'

beforeEach(() => {
  setActivePinia(createPinia())
  resetIdCounters()
})

describe('createMatch validation (T-04)', () => {
  it('throws title_required for empty title', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    expect(() =>
      matches.createMatch({
        title: '   ',
        homeTeamId: t1.id,
        awayTeamId: t2.id,
        halfMinutes: 45,
      }),
    ).toThrow('title_required')
  })

  it('throws title_too_long for title >100 chars', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    expect(() =>
      matches.createMatch({
        title: 'x'.repeat(101),
        homeTeamId: t1.id,
        awayTeamId: t2.id,
        halfMinutes: 45,
      }),
    ).toThrow('title_too_long')
  })

  it('throws half_minutes_out_of_range for 0', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    expect(() =>
      matches.createMatch({
        title: 'OK',
        homeTeamId: t1.id,
        awayTeamId: t2.id,
        halfMinutes: 0,
      }),
    ).toThrow('half_minutes_out_of_range')
  })

  it('throws half_minutes_out_of_range for 200', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    expect(() =>
      matches.createMatch({
        title: 'OK',
        homeTeamId: t1.id,
        awayTeamId: t2.id,
        halfMinutes: 200,
      }),
    ).toThrow('half_minutes_out_of_range')
  })

  it('throws team_not_found for missing team (既存挙動の維持確認)', () => {
    const matches = useMatchesStore()
    expect(() =>
      matches.createMatch({
        title: 'OK',
        homeTeamId: 999_999,
        awayTeamId: 888_888,
        halfMinutes: 45,
      }),
    ).toThrow('team_not_found')
  })

  it('accepts createMatch with omitted halfMinutes (defaults to 45)', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    const m = matches.createMatch({
      title: '練習試合',
      homeTeamId: t1.id,
      awayTeamId: t2.id,
    })
    expect(m.halfMinutes).toBe(45)
  })
})

describe('manualScoreEdit validation (T-03)', () => {
  it('rejects negative homeScore (no state change)', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    const m = matches.createMatch({ title: 't', homeTeamId: t1.id, awayTeamId: t2.id })
    matches.manualScoreEdit(m.id, { homeScore: -1, awayScore: 0, reason: '' })
    expect(matches.find(m.id)!.homeScore).toBe(0)
    expect(matches.find(m.id)!.scoreHistory.length).toBe(0)
  })

  it('rejects non-integer score', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    const m = matches.createMatch({ title: 't', homeTeamId: t1.id, awayTeamId: t2.id })
    matches.manualScoreEdit(m.id, { homeScore: 1.5, awayScore: 0, reason: '' })
    expect(matches.find(m.id)!.homeScore).toBe(0)
  })

  it('rejects score >= 1000', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    const m = matches.createMatch({ title: 't', homeTeamId: t1.id, awayTeamId: t2.id })
    matches.manualScoreEdit(m.id, { homeScore: 1000, awayScore: 0, reason: '' })
    expect(matches.find(m.id)!.homeScore).toBe(0)
  })

  it('accepts valid score', () => {
    const teams = useTeamsStore()
    const t1 = teams.createTeam({ name: 'A' })
    const t2 = teams.createTeam({ name: 'B' })
    const matches = useMatchesStore()
    const m = matches.createMatch({ title: 't', homeTeamId: t1.id, awayTeamId: t2.id })
    matches.manualScoreEdit(m.id, { homeScore: 3, awayScore: 0, reason: 'VAR 判定' })
    expect(matches.find(m.id)!.homeScore).toBe(3)
    expect(matches.find(m.id)!.awayScore).toBe(0)
    expect(matches.find(m.id)!.scoreHistory.length).toBe(1)
  })
})
