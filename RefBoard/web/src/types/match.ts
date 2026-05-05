/** 試合ステータス（UI ドロップダウン用） */
export type MatchUiStatus =
  | 'pre_match'
  | 'first_half'
  | 'halftime'
  | 'second_half'
  | 'extra_time'
  | 'penalties'
  | 'full_time'

export type MatchDbStatus = 'draft' | 'finished' | 'cancelled'

export type PlayerRowStatus = 'playing' | 'warning' | 'sent_off' | 'bench'

export type MatchPlayer = {
  id: string
  number: number
  name: string
  position: string
  status: PlayerRowStatus
}

export type MatchEventKind = 'goal' | 'yellow' | 'red' | 'sub' | 'other'

export type MatchEvent = {
  id: string
  minute: string
  kind: MatchEventKind
  text: string
}

export type HalfScoreBreakdown = {
  firstHalf: { home: number; away: number }
  secondHalf: { home: number; away: number }
  extra: { home: number; away: number }
}

export type MatchDetailModel = {
  id: number
  matchName: string
  venue: string
  matchDate: string
  kickoffTime: string
  uiStatus: MatchUiStatus
  home: { name: string; short: string; isHome: boolean }
  away: { name: string; short: string; isHome: boolean }
  score: { home: number; away: number }
  clockLabel: string
  clockMmSs: string
  breakdown: HalfScoreBreakdown
  homePlayers: MatchPlayer[]
  awayPlayers: MatchPlayer[]
  events: MatchEvent[]
}

export type MatchListRow = {
  id: number
  team1_id: number
  team2_id: number
  team1_name?: string
  team2_name?: string
  team1_score: number
  team2_score: number
  status: MatchDbStatus
  match_date: string
  match_name?: string | null
  venue?: string | null
  kickoff_time?: string | null
}

export type TeamRow = {
  id: number
  name: string
  short_name?: string | null
  color?: string | null
}
