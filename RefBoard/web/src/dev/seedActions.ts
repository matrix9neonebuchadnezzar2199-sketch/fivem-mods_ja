import { saveLocalBatch, clearAllLocal, loadLocal, removeLocal } from '../utils/localPersist'
import {
  resetIdCounters,
  resetCountersMemoryOnly,
  nextId,
  beginIdCounterBatch,
  endIdCounterBatch,
  hydrateCountersFromDisk,
} from '../utils/localId'
import { useTeamsStore } from '../stores/teams'
import { useMatchesStore } from '../stores/matches'
import { useSettingsStore } from '../stores/settings'
import { SEED_TEAMS, SEED_MATCHES, buildSeedRoster } from './sampleData'
import type { Match, MatchEvent, MatchPlayer, ScoreHistoryEntry, RosterMember, Team, Half } from '../types/local'

const SEED_FLAG_KEY = 'seed_state'

/** Pinia の settings と同じキー（`localPersist` の前缀とは別） */
const SETTINGS_STORAGE_KEY = 'refboard_settings'
const LOCALE_STORAGE_KEY = 'refboard-locale'

interface SeedState {
  installedAt: string
}

export function isSeedInstalled(): boolean {
  const s = loadLocal<SeedState | null>(SEED_FLAG_KEY, null)
  return s != null && typeof (s as SeedState).installedAt === 'string'
}

export function getSeedInstalledAt(): string | null {
  const s = loadLocal<SeedState | null>(SEED_FLAG_KEY, null)
  return s?.installedAt ?? null
}

/** 試合・チーム・ロスターのみ削除（設定・selfName・取り込み履歴は保持） */
export function clearMatchData(): void {
  saveLocalBatch({
    teams: [] as Team[],
    roster_members: [] as RosterMember[],
    matches: [] as Match[],
  })
  removeLocal(SEED_FLAG_KEY)
  resetIdCounters()
}

/** 全データ削除（設定・取り込み履歴含む `refboard_local_*` ＋ settings キー） */
export function clearAllData(): void {
  clearAllLocal()
  resetIdCounters()
  try {
    localStorage.removeItem(SETTINGS_STORAGE_KEY)
    localStorage.removeItem(LOCALE_STORAGE_KEY)
  } catch {
    /* ignore */
  }
}

/** 投入：空にしてからシード（`location.reload` なし・ID 採番はバッチでディスク 1 回） */
export function installSeedData(): void {
  beginIdCounterBatch()
  try {
    saveLocalBatch({
      teams: [] as Team[],
      roster_members: [] as RosterMember[],
      matches: [] as Match[],
    })
    removeLocal(SEED_FLAG_KEY)
    resetCountersMemoryOnly()

    const nowMs = Date.now()
    const nowIso = new Date(nowMs).toISOString()

    const teams: Team[] = SEED_TEAMS.map((s) => ({
      id: nextId('team'),
      name: s.name,
      shortName: s.shortName,
      colorHex: s.colorHex,
      createdAt: nowIso,
      updatedAt: nowIso,
    }))

    const rosters: RosterMember[] = []
    for (let i = 0; i < SEED_TEAMS.length; i++) {
      const team = teams[i]
      const seed = SEED_TEAMS[i]
      for (const row of buildSeedRoster(seed)) {
        rosters.push({
          id: nextId('rosterMember'),
          teamId: team.id,
          name: row.name,
          number: row.number,
          position: row.position,
          note: null,
        })
      }
    }

    const matches: Match[] = SEED_MATCHES.map((s) => buildMatchFromSeed(s, teams, rosters, nowMs))

    saveLocalBatch({
      teams,
      roster_members: rosters,
      matches,
      [SEED_FLAG_KEY]: { installedAt: nowIso } satisfies SeedState,
    })
  } finally {
    endIdCounterBatch()
    hydrateCountersFromDisk()
  }
}

/** 疑似データ操作後に Pinia を `localStorage` から再読込（ページリロード不要） */
export function rehydrateStoresAfterLocalStorageMutation(): void {
  hydrateCountersFromDisk()
  useTeamsStore().reload()
  useMatchesStore().reload()
  useSettingsStore().load()
}

