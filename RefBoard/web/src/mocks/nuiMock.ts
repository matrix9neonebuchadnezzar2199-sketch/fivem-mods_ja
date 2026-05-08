/**
 * Vite 開発時（FiveM 外）の NUI 応答モック。console に [NUI MOCK] を出す。
 *
 * 永続化: `mockPersistence.ts` の localStorage レイヤ（`refboard:mock:state`）。
 * 開発時のみ `window.__refboardMock` を公開（`import.meta.env.DEV`）。
 */
import { mockMatchDetail } from './matchDetail'
import type { MatchDetailModel, MatchPlayer } from '../types/match'
import {
  MOCK_AUDIT,
  clearMockStorage,
  loadMockState,
  type MockPersistenceState,
  type PersistedListRow,
  type PersistedTeam,
  type RosterRow,
  saveMockState,
} from './mockPersistence'

function clone<T>(x: T): T {
  return JSON.parse(JSON.stringify(x)) as T
}

let mockDb: MockPersistenceState = loadMockState()

function activeTeams(): PersistedTeam[] {
  return mockDb.teams.filter((t) => !t.deleted_at)
}

/** match_list 用（メモリ上で編集し flush で mockDb に書き戻す） */
const mockListRows: PersistedListRow[] = []
const mockRosterByTeam: Record<number, RosterRow[]> = {}

function rebuildLocalViews() {
  mockListRows.length = 0
  mockListRows.push(...mockDb.listRows.map((r) => ({ ...r })))
  Object.keys(mockRosterByTeam).forEach((k) => delete mockRosterByTeam[Number(k)])
  for (const [k, rows] of Object.entries(mockDb.rosterByTeam)) {
    mockRosterByTeam[Number(k)] = rows.map((x) => ({ ...x }))
  }
}

let liveDetail: MatchDetailModel = clone(mockMatchDetail)

function hydrateFromDisk() {
  mockDb = loadMockState()
  rebuildLocalViews()
  const fid = mockDb.focusedMatchId
  const snap = mockDb.matchDetails[String(fid)] || mockDb.matchDetails['1'] || clone(mockMatchDetail)
  liveDetail = clone(snap)
  mockDb.focusedMatchId = liveDetail.id
  ensureLiveDetailClockFields()
}

hydrateFromDisk()

function flushPersistence() {
  mockDb.matchDetails[String(liveDetail.id)] = clone(liveDetail)
  mockDb.listRows = mockListRows.map((r) => ({ ...r }))
  mockDb.rosterByTeam = {}
  for (const k of Object.keys(mockRosterByTeam)) {
    mockDb.rosterByTeam[k] = mockRosterByTeam[Number(k)].map((x) => ({ ...x }))
  }
  mockDb.focusedMatchId = liveDetail.id
  saveMockState(mockDb)
  rebuildLocalViews()
}

/** 試合一覧 `mockListRows` の score を `liveDetail` に合わせる（ゴール後に一覧へ戻ったときのズレ防止） */
function syncMockListRowScoresFromLive() {
  const row = mockListRows.find((r) => r.id === liveDetail.id)
  if (!row) return
  row.team1_score = liveDetail.score.home
  row.team2_score = liveDetail.score.away
}

function formatElapsedClock(ms: number): string {
  const s = Math.floor(Math.max(0, ms) / 1000)
  const mm = Math.floor(s / 60)
  const ss = s % 60
  return `${mm}:${String(ss).padStart(2, '0')}`
}

function liveElapsedMs(): number {
  const acc = Number(liveDetail.clockAccumulatedMs) || 0
  if (liveDetail.clockRunning && liveDetail.clockStartedAtMs != null) {
    return acc + (Date.now() - Number(liveDetail.clockStartedAtMs))
  }
  return acc
}

function syncLiveDetailClockMmSs() {
  liveDetail.clockMmSs = formatElapsedClock(liveElapsedMs())
}

function ensureLiveDetailClockFields() {
  if (typeof liveDetail.clockAccumulatedMs !== 'number') {
    liveDetail.clockAccumulatedMs = 0
  }
  if (typeof liveDetail.clockRunning !== 'boolean') {
    liveDetail.clockRunning = false
  }
  if (liveDetail.clockStartedAtMs === undefined) {
    liveDetail.clockStartedAtMs = null
  }
  syncLiveDetailClockMmSs()
}

function postNui(type: string, payload: unknown) {
  window.postMessage({ type, payload }, '*')
}

/** DEV モック: イベント行テキストに「背番号 + 名前」が出ている＝タイムライン参照ありとみなす（本番の match_events 判定に相当） */
function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

function mockTimelineReferencesPlayer(player: MatchPlayer, events: { text?: string }[] | undefined): boolean {
  if (!events?.length) return false
  const n = Number(player.number)
  if (!Number.isFinite(n)) return false
  const re = new RegExp(`\\b${n}\\s+${escapeRegExp(player.name)}\\b`)
  return events.some((e) => Boolean(e.text && re.test(e.text)))
}

function toMockServerPlayer(p: MatchPlayer, teamId: number) {
  const out = p.status === 'subbed_out' || p.status === 'sent_off'
  return {
    id: Number(p.id) || 0,
    team_id: teamId,
    server_id: Number(p.id) || 0,
    license: `mock:${teamId}:${p.id}`,
    player_name: p.name,
    jersey_number: p.number,
    position: p.position,
    is_starter: p.status === 'bench' ? 0 : 1,
    is_active: out ? 0 : 1,
    yellow_cards: p.yellowCards ?? 0,
    ejected_at_ms: p.status === 'sent_off' ? Date.now() : null,
    ui_status: p.status,
  }
}

function applyHalfToLive(half: string, pkFirst?: number) {
  liveDetail.serverHalf = half
  if (half === 'pk' && pkFirst != null) {
    liveDetail.pkFirstTeamId = pkFirst
  }
  const map: Record<string, MatchDetailModel['uiStatus']> = {
    '1st': 'first_half',
    halftime: 'halftime',
    '2nd': 'second_half',
    et: 'extra_time',
    pk: 'penalties',
  }
  const u = map[half]
  if (u) {
    liveDetail.uiStatus = u
  }
}

