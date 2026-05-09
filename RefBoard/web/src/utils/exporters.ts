import type { MatchDetailModel, MatchEvent as UiMatchEvent, ScoreHistoryRow } from '../types/match'
import type { Match, MatchEvent, MatchPlayer, RosterMember, Team } from '../types/local'
import { formatMinute, formatMinuteForCsv } from './matchTime'
import { dumpAllLocal, LOCAL_PERSIST_KEY_PREFIX, LOCAL_PERSIST_SCHEMA_VERSION } from './localPersist'
import { localEventToRow } from './localMatchAdapter'

export interface BackupFile {
  schemaVersion: number
  exportedAt: string
  appVersion: string
  data: Record<string, unknown>
}

export type ImportPreviewReason = 'invalid_json' | 'invalid_shape' | 'unsupported_schema'

export interface ImportPreview {
  ok: boolean
  reason?: ImportPreviewReason
  schemaVersion?: number
  appVersion?: string
  exportedAt?: string
  counts: { teams: number; rosterMembers: number; matches: number }
}

/** 部分マージ UI 用。`buildPreview` の集計に加え、バックアップ内の一覧を返す */
export type ImportPreviewMatchRow = {
  id: number
  title: string
  homeTeamId: number
  awayTeamId: number
  homeName: string
  awayName: string
  status: Match['status']
  scheduledAt: string | null
  finishedAt: string | null
  playerCount: number
  eventCount: number
  /** 試合の players から収集（検証・自動同伴用） */
  playerRosterIds: number[]
}

export type ImportPreviewDetail = ImportPreview & {
  teams: Array<Pick<Team, 'id' | 'name' | 'shortName' | 'colorHex'>>
  rosterMembers: Array<Pick<RosterMember, 'id' | 'teamId' | 'name' | 'number' | 'position'>>
  matches: ImportPreviewMatchRow[]
}

export function parseBackupText(
  text: string,
):
  | { ok: true; file: BackupFile }
  | { ok: false; reason: ImportPreviewReason; badSchemaVersion?: number } {
  let json: unknown
  try {
    json = JSON.parse(text) as unknown
  } catch {
    return { ok: false, reason: 'invalid_json' }
  }
  if (!json || typeof json !== 'object') return { ok: false, reason: 'invalid_shape' }
  const f = json as Partial<BackupFile>
  if (typeof f.schemaVersion !== 'number') return { ok: false, reason: 'invalid_shape' }
  if (f.schemaVersion !== LOCAL_PERSIST_SCHEMA_VERSION) {
    return { ok: false, reason: 'unsupported_schema', badSchemaVersion: f.schemaVersion }
  }
  if (!f.data || typeof f.data !== 'object') return { ok: false, reason: 'invalid_shape' }
  return {
    ok: true,
    file: {
      schemaVersion: f.schemaVersion,
      exportedAt: typeof f.exportedAt === 'string' ? f.exportedAt : '',
      appVersion: typeof f.appVersion === 'string' ? f.appVersion : '',
      data: f.data as Record<string, unknown>,
    },
  }
}

function countPersistedEntities(data: Record<string, unknown>, shortKey: string): number {
  const fullKey = LOCAL_PERSIST_KEY_PREFIX + shortKey
  const raw = data[fullKey]
  if (!raw || typeof raw !== 'object') return 0
  const w = raw as { version?: number; data?: unknown }
  if (w.version !== LOCAL_PERSIST_SCHEMA_VERSION || !Array.isArray(w.data)) return 0
  return w.data.length
}

export function buildPreview(file: BackupFile): ImportPreview {
  return {
    ok: true,
    schemaVersion: file.schemaVersion,
    appVersion: file.appVersion,
    exportedAt: file.exportedAt,
    counts: {
      teams: countPersistedEntities(file.data, 'teams'),
      rosterMembers: countPersistedEntities(file.data, 'roster_members'),
      matches: countPersistedEntities(file.data, 'matches'),
    },
  }
}

function unwrapPersistedForPreview<T>(data: Record<string, unknown>, shortKey: string): T[] {
  const fullKey = LOCAL_PERSIST_KEY_PREFIX + shortKey
  const raw = data[fullKey]
  if (!raw || typeof raw !== 'object') return []
  const w = raw as { version?: number; data?: unknown }
  if (w.version !== LOCAL_PERSIST_SCHEMA_VERSION || !Array.isArray(w.data)) return []
  return w.data as T[]
}

