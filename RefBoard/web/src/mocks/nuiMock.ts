/**
 * Vite 開発時（FiveM 外）の NUI 応答モック。console に [NUI MOCK] を出す。
 */
import { mockMatchDetail } from './matchDetail'
import type { MatchDetailModel, MatchPlayer } from '../types/match'

function clone<T>(x: T): T {
  return JSON.parse(JSON.stringify(x)) as T
}

let mockMatchSeq = 100

/** モック内の試合一覧（match_list 用） */
const mockListRows = [
  {
    id: 1,
    team1_id: 1,
    team2_id: 2,
    team1_name: 'Los Santos FC',
    team2_name: 'Vinewood United',
    team1_score: 2,
    team2_score: 1,
    status: 'draft' as 'draft' | 'finished',
    current_half: '2nd',
    match_date: '2026-05-05',
    match_name: 'リーグ戦 第7節',
    venue: 'Maze Bank Arena',
    kickoff_time: '20:00:00',
  },
]

const mockTeams = [
  { id: 1, name: 'Los Santos FC', short_name: 'LS', color: '#3b82f6' },
  { id: 2, name: 'Vinewood United', short_name: 'VW', color: '#64748b' },
]

let liveDetail: MatchDetailModel = clone(mockMatchDetail)

/** 試合一覧 `mockListRows` の score を `liveDetail` に合わせる（ゴール後に一覧へ戻ったときのズレ防止） */
function syncMockListRowScoresFromLive() {
  const row = mockListRows.find((r) => r.id === liveDetail.id)
  if (!row) return
  row.team1_score = liveDetail.score.home
  row.team2_score = liveDetail.score.away
}

