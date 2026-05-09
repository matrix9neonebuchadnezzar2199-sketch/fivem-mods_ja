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
  /** CSV 用。ローカル `MatchEvent` 由来の数値（`minute` は表示ラベル） */
  eventMinute?: number
  eventStoppage?: number | null
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
  /** 表示用スナップショット（経過 mm:ss）。進行中はティックで再計算し detail は頻繁に書き換えない */
  clockMmSs: string
  /** DB matches.clock_accumulated_ms（停止時点までの累積経過 ms） */
  clockAccumulatedMs: number
  /** DB matches.clock_running */
  clockRunning: boolean
  /** DB matches.clock_started_at（Unix epoch ms）。進行中のみ */
  clockStartedAtMs: number | null
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

/** refboard:match:clock:ack */
export type MatchClockAck = {
  ok?: boolean
  error?: string
  matchId?: number
  clock_running?: number
  /** サーバが nil を JSON 省略すると undefined になり得る */
  clock_started_at?: number | null | string
  clock_accumulated_ms?: number
}

export type MatchListRow = {
  id: number
  team1_id: number
  team2_id: number
  team1_name?: string
  team2_name?: string
  team1_score: number
  team2_score: number
  status: MatchDbStatus | 'live'
  match_date: string
  match_name?: string | null
  venue?: string | null
  kickoff_time?: string | null
  /** DB: 計測中のみ一覧で残り時間をライブ表示 */
  clock_running?: number
  clock_started_at?: number | null
  clock_accumulated_ms?: number
}

export type TeamRow = {
  id: number
  name: string
  short_name?: string | null
  color?: string | null
  emblem_emoji?: string | null
}
