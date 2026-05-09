/**
 * モック永続化レイヤ（ブラウザ専用）
 *
 * - localStorage キー: `refboard:mock:state`
 * - スキーマバージョン: `STORAGE_VERSION`（現在 5）。破壊的変更時は bump し、古い JSON は破棄して `seedInitialState()` が使われる。
 * - 開発者は `window.__refboardMock.reset()`（DEV のみ公開）で手動リセット可能。
 * - FiveM 本番 NUI では `useBrowserMock()` が false のため本モジュールの save は呼ばれない想定。
 *
 * sessionStorage ではなく localStorage を選んだ理由: タブを閉じても開発中のシード／CRUD 検証が維持され、実機 DB に近い「再訪問で状態が残る」体験になるため。
 */

import type { MatchDbStatus, MatchDetailModel, MatchPlayer, MatchUiStatus } from '../types/match'
import { formatClockMs, getElapsedMsFromClockState } from '../utils/matchClock'
import { mockMatchDetail } from './matchDetail'

export const STORAGE_KEY = 'refboard:mock:state'
/** 破壊的シード変更時に上げる（localStorage を捨てて `seedInitialState()` へ） */
export const STORAGE_VERSION = 5

export type PersistedTeam = {
  id: number
  name: string
  short_name: string
  color: string
  emblem_emoji?: string | null
  deleted_at?: string | null
}

export type PersistedListRow = {
  id: number
  team1_id: number
  team2_id: number
  team1_name: string
  team2_name: string
  team1_score: number
  team2_score: number
  status: 'draft' | 'finished' | 'cancelled'
  current_half: string
  match_date: string
  match_name: string
  venue: string
  kickoff_time: string
  clock_running?: number
  clock_started_at?: number | null
  clock_accumulated_ms?: number
}

export type RosterRow = {
  id: number
  player_name: string
  jersey_number: number | null
  position: string | null
  license: string | null
  matches_played?: number
  goals?: number
  yellows?: number
  reds?: number
}

export type ScoreHistoryMockRow = {
  id: number
  match_id: number
  team1_score: number
  team2_score: number
  half: string
  match_time_ms: number
  action: string
  reason: string | null
  changed_by_license: string
  changed_by_name: string
  created_at: string
  match_date?: string
  match_name?: string
  team1_name?: string
  team2_name?: string
}

export interface MockPersistenceState {
  version: number
  teams: PersistedTeam[]
  listRows: PersistedListRow[]
  matchDetails: Record<string, MatchDetailModel>
  rosterByTeam: Record<string, RosterRow[]>
  matchDrafts: Record<string, unknown>
  scoreHistory: ScoreHistoryMockRow[]
  focusedMatchId: number
  nextIds: {
    team: number
    match: number
    roster: number
    history: number
  }
}

function clone<T>(x: T): T {
  return JSON.parse(JSON.stringify(x)) as T
}

const MOCK_LICENSE = 'mock-license'
const MOCK_REF_NAME = 'モック審判'

/** 1チームあたりロスター15人（GK1 + DF4 + MF5 + FW5）のテスト用シード */
const ROSTER_POSITIONS: Array<'GK' | 'DF' | 'MF' | 'FW'> = [
  'GK',
  'DF',
  'DF',
  'DF',
  'DF',
  'MF',
  'MF',
  'MF',
  'MF',
  'MF',
  'FW',
  'FW',
  'FW',
  'FW',
  'FW',
]

function rosterRowsForTeam(teamId: number, code: string, firstRosterId: number): RosterRow[] {
  return ROSTER_POSITIONS.map((position, i) => ({
    id: firstRosterId + i,
    player_name: `${code} 選手${String(i + 1).padStart(2, '0')}`,
    jersey_number: i + 1,
    position,
    license: `mock:t${teamId}:j${i + 1}`,
    matches_played: 0,
    goals: 0,
    yellows: 0,
    reds: 0,
  }))
}

const TEAM_NAMES: Record<number, string> = {
  1: 'Los Santos FC',
  2: 'Vinewood United',
  3: 'Paleto Bay SC',
  4: 'Sandy Shores AC',
  5: 'Grapeseed Town FC',
}

