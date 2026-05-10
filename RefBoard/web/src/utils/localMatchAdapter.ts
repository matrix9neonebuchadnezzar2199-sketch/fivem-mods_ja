import type { Match, MatchEvent as LocalMatchEvent, MatchPlayer as LocalMatchPlayer, Half } from '../types/local'
import type { MatchDetailModel, MatchDbStatus, MatchEvent, MatchPlayer, MatchUiStatus, ScoreHistoryRow } from '../types/match'
import { formatMinute as formatMinuteDisplay } from './matchTime'

function halfToServerHalf(h: Half): string {
  switch (h) {
    case '1H':
      return '1st'
    case 'HT':
      return 'halftime'
    case '2H':
    case 'FT':
      return '2nd'
    case 'PK':
      return 'pk'
    default:
      return '1st'
  }
}

function halfToUiStatus(m: Match): MatchUiStatus {
  if (m.status === 'finished') return 'full_time'
  switch (m.currentHalf) {
    case 'HT':
      return 'halftime'
    case '2H':
      return 'second_half'
    case 'FT':
      return 'full_time'
    case 'PK':
      return 'penalties'
    case '1H':
    default:
      return 'first_half'
  }
}

function mapPlayerStatus(s: LocalMatchPlayer['status']): MatchPlayer['status'] {
  switch (s) {
    case 'ejected':
      return 'sent_off'
    case 'subbed_in':
    case 'playing':
      return 'playing'
    case 'warning':
      return 'warning'
    case 'subbed_out':
      return 'subbed_out'
    default:
      return 'playing'
  }
}

function localPlayerToRow(p: LocalMatchPlayer): MatchPlayer {
  return {
    id: String(p.id),
    number: p.number ?? 0,
    name: p.name,
    position: '—',
    status: mapPlayerStatus(p.status),
    yellowCards: p.status === 'warning' ? 1 : 0,
  }
}

function localKindToOld(k: LocalMatchEvent['kind']): MatchEvent['kind'] {
  if (k === 'pk_goal' || k === 'pk_miss') return 'penalty'
  if (k === 'sub_in' || k === 'sub_out') return 'sub'
  if (k === 'goal' || k === 'assist') return 'goal'
  if (k === 'yellow') return 'yellow'
  if (k === 'red') return 'red'
  return 'other'
}

export function localEventToRow(e: LocalMatchEvent, players: LocalMatchPlayer[]): MatchEvent {
  const scorer = e.playerId != null ? players.find((p) => p.id === e.playerId) : null
  const assist = e.assistPlayerId != null ? players.find((p) => p.id === e.assistPlayerId) : null
  const internalCardNote = e.note === 'red_card' || e.note === 'second_yellow'
  let text =
    e.kind === 'yellow' || e.kind === 'red' ? (internalCardNote ? '' : (e.note ?? '').trim()) : (e.note || '')
  if (!text && e.kind === 'goal' && scorer) {
    text = `⚽ ${scorer.number ?? ''} ${scorer.name}`.trim()
    if (assist) text += ` (${assist.number ?? ''} ${assist.name})`
  }
  if (!text && (e.kind === 'yellow' || e.kind === 'red') && scorer) {
    text = `${e.kind === 'yellow' ? '🟨' : '🟥'} ${scorer.number ?? ''} ${scorer.name}`.trim()
  }
  if (!text && e.kind === 'sub_out') {
    const out = e.subOutPlayerId != null ? players.find((p) => p.id === e.subOutPlayerId) : null
    const inn = e.subInPlayerId != null ? players.find((p) => p.id === e.subInPlayerId) : null
    if (out && inn) {
      text = `⇄ ${out.number ?? ''} ${out.name} → ${inn.number ?? ''} ${inn.name}`.trim()
    }
  }
  if (!text && e.kind === 'sub_in') {
    const inn = e.subInPlayerId != null ? players.find((p) => p.id === e.subInPlayerId) : null
    if (inn) text = `↑ ${inn.number ?? ''} ${inn.name}`.trim()
  }
  if (!text && (e.kind === 'pk_goal' || e.kind === 'pk_miss')) {
    const shotLabel = e.kind === 'pk_goal' ? '⚽' : '失敗'
    if (scorer) text = `${shotLabel} ${scorer.number ?? ''} ${scorer.name}`.trim()
    else text = shotLabel
  }
  const isPkShot = e.kind === 'pk_goal' || e.kind === 'pk_miss'
  const minuteLabel = isPkShot ? 'PK' : formatMinuteDisplay(e.minute, e.stoppage ?? null)
  return {
    id: String(e.id),
    minute: minuteLabel,
    eventMinute: isPkShot ? undefined : e.minute,
    eventStoppage: isPkShot ? undefined : (e.stoppage ?? null),
    kind: localKindToOld(e.kind),
    text,
    penaltySuccess: e.kind === 'pk_goal' || e.kind === 'pk_miss' ? (e.kind === 'pk_goal' ? true : false) : undefined,
    pkTeamId: isPkShot ? (e.teamId ?? null) : undefined,
    pkPlayerNumber: isPkShot ? (scorer?.number ?? null) : undefined,
    pkPlayerName: isPkShot ? (scorer?.name ?? null) : undefined,
  }
}

