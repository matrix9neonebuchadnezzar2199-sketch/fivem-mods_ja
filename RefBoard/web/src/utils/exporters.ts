import type { MatchDetailModel, MatchEvent, ScoreHistoryRow } from '../types/match'
import { formatMinuteForCsv } from './matchTime'
import { dumpAllLocal, LOCAL_PERSIST_KEY_PREFIX, LOCAL_PERSIST_SCHEMA_VERSION } from './localPersist'

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

export function exportMatchEventsToCSV(events: MatchEvent[]): string {
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
      exporter_version: '0.5.1',
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
    appVersion: '0.1.0',
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
