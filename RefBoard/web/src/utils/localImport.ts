import {
  LOCAL_PERSIST_KEY_PREFIX,
  LOCAL_PERSIST_SCHEMA_VERSION,
  clearAllLocal,
  loadLocal,
  saveLocal,
} from './localPersist'
import { hydrateCountersFromDisk, nextId } from './localId'
import type { BackupFile } from './exporters'
import type { Match, MatchEvent, MatchPlayer, RosterMember, ScoreHistoryEntry, Team } from '../types/local'

export type ImportMode = 'replace' | 'merge'

const IMPORT_HISTORY_KEY = 'import_history'
const HISTORY_FULL_KEY = LOCAL_PERSIST_KEY_PREFIX + IMPORT_HISTORY_KEY

export interface ImportRecord {
  at: string
  by: string
  mode: ImportMode
  sourceAppVersion: string
  counts: { teams: number; rosterMembers: number; matches: number }
}

export interface ImportResult {
  mode: ImportMode
  counts: { teams: number; rosterMembers: number; matches: number }
  at: string
}

function unwrapPersistedArray<T>(data: Record<string, unknown>, shortKey: string): T[] {
  const fullKey = LOCAL_PERSIST_KEY_PREFIX + shortKey
  const raw = data[fullKey]
  if (!raw || typeof raw !== 'object') return []
  const w = raw as { version?: number; data?: unknown }
  if (w.version !== LOCAL_PERSIST_SCHEMA_VERSION || !Array.isArray(w.data)) return []
  return JSON.parse(JSON.stringify(w.data)) as T[]
}

function countInFile(file: BackupFile, shortKey: string): number {
  const fullKey = LOCAL_PERSIST_KEY_PREFIX + shortKey
  const raw = file.data[fullKey]
  if (!raw || typeof raw !== 'object') return 0
  const w = raw as { version?: number; data?: unknown }
  if (w.version !== LOCAL_PERSIST_SCHEMA_VERSION || !Array.isArray(w.data)) return 0
  return w.data.length
}

function appendImportHistory(prev: ImportRecord[], rec: ImportRecord): void {
  const next = [rec, ...prev].slice(0, 20)
  saveLocal(IMPORT_HISTORY_KEY, next)
}

export function loadImportHistory(): ImportRecord[] {
  const rows = loadLocal<Array<ImportRecord & { added?: ImportRecord['counts'] }>>(IMPORT_HISTORY_KEY, [])
  return rows.map((r) => ({
    at: r.at,
    by: r.by,
    mode: r.mode,
    sourceAppVersion: r.sourceAppVersion ?? '',
    counts: r.counts ?? r.added ?? { teams: 0, rosterMembers: 0, matches: 0 },
  }))
}

export function importBackup(file: BackupFile, mode: ImportMode, by: string): ImportResult {
  if (mode === 'replace') return replaceImport(file, by)
  return mergeImport(file, by)
}

function replaceImport(file: BackupFile, by: string): ImportResult {
  const prevHistory = loadLocal<ImportRecord[]>(IMPORT_HISTORY_KEY, [])
  clearAllLocal()
  for (const [fullKey, val] of Object.entries(file.data)) {
    if (typeof fullKey !== 'string' || !fullKey.startsWith(LOCAL_PERSIST_KEY_PREFIX)) continue
    if (fullKey === HISTORY_FULL_KEY) continue
    try {
      localStorage.setItem(fullKey, JSON.stringify(val))
    } catch {
      /* quota */
    }
  }
  const counts = {
    teams: countInFile(file, 'teams'),
    rosterMembers: countInFile(file, 'roster_members'),
    matches: countInFile(file, 'matches'),
  }
  const rec: ImportRecord = {
    at: new Date().toISOString(),
    by,
    mode: 'replace',
    sourceAppVersion: file.appVersion || '',
    counts,
  }
  appendImportHistory(prevHistory, rec)
  return { mode: 'replace', counts, at: rec.at }
}

