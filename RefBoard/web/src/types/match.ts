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

/** match_score_history 1行（編集履歴ダイアログ用） */
export type ScoreHistoryRow = {
  id: number
  team1_score: number
  team2_score: number
  action: string
  reason: string | null
  changed_by_name: string
  created_at: string
}

export type PlayerRowStatus =
  | 'playing'
  | 'warning'
  | 'warning_double'
  | 'sent_off'
  | 'bench'
  | 'subbed_out'

export type MatchPlayer = {
  id: string
  number: number
  name: string
  position: string
  status: PlayerRowStatus
  /** サーバー由来（カード2枚目確認用） */
  yellowCards?: number
}

export type MatchEventKind = 'goal' | 'yellow' | 'red' | 'sub' | 'penalty' | 'other'

export type MatchEvent = {
  id: string
  minute: string
  kind: MatchEventKind
  text: string
  /** PK 記録時のみ */
  penaltySuccess?: boolean
}

export type HalfScoreBreakdown = {
  firstHalf: { home: number; away: number }
  secondHalf: { home: number; away: number }
  extra: { home: number; away: number }
  pk: { home: number; away: number }
}

export type MatchDetailModel = {
  id: number
  /** DB の team1_id（左＝ホーム想定） */
  team1Id: number
  /** DB の team2_id */
  team2Id: number
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
  /** DB matches.current_half */
  serverHalf: string
  pkFirstTeamId: number | null
  homePlayers: MatchPlayer[]
  awayPlayers: MatchPlayer[]
  events: MatchEvent[]
  /** DB の matches.status */
  dbStatus: MatchDbStatus
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