function postNui(type: string, payload: unknown) {
  window.postMessage({ type, payload }, '*')
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

const mockRosterByTeam: Record<
  number,
  Array<{
    id: number
    player_name: string
    jersey_number: number | null
    position: string | null
    license: string | null
    matches_played?: number
    goals?: number
    yellows?: number
    reds?: number
  }>
> = {
  1: [
    {
      id: 9001,
      player_name: 'LS Keeper',
      jersey_number: 1,
      position: 'GK',
      license: 'mock:ls:1',
      matches_played: 2,
      goals: 0,
      yellows: 0,
      reds: 0,
    },
    {
      id: 9002,
      player_name: 'LS Striker',
      jersey_number: 9,
      position: 'FW',
      license: 'mock:ls:9',
      matches_played: 2,
      goals: 5,
      yellows: 1,
      reds: 0,
    },
  ],
  2: [
    {
      id: 9101,
      player_name: 'VW Mid',
      jersey_number: 10,
      position: 'MF',
      license: null,
      matches_played: 1,
      goals: 1,
      yellows: 0,
      reds: 0,
    },
  ],
}

function mockManageTeamsPayload() {
  return mockTeams.map((t) => ({
    ...t,
    emblem_emoji: t.id === 1 ? '🔵' : '⚪',
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
    case 'match_checkResume':
      return { ok: true, forwarded: true }
    case 'match_finish':
      return { ok: true, forwarded: true }
    case 'match_reopen':
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
          { category: 'auth', name: 'license', status: 'warning', detail: 'mock', timestamp: ts },
          { category: 'auth', name: 'referee_permission', status: 'ok', detail: 'mock', timestamp: ts },
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
      postNui('refboard:team:list:ack', { teams: mockTeams })
    }
    if (path === 'team_manage_list') {
      postNui('refboard:team:manage_list:ack', { teams: mockManageTeamsPayload() })
    }
    if (path === 'team_detail') {
      const tid = Number((data as { teamId?: number })?.teamId) || 1
      const tm = mockTeams.find((x) => x.id === tid)
      postNui('refboard:team:detail:ack', {
        team: tm
          ? { id: tm.id, name: tm.name, short_name: tm.short_name, color: tm.color, emblem_emoji: tid === 1 ? '🔵' : '⚪', created_at: '2026-05-01' }
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
      postNui('refboard:team:create:ack', { ok: true, teamId: 99 })
    }
    if (path === 'team_update') {
      postNui('refboard:team:update:ack', { ok: true })
    }
    if (path === 'team_delete') {
      postNui('refboard:team:delete:ack', { ok: true })
    }
    if (path === 'team_roster_list') {
      const tid = Number((data as { teamId?: number })?.teamId) || 1
      postNui('refboard:team:roster:list:ack', { rows: mockRosterByTeam[tid] ?? [] })
    }
    if (path === 'team_roster_add') {
      postNui('refboard:team:roster:add:ack', { ok: true, rosterId: 999 })
    }
    if (path === 'team_roster_update') {
      postNui('refboard:team:roster:update:ack', { ok: true })
    }
    if (path === 'team_roster_remove') {
      postNui('refboard:team:roster:remove:ack', { ok: true })
    }
    if (path === 'data_team_stats') {
      postNui('refboard:data:team_stats:ack', {
        rows: mockTeams.map((t) => ({
          id: t.id,
          name: t.name,
          short_name: t.short_name,
          color: t.color,
          emblem_emoji: t.id === 1 ? '🔵' : '⚪',
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
      postNui('refboard:data:score_edit_log:ack', {
        rows: [
          {
            id: 1,
            match_id: 1,
            team1_score: 1,
            team2_score: 1,
            half: '2nd',
            match_time_ms: 0,
            action: 'manual_edit',
            reason: '訂正',
            changed_by_license: 'lic',
            changed_by_name: '審判A',
            created_at: '2026-05-05T12:00:00',
            match_date: '2026-05-05',
            match_name: 'テスト',
            team1_name: 'Los Santos FC',
            team2_name: 'Vinewood United',
          },
        ],
      })
    }
    if (path === 'data_match_history') {
      postNui('refboard:data:match_history:ack', { rows: mockListRows })
    }
    if (path === 'data_db_meta') {
      postNui('refboard:data:db_meta:ack', { schemaVersion: '0.5.1-mock', resourceVersion: '0.6.0' })
    }
    if (path === 'match_list') {
      const st = (data as { status?: string })?.status
      const rows =
        st && st !== 'all'
          ? mockListRows.filter((r) => r.status === st)
          : mockListRows
      postNui('refboard:match:list:ack', { matches: rows })
    }
    if (path === 'match_create') {
      const id = ++mockMatchSeq
      mockListRows.unshift({
        id,
        team1_id: Number((data as { team1Id?: number })?.team1Id) || 1,
        team2_id: Number((data as { team2Id?: number })?.team2Id) || 2,
        team1_name: 'Los Santos FC',
        team2_name: 'Vinewood United',
        team1_score: 0,
        team2_score: 0,
        status: 'draft',
        current_half: '1st',
        match_date: String((data as { matchDate?: string })?.matchDate || '2026-05-05'),
        match_name: String((data as { matchName?: string | null })?.matchName ?? ''),
        venue: String((data as { venue?: string | null })?.venue ?? ''),
        kickoff_time: String((data as { kickoffTime?: string | null })?.kickoffTime ?? ''),
      })
      liveDetail = clone({
        ...mockMatchDetail,
        id,
        team1Id: Number((data as { team1Id?: number })?.team1Id) || 1,
        team2Id: Number((data as { team2Id?: number })?.team2Id) || 2,
        matchName: String((data as { matchName?: string })?.matchName || ''),
        venue: String((data as { venue?: string })?.venue || ''),
        matchDate: String((data as { matchDate?: string })?.matchDate || '2026-05-05'),
        kickoffTime: String((data as { kickoffTime?: string })?.kickoffTime || '').slice(0, 5),
        score: { home: 0, away: 0 },
        breakdown: {
          firstHalf: { home: 0, away: 0 },
          secondHalf: { home: 0, away: 0 },
          extra: { home: 0, away: 0 },
          pk: { home: 0, away: 0 },
        },
        serverHalf: '1st',
        pkFirstTeamId: Number((data as { team1Id?: number })?.team1Id) || 1,
        uiStatus: 'first_half',
        events: [],
        homePlayers: [],
        awayPlayers: [],
        dbStatus: 'draft',
      })
      postNui('refboard:match:create:ack', { ok: true, matchId: id })
    }
    if (path === 'match_get') {
      const mid = Number((data as { matchId?: number })?.matchId) || liveDetail.id
      if (mid === liveDetail.id) {
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
            clock_running: 0,
            clock_accumulated_ms: 5400000,
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
          history: [],
        })
      } else {
        postNui('refboard:match:get:ack', { match: null, players: [], events: [], history: [] })
      }
    }
    if (path === 'autosave_draft') {
      postNui('refboard:autosave:saved', {
        matchId: (data as { matchId?: number })?.matchId,
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
      const pid = `p${Date.now()}`
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
      postNui('refboard:player:add:ack', { ok: true, playerId: pid })
      postNui('refboard:match:state', {
        matchId: d.matchId,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        events: liveDetail.events,
        players: null,
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
      postNui('refboard:score:goal:ack', { ok: true })
      postNui('refboard:match:state', {
        matchId: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        events: liveDetail.events,
        players: null,
      })
      syncMockListRowScoresFromLive()
      postNui('refboard:autosave:saved', { matchId: liveDetail.id, savedAt: Date.now() })
    }
    if (path === 'score_manual_edit') {
      const d = data as { team1Score?: number; team2Score?: number }
      liveDetail.score.home = Number(d.team1Score) ?? liveDetail.score.home
      liveDetail.score.away = Number(d.team2Score) ?? liveDetail.score.away
      postNui('refboard:score:manual_edit:ack', { ok: true })
      postNui('refboard:match:state', {
        matchId: liveDetail.id,
        team1_score: liveDetail.score.home,
        team2_score: liveDetail.score.away,
        events: liveDetail.events,
        players: null,
      })
      syncMockListRowScoresFromLive()
    }
    if (path === 'match_finish') {
      const row = mockListRows.find((r) => r.id === liveDetail.id)
      if (row) row.status = 'finished'
      liveDetail.dbStatus = 'finished'
      postNui('refboard:match:finish:ack', { ok: true })
      postNui('refboard:match:finished', { matchId: liveDetail.id })
    }
    if (path === 'match_reopen') {
      const mid = (data as { matchId?: number })?.matchId
      const row = mockListRows.find((r) => r.id === mid)
      if (row) row.status = 'draft'
      if (mid === liveDetail.id) liveDetail.dbStatus = 'draft'
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
      const ok = d.success === true
      liveDetail.events = [
        {
          id: `e${Date.now()}`,
          minute: 'PK',
          kind: 'penalty',
          text: ok ? `⚽ PK 成功 ${pl.number} ${pl.name}` : `❌ PK 失敗 ${pl.number} ${pl.name}`,
          penaltySuccess: ok,
        },
        ...liveDetail.events,
      ]
      if (ok) {
        if (d.teamId === liveDetail.team1Id) liveDetail.breakdown.pk.home += 1
        else liveDetail.breakdown.pk.away += 1
      }
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
