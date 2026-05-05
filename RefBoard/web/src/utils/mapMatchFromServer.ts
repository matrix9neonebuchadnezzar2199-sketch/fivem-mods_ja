import type {
  HalfScoreBreakdown,
  MatchDbStatus,
  MatchDetailModel,
  MatchEvent,
  MatchEventKind,
  MatchPlayer,
  MatchUiStatus,
  PlayerRowStatus,
  ScoreHistoryRow,
} from '../types/match'

export type ServerMatchRow = {
  id: number
  team1_id: number
  team2_id: number
  team1_score: number
  team2_score: number
  status: string
  current_half: string
  match_date: string
  match_name?: string | null
  venue?: string | null
  kickoff_time?: string | null
  clock_running?: number
  clock_accumulated_ms?: number
  team1_name?: string
  team2_name?: string
}

export type ServerPlayerRow = {
  id: number
  team_id: number
  server_id: number
  license?: string | null
  player_name: string
  jersey_number?: number | null
  position?: string | null
  is_starter?: number
  is_active?: number
  yellow_cards?: number
  ui_status?: string
}

export type ServerEventRow = {
  id: number
  match_time_ms: number
  event_type?: string
  minute?: string
  text?: string
  kind?: string
}

export type ServerHistoryRow = {
  id: number
  team1_score: number
  team2_score: number
  action: string
  reason?: string | null
  changed_by_name: string
  created_at: string
}

export type MatchGetAck = {
  match: ServerMatchRow | null
  players?: ServerPlayerRow[]
  events?: ServerEventRow[]
  history?: ServerHistoryRow[]
}

function kickoffUi(v: string | null | undefined): string {
  if (!v || typeof v !== 'string') return ''
  return v.length >= 5 ? v.slice(0, 5) : v
}

function clockMmSs(ms: number): string {
  const s = Math.floor(ms / 1000)
  const mm = Math.floor(s / 60)
  const ss = s % 60
  return `${mm}:${String(ss).padStart(2, '0')}`
}

function mapUiStatus(status: string, half: string): MatchUiStatus {
  if (status === 'finished' || status === 'cancelled') return 'full_time'
  if (half === 'halftime') return 'halftime'
  if (half === '2nd') return 'second_half'
  if (half === 'et') return 'extra_time'
  if (half === 'pk') return 'penalties'
  return 'first_half'
}

function defaultBreakdown(home: number, away: number): HalfScoreBreakdown {
  return {
    firstHalf: { home: 0, away: 0 },
    secondHalf: { home, away },
    extra: { home: 0, away: 0 },
  }
}

function mapPlayerStatus(p: ServerPlayerRow): PlayerRowStatus {
  const s = p.ui_status
  if (s === 'sent_off' || s === 'bench' || s === 'warning' || s === 'playing') {
    return s
  }
  return 'playing'
}

function mapEventKind(k?: string): MatchEventKind {
  if (k === 'goal' || k === 'yellow' || k === 'red' || k === 'sub' || k === 'other') {
    return k
  }
  return 'other'
}

export function mapPlayersForTeam(rows: ServerPlayerRow[] | undefined, teamId: number): MatchPlayer[] {
  if (!rows) return []
  return rows
    .filter((r) => r.team_id === teamId)
    .map((p) => ({
      id: String(p.id),
      number: p.jersey_number ?? p.server_id ?? 0,
      name: p.player_name,
      position: (p.position && p.position.trim()) || '—',
      status: mapPlayerStatus(p),
    }))
}

export function mapEventsFromServer(events: ServerEventRow[] | undefined): MatchEvent[] {
  if (!events) return []
  return events.map((e) => ({
    id: String(e.id),
    minute: e.minute ?? "0'",
    kind: mapEventKind(e.kind),
    text: e.text ?? '',
  }))
}

export function mapHistoryRows(rows: ServerHistoryRow[] | undefined): ScoreHistoryRow[] {
  if (!rows) return []
  return rows.map((h) => ({
    id: h.id,
    team1_score: h.team1_score,
    team2_score: h.team2_score,
    action: h.action,
    reason: h.reason ?? null,
    changed_by_name: h.changed_by_name,
    created_at: h.created_at,
  }))
}

export function mapMatchGetAckToDetail(ack: MatchGetAck): MatchDetailModel | null {
  const m = ack.match
  if (!m) return null
  const homeScore = Number(m.team1_score) || 0
  const awayScore = Number(m.team2_score) || 0
  const acc = Number(m.clock_accumulated_ms) || 0
  const players = ack.players || []
  const status = m.status || 'draft'
  const half = m.current_half || '1st'

  return {
    id: m.id,
    team1Id: m.team1_id,
    team2Id: m.team2_id,
    dbStatus: (m.status === 'draft' || m.status === 'finished' || m.status === 'cancelled'
      ? m.status
      : 'draft') as MatchDbStatus,
    matchName: m.match_name || '',
    venue: m.venue || '',
    matchDate: m.match_date || '',
    kickoffTime: kickoffUi(m.kickoff_time),
    uiStatus: mapUiStatus(status, half),
    home: { name: m.team1_name || 'Team 1', short: (m.team1_name || 'T1').slice(0, 2).toUpperCase(), isHome: true },
    away: { name: m.team2_name || 'Team 2', short: (m.team2_name || 'T2').slice(0, 2).toUpperCase(), isHome: false },
    score: { home: homeScore, away: awayScore },
    clockLabel: status === 'finished' ? '試合終了' : status === 'cancelled' ? 'キャンセル' : '進行中',
    clockMmSs: clockMmSs(acc),
    breakdown: defaultBreakdown(homeScore, awayScore),
    homePlayers: mapPlayersForTeam(players, m.team1_id),
    awayPlayers: mapPlayersForTeam(players, m.team2_id),
    events: mapEventsFromServer(ack.events),
  }
}
