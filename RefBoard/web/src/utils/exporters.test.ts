import { describe, it, expect } from 'vitest'
import type { Match, MatchEvent, MatchPlayer } from '../types/local'
import {
  CSV_EVENT_COLUMNS_DETAILED,
  CSV_EVENT_COLUMNS_STANDARD,
  exportMatchEventsToCSV,
  exportMatchSummaryToCSV,
} from './exporters'

const ctx = { operator: '審判テスト' }

function headerLine(csv: string): string {
  return csv.replace(/^\uFEFF/, '').split(/\r?\n/)[0] ?? ''
}

function baseMatch(overrides: Partial<Match> = {}): Match {
  const now = '2026-05-10T12:00:00.000Z'
  return {
    id: 42,
    title: 'カップ戦 PKデモ',
    homeTeamId: 10,
    awayTeamId: 20,
    homeName: 'Home FC',
    awayName: 'Away Utd',
    homeScore: 1,
    awayScore: 1,
    homePkScore: 2,
    awayPkScore: 2,
    status: 'live',
    currentHalf: 'PK',
    halfMinutes: 45,
    clockAccumulatedMs: 0,
    scheduledAt: '2026-05-10T15:00:00.000Z',
    players: [],
    events: [],
    scoreHistory: [],
    createdAt: now,
    updatedAt: now,
    ...overrides,
  }
}

function ev(overrides: Partial<MatchEvent> & Pick<MatchEvent, 'id' | 'kind'>): MatchEvent {
  return {
    matchId: 42,
    half: '2H',
    minute: 10,
    stoppage: null,
    teamId: 10,
    playerId: null,
    assistPlayerId: null,
    subInPlayerId: null,
    subOutPlayerId: null,
    note: null,
    voided: false,
    createdAt: '2026-05-10T14:00:00.000Z',
    ...overrides,
  }
}

