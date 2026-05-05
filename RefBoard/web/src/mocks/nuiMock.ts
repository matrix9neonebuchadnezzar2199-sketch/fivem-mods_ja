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
    status: 'draft' as const,
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

function postNui(type: string, payload: unknown) {
  window.postMessage({ type, payload }, '*')
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
    default:
      // eslint-disable-next-line no-console
      console.warn('[NUI MOCK] Unhandled event:', path)
      return { ok: false, error: 'mock_not_implemented' }
  }
}

/** fetch の戻りのあと、本番と同様に遅延で postMessage するイベント */
export function queueMockSideEffects(path: string, data: unknown): void {
  queueMicrotask(() => {
    if (path === 'lock_acquire') {
      postNui('refboard:lock:acquire:result', { ok: true })
    }
    if (path === 'team_list') {
      postNui('refboard:team:list:ack', { teams: mockTeams })
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
        match_name: (data as { matchName?: string | null })?.matchName ?? null,
        venue: (data as { venue?: string | null })?.venue ?? null,
        kickoff_time: (data as { kickoffTime?: string | null })?.kickoffTime ?? null,
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
            status: 'draft',
            current_half: '2nd',
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
            ...liveDetail.homePlayers.map((p) => ({
              id: Number(p.id) || p.id,
              team_id: liveDetail.team1Id,
              server_id: Number(p.id) || 0,
              license: `mock:home:${p.id}`,
              player_name: p.name,
              jersey_number: p.number,
              position: p.position,
              is_starter: p.status === 'bench' ? 0 : 1,
              is_active: p.status === 'sent_off' ? 0 : 1,
              yellow_cards: p.status === 'warning' ? 1 : 0,
            })),
            ...liveDetail.awayPlayers.map((p) => ({
              id: Number(p.id) || p.id,
              team_id: liveDetail.team2Id,
              server_id: Number(p.id) || 0,
              license: `mock:away:${p.id}`,
              player_name: p.name,
              jersey_number: p.number,
              position: p.position,
              is_starter: p.status === 'bench' ? 0 : 1,
              is_active: p.status === 'sent_off' ? 0 : 1,
              yellow_cards: p.status === 'warning' ? 1 : 0,
            })),
          ],
          events: liveDetail.events.map((e, i) => ({
            id: i + 1,
            match_time_ms: (parseInt(e.minute, 10) || 15) * 60000,
            event_type: e.kind === 'goal' ? 'goal' : 'yellow_card',
            half: '1st',
            player_name: e.text,
            assist_name: null,
            jersey_number: null,
          })),
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
  })
}
