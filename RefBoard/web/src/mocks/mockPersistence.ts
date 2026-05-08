/**
 * モック永続化レイヤ（ブラウザ専用）
 *
 * - localStorage キー: `refboard:mock:state`
 * - スキーマバージョン: `STORAGE_VERSION`（現在 2）。破壊的変更時は bump し、古い JSON は破棄して `seedInitialState()` が使われる。
 * - 開発者は `window.__refboardMock.reset()`（DEV のみ公開）で手動リセット可能。
 * - FiveM 本番 NUI では `useBrowserMock()` が false のため本モジュールの save は呼ばれない想定。
 *
 * sessionStorage ではなく localStorage を選んだ理由: タブを閉じても開発中のシード／CRUD 検証が維持され、実機 DB に近い「再訪問で状態が残る」体験になるため。
 */

import type { MatchDetailModel } from '../types/match'
import { mockMatchDetail } from './matchDetail'

export const STORAGE_KEY = 'refboard:mock:state'
/** 破壊的シード変更時に上げる（localStorage を捨てて `seedInitialState()` へ） */
export const STORAGE_VERSION = 2

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

export function seedInitialState(): MockPersistenceState {
  const teams: PersistedTeam[] = [
    { id: 1, name: 'Los Santos FC', short_name: 'LS', color: '#3b82f6', emblem_emoji: '⚽', deleted_at: null },
    { id: 2, name: 'Vinewood United', short_name: 'VW', color: '#64748b', emblem_emoji: null, deleted_at: null },
    { id: 3, name: 'Paleto Bay SC', short_name: 'PB', color: '#22c55e', emblem_emoji: null, deleted_at: null },
    { id: 4, name: 'Sandy Shores AC', short_name: 'SS', color: '#f59e0b', emblem_emoji: null, deleted_at: null },
    { id: 5, name: 'Grapeseed Town FC', short_name: 'GT', color: '#a855f7', emblem_emoji: null, deleted_at: null },
  ]
  const listRows: PersistedListRow[] = [
    {
      id: 1,
      team1_id: 1,
      team2_id: 2,
      team1_name: 'Los Santos FC',
      team2_name: 'Vinewood United',
      team1_score: 2,
      team2_score: 1,
      status: 'draft',
      current_half: '2nd',
      match_date: '2026-05-05',
      match_name: 'リーグ戦 第7節',
      venue: 'Maze Bank Arena',
      kickoff_time: '20:00:00',
    },
  ]
  const rosterByTeam: Record<string, RosterRow[]> = {
    '1': rosterRowsForTeam(1, 'LS', 9001),
    '2': rosterRowsForTeam(2, 'VW', 9016),
    '3': rosterRowsForTeam(3, 'PB', 9031),
    '4': rosterRowsForTeam(4, 'SS', 9046),
    '5': rosterRowsForTeam(5, 'GT', 9061),
  }
  const scoreHistory: ScoreHistoryMockRow[] = [
    {
      id: 1,
      match_id: 1,
      team1_score: 1,
      team2_score: 1,
      half: '2nd',
      match_time_ms: 0,
      action: 'manual_edit',
      reason: '訂正',
      changed_by_license: MOCK_LICENSE,
      changed_by_name: MOCK_REF_NAME,
      created_at: '2026-05-05T12:00:00',
      match_date: '2026-05-05',
      match_name: 'テスト',
      team1_name: 'Los Santos FC',
      team2_name: 'Vinewood United',
    },
  ]
  return {
    version: STORAGE_VERSION,
    teams,
    listRows,
    matchDetails: { '1': clone(mockMatchDetail) },
    rosterByTeam,
    matchDrafts: {},
    scoreHistory,
    focusedMatchId: 1,
    nextIds: { team: 6, match: 2, roster: 9076, history: 2 },
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