function mergeImport(file: BackupFile, by: string): ImportResult {
  hydrateCountersFromDisk()

  const teamsIn = unwrapPersistedArray<Team>(file.data, 'teams')
  const rosterIn = unwrapPersistedArray<RosterMember>(file.data, 'roster_members')
  const matchesIn = unwrapPersistedArray<Match>(file.data, 'matches')

  const teamIdMap = new Map<number, number>()
  const rosterIdMap = new Map<number, number>()

  const curTeams = [...loadLocal<Team[]>('teams', [])]
  for (const t of teamsIn) {
    const newId = nextId('team')
    teamIdMap.set(t.id, newId)
    curTeams.push({ ...t, id: newId })
  }
  saveLocal('teams', curTeams)

  const curRoster = [...loadLocal<RosterMember[]>('roster_members', [])]
  for (const r of rosterIn) {
    const newId = nextId('rosterMember')
    rosterIdMap.set(r.id, newId)
    const mappedTeam = teamIdMap.get(r.teamId)
    curRoster.push({
      ...r,
      id: newId,
      teamId: mappedTeam ?? r.teamId,
    })
  }
  saveLocal('roster_members', curRoster)

  const curMatches = [...loadLocal<Match[]>('matches', [])]
  for (const m of matchesIn) {
    const newMatchId = nextId('match')
    const playerIdMap = new Map<number, number>()

    const players = m.players.map<MatchPlayer>((p) => {
      const newPlayerId = nextId('player')
      playerIdMap.set(p.id, newPlayerId)
      const tid = teamIdMap.get(p.teamId) ?? p.teamId
      const rid =
        p.rosterMemberId != null && p.rosterMemberId !== undefined
          ? rosterIdMap.get(p.rosterMemberId) ?? null
          : null
      return {
        ...p,
        id: newPlayerId,
        matchId: newMatchId,
        teamId: tid,
        rosterMemberId: rid,
      }
    })

    const events = m.events.map<MatchEvent>((e) => ({
      ...e,
      id: nextId('event'),
      matchId: newMatchId,
      teamId: e.teamId != null && e.teamId !== undefined ? (teamIdMap.get(e.teamId) ?? e.teamId) : null,
      playerId:
        e.playerId != null && e.playerId !== undefined ? (playerIdMap.get(e.playerId) ?? e.playerId) : null,
      assistPlayerId:
        e.assistPlayerId != null && e.assistPlayerId !== undefined
          ? (playerIdMap.get(e.assistPlayerId) ?? e.assistPlayerId)
          : null,
      subInPlayerId:
        e.subInPlayerId != null && e.subInPlayerId !== undefined
          ? (playerIdMap.get(e.subInPlayerId) ?? e.subInPlayerId)
          : null,
      subOutPlayerId:
        e.subOutPlayerId != null && e.subOutPlayerId !== undefined
          ? (playerIdMap.get(e.subOutPlayerId) ?? e.subOutPlayerId)
          : null,
    }))

    const scoreHistory = m.scoreHistory.map<ScoreHistoryEntry>((s) => ({
      ...s,
      id: nextId('scoreHistory'),
      matchId: newMatchId,
    }))

    curMatches.push({
      ...m,
      id: newMatchId,
      homeTeamId: teamIdMap.get(m.homeTeamId) ?? m.homeTeamId,
      awayTeamId: teamIdMap.get(m.awayTeamId) ?? m.awayTeamId,
      players,
      events,
      scoreHistory,
    })
  }
  saveLocal('matches', curMatches)

  const counts = {
    teams: teamsIn.length,
    rosterMembers: rosterIn.length,
    matches: matchesIn.length,
  }
  const rec: ImportRecord = {
    at: new Date().toISOString(),
    by,
    mode: 'merge',
    sourceAppVersion: file.appVersion || '',
    counts,
  }
  appendImportHistory(loadLocal<ImportRecord[]>(IMPORT_HISTORY_KEY, []), rec)
  return { mode: 'merge', counts, at: rec.at }
}