function buildMatchFromSeed(
  s: (typeof SEED_MATCHES)[number],
  teams: Team[],
  rosters: RosterMember[],
  nowMs: number,
): Match {
  const home = teams[s.homeIndex]
  const away = teams[s.awayIndex]
  const matchId = nextId('match')
  const nowIso = new Date(nowMs).toISOString()

  const players: MatchPlayer[] = []
  const homeRoster = rosters.filter((r) => r.teamId === home.id).slice(0, 11)
  const awayRoster = rosters.filter((r) => r.teamId === away.id).slice(0, 11)
  for (const r of homeRoster) {
    players.push({
      id: nextId('player'),
      matchId,
      teamId: home.id,
      rosterMemberId: r.id,
      name: r.name,
      number: r.number ?? null,
      status: 'playing',
    })
  }
  for (const r of awayRoster) {
    players.push({
      id: nextId('player'),
      matchId,
      teamId: away.id,
      rosterMemberId: r.id,
      name: r.name,
      number: r.number ?? null,
      status: 'playing',
    })
  }

  let clockStartedAt: number | null = null
  let clockAccumulatedMs = 0
  let currentHalf: Half = '1H'
  let startedAt: string | null = null
  let finishedAt: string | null = null
  let scheduledAt: string | null = null
  const events: MatchEvent[] = []
  const scoreHistory: ScoreHistoryEntry[] = []

  const homePlayers = players.filter((p) => p.teamId === home.id)
  const awayPlayers = players.filter((p) => p.teamId === away.id)

  if (s.status === 'finished') {
    currentHalf = 'FT'
    startedAt = new Date(nowMs - 2 * 60 * 60 * 1000).toISOString()
    finishedAt = new Date(nowMs - 30 * 60 * 1000).toISOString()
    clockAccumulatedMs = 90 * 60 * 1000
    if (s.finishedGoals && homePlayers.length > 0 && awayPlayers.length > 0) {
      let minute = 5
      for (let g = 0; g < s.finishedGoals.home; g++) {
        events.push(makeGoalEvent(matchId, home.id, homePlayers[g % homePlayers.length].id, '1H', minute))
        minute += 18
      }
      minute = 12
      for (let g = 0; g < s.finishedGoals.away; g++) {
        events.push(makeGoalEvent(matchId, away.id, awayPlayers[g % awayPlayers.length].id, '2H', 50 + minute))
        minute += 15
      }
      if (homePlayers.length > 3) {
        events.push(makeCardEvent(matchId, home.id, homePlayers[3].id, '1H', 38, 'yellow'))
      }
    }
  } else if (s.status === 'live') {
    if (s.pkInProgress) {
      currentHalf = 'PK'
      clockStartedAt = null
      clockAccumulatedMs = 90 * 60 * 1000
      startedAt = new Date(nowMs - 2 * 60 * 60 * 1000).toISOString()
      if (homePlayers.length >= 2 && awayPlayers.length >= 2) {
        events.push(makeGoalEvent(matchId, home.id, homePlayers[0].id, '2H', 28))
        events.push(makeGoalEvent(matchId, away.id, awayPlayers[0].id, '2H', 41))
        events.push(makeGoalEvent(matchId, home.id, homePlayers[1].id, '2H', 62))
        events.push(makeGoalEvent(matchId, away.id, awayPlayers[1].id, '2H', 78))
        events.push(makePkEvent(matchId, 'pk_goal', home.id, homePlayers[0].id))
        events.push(makePkEvent(matchId, 'pk_goal', away.id, awayPlayers[0].id))
        events.push(makePkEvent(matchId, 'pk_miss', home.id, homePlayers[1].id))
        events.push(makePkEvent(matchId, 'pk_miss', away.id, awayPlayers[1].id))
      }
    } else if (s.pkDemo) {
      currentHalf = 'PK'
      clockStartedAt = null
      clockAccumulatedMs = 90 * 60 * 1000
      startedAt = new Date(nowMs - 2 * 60 * 60 * 1000).toISOString()
      if (homePlayers.length >= 3 && awayPlayers.length >= 3) {
        events.push(makeGoalEvent(matchId, home.id, homePlayers[0].id, '2H', 23))
        events.push(makeGoalEvent(matchId, away.id, awayPlayers[0].id, '2H', 67))
        events.push(makePkEvent(matchId, 'pk_goal', home.id, homePlayers[0].id))
        events.push(makePkEvent(matchId, 'pk_goal', away.id, awayPlayers[0].id))
        events.push(makePkEvent(matchId, 'pk_miss', home.id, homePlayers[1].id))
        events.push(makePkEvent(matchId, 'pk_miss', away.id, awayPlayers[1].id))
        events.push(makePkEvent(matchId, 'pk_goal', home.id, homePlayers[2].id))
        events.push(makePkEvent(matchId, 'pk_goal', away.id, awayPlayers[2].id))
      }
    } else {
      const elapsedMin = s.liveElapsedMinutes ?? 0
      currentHalf = elapsedMin <= 45 ? '1H' : '2H'
      const elapsed = elapsedMin * 60 * 1000
      clockStartedAt = nowMs - elapsed
      clockAccumulatedMs = 0
      startedAt = new Date(clockStartedAt).toISOString()

      if (homePlayers.length > 0 && awayPlayers.length > 0) {
        const half1: Half = '1H'
        const half2: Half = '2H'
        let m = 8
        for (let g = 0; g < s.homeScore; g++) {
          const half: Half = m <= 40 ? half1 : half2
          const minute = half === half1 ? Math.min(44, m) : Math.min(89, 48 + m)
          events.push(makeGoalEvent(matchId, home.id, homePlayers[g % homePlayers.length].id, half, minute))
          m += 12
        }
        m = 10
        for (let g = 0; g < s.awayScore; g++) {
          const half: Half = m <= 38 ? half1 : half2
          const minute = half === half1 ? Math.min(43, m + 5) : Math.min(88, 52 + m)
          events.push(makeGoalEvent(matchId, away.id, awayPlayers[g % awayPlayers.length].id, half, minute))
          m += 11
        }
      }
    }
  } else {
    currentHalf = '1H'
    if (s.scheduledOffsetDays != null) {
      scheduledAt = new Date(nowMs + s.scheduledOffsetDays * 24 * 60 * 60 * 1000).toISOString()
    }
  }

  return {
    id: matchId,
    title: s.title,
    homeTeamId: home.id,
    awayTeamId: away.id,
    homeName: home.name,
    awayName: away.name,
    homeScore: s.homeScore,
    awayScore: s.awayScore,
    homePkScore: s.pkInProgress ? 1 : s.pkDemo ? 2 : null,
    awayPkScore: s.pkInProgress ? 1 : s.pkDemo ? 2 : null,
    status: s.status,
    currentHalf,
    halfMinutes: 45,
    clockStartedAt,
    clockAccumulatedMs,
    scheduledAt,
    startedAt,
    finishedAt,
    reopenedAt: null,
    players,
    events,
    scoreHistory,
    createdAt: nowIso,
    updatedAt: nowIso,
  }
}