export function buildPreviewDetail(file: BackupFile): ImportPreviewDetail {
  const base = buildPreview(file)

  const teams = unwrapPersistedForPreview<Team>(file.data, 'teams')
  const roster = unwrapPersistedForPreview<RosterMember>(file.data, 'roster_members')
  const matches = unwrapPersistedForPreview<Match>(file.data, 'matches')

  return {
    ...base,
    ok: true,
    teams: teams.map((t) => ({
      id: t.id,
      name: t.name,
      shortName: t.shortName ?? null,
      colorHex: t.colorHex ?? null,
    })),
    rosterMembers: roster.map((r) => ({
      id: r.id,
      teamId: r.teamId,
      name: r.name,
      number: r.number ?? null,
      position: r.position ?? null,
    })),
    matches: matches.map((m) => {
      const rosterSet = new Set<number>()
      for (const p of m.players ?? []) {
        if (p.rosterMemberId != null && p.rosterMemberId !== undefined) rosterSet.add(p.rosterMemberId)
      }
      return {
        id: m.id,
        title: m.title,
        homeTeamId: m.homeTeamId,
        awayTeamId: m.awayTeamId,
        homeName: m.homeName,
        awayName: m.awayName,
        status: m.status,
        scheduledAt: m.scheduledAt ?? null,
        finishedAt: m.finishedAt ?? null,
        playerCount: m.players?.length ?? 0,
        eventCount: m.events?.length ?? 0,
        playerRosterIds: [...rosterSet],
      }
    }),
  }
}

export function toCSV(rows: Record<string, unknown>[], columns: string[]): string {
  const escape = (v: unknown) => {
    if (v === null || v === undefined) return ''
    const s = String(v)
    if (s.includes(',') || s.includes('"') || s.includes('\n')) {
      return `"${s.replace(/"/g, '""')}"`
    }
    return s
  }
  const header = columns.join(',')
  const body = rows.map((r) => columns.map((c) => escape(r[c])).join(',')).join('\n')
  return '\uFEFF' + header + '\n' + body
}