function findPlayerByNumericId(id: number): { side: 'home' | 'away'; idx: number } | null {
  const sid = String(id)
  const hi = liveDetail.homePlayers.findIndex((x) => String(x.id) === sid || Number(x.id) === id)
  if (hi >= 0) return { side: 'home', idx: hi }
  const ai = liveDetail.awayPlayers.findIndex((x) => String(x.id) === sid || Number(x.id) === id)
  if (ai >= 0) return { side: 'away', idx: ai }
  return null
}

function mockManageTeamsPayload() {
  return activeTeams().map((t) => ({
    id: t.id,
    name: t.name,
    short_name: t.short_name,
    color: t.color,
    emblem_emoji: t.emblem_emoji ?? (t.id === 1 ? '🔵' : '⚪'),
    roster_count: mockRosterByTeam[t.id]?.length ?? 0,
    last_match_date: '2026-05-05',
  }))
}

function maybeEmitPkDecided() {
  if (liveDetail.serverHalf !== 'pk') return
  const ev = [...liveDetail.events].filter((e) => e.kind === 'penalty').reverse()
  const n = ev.length
  if (n === 0) return
  const first = liveDetail.pkFirstTeamId ?? liveDetail.team1Id
  const second = first === liveDetail.team1Id ? liveDetail.team2Id : liveDetail.team1Id
  let tf = 0
  let ts = 0
  for (let i = 0; i < n; i++) {
    if (ev[i].penaltySuccess !== true) continue
    if (i % 2 === 0) tf++
    else ts++
  }
  const shotsFirst = Math.ceil(n / 2)
  const shotsSecond = Math.floor(n / 2)
  let decided = false
  if (n < 10) {
    const remFirst = 5 - shotsFirst
    const remSecond = 5 - shotsSecond
    decided = tf > ts + remSecond || ts > tf + remFirst
  } else {
    decided = n % 2 === 0 && tf !== ts
  }
  if (!decided) return
  const winnerTeamId = tf > ts ? first : second
  postNui('refboard:event:pk_decided', {
    matchId: liveDetail.id,
    winnerTeamId,
    finalPkScore: { team1: liveDetail.breakdown.pk.home, team2: liveDetail.breakdown.pk.away },
  })
}

function teamNameById(id: number): string {
  const t = mockDb.teams.find((x) => x.id === id && !x.deleted_at)
  return t?.name ?? `Team ${id}`
}

function newEmptyMatchDetail(
  id: number,
  team1Id: number,
  team2Id: number,
  matchDate: string,
  matchName: string,
  venue: string,
  kickoffTime: string,
): MatchDetailModel {
  const n1 = teamNameById(team1Id)
  const n2 = teamNameById(team2Id)
  return {
    ...clone(mockMatchDetail),
    id,
    team1Id,
    team2Id,
    matchName,
    venue,
    matchDate,
    kickoffTime: kickoffTime ? kickoffTime.slice(0, 5) : '',
    home: { name: n1, short: mockDb.teams.find((x) => x.id === team1Id)?.short_name ?? 'T1', isHome: true },
    away: { name: n2, short: mockDb.teams.find((x) => x.id === team2Id)?.short_name ?? 'T2', isHome: false },
    score: { home: 0, away: 0 },
    clockLabel: '0:00',
    clockMmSs: '00:00',
    breakdown: {
      firstHalf: { home: 0, away: 0 },
      secondHalf: { home: 0, away: 0 },
      extra: { home: 0, away: 0 },
      pk: { home: 0, away: 0 },
    },
    serverHalf: '1st',
    pkFirstTeamId: team1Id,
    uiStatus: 'first_half',
    homePlayers: [],
    awayPlayers: [],
    events: [],
    dbStatus: 'draft',
    clockAccumulatedMs: 0,
    clockRunning: false,
    clockStartedAtMs: null,
  }
}

export function mockResponse(path: string, data: unknown): unknown {
  // eslint-disable-next-line no-console
  console.log('[NUI MOCK]', path, data)

  switch (path) {
    case 'session_enter':
      return { ok: true, mode: (data as { mode?: string })?.mode ?? 'view' }
    case 'session_leave':
      return { ok: true, forwarded: true }
    case 'lock_acquire':
      return { ok: true, forwarded: true }
    case 'lock_release':
      return { ok: true, forwarded: true }
    case 'lock_heartbeat':
      return { ok: true, forwarded: true }
    case 'team_list':
      return { ok: true, forwarded: true }
    case 'match_list':
      return { ok: true, forwarded: true }
    case 'match_create':
      return { ok: true, forwarded: true }
    case 'match_get':
      return { ok: true, forwarded: true }
    case 'match_clock':
      return { ok: true, forwarded: true }
    case 'match_checkResume':
      return { ok: true, forwarded: true }
    case 'match_finish':
      return { ok: true, forwarded: true }
    case 'match_reopen':
      return { ok: true, forwarded: true }
    case 'match_delete':
      return { ok: true, forwarded: true }
    case 'autosave_draft':
      return { ok: true, forwarded: true }
    case 'presence_list':
      return { ok: true, forwarded: true }
    case 'presence_focus':
      return { ok: true, forwarded: true }
    case 'match_set_half':
      return { ok: true, forwarded: true }
    case 'event_substitute':
      return { ok: true, forwarded: true }
    case 'event_issue_card':
      return { ok: true, forwarded: true }
    case 'event_record_penalty':
      return { ok: true, forwarded: true }
    case 'score_goal':
      return { ok: true, forwarded: true }
    case 'score_manual_edit':
      return { ok: true, forwarded: true }
    case 'player_resolve': {
      const sid = Number((data as { serverId?: number })?.serverId)
      if (!sid || sid === 99999) {
        return { ok: true, forwarded: true }
      }
      return { ok: true, forwarded: true }
    }
    case 'player_add':
    case 'player_remove':
      return { ok: true, forwarded: true }
    case 'player_online_list':
      return { ok: true, forwarded: true }
    case 'team_manage_list':
    case 'team_detail':
    case 'team_create':
    case 'team_update':
    case 'team_delete':
    case 'team_roster_list':
    case 'team_roster_add':
    case 'team_roster_update':
    case 'team_roster_remove':
    case 'data_team_stats':
    case 'data_player_stats':
    case 'data_score_edit_log':
    case 'data_match_history':
    case 'data_db_meta':
    case 'player_add_from_roster':
    case 'health_check':
      return { ok: true, forwarded: true }
    default:
      // eslint-disable-next-line no-console
      console.warn('[NUI MOCK] Unhandled event:', path)
      return { ok: false, error: 'mock_not_implemented' }
  }
}