/** フィールドゴール（PK 以外）をハーフ別に集計。void 済み・不正 teamId は除外 */
export function computeFieldGoalBreakdown(m: Match): {
  firstHalf: { home: number; away: number }
  secondHalf: { home: number; away: number }
  extra: { home: number; away: number }
} {
  const firstHalf = { home: 0, away: 0 }
  const secondHalf = { home: 0, away: 0 }
  const extra = { home: 0, away: 0 }

  for (const e of m.events) {
    if (e.voided || e.kind !== 'goal') continue
    const tid = e.teamId
    if (tid == null) continue
    const isHome = tid === m.homeTeamId
    const isAway = tid === m.awayTeamId
    if (!isHome && !isAway) continue
    const bucket = e.half === '1H' ? firstHalf : secondHalf
    if (isHome) bucket.home += 1
    else bucket.away += 1
  }

  return { firstHalf, secondHalf, extra }
}

export function serverHalfStringToHalf(s: string): Half {
  switch (s) {
    case 'halftime':
      return 'HT'
    case '2nd':
      return '2H'
    case 'et':
      return '2H'
    case 'pk':
      return 'PK'
    case '1st':
    default:
      return '1H'
  }
}

export function matchToDetailModel(m: Match, elapsedMs: number): MatchDetailModel {
  const sec = Math.floor(Math.max(0, elapsedMs) / 1000)
  const mm = Math.floor(sec / 60)
  const ss = sec % 60
  const clockMmSs = `${mm}:${String(ss).padStart(2, '0')}`

  const dbStatus: MatchDbStatus = m.status === 'finished' ? 'finished' : 'draft'
  const scheduledDate = m.scheduledAt ? m.scheduledAt.slice(0, 10) : m.createdAt.slice(0, 10)
  const kick = m.scheduledAt && m.scheduledAt.length >= 16 ? m.scheduledAt.slice(11, 16) : ''
  const fieldBreakdown = computeFieldGoalBreakdown(m)

  return {
    id: m.id,
    team1Id: m.homeTeamId,
    team2Id: m.awayTeamId,
    matchName: m.title,
    venue: m.venue || '',
    matchDate: scheduledDate,
    kickoffTime: kick,
    uiStatus: halfToUiStatus(m),
    home: { name: m.homeName, short: (m.homeName || 'H').slice(0, 2).toUpperCase(), isHome: true },
    away: { name: m.awayName, short: (m.awayName || 'A').slice(0, 2).toUpperCase(), isHome: false },
    score: { home: m.homeScore, away: m.awayScore },
    clockLabel: m.status === 'finished' ? '試合終了' : m.status === 'live' ? '進行中' : '試合前',
    clockMmSs,
    clockAccumulatedMs: m.clockAccumulatedMs,
    clockRunning: Boolean(m.clockStartedAt),
    clockStartedAtMs: m.clockStartedAt ?? null,
    breakdown: {
      firstHalf: fieldBreakdown.firstHalf,
      secondHalf: fieldBreakdown.secondHalf,
      extra: fieldBreakdown.extra,
      pk: { home: m.homePkScore ?? 0, away: m.awayPkScore ?? 0 },
    },
    serverHalf: halfToServerHalf(m.currentHalf),
    pkFirstTeamId: m.pkFirstTeamId ?? m.homeTeamId,
    homePlayers: m.players.filter((p) => p.teamId === m.homeTeamId).map(localPlayerToRow),
    awayPlayers: m.players.filter((p) => p.teamId === m.awayTeamId).map(localPlayerToRow),
    events: m.events
      .filter((e) => !e.voided)
      .slice()
      .sort((a, b) => a.id - b.id)
      .map((e) => localEventToRow(e, m.players)),
    dbStatus,
  }
}

export function scoreHistoryToRows(m: Match): ScoreHistoryRow[] {
  return m.scoreHistory.map((h) => ({
    id: h.id,
    team1_score: h.homeScore,
    team2_score: h.awayScore,
    action: 'manual_edit',
    reason: h.reason ?? null,
    changed_by_name: 'local',
    created_at: h.createdAt,
  }))
}

/** detail の編集フィールドを Match に反映（タイトル・会場・日付・キックオフ） */
export function applyBasicInfoFromDetail(m: Match, d: MatchDetailModel): Partial<Match> {
  const scheduled =
    d.matchDate && d.kickoffTime
      ? `${d.matchDate}T${d.kickoffTime.length === 5 ? d.kickoffTime : d.kickoffTime.slice(0, 5)}:00`
      : d.matchDate
        ? `${d.matchDate}T12:00:00`
        : null
  return {
    title: d.matchName.trim() || m.title,
    venue: d.venue?.trim() || null,
    scheduledAt: scheduled,
  }
}
