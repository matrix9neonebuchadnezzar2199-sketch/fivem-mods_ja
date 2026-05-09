export type Half = '1H' | 'HT' | '2H' | 'FT' | 'PK'

export type PlayerStatus = 'playing' | 'warning' | 'ejected' | 'subbed_out' | 'subbed_in'

export interface RosterMember {
  id: number
  teamId: number
  name: string
  number?: number | null
  position?: string | null
  note?: string | null
}

export interface Team {
  id: number
  name: string
  shortName?: string | null
  colorHex?: string | null
  createdAt: string
  updatedAt: string
}

export interface MatchPlayer {
  id: number
  matchId: number
  teamId: number
  rosterMemberId?: number | null
  name: string
  number?: number | null
  status: PlayerStatus
}

export type MatchEventKind =
  | 'goal'
  | 'assist'
  | 'yellow'
  | 'red'
  | 'sub_in'
  | 'sub_out'
  | 'pk_goal'
  | 'pk_miss'
  | 'manual_score'
  | 'note'

export interface MatchEvent {
  id: number
  matchId: number
  kind: MatchEventKind
  half: Half
  minute: number
  stoppage?: number | null
  teamId?: number | null
  playerId?: number | null
  assistPlayerId?: number | null
  subInPlayerId?: number | null
  subOutPlayerId?: number | null
  note?: string | null
  voided?: boolean
  createdAt: string
}

export interface ScoreHistoryEntry {
  id: number
  matchId: number
  homeScore: number
  awayScore: number
  reason?: string | null
  createdAt: string
}

export interface Match {
  id: number
  title: string
  homeTeamId: number
  awayTeamId: number
  homeName: string
  awayName: string
  homeScore: number
  awayScore: number
  homePkScore?: number | null
  awayPkScore?: number | null
  status: 'draft' | 'live' | 'finished'
  currentHalf: Half
  halfMinutes: number
  clockStartedAt?: number | null
  clockAccumulatedMs: number
  scheduledAt?: string | null
  startedAt?: string | null
  finishedAt?: string | null
  reopenedAt?: string | null
  /** 会場（旧 UI の BasicInfo 用） */
  venue?: string | null
  players: MatchPlayer[]
  events: MatchEvent[]
  scoreHistory: ScoreHistoryEntry[]
  createdAt: string
  updatedAt: string
}