describe('exportMatchEventsToCSV / summary', () => {
  it('standard mode header has 13 columns', () => {
    const m = baseMatch({ events: [ev({ id: 1, kind: 'note', teamId: null })] })
    const csv = exportMatchEventsToCSV(m, ctx, 'standard')
    const cols = headerLine(csv).split(',')
    expect(cols.length).toBe(13)
    expect(cols).toEqual([...CSV_EVENT_COLUMNS_STANDARD])
  })

  it('detailed mode header has 26 columns', () => {
    const m = baseMatch({ events: [ev({ id: 1, kind: 'note', teamId: null })] })
    const csv = exportMatchEventsToCSV(m, ctx, 'detailed')
    const cols = headerLine(csv).split(',')
    expect(cols.length).toBe(26)
    expect(cols).toEqual([...CSV_EVENT_COLUMNS_DETAILED])
  })

  it('PK rows have pk_result and pk_shot_index per team', () => {
    const players: MatchPlayer[] = [
      { id: 1, matchId: 42, teamId: 10, name: 'A', number: 1, status: 'playing' },
      { id: 2, matchId: 42, teamId: 20, name: 'B', number: 2, status: 'playing' },
    ]
    const m = baseMatch({
      players,
      events: [
        ev({ id: 1, kind: 'pk_goal', half: 'PK', minute: 0, teamId: 10, playerId: 1 }),
        ev({ id: 2, kind: 'pk_goal', half: 'PK', minute: 0, teamId: 20, playerId: 2 }),
        ev({ id: 3, kind: 'pk_miss', half: 'PK', minute: 0, teamId: 10, playerId: 1 }),
        ev({ id: 4, kind: 'pk_goal', half: 'PK', minute: 0, teamId: 20, playerId: 2 }),
      ],
    })
    const csv = exportMatchEventsToCSV(m, ctx, 'detailed')
    const lines = csv.replace(/^\uFEFF/, '').split(/\r?\n/)
    const row1 = lines[1].split(',')
    const pkResultIdx = CSV_EVENT_COLUMNS_DETAILED.indexOf('pk_result')
    const pkIdxIdx = CSV_EVENT_COLUMNS_DETAILED.indexOf('pk_shot_index')
    expect(row1[pkResultIdx]).toBe('goal')
    expect(row1[pkIdxIdx]).toBe('1')
    const row3 = lines[3].split(',')
    expect(row3[pkResultIdx]).toBe('miss')
    expect(row3[pkIdxIdx]).toBe('2')
  })

  it('substitution row fills sub_in / sub_out columns', () => {
    const players: MatchPlayer[] = [
      { id: 1, matchId: 42, teamId: 10, name: 'Out', number: 7, status: 'playing' },
      { id: 2, matchId: 42, teamId: 10, name: 'In', number: 15, status: 'playing' },
    ]
    const m = baseMatch({
      homePkScore: null,
      awayPkScore: null,
      currentHalf: '2H',
      players,
      events: [
        ev({
          id: 1,
          kind: 'sub_out',
          minute: 55,
          teamId: 10,
          subOutPlayerId: 1,
          subInPlayerId: 2,
        }),
      ],
    })
    const csv = exportMatchEventsToCSV(m, ctx, 'detailed')
    const lines = csv.replace(/^\uFEFF/, '').split(/\r?\n/)
    const row = lines[1].split(',')
    const kindIdx = CSV_EVENT_COLUMNS_DETAILED.indexOf('event_kind')
    const subInN = CSV_EVENT_COLUMNS_DETAILED.indexOf('sub_in_player_number')
    const subOutN = CSV_EVENT_COLUMNS_DETAILED.indexOf('sub_out_player_number')
    expect(row[kindIdx]).toBe('substitution')
    expect(row[subInN]).toBe('15')
    expect(row[subOutN]).toBe('7')
  })

  it('goal with assist fills assist columns', () => {
    const players: MatchPlayer[] = [
      { id: 1, matchId: 42, teamId: 10, name: '山田', number: 10, status: 'playing' },
      { id: 2, matchId: 42, teamId: 10, name: '鈴木', number: 8, status: 'playing' },
    ]
    const m = baseMatch({
      homePkScore: null,
      awayPkScore: null,
      currentHalf: '1H',
      players,
      events: [ev({ id: 1, kind: 'goal', minute: 23, teamId: 10, playerId: 1, assistPlayerId: 2 })],
    })
    const csv = exportMatchEventsToCSV(m, ctx, 'detailed')
    const lines = csv.replace(/^\uFEFF/, '').split(/\r?\n/)
    const row = lines[1].split(',')
    const an = CSV_EVENT_COLUMNS_DETAILED.indexOf('assist_player_number')
    const aname = CSV_EVENT_COLUMNS_DETAILED.indexOf('assist_player_name')
    expect(row[an]).toBe('8')
    expect(row[aname]).toBe('鈴木')
  })

  it('escapes commas and quotes in player names', () => {
    const players: MatchPlayer[] = [
      { id: 1, matchId: 42, teamId: 10, name: 'Smith, John "JJ"', number: 9, status: 'playing' },
    ]
    const m = baseMatch({
      homePkScore: null,
      awayPkScore: null,
      players,
      events: [ev({ id: 1, kind: 'goal', minute: 1, teamId: 10, playerId: 1 })],
    })
    const csv = exportMatchEventsToCSV(m, ctx, 'detailed')
    expect(csv).toContain('"Smith, John ""JJ"""')
  })

  it('minute_label uses 45+2 for stoppage', () => {
    const players: MatchPlayer[] = [
      { id: 1, matchId: 42, teamId: 10, name: 'P', number: 1, status: 'playing' },
    ]
    const m = baseMatch({
      homePkScore: null,
      awayPkScore: null,
      currentHalf: '2H',
      players,
      events: [ev({ id: 1, kind: 'yellow', minute: 45, stoppage: 2, teamId: 10, playerId: 1 })],
    })
    const csv = exportMatchEventsToCSV(m, ctx, 'detailed')
    const lines = csv.replace(/^\uFEFF/, '').split(/\r?\n/)
    const row = lines[1].split(',')
    const ml = CSV_EVENT_COLUMNS_DETAILED.indexOf('minute_label')
    const em = CSV_EVENT_COLUMNS_DETAILED.indexOf('event_minute')
    const es = CSV_EVENT_COLUMNS_DETAILED.indexOf('event_stoppage')
    expect(row[ml]).toBe(`45+2'`)
    expect(row[em]).toBe('45')
    expect(row[es]).toBe('2')
  })

  it('summary CSV is one data row with expected columns', () => {
    const m = baseMatch({ events: [] })
    const csv = exportMatchSummaryToCSV(m, ctx)
    const lines = csv.replace(/^\uFEFF/, '').split(/\r?\n/).filter(Boolean)
    expect(lines.length).toBe(2)
    expect(lines[0].split(',').length).toBe(9)
    expect(lines[0]).toContain('match_id')
    expect(lines[1]).toContain('m_42')
    expect(lines[1]).toContain('審判テスト')
  })

  it('skips voided and sub_in events', () => {
    const m = baseMatch({
      homePkScore: null,
      awayPkScore: null,
      events: [
        ev({ id: 1, kind: 'goal', minute: 1, teamId: 10, playerId: 1, voided: true }),
        ev({ id: 2, kind: 'sub_in', minute: 50, teamId: 10, playerId: 2 }),
        ev({ id: 3, kind: 'note', minute: 0, teamId: null }),
      ],
    })
    const csv = exportMatchEventsToCSV(m, ctx, 'standard')
    const lines = csv.replace(/^\uFEFF/, '').split(/\r?\n/).filter(Boolean)
    expect(lines.length).toBe(2)
  })
})