/** sql/dev_seed_20matches と同じ並びの試合20件（モック一覧用） */
function seedFixture20ListRows(): PersistedListRow[] {
  const venue = 'テストスタジアム'
  const spec: Array<{
    id: number
    t1: number
    t2: number
    s1: number
    s2: number
    status: 'draft' | 'finished' | 'cancelled'
    half: string
    date: string
    name: string
  }> = [
    { id: 1, t1: 1, t2: 2, s1: 0, s2: 0, status: 'draft', half: '1st', date: '2026-05-01', name: '開発用試合01' },
    { id: 2, t1: 2, t2: 3, s1: 0, s2: 0, status: 'draft', half: '1st', date: '2026-05-02', name: '開発用試合02' },
    { id: 3, t1: 3, t2: 4, s1: 0, s2: 0, status: 'draft', half: 'halftime', date: '2026-05-03', name: '開発用試合03' },
    { id: 4, t1: 4, t2: 5, s1: 0, s2: 0, status: 'draft', half: '2nd', date: '2026-05-04', name: '開発用試合04' },
    { id: 5, t1: 5, t2: 1, s1: 0, s2: 0, status: 'draft', half: '1st', date: '2026-05-05', name: '開発用試合05' },
    { id: 6, t1: 1, t2: 2, s1: 0, s2: 0, status: 'draft', half: '1st', date: '2026-05-06', name: '開発用試合06' },
    { id: 7, t1: 2, t2: 3, s1: 0, s2: 0, status: 'draft', half: '1st', date: '2026-05-07', name: '開発用試合07' },
    { id: 8, t1: 3, t2: 4, s1: 0, s2: 0, status: 'draft', half: '1st', date: '2026-05-08', name: '開発用試合08' },
    { id: 9, t1: 4, t2: 5, s1: 0, s2: 0, status: 'draft', half: '1st', date: '2026-05-09', name: '開発用試合09' },
    { id: 10, t1: 5, t2: 1, s1: 0, s2: 0, status: 'draft', half: '1st', date: '2026-05-10', name: '開発用試合10' },
    { id: 11, t1: 1, t2: 2, s1: 2, s2: 1, status: 'finished', half: '2nd', date: '2026-05-11', name: '開発用試合11' },
    { id: 12, t1: 2, t2: 3, s1: 0, s2: 0, status: 'finished', half: '2nd', date: '2026-05-12', name: '開発用試合12' },
    { id: 13, t1: 3, t2: 4, s1: 3, s2: 3, status: 'finished', half: '2nd', date: '2026-05-13', name: '開発用試合13' },
    { id: 14, t1: 4, t2: 5, s1: 1, s2: 2, status: 'finished', half: '2nd', date: '2026-05-14', name: '開発用試合14' },
    { id: 15, t1: 5, t2: 1, s1: 4, s2: 0, status: 'finished', half: '2nd', date: '2026-05-15', name: '開発用試合15' },
    { id: 16, t1: 1, t2: 2, s1: 0, s2: 1, status: 'finished', half: 'pk', date: '2026-05-16', name: '開発用試合16' },
    { id: 17, t1: 2, t2: 3, s1: 2, s2: 2, status: 'finished', half: '2nd', date: '2026-05-17', name: '開発用試合17' },
    { id: 18, t1: 3, t2: 4, s1: 1, s2: 0, status: 'finished', half: '2nd', date: '2026-05-18', name: '開発用試合18' },
    { id: 19, t1: 4, t2: 5, s1: 0, s2: 0, status: 'cancelled', half: '1st', date: '2026-05-19', name: '開発用試合19' },
    { id: 20, t1: 5, t2: 1, s1: 5, s2: 4, status: 'finished', half: '2nd', date: '2026-05-20', name: '開発用試合20' },
  ]
  return spec.map((x) => ({
    id: x.id,
    team1_id: x.t1,
    team2_id: x.t2,
    team1_name: TEAM_NAMES[x.t1] ?? 'Team A',
    team2_name: TEAM_NAMES[x.t2] ?? 'Team B',
    team1_score: x.s1,
    team2_score: x.s2,
    status: x.status,
    current_half: x.half,
    match_date: x.date,
    match_name: x.name,
    venue,
    kickoff_time: '',
    clock_running: 0,
    clock_started_at: null,
    clock_accumulated_ms: 0,
  }))
}