/** fetch の戻りのあと、本番と同様に遅延で postMessage するイベント */
export function queueMockSideEffects(path: string, data: unknown): void {
  queueMicrotask(() => {
    if (path === 'session_enter') {
      const d = data as { mode?: string; editPassword?: string }
      if (d.mode === 'edit') {
        const ok = (d.editPassword ?? '').trim() === 'ref'
        if (ok) {
          postNui('refboard:session:ack', { ok: true, mode: 'edit' })
        } else {
          postNui('refboard:session:ack', { ok: false, error: 'bad_password' })
        }
      } else {
        postNui('refboard:session:ack', { ok: true, mode: 'view' })
      }
    }
    if (path === 'health_check') {
      const cv = (data as { clientVersion?: string })?.clientVersion ?? ''
      const ts = Date.now()
      postNui('refboard:health:check:ack', {
        results: [
          { category: 'server', name: 'ping', status: 'ok', detail: 'pong', timestamp: ts },
          { category: 'server', name: 'version', status: 'ok', detail: `server=0.6.0 client=${cv || '(n/a)'}`, timestamp: ts },
          { category: 'db', name: 'connection', status: 'ok', detail: 'mock', timestamp: ts },
          { category: 'db', name: 'schema', status: 'warning', detail: 'mock (browser)', timestamp: ts },
          { category: 'db', name: 'migration_roster', status: 'warning', detail: 'mock', timestamp: ts },
          { category: 'auth', name: 'license', status: 'warning', detail: 'mock (browser)', timestamp: ts },
          { category: 'auth', name: 'edit_password', status: 'ok', detail: 'mock (browser)', timestamp: ts },
          { category: 'presence', name: 'self_registration', status: 'warning', detail: 'mock', timestamp: ts },
          { category: 'lock', name: 'current_editor', status: 'ok', detail: 'none', timestamp: ts },
          { category: 'config', name: 'log_level', status: 'ok', detail: 'INFO', timestamp: ts },
          { category: 'config', name: 'test_commands', status: 'ok', detail: 'false', timestamp: ts },
        ],
        serverVersion: '0.6.0',
        clientVersion: cv,
        logLevel: 'INFO',
        enableTestCommands: false,
      })
    }
    if (path === 'lock_acquire') {
      postNui('refboard:lock:acquire:result', { ok: true })
    }
    if (path === 'team_list') {
      postNui(
        'refboard:team:list:ack',
        {
          teams: activeTeams().map((t) => ({
            id: t.id,
            name: t.name,
            short_name: t.short_name,
            color: t.color,
            emblem_emoji: t.emblem_emoji ?? null,
          })),
        },
      )
    }
    if (path === 'team_manage_list') {
      const q = String((data as { q?: string })?.q ?? '')
        .trim()
        .toLowerCase()
      const base = mockManageTeamsPayload().filter((x) => {
        if (!q) return true
        return (x.name ?? '').toLowerCase().includes(q) || (x.short_name ?? '').toLowerCase().includes(q)
      })
      postNui('refboard:team:manage_list:ack', { teams: base })
    }
    if (path === 'team_detail') {
      const tid = Number((data as { teamId?: number })?.teamId) || 1
      const tm = mockDb.teams.find((x) => x.id === tid && !x.deleted_at)
      postNui('refboard:team:detail:ack', {
        team: tm
          ? {
              id: tm.id,
              name: tm.name,
              short_name: tm.short_name,
              color: tm.color,
              emblem_emoji: tm.emblem_emoji ?? (tid === 1 ? '🔵' : '⚪'),
              created_at: '2026-05-01',
            }
          : null,
        stats: {
          matches_played: 10,
          wins: 6,
          draws: 2,
          losses: 2,
          goals_for: 18,
          goals_against: 12,
        },
      })
    }
    if (path === 'team_create') {
      const p = data as {
        name?: string
        shortName?: string | null
        color?: string | null
        emblemEmoji?: string | null
      }
      const name = typeof p.name === 'string' ? p.name.trim() : ''
      if (!name) {
        postNui('refboard:team:create:ack', { ok: false, error: 'bad_name' })
        return
      }
      const dup = activeTeams().some((t) => t.name.trim().toLowerCase() === name.toLowerCase())
      if (dup) {
        postNui('refboard:team:create:ack', { ok: false, error: 'duplicate_name' })
        return
      }
      const id = mockDb.nextIds.team++
      const row: PersistedTeam = {
        id,
        name,
        short_name: typeof p.shortName === 'string' ? p.shortName : '',
        color: typeof p.color === 'string' && p.color ? p.color : '#3b82f6',
        emblem_emoji: typeof p.emblemEmoji === 'string' ? p.emblemEmoji : '⚽',
        deleted_at: null,
      }
      mockDb.teams.push(row)
      mockDb.rosterByTeam[String(id)] = []
      flushPersistence()
      postNui('refboard:team:create:ack', { ok: true, teamId: id })
    }
    if (path === 'team_update') {
      const p = data as {
        teamId?: number
        name?: string
        shortName?: string | null
        color?: string | null
        emblemEmoji?: string | null
      }
      const id = Number(p.teamId)
      const t = id ? mockDb.teams.find((x) => x.id === id) : undefined
      if (!t || t.deleted_at) {
        postNui('refboard:team:update:ack', { ok: false, error: 'not_found' })
      } else {
        if (typeof p.name === 'string' && p.name.trim()) t.name = p.name.trim()
        if (p.shortName !== undefined) t.short_name = typeof p.shortName === 'string' ? p.shortName : ''
        if (p.color !== undefined && typeof p.color === 'string') t.color = p.color
        if (p.emblemEmoji !== undefined) t.emblem_emoji = typeof p.emblemEmoji === 'string' ? p.emblemEmoji : null
        flushPersistence()
        postNui('refboard:team:update:ack', { ok: true })
      }
    }
    if (path === 'team_delete') {
      const id = Number((data as { teamId?: number })?.teamId)
      const t = id ? mockDb.teams.find((x) => x.id === id) : undefined
      if (!t || t.deleted_at) {
        postNui('refboard:team:delete:ack', { ok: false, error: 'not_found' })
      } else {
        t.deleted_at = new Date().toISOString()
        flushPersistence()
        postNui('refboard:team:delete:ack', { ok: true })
      }
    }
    if (path === 'team_roster_list') {
      const tid = Number((data as { teamId?: number })?.teamId) || 1
      postNui('refboard:team:roster:list:ack', { rows: mockRosterByTeam[tid] ?? [] })
    }
    if (path === 'team_roster_add') {
      const p = data as {
        teamId?: number
        playerName?: string
        jerseyNumber?: number | null
        position?: string | null
        license?: string | null
      }
      const teamId = Number(p.teamId)
      const nm = typeof p.playerName === 'string' ? p.playerName.trim() : ''
      if (!teamId || !nm) {
        postNui('refboard:team:roster:add:ack', { ok: false, error: 'bad_args' })
      } else {
        const rid = mockDb.nextIds.roster++
        const row: RosterRow = {
          id: rid,
          player_name: nm,
          jersey_number: p.jerseyNumber ?? null,
          position: typeof p.position === 'string' ? p.position : null,
          license: typeof p.license === 'string' ? p.license : null,
        }
        if (!mockRosterByTeam[teamId]) mockRosterByTeam[teamId] = []
        mockRosterByTeam[teamId].push(row)
        flushPersistence()
        postNui('refboard:team:roster:add:ack', { ok: true, rosterId: rid })
      }
    }
    if (path === 'team_roster_update') {
      const p = data as {
        teamId?: number
        rosterId?: number
        playerName?: string
        jerseyNumber?: number | null
        position?: string | null
        license?: string | null
      }
      const teamId = Number(p.teamId)
      const rid = Number(p.rosterId)
      const list = mockRosterByTeam[teamId]
      const row = list?.find((x) => x.id === rid)
      if (!row) {
        postNui('refboard:team:roster:update:ack', { ok: false, error: 'not_found' })
      } else {
        if (typeof p.playerName === 'string' && p.playerName.trim()) row.player_name = p.playerName.trim()
        if (p.jerseyNumber !== undefined) row.jersey_number = p.jerseyNumber ?? null
        if (p.position !== undefined) row.position = typeof p.position === 'string' ? p.position : null
        if (p.license !== undefined) row.license = typeof p.license === 'string' ? p.license : null
        flushPersistence()
        postNui('refboard:team:roster:update:ack', { ok: true })
      }
    }
    if (path === 'team_roster_remove') {
      const p = data as { teamId?: number; rosterId?: number }
      const teamId = Number(p.teamId)
      const rid = Number(p.rosterId)
      const list = mockRosterByTeam[teamId]
      if (!list) {
        postNui('refboard:team:roster:remove:ack', { ok: false, error: 'not_found' })
      } else {
        const idx = list.findIndex((x) => x.id === rid)
        if (idx < 0) {
          postNui('refboard:team:roster:remove:ack', { ok: false, error: 'not_found' })
        } else {
          list.splice(idx, 1)
          flushPersistence()
          postNui('refboard:team:roster:remove:ack', { ok: true })
        }
      }
    }
    if (path === 'data_team_stats') {
      postNui('refboard:data:team_stats:ack', {
        rows: activeTeams().map((t) => ({
          id: t.id,
          name: t.name,
          short_name: t.short_name,
          color: t.color,
          emblem_emoji: t.emblem_emoji ?? (t.id === 1 ? '🔵' : '⚪'),
          matches_played: 8,
          wins: 5,
          draws: 1,
          losses: 2,
          goals_for: 14,
          goals_against: 9,
        })),
      })
    }
    if (path === 'data_player_stats') {
      postNui('refboard:data:player_stats:ack', {
        rows: [
          {
            grp_key: 'mock:license:1',
            player_name: 'Mock Player',
            has_license: 1,
            matches_played: 3,
            appearances: 3,
            goals: 2,
            assists: 1,
            yellows: 0,
            reds: 0,
          },
          {
            grp_key: '__guest__|Guest|9',
            player_name: 'Guest',
            has_license: 0,
            matches_played: 1,
            appearances: 1,
            goals: 0,
            assists: 0,
            yellows: 1,
            reds: 0,
          },
        ],
      })
    }
    if (path === 'data_score_edit_log') {
      postNui('refboard:data:score_edit_log:ack', { rows: [...mockDb.scoreHistory].reverse().slice(0, 1000) })
    }
    if (path === 'data_match_history') {
      const st = (data as { status?: string })?.status
      const rows =
        st && st !== 'all' ? mockListRows.filter((r) => r.status === st) : mockListRows
      postNui('refboard:data:match_history:ack', { rows })
    }
    if (path === 'data_db_meta') {
      postNui('refboard:data:db_meta:ack', { schemaVersion: '0.5.1-mock', resourceVersion: '0.6.0' })
    }
    if (path === 'match_list') {
      const st = (data as { status?: string })?.status
      const rows =
        st && st !== 'all' ? mockListRows.filter((r) => r.status === st) : mockListRows
      postNui('refboard:match:list:ack', { matches: rows })
    }
    if (path === 'match_checkResume') {
      const draftIds = Object.keys(mockDb.matchDrafts).map(Number).filter(Boolean)
      if (draftIds.length > 0) {
        const mid = draftIds[draftIds.length - 1]
        postNui('refboard:match:checkResume:ack', {
          hasResume: true,
          match: { id: mid, lastEditor: MOCK_AUDIT.refereeName },
        })
      } else {
        postNui('refboard:match:checkResume:ack', { hasResume: false, match: null })
      }
    }
    if (path === 'match_create') {
      const d = data as {
        team1Id?: number
        team2Id?: number
        matchDate?: string
        matchName?: string | null
        venue?: string | null
        kickoffTime?: string | null
      }
      const t1 = Number(d.team1Id) || 1
      const t2 = Number(d.team2Id) || 2
      const okTeams =
        activeTeams().some((x) => x.id === t1) &&
        activeTeams().some((x) => x.id === t2) &&
        t1 !== t2
      if (!okTeams) {
        postNui('refboard:match:create:ack', { ok: false, error: 'bad_teams' })
      } else {
        const id = mockDb.nextIds.match++
        const matchDate = String(d.matchDate || '2026-05-05')
        const matchName = String(d.matchName ?? '')
        const venue = String(d.venue ?? '')
        const kickoffTime = String(d.kickoffTime ?? '')
        mockListRows.unshift({
          id,
          team1_id: t1,
          team2_id: t2,
          team1_name: teamNameById(t1),
          team2_name: teamNameById(t2),
          team1_score: 0,
          team2_score: 0,
          status: 'draft',
          current_half: '1st',
          match_date: matchDate,
          match_name: matchName,
          venue,
          kickoff_time: kickoffTime.length >= 5 ? `${kickoffTime.slice(0, 5)}:00` : '',
        })
        const detail = newEmptyMatchDetail(id, t1, t2, matchDate, matchName, venue, kickoffTime)
        mockDb.matchDetails[String(id)] = detail
        liveDetail = clone(detail)
        ensureLiveDetailClockFields()
        mockDb.focusedMatchId = id
        flushPersistence()
        postNui('refboard:match:create:ack', { ok: true, matchId: id })
      }
    }
    if (path === 'match_delete') {
      const mid = Number((data as { matchId?: number })?.matchId)
      const idx = mockListRows.findIndex((r) => r.id === mid)
      if (!mid || idx < 0) {
        postNui('refboard:match:delete:ack', { ok: false, error: 'not_found' })
      } else {
        mockListRows.splice(idx, 1)
        delete mockDb.matchDetails[String(mid)]
        delete mockDb.matchDrafts[String(mid)]
        mockDb.scoreHistory = mockDb.scoreHistory.filter((h) => h.match_id !== mid)
        if (liveDetail.id === mid) {
          const next = mockListRows[0]
          if (next) {
            const snap = mockDb.matchDetails[String(next.id)]
            liveDetail = snap
              ? clone(snap)
              : newEmptyMatchDetail(
                  next.id,
                  next.team1_id,
                  next.team2_id,
                  next.match_date,
                  next.match_name,
                  next.venue,
                  next.kickoff_time,
                )
            if (!snap) {
              mockDb.matchDetails[String(next.id)] = clone(liveDetail)
            }
            mockDb.focusedMatchId = next.id
          } else {
            liveDetail = clone(mockMatchDetail)
            mockDb.focusedMatchId = liveDetail.id
            if (!mockDb.matchDetails[String(liveDetail.id)]) {
              mockDb.matchDetails[String(liveDetail.id)] = clone(liveDetail)
            }
          }
          ensureLiveDetailClockFields()
        }
        flushPersistence()
        postNui('refboard:match:delete:ack', { ok: true, matchId: mid })
      }
    }
    if (path === 'match_get') {
      const mid = Number((data as { matchId?: number })?.matchId) || mockDb.focusedMatchId
      mockDb.matchDetails[String(liveDetail.id)] = clone(liveDetail)
      const snap = mockDb.matchDetails[String(mid)]
      if (snap) {
        liveDetail = clone(snap)
        ensureLiveDetailClockFields()
        mockDb.focusedMatchId = mid
        flushPersistence()
        postNui('refboard:match:get:ack', {
          match: {
            id: liveDetail.id,
            team1_id: liveDetail.team1Id,
            team2_id: liveDetail.team2Id,
            team1_score: liveDetail.score.home,
            team2_score: liveDetail.score.away,
            status: liveDetail.dbStatus,
            current_half: liveDetail.serverHalf,
            pk_first_team_id: liveDetail.pkFirstTeamId,
            match_date: liveDetail.matchDate,
            match_name: liveDetail.matchName,
            venue: liveDetail.venue,
            kickoff_time: liveDetail.kickoffTime ? `${liveDetail.kickoffTime}:00` : null,
            clock_running: liveDetail.clockRunning ? 1 : 0,
            clock_started_at: liveDetail.clockStartedAtMs,
            clock_accumulated_ms: liveDetail.clockAccumulatedMs,
            team1_name: liveDetail.home.name,
            team2_name: liveDetail.away.name,
          },
          players: [
            ...liveDetail.homePlayers.map((p) => toMockServerPlayer(p, liveDetail.team1Id)),
            ...liveDetail.awayPlayers.map((p) => toMockServerPlayer(p, liveDetail.team2Id)),
          ],
          events: liveDetail.events.map((e, i) => ({
            id: Number(e.id) || i + 1,
            match_time_ms: (parseInt(String(e.minute).replace(/\D/g, ''), 10) || 15) * 60000,
            kind: e.kind,
            minute: e.minute,
            text: e.text,
            penalty_success:
              e.kind === 'penalty'
                ? e.penaltySuccess === true
                  ? 1
                  : e.penaltySuccess === false
                    ? 0
                    : null
                : null,
          })),
          breakdown: liveDetail.breakdown,
          history: mockDb.scoreHistory
            .filter((h) => h.match_id === liveDetail.id)
            .sort((a, b) => b.id - a.id)
            .map((h) => ({
              id: h.id,
              team1_score: h.team1_score,
              team2_score: h.team2_score,
              action: h.action,
              reason: h.reason,
              changed_by_name: h.changed_by_name,
              created_at: h.created_at,
            })),
        })
      } else {
        postNui('refboard:match:get:ack', { match: null, players: [], events: [], history: [] })
      }
    }
    if (path === 'match_clock') {
      const d = data as { matchId?: number; action?: string; deltaRemainingMs?: number }
      const mid = Number(d.matchId) || liveDetail.id
      if (mid === liveDetail.id) {
        const action = d.action
        if (action === 'start') {
          if (!liveDetail.clockRunning) {
            liveDetail.clockRunning = true
            liveDetail.clockStartedAtMs = Date.now()
          }
        } else if (action === 'stop') {
          if (liveDetail.clockRunning) {
            liveDetail.clockAccumulatedMs = liveElapsedMs()
            liveDetail.clockRunning = false
            liveDetail.clockStartedAtMs = null
          }
        } else if (action === 'clear') {
          liveDetail.clockRunning = false
          liveDetail.clockStartedAtMs = null
          liveDetail.clockAccumulatedMs = 0
        } else if (action === 'adjust') {
          const delta = Number(d.deltaRemainingMs) || 0
          const cur = liveElapsedMs()
          const newElapsed = Math.max(0, cur - delta)
          liveDetail.clockAccumulatedMs = newElapsed
          if (liveDetail.clockRunning) {
            liveDetail.clockStartedAtMs = Date.now()
          }
        }
        syncLiveDetailClockMmSs()
        flushPersistence()
        postNui('refboard:match:clock:ack', {
          ok: true,
          matchId: liveDetail.id,
          clock_running: liveDetail.clockRunning ? 1 : 0,
          clock_started_at: liveDetail.clockStartedAtMs,
          clock_accumulated_ms: liveDetail.clockAccumulatedMs,
        })
        postNui('refboard:match:state', {
          matchId: liveDetail.id,
          team1_score: liveDetail.score.home,
          team2_score: liveDetail.score.away,
          status: liveDetail.dbStatus,
          current_half: liveDetail.serverHalf,
          pk_first_team_id: liveDetail.pkFirstTeamId,
          clock_running: liveDetail.clockRunning ? 1 : 0,
          clock_started_at: liveDetail.clockStartedAtMs,
          clock_accumulated_ms: liveDetail.clockAccumulatedMs,
          events: liveDetail.events,
          players: null,
        })
      }
    }
    if (path === 'autosave_draft') {
      const p = data as { matchId?: number; state?: unknown }
      const mid = Number(p.matchId) || liveDetail.id
      if (p.state !== undefined) {
        mockDb.matchDrafts[String(mid)] = p.state
        flushPersistence()
      }
      postNui('refboard:autosave:saved', {
        matchId: mid,
        savedAt: Date.now(),
      })
    }
    if (path === 'player_resolve') {
      const sid = Number((data as { serverId?: number })?.serverId)
      if (!sid || sid === 99999) {
        postNui('refboard:player:resolve:ack', { ok: false, error: 'not_found' })
      } else {
        postNui('refboard:player:resolve:ack', {
          ok: true,
          name: `テストプレイヤー${sid}`,
          license: `mock:license:${sid}`,
        })
      }
    }
    if (path === 'player_online_list') {
      postNui('refboard:player:online_list:ack', {
        players: [
          { serverId: 1, name: '田中審判', license: 'mock:1' },
          { serverId: 5, name: 'John Miller', license: 'mock:5' },
          { serverId: 12, name: 'Robert Taylor', license: 'mock:12' },
        ],
      })
    }
    if (path === 'player_add') {
      const d = data as {
        matchId?: number
        teamId?: number
        playerName?: string
        serverId?: number
        jerseyNumber?: number | null
        position?: string | null
        isStarter?: boolean
      }
      const pid = String(Date.now())
      const row: MatchPlayer = {
        id: pid,
        number: d.jerseyNumber ?? d.serverId ?? 0,
        name: d.playerName || '?',
        position: d.position || 'MF',
        status: d.isStarter === false ? 'bench' : 'playing',
        yellowCards: 0,
      }
      if (d.teamId === liveDetail.team1Id) {
        liveDetail.homePlayers = [...liveDetail.homePlayers, row]
      } else {
        liveDetail.awayPlayers = [...liveDetail.awayPlayers, row]
      }
      flushPersistence()
      postNui('refboard:player:add:ack', { ok: true, playerId: pid })
      postNui('refboard:match:state', {
        matchId: d.matchId,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        events: liveDetail.events,
        players: null,
      })
    }
    if (path === 'player_remove') {
      const d = data as { matchId?: number; teamId?: number; playerId?: number }
      const tid = Number(d.teamId)
      const wantId = Number(d.playerId)
      const allPlayers = [...liveDetail.homePlayers, ...liveDetail.awayPlayers]
      const target = allPlayers.find((x) => Number.isFinite(wantId) && Number(x.id) === wantId)
      if (target && mockTimelineReferencesPlayer(target, liveDetail.events)) {
        postNui('refboard:player:remove:ack', {
          ok: false,
          error: 'player_has_events',
          code: 'E3006',
        })
        return
      }
      const filter = (xs: MatchPlayer[]) =>
        xs.filter((x) => !(Number.isFinite(wantId) && Number(x.id) === wantId))
      if (tid === liveDetail.team1Id) {
        liveDetail.homePlayers = filter(liveDetail.homePlayers)
      } else if (tid === liveDetail.team2Id) {
        liveDetail.awayPlayers = filter(liveDetail.awayPlayers)
      }
      flushPersistence()
      postNui('refboard:player:remove:ack', { ok: true })
      postNui('refboard:match:state', {
        matchId: d.matchId,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        events: liveDetail.events,
        players: [
          ...liveDetail.homePlayers.map((p) => toMockServerPlayer(p, liveDetail.team1Id)),
          ...liveDetail.awayPlayers.map((p) => toMockServerPlayer(p, liveDetail.team2Id)),
        ],
      })
    }
    if (path === 'score_goal') {
      const d = data as { teamId?: number; scorerPlayerId?: string | number }
      const tid = Number(d.teamId)
      if (tid === liveDetail.team1Id) {
        liveDetail.score.home += 1
      } else if (tid === liveDetail.team2Id) {
        liveDetail.score.away += 1
      }
      const scorer = [...liveDetail.homePlayers, ...liveDetail.awayPlayers].find(
        (x) => String(x.id) === String(d.scorerPlayerId),
      )
      const label = scorer ? `${scorer.number} ${scorer.name}` : '得点'
      liveDetail.events = [
        {
          id: `e${Date.now()}`,
          minute: "90'",
          kind: 'goal' as const,
          text: `⚽ ${label}`,
        },
        ...liveDetail.events,
      ]
      const hid = mockDb.nextIds.history++
      mockDb.scoreHistory.push({
        id: hid,
        match_id: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        half: liveDetail.serverHalf,
        match_time_ms: 0,
        action: 'goal',
        reason: null,
        changed_by_license: MOCK_AUDIT.license,
        changed_by_name: MOCK_AUDIT.refereeName,
        created_at: new Date().toISOString(),
        match_date: liveDetail.matchDate,
        match_name: liveDetail.matchName,
        team1_name: liveDetail.home.name,
        team2_name: liveDetail.away.name,
      })
      syncMockListRowScoresFromLive()
      flushPersistence()
      postNui('refboard:score:goal:ack', { ok: true })
      postNui('refboard:match:state', {
        matchId: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        events: liveDetail.events,
        players: null,
      })
      postNui('refboard:autosave:saved', { matchId: liveDetail.id, savedAt: Date.now() })
    }
    if (path === 'score_manual_edit') {
      const d = data as { team1Score?: number; team2Score?: number; reason?: string; matchId?: number }
      liveDetail.score.home = Number(d.team1Score) ?? liveDetail.score.home
      liveDetail.score.away = Number(d.team2Score) ?? liveDetail.score.away
      const reason = typeof d.reason === 'string' && d.reason.length >= 5 ? d.reason : 'manual_edit'
      const hid = mockDb.nextIds.history++
      mockDb.scoreHistory.push({
        id: hid,
        match_id: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        half: liveDetail.serverHalf,
        match_time_ms: 0,
        action: 'manual_edit',
        reason,
        changed_by_license: MOCK_AUDIT.license,
        changed_by_name: MOCK_AUDIT.refereeName,
        created_at: new Date().toISOString(),
        match_date: liveDetail.matchDate,
        match_name: liveDetail.matchName,
        team1_name: liveDetail.home.name,
        team2_name: liveDetail.away.name,
      })
      syncMockListRowScoresFromLive()
      flushPersistence()
      postNui('refboard:score:manual_edit:ack', { ok: true })
      postNui('refboard:match:state', {
        matchId: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        events: liveDetail.events,
        players: null,
      })
    }
    if (path === 'match_finish') {
      const row = mockListRows.find((r) => r.id === liveDetail.id)
      if (row) row.status = 'finished'
      liveDetail.dbStatus = 'finished'
      if (liveDetail.clockRunning) {
        liveDetail.clockAccumulatedMs = liveElapsedMs()
        liveDetail.clockRunning = false
        liveDetail.clockStartedAtMs = null
      }
      syncLiveDetailClockMmSs()
      flushPersistence()
      postNui('refboard:match:finish:ack', { ok: true })
      postNui('refboard:match:finished', { matchId: liveDetail.id })
    }
    if (path === 'match_reopen') {
      const mid = (data as { matchId?: number })?.matchId
      const row = mockListRows.find((r) => r.id === mid)
      if (row) row.status = 'draft'
      if (mid === liveDetail.id) liveDetail.dbStatus = 'draft'
      const snap = mid ? mockDb.matchDetails[String(mid)] : undefined
      if (snap && mid === liveDetail.id) {
        snap.dbStatus = 'draft'
      }
      flushPersistence()
      postNui('refboard:match:reopen:ack', { ok: true })
    }
    if (path === 'match_set_half') {
      const d = data as { matchId?: number; half?: string; pkFirstTeamId?: number }
      if (d.matchId === liveDetail.id && d.half) {
        applyHalfToLive(d.half, d.pkFirstTeamId)
        const row = mockListRows.find((r) => r.id === liveDetail.id)
        if (row) {
          ;(row as { current_half?: string }).current_half = liveDetail.serverHalf
        }
        flushPersistence()
        postNui('refboard:match:set_half:ack', { ok: true })
        postNui('refboard:match:state', {
          matchId: liveDetail.id,
          team1_score: liveDetail.score.home,
          team2_score: liveDetail.score.away,
          status: liveDetail.dbStatus,
          current_half: liveDetail.serverHalf,
          pk_first_team_id: liveDetail.pkFirstTeamId,
          breakdown: liveDetail.breakdown,
          events: liveDetail.events,
          players: null,
        })
      }
    }
    if (path === 'event_substitute') {
      const d = data as { matchId?: number; outPlayerId?: number; inPlayerId?: number }
      if (d.matchId !== liveDetail.id) return
      const outId = d.outPlayerId
      const inId = d.inPlayerId
      if (!outId || !inId) return
      const o = findPlayerByNumericId(outId)
      const inn = findPlayerByNumericId(inId)
      if (!o || !inn) return
      const outP =
        o.side === 'home' ? liveDetail.homePlayers[o.idx] : liveDetail.awayPlayers[o.idx]
      const inP =
        inn.side === 'home' ? liveDetail.homePlayers[inn.idx] : liveDetail.awayPlayers[inn.idx]
      outP.status = 'subbed_out'
      inP.status = 'playing'
      liveDetail.events = [
        {
          id: `e${Date.now()}`,
          minute: `${liveDetail.clockMmSs}'`,
          kind: 'sub',
          text: `🔄 OUT ${outP.number} ${outP.name} → IN ${inP.number} ${inP.name}`,
        },
        ...liveDetail.events,
      ]
      flushPersistence()
      postNui('refboard:event:substitute:ack', { ok: true })
      postNui('refboard:match:state', {
        matchId: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        status: liveDetail.dbStatus,
        current_half: liveDetail.serverHalf,
        pk_first_team_id: liveDetail.pkFirstTeamId,
        breakdown: liveDetail.breakdown,
        events: liveDetail.events,
        players: [
          ...liveDetail.homePlayers.map((p) => toMockServerPlayer(p, liveDetail.team1Id)),
          ...liveDetail.awayPlayers.map((p) => toMockServerPlayer(p, liveDetail.team2Id)),
        ],
      })
    }
    if (path === 'event_issue_card') {
      const d = data as {
        matchId?: number
        teamId?: number
        playerId?: number
        cardType?: string
        ejectionReason?: string
      }
      if (d.matchId !== liveDetail.id || !d.playerId || !d.teamId) return
      const hit = findPlayerByNumericId(d.playerId)
      if (!hit) return
      const pl =
        hit.side === 'home' ? liveDetail.homePlayers[hit.idx] : liveDetail.awayPlayers[hit.idx]
      if (d.cardType === 'yellow_card') {
        pl.yellowCards = (pl.yellowCards ?? 0) + 1
        if (pl.yellowCards >= 2) {
          pl.status = 'sent_off'
        } else {
          pl.status = 'warning'
        }
        liveDetail.events = [
          {
            id: `e${Date.now()}`,
            minute: `${liveDetail.clockMmSs}'`,
            kind: 'yellow',
            text: `🟨 ${pl.number} ${pl.name}`,
          },
          ...liveDetail.events,
        ]
      } else {
        pl.status = 'sent_off'
        pl.yellowCards = Math.max(pl.yellowCards ?? 0, 1)
        liveDetail.events = [
          {
            id: `e${Date.now()}`,
            minute: `${liveDetail.clockMmSs}'`,
            kind: 'red',
            text: `🟥 ${pl.number} ${pl.name}`,
          },
          ...liveDetail.events,
        ]
      }
      flushPersistence()
      postNui('refboard:event:issue_card:ack', { ok: true })
      postNui('refboard:match:state', {
        matchId: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        status: liveDetail.dbStatus,
        current_half: liveDetail.serverHalf,
        pk_first_team_id: liveDetail.pkFirstTeamId,
        breakdown: liveDetail.breakdown,
        events: liveDetail.events,
        players: [
          ...liveDetail.homePlayers.map((p) => toMockServerPlayer(p, liveDetail.team1Id)),
          ...liveDetail.awayPlayers.map((p) => toMockServerPlayer(p, liveDetail.team2Id)),
        ],
      })
    }
    if (path === 'event_record_penalty') {
      const d = data as { matchId?: number; teamId?: number; playerId?: number; success?: boolean }
      if (d.matchId !== liveDetail.id || !d.playerId || !d.teamId) return
      const hit = findPlayerByNumericId(d.playerId)
      if (!hit) return
      const pl =
        hit.side === 'home' ? liveDetail.homePlayers[hit.idx] : liveDetail.awayPlayers[hit.idx]
      const okp = d.success === true
      liveDetail.events = [
        {
          id: `e${Date.now()}`,
          minute: 'PK',
          kind: 'penalty',
          text: okp ? `⚽ PK 成功 ${pl.number} ${pl.name}` : `❌ PK 失敗 ${pl.number} ${pl.name}`,
          penaltySuccess: okp,
        },
        ...liveDetail.events,
      ]
      if (okp) {
        if (d.teamId === liveDetail.team1Id) liveDetail.breakdown.pk.home += 1
        else liveDetail.breakdown.pk.away += 1
      }
      flushPersistence()
      postNui('refboard:event:record_penalty:ack', { ok: true })
      postNui('refboard:match:state', {
        matchId: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        status: liveDetail.dbStatus,
        current_half: liveDetail.serverHalf,
        pk_first_team_id: liveDetail.pkFirstTeamId,
        breakdown: liveDetail.breakdown,
        events: liveDetail.events,
        players: null,
      })
      maybeEmitPkDecided()
    }
    if (path === 'player_add_from_roster') {
      const d = data as { matchId?: number; teamId?: number; rosterId?: number; isStarter?: boolean }
      const row = mockRosterByTeam[d.teamId || 0]?.find((x) => x.id === d.rosterId)
      const pid = `r${Date.now()}`
      const mp: MatchPlayer = {
        id: pid,
        number: row?.jersey_number ?? 0,
        name: row?.player_name ?? '?',
        position: row?.position || 'MF',
        status: d.isStarter === false ? 'bench' : 'playing',
        yellowCards: 0,
      }
      if (d.teamId === liveDetail.team1Id) {
        liveDetail.homePlayers = [...liveDetail.homePlayers, mp]
      } else if (d.teamId === liveDetail.team2Id) {
        liveDetail.awayPlayers = [...liveDetail.awayPlayers, mp]
      }
      flushPersistence()
      postNui('refboard:player:add_from_roster:ack', { ok: true, playerId: pid })
      postNui('refboard:match:state', {
        matchId: d.matchId,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        events: liveDetail.events,
        players: null,
      })
    }
  })
}

if (import.meta.env.DEV && typeof window !== 'undefined') {
  ;(window as unknown as { __refboardMock?: unknown }).__refboardMock = {
    reset: () => {
      clearMockStorage()
      location.reload()
    },
    dump: () => {
      // eslint-disable-next-line no-console
      console.log(loadMockState())
    },
    setState: (partial: Partial<MockPersistenceState>) => {
      const cur = loadMockState()
      saveMockState({ ...cur, ...partial, version: cur.version })
      location.reload()
    },
  }
}
