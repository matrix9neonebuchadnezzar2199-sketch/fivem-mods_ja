import {
  LOCAL_PERSIST_KEY_PREFIX,
  LOCAL_PERSIST_SCHEMA_VERSION,
  clearAllLocal,
  loadLocal,
  saveLocal,
} from './localPersist'
import { hydrateCountersFromDisk, nextId } from './localId'
import type { BackupFile } from './exporters'
import type { ImportPreviewDetail } from './exporters'
import { buildPreviewDetail } from './exporters'
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
  /** 部分マージで実際に書き込んだ件数がファイル全件未満のとき true */
  partial?: boolean
}

export interface ImportResult {
  mode: ImportMode
  counts: { teams: number; rosterMembers: number; matches: number }
  at: string
  partial?: boolean
}

export interface ImportSelection {
  /** バックアップ内の旧 ID */
  teamIds: Set<number>
  rosterMemberIds: Set<number>
  matchIds: Set<number>
  /** 試合選択時にホーム/アウェイチームと players の rosterMemberId を同伴 */
  autoIncludeRelated: boolean
}

export function buildAllSelected(detail: ImportPreviewDetail): ImportSelection {
  return {
    teamIds: new Set(detail.teams.map((t) => t.id)),
    rosterMemberIds: new Set(detail.rosterMembers.map((r) => r.id)),
    matchIds: new Set(detail.matches.map((m) => m.id)),
    autoIncludeRelated: true,
  }
}

export function buildEmptySelection(): ImportSelection {
  return { teamIds: new Set(), rosterMemberIds: new Set(), matchIds: new Set(), autoIncludeRelated: true }
}

/** 試合選択に基づきチーム ID を同伴（ロスターは mergeImportPartial 内で補完） */
export function expandSelection(detail: ImportPreviewDetail, base: ImportSelection): ImportSelection {
  const out: ImportSelection = {
    teamIds: new Set(base.teamIds),
    rosterMemberIds: new Set(base.rosterMemberIds),
    matchIds: new Set(base.matchIds),
    autoIncludeRelated: base.autoIncludeRelated,
  }
  if (!base.autoIncludeRelated) return out
  const matchById = new Map(detail.matches.map((m) => [m.id, m]))
  for (const mid of out.matchIds) {
    const m = matchById.get(mid)
    if (!m) continue
    out.teamIds.add(m.homeTeamId)
    out.teamIds.add(m.awayTeamId)
  }
  return out
}

export type SelectionValidationError =
  | { kind: 'match_missing_team'; matchId: number; matchTitle: string; missingTeamId: number }
  | { kind: 'match_missing_roster'; matchId: number; matchTitle: string; missingRosterMemberId: number }

export interface SelectionValidation {
  ok: boolean
  errors: SelectionValidationError[]
}

/** 展開後の teamIds / rosterIds で検証（autoIncludeRelated 時は試合から同伴した ID を含める） */
export function validateSelection(detail: ImportPreviewDetail, sel: ImportSelection): SelectionValidation {
  const errors: SelectionValidationError[] = []
  let teamIds = new Set(sel.teamIds)
  let rosterIds = new Set(sel.rosterMemberIds)

  if (sel.autoIncludeRelated) {
    for (const m of detail.matches) {
      if (!sel.matchIds.has(m.id)) continue
      teamIds.add(m.homeTeamId)
      teamIds.add(m.awayTeamId)
      for (const rid of m.playerRosterIds) rosterIds.add(rid)
    }
  }

  for (const mid of sel.matchIds) {
    const m = detail.matches.find((x) => x.id === mid)
    if (!m) continue
    if (!teamIds.has(m.homeTeamId)) {
      errors.push({ kind: 'match_missing_team', matchId: m.id, matchTitle: m.title, missingTeamId: m.homeTeamId })
    }
    if (!teamIds.has(m.awayTeamId)) {
      errors.push({ kind: 'match_missing_team', matchId: m.id, matchTitle: m.title, missingTeamId: m.awayTeamId })
    }
    if (!sel.autoIncludeRelated) {
      for (const rid of m.playerRosterIds) {
        if (!rosterIds.has(rid)) {
          errors.push({ kind: 'match_missing_roster', matchId: m.id, matchTitle: m.title, missingRosterMemberId: rid })
        }
      }
    }
  }

  return { ok: errors.length === 0, errors }
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
    partial: r.partial === true,
  }))
}