/** チームロスター → 試合詳細用メンバー（先発11＋控え4想定） */
function rosterRowsToMatchPlayers(matchId: number, teamId: number, rows: RosterRow[] | undefined): MatchPlayer[] {
  if (!rows?.length) return []
  return rows.map((r, i) => ({
    id: `m${matchId}-t${teamId}-r${r.id}`,
    number: typeof r.jersey_number === 'number' ? r.jersey_number : i + 1,
    name: r.player_name,
    position: String(r.position ?? 'MF'),
    status: i < 11 ? 'playing' : 'bench',
    yellowCards: 0,
  }))
}

function mapHalfToUiStatus(half: string, dbStatus: MatchDbStatus): MatchUiStatus {
  if (dbStatus === 'finished') return 'full_time'
  if (dbStatus === 'cancelled') return 'pre_match'
  if (half === 'halftime') return 'halftime'
  if (half === '2nd') return 'second_half'
  if (half === 'pk') return 'penalties'
  if (half === 'et') return 'extra_time'
  return 'first_half'
}

function matchDetailFromListRow(
  row: PersistedListRow,
  teams: PersistedTeam[],
  rosterByTeam: Record<string, RosterRow[]>,
): MatchDetailModel {
  const t1 = teams.find((t) => t.id === row.team1_id)
  const t2 = teams.find((t) => t.id === row.team2_id)
  const d = clone(mockMatchDetail)
  d.id = row.id
  d.team1Id = row.team1_id
  d.team2Id = row.team2_id
  d.matchName = row.match_name
  d.venue = row.venue
  d.matchDate = row.match_date
  d.kickoffTime = row.kickoff_time ? String(row.kickoff_time).slice(0, 5) : ''
  d.home = {
    name: row.team1_name,
    short: t1?.short_name ?? 'T1',
    isHome: true,
  }
  d.away = {
    name: row.team2_name,
    short: t2?.short_name ?? 'T2',
    isHome: false,
  }
  d.score = { home: row.team1_score, away: row.team2_score }
  d.dbStatus = row.status
  d.serverHalf = row.current_half
  d.pkFirstTeamId = row.team1_id
  d.uiStatus = mapHalfToUiStatus(row.current_half, row.status)
  const acc = Number(row.clock_accumulated_ms) || 0
  const running = Number(row.clock_running) === 1
  const started =
    row.clock_started_at != null && String(row.clock_started_at) !== ''
      ? Number(row.clock_started_at)
      : null
  d.clockAccumulatedMs = acc
  d.clockRunning = running
  d.clockStartedAtMs = started != null && Number.isFinite(started) ? started : null
  const elapsed = getElapsedMsFromClockState(acc, running, d.clockStartedAtMs, Date.now())
  d.clockMmSs = formatClockMs(elapsed)
  d.clockLabel = row.status === 'finished' ? '試合終了' : row.status === 'cancelled' ? '中止' : '0:00'
  const h = row.team1_score
  const a = row.team2_score
  if (row.current_half === 'pk') {
    d.breakdown = {
      firstHalf: { home: 0, away: 0 },
      secondHalf: { home: 0, away: 0 },
      extra: { home: 0, away: 0 },
      pk: { home: h, away: a },
    }
  } else {
    const fh = { home: Math.floor(h * 0.45), away: Math.floor(a * 0.45) }
    d.breakdown = {
      firstHalf: fh,
      secondHalf: { home: h - fh.home, away: a - fh.away },
      extra: { home: 0, away: 0 },
      pk: { home: 0, away: 0 },
    }
  }
  d.homePlayers = rosterRowsToMatchPlayers(row.id, row.team1_id, rosterByTeam[String(row.team1_id)])
  d.awayPlayers = rosterRowsToMatchPlayers(row.id, row.team2_id, rosterByTeam[String(row.team2_id)])
  d.events = []
  return d
}

