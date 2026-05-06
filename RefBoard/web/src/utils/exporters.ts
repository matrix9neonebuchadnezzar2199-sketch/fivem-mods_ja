import type { MatchDetailModel, MatchEvent, ScoreHistoryRow } from '../types/match'

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
    minute: e.minute,
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