export function importBackup(
  file: BackupFile,
  mode: ImportMode,
  by: string,
  /** `merge` のときのみ。未指定ならファイル全件を追記相当 */
  mergeSelection?: ImportSelection,
): ImportResult {
  if (mode === 'replace') return replaceImport(file, by)
  if (mergeSelection) return mergeImportPartial(file, mergeSelection, by)
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
    partial: false,
  }
  appendImportHistory(prevHistory, rec)
  return { mode: 'replace', counts, at: rec.at, partial: false }
}

function mergeImport(file: BackupFile, by: string): ImportResult {
  const detail = buildPreviewDetail(file)
  return mergeImportPartial(file, buildAllSelected(detail), by)
}

/**
 * 選択されたチーム／ロスター／試合だけを新 ID で追記。`autoIncludeRelated` が true のとき、
 * 選択試合のホーム・アウェイ・players の rosterMemberId を同伴して取り込む。
 */
export function mergeImportPartial(file: BackupFile, sel: ImportSelection, by: string): ImportResult {
  hydrateCountersFromDisk()

  const teamsAll = unwrapPersistedArray<Team>(file.data, 'teams')
  const rosterAll = unwrapPersistedArray<RosterMember>(file.data, 'roster_members')
  const matchesAll = unwrapPersistedArray<Match>(file.data, 'matches')

  let teamIds = new Set(sel.teamIds)
  let rosterIds = new Set(sel.rosterMemberIds)
  const matchIds = new Set(sel.matchIds)

  if (sel.autoIncludeRelated) {
    for (const m of matchesAll) {
      if (!matchIds.has(m.id)) continue
      teamIds.add(m.homeTeamId)
      teamIds.add(m.awayTeamId)
      for (const p of m.players ?? []) {
        if (p.rosterMemberId != null && p.rosterMemberId !== undefined) rosterIds.add(p.rosterMemberId)
      }
    }
  }

  const teamsSel = teamsAll.filter((t) => teamIds.has(t.id))
  const rosterSel = rosterAll.filter((r) => rosterIds.has(r.id) && teamIds.has(r.teamId))
  const matchesSel = matchesAll.filter(
    (m) => matchIds.has(m.id) && teamIds.has(m.homeTeamId) && teamIds.has(m.awayTeamId),
  )

  const teamIdMap = new Map<number, number>()
  const rosterIdMap = new Map<number, number>()

  const curTeams = [...loadLocal<Team[]>('teams', [])]
  for (const t of teamsSel) {
    const newId = nextId('team')
    teamIdMap.set(t.id, newId)
    curTeams.push({ ...t, id: newId })
  }
  saveLocal('teams', curTeams)

  const curRoster = [...loadLocal<RosterMember[]>('roster_members', [])]
  for (const r of rosterSel) {
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
  for (const m of matchesSel) {
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

  const partial =
    teamsSel.length !== teamsAll.length ||
    rosterSel.length !== rosterAll.length ||
    matchesSel.length !== matchesAll.length

  const counts = {
    teams: teamsSel.length,
    rosterMembers: rosterSel.length,
    matches: matchesSel.length,
  }
  const rec: ImportRecord = {
    at: new Date().toISOString(),
    by,
    mode: 'merge',
    sourceAppVersion: file.appVersion || '',
    counts,
    partial,
  }
  appendImportHistory(loadLocal<ImportRecord[]>(IMPORT_HISTORY_KEY, []), rec)
  return { mode: 'merge', counts, at: rec.at, partial }
}