/** SQL 完全初期化に相当する空庫（チーム・試合なし） */
export function seedEmptyAfterWipeState(): MockPersistenceState {
  return {
    version: STORAGE_VERSION,
    teams: [],
    listRows: [],
    matchDetails: {},
    rosterByTeam: {},
    matchDrafts: {},
    scoreHistory: [],
    focusedMatchId: 0,
    nextIds: { team: 1, match: 1, roster: 1, history: 1 },
  }
}

export function seedInitialState(): MockPersistenceState {
  const teams: PersistedTeam[] = [
    { id: 1, name: 'Los Santos FC', short_name: 'LS', color: '#3b82f6', emblem_emoji: '⚽', deleted_at: null },
    { id: 2, name: 'Vinewood United', short_name: 'VW', color: '#64748b', emblem_emoji: null, deleted_at: null },
    { id: 3, name: 'Paleto Bay SC', short_name: 'PB', color: '#22c55e', emblem_emoji: null, deleted_at: null },
    { id: 4, name: 'Sandy Shores AC', short_name: 'SS', color: '#f59e0b', emblem_emoji: null, deleted_at: null },
    { id: 5, name: 'Grapeseed Town FC', short_name: 'GT', color: '#a855f7', emblem_emoji: null, deleted_at: null },
  ]
  const listRows = seedFixture20ListRows()
  const rosterByTeam: Record<string, RosterRow[]> = {
    '1': rosterRowsForTeam(1, 'LS', 9001),
    '2': rosterRowsForTeam(2, 'VW', 9016),
    '3': rosterRowsForTeam(3, 'PB', 9031),
    '4': rosterRowsForTeam(4, 'SS', 9046),
    '5': rosterRowsForTeam(5, 'GT', 9061),
  }
  const matchDetails: Record<string, MatchDetailModel> = {}
  for (const row of listRows) {
    matchDetails[String(row.id)] = matchDetailFromListRow(row, teams, rosterByTeam)
  }
  const scoreHistory: ScoreHistoryMockRow[] = [
    {
      id: 1,
      match_id: 1,
      team1_score: 0,
      team2_score: 0,
      half: '1st',
      match_time_ms: 0,
      action: 'mock_seed',
      reason: null,
      changed_by_license: MOCK_LICENSE,
      changed_by_name: MOCK_REF_NAME,
      created_at: '2026-05-01T10:00:00',
      match_date: '2026-05-01',
      match_name: '開発用試合01',
      team1_name: 'Los Santos FC',
      team2_name: 'Vinewood United',
    },
  ]
  return {
    version: STORAGE_VERSION,
    teams,
    listRows,
    matchDetails,
    rosterByTeam,
    matchDrafts: {},
    scoreHistory,
    focusedMatchId: 1,
    nextIds: { team: 6, match: 21, roster: 9076, history: 2 },
  }
}

export function loadMockState(): MockPersistenceState {
  if (typeof localStorage === 'undefined') {
    return seedInitialState()
  }
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return seedInitialState()
    const parsed = JSON.parse(raw) as MockPersistenceState
    if (parsed.version !== STORAGE_VERSION) {
      // eslint-disable-next-line no-console
      console.warn('[NUI MOCK] storage version mismatch, reseeding')
      return seedInitialState()
    }
    return parsed
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn('[NUI MOCK] failed to load state, reseeding', e)
    return seedInitialState()
  }
}

export function saveMockState(state: MockPersistenceState): void {
  if (typeof localStorage === 'undefined') return
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('[NUI MOCK] failed to save state', e)
  }
}

export function clearMockStorage(): void {
  if (typeof localStorage === 'undefined') return
  localStorage.removeItem(STORAGE_KEY)
}

export const MOCK_AUDIT = {
  license: MOCK_LICENSE,
  refereeName: MOCK_REF_NAME,
} as const