export function downloadFile(content: string, filename: string, mime: string) {
  const blob = new Blob([content], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}

/** 試合イベント CSV の列セット（標準 13 / 詳細 26） */
export type CsvColumnSet = 'standard' | 'detailed'

export type CsvExportContext = {
  /** 設定の表示名（未設定は空文字） */
  operator: string
}

const SUMMARY_CSV_COLUMNS = [
  'match_id',
  'match_title',
  'match_date',
  'home_team',
  'away_team',
  'final_score',
  'match_status',
  'operator',
  'exported_at',
] as const

/** 標準モード（13 列・イベント行） */
export const CSV_EVENT_COLUMNS_STANDARD = [
  'match_id',
  'match_title',
  'match_date',
  'home_team',
  'away_team',
  'final_score',
  'event_index',
  'event_kind',
  'event_team',
  'minute_label',
  'event_minute',
  'event_text',
  'recorded_at_iso',
] as const

/** 詳細モード（26 列・イベント行） */
export const CSV_EVENT_COLUMNS_DETAILED = [
  'match_id',
  'match_title',
  'match_date',
  'home_team',
  'away_team',
  'final_score',
  'event_index',
  'event_kind',
  'event_team',
  'minute_label',
  'event_minute',
  'event_stoppage',
  'player_number',
  'player_name',
  'assist_player_number',
  'assist_player_name',
  'card_color',
  'sub_in_player_number',
  'sub_in_player_name',
  'sub_out_player_number',
  'sub_out_player_name',
  'pk_result',
  'pk_shot_index',
  'event_text',
  'recorded_at_iso',
  'operator',
] as const

function matchIdCsv(m: Match): string {
  return `m_${m.id}`
}

function matchDateCsv(m: Match): string {
  if (m.scheduledAt && m.scheduledAt.length >= 10) return m.scheduledAt.slice(0, 10)
  return m.createdAt.slice(0, 10)
}

function finalScoreCsv(m: Match): string {
  const reg = `${m.homeScore}-${m.awayScore}`
  const hasPk =
    (m.homePkScore != null && m.homePkScore > 0) ||
    (m.awayPkScore != null && m.awayPkScore > 0) ||
    (m.events ?? []).some((e) => !e.voided && (e.kind === 'pk_goal' || e.kind === 'pk_miss'))
  if (!hasPk) return reg
  const ph = m.homePkScore ?? 0
  const pa = m.awayPkScore ?? 0
  return `${reg} (PK ${ph}-${pa})`
}

function eventTeamCsv(m: Match, teamId: number | null | undefined): string {
  if (teamId == null) return ''
  if (teamId === m.homeTeamId) return 'home'
  if (teamId === m.awayTeamId) return 'away'
  return ''
}

function findPlayer(players: MatchPlayer[], id: number | null | undefined): MatchPlayer | null {
  if (id == null) return null
  return players.find((p) => p.id === id) ?? null
}

function csvEventKind(e: MatchEvent): string {
  if (e.kind === 'sub_out') return 'substitution'
  return e.kind
}

function shouldIncludeEventForCsv(e: MatchEvent): boolean {
  if (e.voided) return false
  if (e.kind === 'sub_in') return false
  return true
}

function minuteLabelCsv(e: MatchEvent): string {
  if (e.kind === 'pk_goal' || e.kind === 'pk_miss') return 'PK'
  return formatMinute(e.minute, e.stoppage ?? null)
}

function eventMinuteCsv(e: MatchEvent): string {
  if (e.kind === 'pk_goal' || e.kind === 'pk_miss') return ''
  return String(Math.max(0, Math.floor(e.minute)))
}

function eventStoppageCsv(e: MatchEvent): string {
  if (e.kind === 'pk_goal' || e.kind === 'pk_miss') return ''
  if (e.stoppage == null) return ''
  return String(Math.max(0, Math.floor(e.stoppage)))
}

function eventTextForCsv(e: MatchEvent, players: MatchPlayer[]): string {
  const row = localEventToRow(e, players)
  if (row.text) return row.text
  if (e.kind === 'assist') {
    const p = findPlayer(players, e.playerId)
    return p ? `🎯 ${p.number ?? ''} ${p.name}`.trim() : 'assist'
  }
  if (e.note) return e.note
  return csvEventKind(e)
}

function buildEventRow(
  m: Match,
  e: MatchEvent,
  eventIndex: number,
  pkShotByTeam: Map<number, number>,
  ctx: CsvExportContext,
): Record<string, unknown> {
  const players = m.players ?? []
  const pMain = findPlayer(players, e.playerId)
  const pAssist = findPlayer(players, e.assistPlayerId)
  const pSubIn = findPlayer(players, e.subInPlayerId)
  const pSubOut = findPlayer(players, e.subOutPlayerId)

  let pkResult = ''
  let pkShotIndex = ''
  if (e.kind === 'pk_goal' || e.kind === 'pk_miss') {
    pkResult = e.kind === 'pk_goal' ? 'goal' : 'miss'
    const tid = e.teamId ?? 0
    const n = (pkShotByTeam.get(tid) ?? 0) + 1
    pkShotByTeam.set(tid, n)
    pkShotIndex = String(n)
  }

  let cardColor = ''
  if (e.kind === 'yellow') cardColor = 'yellow'
  else if (e.kind === 'red') cardColor = 'red'

  const kind = csvEventKind(e)
  const isGoal = e.kind === 'goal'
  const isCard = e.kind === 'yellow' || e.kind === 'red'
  const isSub = e.kind === 'sub_out'
  const isPk = e.kind === 'pk_goal' || e.kind === 'pk_miss'
  const isAssist = e.kind === 'assist'

  let playerNumber = ''
  let playerName = ''
  if (isGoal || isCard || isPk) {
    playerNumber = pMain?.number != null ? String(pMain.number) : ''
    playerName = pMain?.name ?? ''
  }

  let assistPlayerNumber = ''
  let assistPlayerName = ''
  if (isGoal && pAssist) {
    assistPlayerNumber = pAssist.number != null ? String(pAssist.number) : ''
    assistPlayerName = pAssist.name ?? ''
  } else if (isAssist && pMain) {
    assistPlayerNumber = pMain.number != null ? String(pMain.number) : ''
    assistPlayerName = pMain.name ?? ''
  }

  return {
    match_id: matchIdCsv(m),
    match_title: m.title,
    match_date: matchDateCsv(m),
    home_team: m.homeName,
    away_team: m.awayName,
    final_score: finalScoreCsv(m),
    event_index: String(eventIndex),
    event_kind: kind,
    event_team: eventTeamCsv(m, e.teamId),
    minute_label: minuteLabelCsv(e),
    event_minute: eventMinuteCsv(e),
    event_stoppage: eventStoppageCsv(e),
    player_number: playerNumber,
    player_name: playerName,
    assist_player_number: assistPlayerNumber,
    assist_player_name: assistPlayerName,
    card_color: cardColor,
    sub_in_player_number: isSub && pSubIn?.number != null ? String(pSubIn.number) : '',
    sub_in_player_name: isSub ? (pSubIn?.name ?? '') : '',
    sub_out_player_number: isSub && pSubOut?.number != null ? String(pSubOut.number) : '',
    sub_out_player_name: isSub ? (pSubOut?.name ?? '') : '',
    pk_result: pkResult,
    pk_shot_index: pkShotIndex,
    event_text: eventTextForCsv(e, players),
    recorded_at_iso: e.createdAt,
    operator: ctx.operator,
  }
}

/** 試合サマリ 1 行 CSV（BOM 付き UTF-8） */
export function exportMatchSummaryToCSV(match: Match, ctx: CsvExportContext): string {
  const row: Record<string, unknown> = {
    match_id: matchIdCsv(match),
    match_title: match.title,
    match_date: matchDateCsv(match),
    home_team: match.homeName,
    away_team: match.awayName,
    final_score: finalScoreCsv(match),
    match_status: match.status,
    operator: ctx.operator,
    exported_at: new Date().toISOString(),
  }
  return toCSV([row], [...SUMMARY_CSV_COLUMNS])
}

/**
 * 試合イベント CSV（標準 13 列 or 詳細 26 列）。
 * ローカル `Match.events` を正とする（voided・sub_in は行として出力しない）。
 */
export function exportMatchEventsToCSV(
  match: Match,
  ctx: CsvExportContext,
  columnSet: CsvColumnSet = 'standard',
): string {
  const cols =
    columnSet === 'detailed' ? [...CSV_EVENT_COLUMNS_DETAILED] : [...CSV_EVENT_COLUMNS_STANDARD]
  const list = (match.events ?? [])
    .filter(shouldIncludeEventForCsv)
    .slice()
    .sort((a, b) => a.id - b.id)

  const pkShotByTeam = new Map<number, number>()
  const rows: Record<string, unknown>[] = []
  let idx = 0
  for (const e of list) {
    idx += 1
    rows.push(buildEventRow(match, e, idx, pkShotByTeam, ctx))
  }
  return toCSV(rows, cols)
}

/** サマリ CSV とイベント CSV を短い間隔で連続ダウンロード */
export function downloadMatchCsvPack(match: Match, ctx: CsvExportContext, columnSet: CsvColumnSet = 'standard'): void {
  const d = new Date()
  const y = d.getFullYear()
  const mo = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const base = `refboard_${matchIdCsv(match)}_${y}-${mo}-${day}`

  const summary = exportMatchSummaryToCSV(match, ctx)
  const events = exportMatchEventsToCSV(match, ctx, columnSet)
  const mime = 'text/csv;charset=utf-8'
  downloadFile(summary, `${base}_summary.csv`, mime)
  window.setTimeout(() => {
    downloadFile(events, `${base}_events.csv`, mime)
  }, 200)
}

/** @deprecated 互換用。UI のみのイベント配列から 5 列 CSV（旧形式）。 */
export function exportMatchEventsToCSVLegacy(events: UiMatchEvent[]): string {
  const cols = ['id', 'minute', 'kind', 'text', 'penaltySuccess']
  const rows = events.map((e) => ({
    id: e.id,
    minute:
      e.minute === 'PK'
        ? 'PK'
        : e.eventMinute != null
          ? formatMinuteForCsv(e.eventMinute, e.eventStoppage ?? null)
          : typeof e.minute === 'string'
            ? e.minute.replace(/'$/, '')
            : e.minute,
    kind: e.kind,
    text: e.text,
    penaltySuccess: e.penaltySuccess ?? '',
  }))
  return toCSV(rows, cols)
}

export function exportMatchToJSON(match: MatchDetailModel, history: ScoreHistoryRow[]) {
  return JSON.stringify(
    {
      match_info: {
        id: match.id,
        team1Id: match.team1Id,
        team2Id: match.team2Id,
        matchName: match.matchName,
        venue: match.venue,
        matchDate: match.matchDate,
        kickoffTime: match.kickoffTime,
        dbStatus: match.dbStatus,
        serverHalf: match.serverHalf,
        pkFirstTeamId: match.pkFirstTeamId,
        clockMmSs: match.clockMmSs,
        clockAccumulatedMs: match.clockAccumulatedMs,
        clockRunning: match.clockRunning,
        clockStartedAtMs: match.clockStartedAtMs,
      },
      teams: { home: match.home, away: match.away },
      score: match.score,
      breakdown: match.breakdown,
      players: { home: match.homePlayers, away: match.awayPlayers },
      events: match.events,
      score_history: history,
      exported_at: new Date().toISOString(),
      exporter_version: '0.3.0',
    },
    null,
    2,
  )
}

export function refboardFilename(prefix: string, ext: string) {
  const d = new Date()
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${prefix}_${y}-${m}-${day}.${ext}`
}

export function exportFullBackup(): void {
  const payload = {
    schemaVersion: 1,
    exportedAt: new Date().toISOString(),
    appVersion: '0.3.0',
    data: dumpAllLocal(),
  }
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  const ts = new Date().toISOString().slice(0, 19).replace(/\D/g, '').slice(0, 13)
  a.href = url
  a.download = `refboard_backup_${ts}.json`
  a.click()
  URL.revokeObjectURL(url)
}