function makeGoalEvent(matchId: number, teamId: number, playerId: number, half: Half, minute: number): MatchEvent {
  return {
    id: nextId('event'),
    matchId,
    kind: 'goal',
    half,
    minute,
    stoppage: null,
    teamId,
    playerId,
    assistPlayerId: null,
    subInPlayerId: null,
    subOutPlayerId: null,
    note: null,
    voided: false,
    createdAt: new Date().toISOString(),
  }
}

function makeCardEvent(
  matchId: number,
  teamId: number,
  playerId: number,
  half: Half,
  minute: number,
  color: 'yellow' | 'red',
): MatchEvent {
  return {
    id: nextId('event'),
    matchId,
    kind: color,
    half,
    minute,
    stoppage: null,
    teamId,
    playerId,
    assistPlayerId: null,
    subInPlayerId: null,
    subOutPlayerId: null,
    note: null,
    voided: false,
    createdAt: new Date().toISOString(),
  }
}

function makePkEvent(
  matchId: number,
  kind: 'pk_goal' | 'pk_miss',
  teamId: number,
  playerId: number,
): MatchEvent {
  return {
    id: nextId('event'),
    matchId,
    kind,
    half: 'PK',
    minute: 0,
    stoppage: null,
    teamId,
    playerId,
    assistPlayerId: null,
    subInPlayerId: null,
    subOutPlayerId: null,
    note: null,
    voided: false,
    createdAt: new Date().toISOString(),
  }
}
