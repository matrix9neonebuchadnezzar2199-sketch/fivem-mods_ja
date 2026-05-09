import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import { loadLocal, saveLocal } from '../utils/localPersist'
import { nextId } from '../utils/localId'
import { useTeamsStore } from './teams'
import type { Match, MatchEvent, MatchPlayer, ScoreHistoryEntry, Half, PlayerStatus } from '../types/local'

const KEY = 'matches'

export const useMatchesStore = defineStore('matches', () => {
  const matches = ref<Match[]>(loadLocal<Match[]>(KEY, []))
  watch(matches, (v) => saveLocal(KEY, v), { deep: true })

  const nowIso = () => new Date().toISOString()
  const nowMs = () => Date.now()
  const find = (id: number) => matches.value.find((m) => m.id === id) || null
  const idx = (id: number) => matches.value.findIndex((m) => m.id === id)

  function createMatch(input: {
    title: string
    homeTeamId: number
    awayTeamId: number
    halfMinutes?: number
    scheduledAt?: string
    venue?: string | null
  }): Match {
    const teams = useTeamsStore()
    const home = teams.getTeam(input.homeTeamId)
    const away = teams.getTeam(input.awayTeamId)
    if (!home || !away) throw new Error('team_not_found')
    const m: Match = {
      id: nextId('match'),
      title: input.title.trim(),
      homeTeamId: home.id,
      awayTeamId: away.id,
      homeName: home.name,
      awayName: away.name,
      homeScore: 0,
      awayScore: 0,
      homePkScore: null,
      awayPkScore: null,
      status: 'draft',
      currentHalf: '1H',
      halfMinutes: input.halfMinutes ?? 45,
      clockStartedAt: null,
      clockAccumulatedMs: 0,
      scheduledAt: input.scheduledAt || null,
      startedAt: null,
      finishedAt: null,
      reopenedAt: null,
      venue: input.venue?.trim() || null,
      players: [],
      events: [],
      scoreHistory: [],
      createdAt: nowIso(),
      updatedAt: nowIso(),
    }
    matches.value.push(m)
    return m
  }

  function deleteMatch(id: number) {
    matches.value = matches.value.filter((m) => m.id !== id)
  }

  function patch(id: number, p: Partial<Match>) {
    const i = idx(id)
    if (i < 0) return
    matches.value[i] = { ...matches.value[i], ...p, updatedAt: nowIso() }
  }

  function clockNowMs(m: Match): number {
    return m.clockAccumulatedMs + (m.clockStartedAt ? nowMs() - m.clockStartedAt : 0)
  }

  function clockStart(id: number) {
    const m = find(id)
    if (!m || m.clockStartedAt) return
    patch(id, {
      clockStartedAt: nowMs(),
      status: m.status === 'draft' ? 'live' : m.status,
      startedAt: m.startedAt || nowIso(),
    })
  }

  function clockPause(id: number) {
    const m = find(id)
    if (!m || !m.clockStartedAt) return
    patch(id, { clockAccumulatedMs: clockNowMs(m), clockStartedAt: null })
  }

  function clockReset(id: number) {
    patch(id, { clockStartedAt: null, clockAccumulatedMs: 0 })
  }

  function clockAdjust(id: number, deltaMs: number) {
    const m = find(id)
    if (!m) return
    const full = Math.max(60_000, m.halfMinutes * 2 * 60 * 1000)
    let acc = m.clockAccumulatedMs
    if (m.clockStartedAt) acc += nowMs() - m.clockStartedAt
    acc = Math.max(0, Math.min(full, acc + deltaMs))
    const keepRunning = Boolean(m.clockStartedAt)
    patch(id, {
      clockAccumulatedMs: acc,
      clockStartedAt: keepRunning ? nowMs() : null,
    })
  }

  function setHalf(id: number, half: Half) {
    patch(id, { currentHalf: half })
  }

  function currentMinuteFromClock(id: number): number {
    const m = find(id)
    if (!m) return 0
    const sec = Math.floor(clockNowMs(m) / 1000)
    return Math.max(0, Math.floor(sec / 60))
  }

  function addPlayer(
    matchId: number,
    input: { teamId: number; name: string; number?: number; rosterMemberId?: number },
  ): MatchPlayer | null {
    const m = find(matchId)
    if (!m) return null
    const p: MatchPlayer = {
      id: nextId('player'),
      matchId,
      teamId: input.teamId,
      rosterMemberId: input.rosterMemberId ?? null,
      name: input.name.trim(),
      number: input.number ?? null,
      status: 'playing',
    }
    m.players.push(p)
    patch(matchId, {})
    return p
  }

  function removePlayer(matchId: number, playerId: number): { ok: true } | { ok: false; error: 'player_has_events' | 'no_match' } {
    const m = find(matchId)
    if (!m) return { ok: false, error: 'no_match' }
    const used = m.events.some(
      (e) =>
        !e.voided &&
        (e.playerId === playerId ||
          e.assistPlayerId === playerId ||
          e.subInPlayerId === playerId ||
          e.subOutPlayerId === playerId),
    )
    if (used) return { ok: false, error: 'player_has_events' }
    m.players = m.players.filter((x) => x.id !== playerId)
    patch(matchId, {})
    return { ok: true }
  }

  function addEvent(matchId: number, e: Omit<MatchEvent, 'id' | 'matchId' | 'createdAt'>): MatchEvent | null {
    const m = find(matchId)
    if (!m) return null
    const ev: MatchEvent = { ...e, id: nextId('event'), matchId, createdAt: nowIso() }
    m.events.push(ev)
    if (ev.kind === 'goal' && !ev.voided) {
      if (ev.teamId === m.homeTeamId) m.homeScore += 1
      else if (ev.teamId === m.awayTeamId) m.awayScore += 1
    } else if (ev.kind === 'pk_goal' && !ev.voided) {
      if (ev.teamId === m.homeTeamId) m.homePkScore = (m.homePkScore || 0) + 1
      else if (ev.teamId === m.awayTeamId) m.awayPkScore = (m.awayPkScore || 0) + 1
    }
    patch(matchId, {})
    return ev
  }

  function voidEvent(matchId: number, eventId: number) {
    const m = find(matchId)
    if (!m) return
    const ev = m.events.find((x) => x.id === eventId)
    if (!ev || ev.voided) return
    ev.voided = true
    if (ev.kind === 'goal') {
      if (ev.teamId === m.homeTeamId) m.homeScore = Math.max(0, m.homeScore - 1)
      else if (ev.teamId === m.awayTeamId) m.awayScore = Math.max(0, m.awayScore - 1)
    } else if (ev.kind === 'pk_goal') {
      if (ev.teamId === m.homeTeamId) m.homePkScore = Math.max(0, (m.homePkScore || 0) - 1)
      else if (ev.teamId === m.awayTeamId) m.awayPkScore = Math.max(0, (m.awayPkScore || 0) - 1)
    }
    patch(matchId, {})
  }

  function manualScoreEdit(matchId: number, p: { homeScore: number; awayScore: number; reason: string }) {
    const m = find(matchId)
    if (!m) return
    const entry: ScoreHistoryEntry = {
      id: nextId('scoreHistory'),
      matchId,
      homeScore: p.homeScore,
      awayScore: p.awayScore,
      reason: p.reason || null,
      createdAt: nowIso(),
    }
    m.scoreHistory.push(entry)
    patch(matchId, { homeScore: p.homeScore, awayScore: p.awayScore })
  }

  function finishMatch(id: number) {
    const m = find(id)
    if (!m) return
    if (m.clockStartedAt) clockPause(id)
    const cur = find(id)
    if (!cur) return
    patch(id, {
      status: 'finished',
      finishedAt: nowIso(),
      currentHalf: cur.currentHalf === 'PK' ? 'PK' : 'FT',
    })
  }

  function reopenMatch(id: number) {
    patch(id, { status: 'live', finishedAt: null, reopenedAt: nowIso() })
  }

  /** チーム名変更時に試合スナップショットを更新 */
  function refreshTeamNames(teamId: number, name: string) {
    for (const m of matches.value) {
      if (m.homeTeamId === teamId) patch(m.id, { homeName: name })
      if (m.awayTeamId === teamId) patch(m.id, { awayName: name })
    }
  }

  function setPlayerStatus(matchId: number, playerId: number, status: PlayerStatus) {
    const m = find(matchId)
    if (!m) return
    const p = m.players.find((x) => x.id === playerId)
    if (p) p.status = status
    patch(matchId, {})
  }

  function reload() {
    matches.value = loadLocal<Match[]>(KEY, [])
  }

  return {
    matches,
    reload,
    find,
    createMatch,
    deleteMatch,
    patch,
    clockNowMs,
    clockStart,
    clockPause,
    clockReset,
    clockAdjust,
    setHalf,
    currentMinuteFromClock,
    addPlayer,
    removePlayer,
    addEvent,
    voidEvent,
    manualScoreEdit,
    finishMatch,
    reopenMatch,
    refreshTeamNames,
    setPlayerStatus,
  }
})
