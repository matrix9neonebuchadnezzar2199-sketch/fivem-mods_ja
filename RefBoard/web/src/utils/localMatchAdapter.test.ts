import { describe, it, expect } from 'vitest'
import type { Match, MatchEvent as LocalMatchEvent, MatchPlayer as LocalMatchPlayer } from '../types/local'
import { computeFieldGoalBreakdown, localEventToRow } from './localMatchAdapter'

const players: LocalMatchPlayer[] = [
  { id: 1, matchId: 1, teamId: 10, name: '山田', number: 10, status: 'playing' },
  { id: 2, matchId: 1, teamId: 20, name: 'Smith', number: 7, status: 'playing' },
]

function pkEvent(overrides: Partial<LocalMatchEvent>): LocalMatchEvent {
  return {
    id: 1,
    matchId: 1,
    kind: 'pk_goal',
    half: 'PK',
    minute: 0,
    stoppage: null,
    teamId: 10,
    playerId: 1,
    assistPlayerId: null,
    subInPlayerId: null,
    subOutPlayerId: null,
    note: null,
    voided: false,
    createdAt: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

function baseMatch(over: Partial<Match> = {}): Match {
  return {
    id: 1,
    title: 'M',
    homeTeamId: 10,
    awayTeamId: 20,
    homeName: 'H',
    awayName: 'A',
    homeScore: 2,
    awayScore: 1,
    homePkScore: null,
    awayPkScore: null,
    status: 'live',
    currentHalf: '2H',
    halfMinutes: 45,
    clockStartedAt: null,
    clockAccumulatedMs: 0,
    scheduledAt: null,
    startedAt: null,
    finishedAt: null,
    reopenedAt: null,
    venue: null,
    players: [],
    events: [],
    scoreHistory: [],
    createdAt: '',
    updatedAt: '',
    ...over,
  }
}

describe('computeFieldGoalBreakdown', () => {
  it('splits 1H vs 2H goals by event half', () => {
    const m = baseMatch({
      events: [
        {
          id: 1,
          matchId: 1,
          kind: 'goal',
          half: '1H',
          minute: 5,
          teamId: 10,
          playerId: 1,
          assistPlayerId: null,
          subInPlayerId: null,
          subOutPlayerId: null,
          note: null,
          voided: false,
          createdAt: '',
        },
        {
          id: 2,
          matchId: 1,
          kind: 'goal',
          half: '2H',
          minute: 50,
          teamId: 20,
          playerId: 2,
          assistPlayerId: null,
          subInPlayerId: null,
          subOutPlayerId: null,
          note: null,
          voided: false,
          createdAt: '',
        },
        {
          id: 3,
          matchId: 1,
          kind: 'goal',
          half: '2H',
          minute: 70,
          teamId: 10,
          playerId: 1,
          assistPlayerId: null,
          subInPlayerId: null,
          subOutPlayerId: null,
          note: null,
          voided: false,
          createdAt: '',
        },
      ],
    })
    const b = computeFieldGoalBreakdown(m)
    expect(b.firstHalf).toEqual({ home: 1, away: 0 })
    expect(b.secondHalf).toEqual({ home: 1, away: 1 })
    expect(b.extra).toEqual({ home: 0, away: 0 })
  })

  it('ignores voided goals and pk_goal', () => {
    const m = baseMatch({
      events: [
        {
          id: 1,
          matchId: 1,
          kind: 'goal',
          half: '1H',
          minute: 1,
          teamId: 10,
          playerId: 1,
          assistPlayerId: null,
          subInPlayerId: null,
          subOutPlayerId: null,
          note: null,
          voided: true,
          createdAt: '',
        },
        {
          id: 2,
          matchId: 1,
          kind: 'pk_goal',
          half: 'PK',
          minute: 0,
          teamId: 10,
          playerId: 1,
          assistPlayerId: null,
          subInPlayerId: null,
          subOutPlayerId: null,
          note: null,
          voided: false,
          createdAt: '',
        },
      ],
    })
    const b = computeFieldGoalBreakdown(m)
    expect(b.firstHalf).toEqual({ home: 0, away: 0 })
    expect(b.secondHalf).toEqual({ home: 0, away: 0 })
  })
})

describe('localEventToRow PK', () => {
  it('pk_goal maps to penalty row with text and pk* fields', () => {
    const row = localEventToRow(pkEvent({ id: 101, kind: 'pk_goal', playerId: 1, teamId: 10 }), players)
    expect(row.kind).toBe('penalty')
    expect(row.penaltySuccess).toBe(true)
    expect(row.text).toContain('⚽')
    expect(row.text).toContain('10')
    expect(row.text).toContain('山田')
    expect(row.pkTeamId).toBe(10)
    expect(row.pkPlayerNumber).toBe(10)
    expect(row.pkPlayerName).toBe('山田')
    expect(row.minute).toBe('PK')
  })

  it('pk_miss sets penaltySuccess false and 失敗 in text', () => {
    const row = localEventToRow(pkEvent({ id: 102, kind: 'pk_miss', playerId: 2, teamId: 20 }), players)
    expect(row.penaltySuccess).toBe(false)
    expect(row.text).toContain('失敗')
    expect(row.text).toContain('Smith')
    expect(row.pkTeamId).toBe(20)
    expect(row.pkPlayerNumber).toBe(7)
    expect(row.pkPlayerName).toBe('Smith')
  })

  it('falls back to icon/label only when player not found', () => {
    const row = localEventToRow(
      pkEvent({ id: 103, kind: 'pk_goal', playerId: 999, teamId: 10 }),
      players,
    )
    expect(row.text).toBe('⚽')
    expect(row.pkPlayerNumber).toBeNull()
    expect(row.pkPlayerName).toBeNull()
    expect(row.pkTeamId).toBe(10)
  })

  it('pk_miss without scorer uses 失敗 label only', () => {
    const row = localEventToRow(
      pkEvent({ id: 104, kind: 'pk_miss', playerId: 998, teamId: 20 }),
      players,
    )
    expect(row.text).toBe('失敗')
    expect(row.penaltySuccess).toBe(false)
  })
})
