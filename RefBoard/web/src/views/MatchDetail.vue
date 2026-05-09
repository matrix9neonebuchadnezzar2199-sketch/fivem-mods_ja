<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useNui } from '../composables/useNui'
import { mockMatchDetail } from '../data/matchDetailSeed'
import type { MatchDetailModel, MatchPlayer, ScoreHistoryRow } from '../types/match'
import type { Half } from '../types/local'
import { downloadFile, downloadMatchCsvPack, exportMatchToJSON, refboardFilename, type CsvColumnSet } from '../utils/exporters'
import { resolveMatchPlayerRowId } from '../utils/matchPlayerRowId'
import { getElapsedMsFromClockState, parseEpochMsFromServer } from '../utils/matchClock'
import type { ParsedMinute } from '../utils/matchTime'
import { applyBasicInfoFromDetail, matchToDetailModel, scoreHistoryToRows, serverHalfStringToHalf } from '../utils/localMatchAdapter'
import { useMatchesStore } from '../stores/matches'
import { useTeamsStore } from '../stores/teams'
import BasicInfoCard from '../components/match/BasicInfoCard.vue'
import ScoreBoardCard from '../components/match/ScoreBoardCard.vue'
import MatchStatusCard from '../components/match/MatchStatusCard.vue'
import PlayerListCard from '../components/match/PlayerListCard.vue'
import EventTimelineCard from '../components/match/EventTimelineCard.vue'
import PenaltyShootoutPanel from '../components/match/PenaltyShootoutPanel.vue'
import CompactEventList from '../components/match/CompactEventList.vue'
import SubstitutionDialog from '../components/match/SubstitutionDialog.vue'
import CardIssueDialog from '../components/match/CardIssueDialog.vue'
import HelpTriggerButton from '../components/help/HelpTriggerButton.vue'
import GoalRecordWizard from '../components/match/GoalRecordWizard.vue'
import AddPlayerDialog from '../components/match/AddPlayerDialog.vue'
import ScoreEditDialog from '../components/match/ScoreEditDialog.vue'
import ScoreHistoryDialog from '../components/match/ScoreHistoryDialog.vue'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from '../stores/settings'
import { useMatchCompactDockStore } from '../stores/matchCompactDock'
import { useKeyboardShortcuts } from '../composables/useKeyboardShortcuts'
import { useToast } from '../composables/useToast'
import { useDialogOverlay } from '../composables/useDialogOverlay'

const { overlayRootClass } = useDialogOverlay()
const matchDetailRemovePlayerOverlayClass = overlayRootClass('z-[170]', 'bg-black/55')
const matchDetailFinishOverlayClass = overlayRootClass('z-[170]', 'bg-black/55')

defineProps<{
  id?: string
}>()

const route = useRoute()
const router = useRouter()
const { send, on } = useNui()
const matchesStore = useMatchesStore()
const teamsStore = useTeamsStore()
/** ローカル版では常に編集可能（閲覧モードなし） */
const localEditor = true
function setFocus(_section: string | null) {
  void _section
}
const { t, te } = useI18n()
const settings = useSettingsStore()
const matchCompactDock = useMatchCompactDockStore()
const { push: toast } = useToast()

const operatorName = computed(() => String(settings.settings.selfName ?? '').trim())
const operatorIsSet = computed(() => operatorName.value.length > 0)

const matchCsvColumnSet = ref<CsvColumnSet>('standard')

const matchId = computed(() => Number(route.params.id))
const rawMatch = computed(() => (matchId.value ? matchesStore.find(matchId.value) : null))
const displayTick = ref(0)
let displayTickInterval: ReturnType<typeof setInterval> | null = null

function closeAllModals() {
  showGoal.value = false
  showAdd.value = false
  showScoreEdit.value = false
  showHistory.value = false
  showFinish.value = false
  showSub.value = false
  showCard.value = false
  showRemovePlayerModal.value = false
  pendingRemovePlayer.value = null
}

useKeyboardShortcuts({
  enabled: () => localEditor && rawMatch.value != null && rawMatch.value.status !== 'finished',
  onGoal: () => {
    showGoal.value = true
  },
  onSub: () => {
    showSub.value = true
  },
  onSave: () => {
    void onSave()
  },
  onCloseModals: () => closeAllModals(),
})

const readonly = computed(() => false)

/** カード不透明度（設定）。スコアボードは opacity 親を持たない（CEF で blur と合成すると霞み・クリック不能になり得る） */
const cardDimStyle = computed(() => ({ opacity: settings.settings.cardOpacity / 100 }))

const detail = reactive<MatchDetailModel>(JSON.parse(JSON.stringify(mockMatchDetail)) as MatchDetailModel)
const historyRows = ref<ScoreHistoryRow[]>([])

function syncDetail() {
  const id = matchId.value
  if (!id) return
  const m = matchesStore.find(id)
  if (!m) {
    void router.push({ name: 'matches' })
    return
  }
  const elapsed = matchesStore.clockNowMs(m)
  Object.assign(detail, matchToDetailModel(m, elapsed))
  historyRows.value = scoreHistoryToRows(m)
  reconcileRunningClockStarted(detail)
  syncClockFromDetail()
}

let basicInfoDebounce: ReturnType<typeof setTimeout> | null = null
watch(
  () => [detail.matchName, detail.venue, detail.matchDate, detail.kickoffTime] as const,
  () => {
    const id = matchId.value
    const m = matchesStore.find(id)
    if (!m) return
    if (basicInfoDebounce) clearTimeout(basicInfoDebounce)
    basicInfoDebounce = setTimeout(() => {
      basicInfoDebounce = null
      matchesStore.patch(id, applyBasicInfoFromDetail(m, detail))
      syncDetail()
    }, 350)
  },
)

const showGoal = ref(false)
const showAdd = ref(false)
const addTeamId = ref(0)

const addDialogRosterRows = computed(() => {
  if (!addTeamId.value) return []
  return teamsStore.rosterFor(addTeamId.value).map((r) => ({
    id: r.id,
    name: r.name,
    number: r.number ?? null,
    position: r.position ?? null,
  }))
})
const showScoreEdit = ref(false)
const showHistory = ref(false)
const showFinish = ref(false)
const showSub = ref(false)
const showCard = ref(false)
const cardPreset = ref<'yellow' | 'red' | null>(null)
const showRemovePlayerModal = ref(false)
const pendingRemovePlayer = ref<{ teamId: number; player: MatchPlayer } | null>(null)
const removePlayerBusy = ref(false)
/** 小窓モードで Lua が SetNuiFocus(false) にしているとき true（歩行優先） */
const compactGameInputActive = ref(false)

const compactFocusHint = computed(() =>
  compactGameInputActive.value ? t('match_detail.compact_focus_game') : t('match_detail.compact_focus_ui'),
)

watch(showCard, (v) => {
  if (!v) cardPreset.value = null
})

// --- 試合時計: DB の clock_* を正とする残りカウントダウン。ティックでは clockMmSs を書き換えない（自動保存のノイズ防止） ---
function parseClockMmSsToMs(s: string): number {
  const m = /^(\d+):(\d{2})$/.exec(String(s ?? '').trim())
  if (!m) return 0
  const mm = Number(m[1]) || 0
  const sec = Number(m[2]) || 0
  return (mm * 60 + sec) * 1000
}

function formatClockMs(ms: number): string {
  const totalSec = Math.floor(Math.max(0, ms) / 1000)
  const mm = Math.floor(totalSec / 60)
  const ss = totalSec % 60
  return `${mm}:${String(ss).padStart(2, '0')}`
}

/** 試合全体の定尺（前半×2、分→ms）。クリア時の残り 90:00 等はここから */
const fullMatchDurationMs = computed(() => {
  const hm = rawMatch.value?.halfMinutes ?? settings.settings.defaultHalfMinutes
  return Math.max(60_000, hm * 2 * 60 * 1000)
})

const clockUiTick = ref(0)
const clockLiveDisplay = ref('0:00')
let clockTickInterval: ReturnType<typeof setInterval> | null = null

function getElapsedMsFromDetail(): number {
  const acc =
    typeof detail.clockAccumulatedMs === 'number'
      ? detail.clockAccumulatedMs
      : parseClockMmSsToMs(detail.clockMmSs)
  const st = parseEpochMsFromServer(detail.clockStartedAtMs)
  return getElapsedMsFromClockState(acc, detail.clockRunning === true, st, Date.now())
}

/**
 * 走行中なのに clock_started_at が無い／JSON でキー省略された場合の救済。
 * 一時停止で経過が 0 扱いになり残りが定尺いっぱいに戻る不具合の主因を防ぐ。
 */
function reconcileRunningClockStarted(m: MatchDetailModel) {
  if (!m.clockRunning) {
    m.clockStartedAtMs = null
    return
  }
  if (m.clockStartedAtMs == null) {
    m.clockStartedAtMs = Date.now()
    if (import.meta.env.DEV) {
      // eslint-disable-next-line no-console
      console.warn('[RefBoard] clock: running without valid clockStartedAtMs; using client Date.now()')
    }
  }
}

const elapsedMmSsLive = computed(() => {
  void clockUiTick.value
  void displayTick.value
  const m = rawMatch.value
  if (!m) return '0:00'
  return formatClockMs(matchesStore.clockNowMs(m))
})

/** イベント時刻欄の既定（空欄確定時は試合時計からこの分・stoppage を採用） */
const suggestedEventTime = computed((): ParsedMinute => {
  const id = matchId.value
  if (!id) return { minute: 0, stoppage: null }
  return { minute: matchesStore.currentMinuteFromClock(id), stoppage: null }
})

function resolveEventTime(override: ParsedMinute | null | undefined): ParsedMinute {
  if (override) return override
  return { ...suggestedEventTime.value }
}

/** PK 中は分・ロスタイムを保存しない（0 / null 固定） */
function eventTimeForStorage(override: ParsedMinute | null | undefined): ParsedMinute {
  if (currentHalf() === 'PK') return { minute: 0, stoppage: null }
  return resolveEventTime(override)
}

const clockPhaseLabel = computed(() =>
  detail.clockRunning ? t('score_board.clock_state_running') : t('score_board.clock_state_stopped'),
)

function stopClockTickInterval() {
  if (clockTickInterval != null) {
    clearInterval(clockTickInterval)
    clockTickInterval = null
  }
}

function refreshClockLiveDisplay() {
  void displayTick.value
  const full = fullMatchDurationMs.value
  const m = rawMatch.value
  const elapsed = m ? matchesStore.clockNowMs(m) : getElapsedMsFromDetail()
  const rem = Math.max(0, Math.min(full, full - elapsed))
  clockLiveDisplay.value = formatClockMs(rem)
  clockUiTick.value++
}

function syncClockFromDetail() {
  stopClockTickInterval()
  refreshClockLiveDisplay()
  if (detail.clockRunning) {
    clockTickInterval = setInterval(refreshClockLiveDisplay, 250)
  }
}

watch(
  () => [detail.clockRunning, detail.clockStartedAtMs, detail.clockAccumulatedMs] as const,
  () => {
    syncClockFromDetail()
  },
)

/** ローカル版: Pinia matches ストアの clock_* を正とする */
function callMatchClock(action: 'start' | 'stop' | 'clear' | 'adjust', deltaMs?: number): Promise<boolean> {
  const id = matchId.value
  if (!id) return Promise.resolve(false)
  if (action === 'start') matchesStore.clockStart(id)
  else if (action === 'stop') matchesStore.clockPause(id)
  else if (action === 'clear') matchesStore.clockReset(id)
  else if (action === 'adjust' && typeof deltaMs === 'number') matchesStore.clockAdjust(id, deltaMs)
  syncDetail()
  return Promise.resolve(true)
}

function toastIfReadonlyClock(): boolean {
  if (!readonly.value) return false
  toast(t('score_board.clock_readonly_hint'), 'info', { ms: 4000 })
  return true
}

async function onClockStart() {
  if (toastIfReadonlyClock()) return
  if (detail.clockRunning) return
  await callMatchClock('start')
}

async function onClockStop() {
  if (toastIfReadonlyClock()) return
  if (!detail.clockRunning) return
  await callMatchClock('stop')
}

async function onClockClear() {
  if (toastIfReadonlyClock()) return
  await callMatchClock('clear')
}

async function onClockAdjust(deltaMs: number) {
  if (toastIfReadonlyClock()) return
  await callMatchClock('adjust', deltaMs)
}

syncClockFromDetail()

/** 下部固定の小窓（スコア＋試合ステータスのみ）。PK 中は全画面を優先 */
const compactDock = ref(false)
/** 小窓解除後にフォーカスを移す（キーボード／スクリーンリーダー用） */
const fullEditorAnchorRef = ref<HTMLElement | null>(null)

const showFullEditor = computed(() => !compactDock.value || detail.serverHalf === 'pk')

const editorHereBasic = computed(() => false)
const editorHereScore = computed(() => false)
const editorHereStatus = computed(() => false)
const editorHereT1 = computed(() => false)
const editorHereT2 = computed(() => false)
const editorHereEvents = computed(() => false)

let offCompactInputMode: (() => void) | null = null

function openCard(kind: 'yellow' | 'red') {
  cardPreset.value = kind
  showCard.value = true
}

function editableTarget(el: EventTarget | null): boolean {
  const t = el as HTMLElement | null
  if (!t) return false
  if (t.isContentEditable) return true
  const tag = t.tagName
  if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return true
  return !!t.closest?.('[contenteditable="true"]')
}

function onDockKeydown(ev: KeyboardEvent) {
  if (!compactDock.value || detail.serverHalf === 'pk') return
  if ((ev.ctrlKey || ev.metaKey) && ev.key.toLowerCase() === 'b') {
    if (editableTarget(ev.target)) return
    ev.preventDefault()
    ev.stopPropagation()
    void send('compact_toggle_input', {})
    return
  }
  if (!((ev.ctrlKey || ev.metaKey) && ev.key.toLowerCase() === 'v')) return
  if (editableTarget(ev.target)) return
  ev.preventDefault()
  ev.stopPropagation()
  compactDock.value = false
}

function exitCompactDock() {
  compactDock.value = false
}

function enterCompactDock() {
  if (detail.serverHalf === 'pk') return
  compactDock.value = true
}

watch(
  () => detail.serverHalf,
  (h) => {
    if (h === 'pk' && compactDock.value) {
      compactDock.value = false
    }
  },
)

watch(compactDock, async (v, prev) => {
  if (v) {
    closeAllModals()
    return
  }
  if (prev !== true) return
  await nextTick()
  await send('refboard:nui_focus_cursor', {})
  requestAnimationFrame(() => {
    fullEditorAnchorRef.value?.focus({ preventScroll: true })
  })
})

watch(
  () => compactDock.value && detail.serverHalf !== 'pk',
  (v) => {
    const on = Boolean(v)
    matchCompactDock.setTransparentChrome(on)
    void send('compact_dock_state', { compact: on })
    if (!on) {
      compactGameInputActive.value = false
    }
  },
  { immediate: true },
)

function loadMatch() {
  compactDock.value = false
  syncDetail()
}

watch(
  () => route.params.id,
  () => {
    compactDock.value = false
    loadMatch()
  },
  { immediate: true },
)

watch(
  () => matchesStore.matches,
  () => {
    syncDetail()
  },
  { deep: true },
)

onMounted(() => {
  settings.load()
  syncClockFromDetail()
  displayTickInterval = window.setInterval(() => {
    displayTick.value++
  }, 250)
  offCompactInputMode = on('refboard:compact_input_mode', (p: { game?: boolean }) => {
    compactGameInputActive.value = Boolean(p?.game)
  })
  window.addEventListener('keydown', onDockKeydown, true)
})

onUnmounted(() => {
  void send('compact_dock_state', { compact: false })
  matchCompactDock.setTransparentChrome(false)
  stopClockTickInterval()
  if (displayTickInterval != null) {
    clearInterval(displayTickInterval)
    displayTickInterval = null
  }
  offCompactInputMode?.()
  window.removeEventListener('keydown', onDockKeydown, true)
})

async function toViewMode() {
  toast(t('match_detail.view_mode_local_hint'), 'info', { ms: 4000 })
}

async function onCancel() {
  await router.push({ name: 'matches' })
}

async function onSave() {
  const id = matchId.value
  const m = matchesStore.find(id)
  if (m) matchesStore.patch(id, applyBasicInfoFromDetail(m, detail))
  await router.push({ name: 'matches' })
}

function openAdd(teamId: number) {
  addTeamId.value = teamId
  showAdd.value = true
}

const canRemoveMatchPlayers = computed(() => localEditor && rawMatch.value != null && rawMatch.value.status !== 'finished')

function openRemovePlayerModal(teamId: number, player: MatchPlayer) {
  if (!canRemoveMatchPlayers.value) {
    toast(t('player.remove_draft_only'), 'info', { ms: 5000 })
    return
  }
  pendingRemovePlayer.value = { teamId, player }
  showRemovePlayerModal.value = true
}

function closeRemovePlayerModal() {
  if (removePlayerBusy.value) return
  showRemovePlayerModal.value = false
  pendingRemovePlayer.value = null
}

function confirmRemovePlayer() {
  const ctx = pendingRemovePlayer.value
  if (!ctx || removePlayerBusy.value) return
  const pid = resolveMatchPlayerRowId(ctx.player.id)
  if (pid == null) {
    toast(t('player.remove_failed'), 'error')
    return
  }
  removePlayerBusy.value = true
  const r = matchesStore.removePlayer(matchId.value, pid)
  removePlayerBusy.value = false
  showRemovePlayerModal.value = false
  pendingRemovePlayer.value = null
  if (r.ok) {
    syncDetail()
    return
  }
  const code = r.error === 'player_has_events' ? 'E3006' : undefined
  const msg =
    r.error === 'player_has_events' && te('errors.E3006')
      ? t('errors.E3006')
      : t('player.remove_failed')
  toast(msg, 'error', { ms: 7000, errorCode: code, errorKey: r.error })
}

function onFinishConfirm() {
  matchesStore.finishMatch(matchId.value)
  showFinish.value = false
  syncDetail()
  toast(t('toast.match_finished'), 'success')
}

function onPkPanelFinishMatch() {
  matchesStore.finishMatch(matchId.value)
  syncDetail()
  toast(t('toast.match_finished'), 'success')
}

function reloadMatch() {
  syncDetail()
}

function currentHalf(): Half {
  return serverHalfStringToHalf(detail.serverHalf)
}

function onSetHalf(p: { matchId: number; half: string; pkFirstTeamId?: number }) {
  void p.pkFirstTeamId
  matchesStore.setHalf(p.matchId, serverHalfStringToHalf(p.half))
  syncDetail()
}

function onRecordGoal(payload: {
  teamId: number
  scorerPlayerId: number
  assistPlayerId: number | null
  eventTime: ParsedMinute | null
}) {
  const id = matchId.value
  const half = currentHalf()
  const t = eventTimeForStorage(payload.eventTime)
  matchesStore.addEvent(id, {
    kind: 'goal',
    half,
    minute: t.minute,
    stoppage: t.stoppage,
    teamId: payload.teamId,
    playerId: payload.scorerPlayerId,
    assistPlayerId: payload.assistPlayerId,
    subInPlayerId: null,
    subOutPlayerId: null,
    note: null,
    voided: false,
  })
  syncDetail()
}

function onManualScore(p: { homeScore: number; awayScore: number; reason: string }) {
  matchesStore.manualScoreEdit(matchId.value, p)
  syncDetail()
}

function onSubstitute(p: { teamId: number; outPlayerId: number; inPlayerId: number; eventTime: ParsedMinute | null }) {
  const id = matchId.value
  const half = currentHalf()
  const t = eventTimeForStorage(p.eventTime)
  matchesStore.addEvent(id, {
    kind: 'sub_out',
    half,
    minute: t.minute,
    stoppage: t.stoppage,
    teamId: p.teamId,
    playerId: p.outPlayerId,
    assistPlayerId: null,
    subInPlayerId: p.inPlayerId,
    subOutPlayerId: p.outPlayerId,
    note: null,
    voided: false,
  })
  matchesStore.addEvent(id, {
    kind: 'sub_in',
    half,
    minute: t.minute,
    stoppage: t.stoppage,
    teamId: p.teamId,
    playerId: p.inPlayerId,
    assistPlayerId: null,
    subInPlayerId: p.inPlayerId,
    subOutPlayerId: p.outPlayerId,
    note: null,
    voided: false,
  })
  matchesStore.setPlayerStatus(id, p.outPlayerId, 'subbed_out')
  matchesStore.setPlayerStatus(id, p.inPlayerId, 'playing')
  syncDetail()
}

function onIssueCard(payload: {
  teamId: number
  playerId: number
  cardType: 'yellow_card' | 'red_card'
  ejectionReason?: 'second_yellow' | 'red_card'
  eventTime: ParsedMinute | null
}) {
  const id = matchId.value
  const half = currentHalf()
  const t = eventTimeForStorage(payload.eventTime)
  if (payload.cardType === 'yellow_card') {
    matchesStore.addEvent(id, {
      kind: 'yellow',
      half,
      minute: t.minute,
      stoppage: t.stoppage,
      teamId: payload.teamId,
      playerId: payload.playerId,
      assistPlayerId: null,
      subInPlayerId: null,
      subOutPlayerId: null,
      note: null,
      voided: false,
    })
    matchesStore.setPlayerStatus(id, payload.playerId, 'warning')
  } else {
    matchesStore.addEvent(id, {
      kind: 'red',
      half,
      minute: t.minute,
      stoppage: t.stoppage,
      teamId: payload.teamId,
      playerId: payload.playerId,
      assistPlayerId: null,
      subInPlayerId: null,
      subOutPlayerId: null,
      note: payload.ejectionReason ?? null,
      voided: false,
    })
    matchesStore.setPlayerStatus(id, payload.playerId, 'ejected')
  }
  syncDetail()
}

function onPkShot(payload: { teamId: number; playerId: number; success: boolean }) {
  const id = matchId.value
  const half: Half = 'PK'
  const kind = payload.success ? 'pk_goal' : 'pk_miss'
  matchesStore.addEvent(id, {
    kind,
    half,
    minute: 0,
    stoppage: null,
    teamId: payload.teamId,
    playerId: payload.playerId,
    assistPlayerId: null,
    subInPlayerId: null,
    subOutPlayerId: null,
    note: null,
    voided: false,
  })
  syncDetail()
}

function onAddFromRoster(p: { rosterMemberId: number }) {
  const r = teamsStore.rosters.find((x) => x.id === p.rosterMemberId)
  if (!r) return
  matchesStore.addPlayer(matchId.value, {
    teamId: addTeamId.value,
    name: r.name,
    number: r.number ?? undefined,
    rosterMemberId: r.id,
  })
  syncDetail()
}

function onAddManual(p: { name: string; number: number | null }) {
  matchesStore.addPlayer(matchId.value, {
    teamId: addTeamId.value,
    name: p.name,
    number: p.number ?? undefined,
  })
  syncDetail()
}

function exportMatchJson() {
  downloadFile(
    exportMatchToJSON(detail, historyRows.value),
    refboardFilename('refboard_match', 'json'),
    'application/json;charset=utf-8',
  )
}

function exportMatchEventsCsv() {
  const m = rawMatch.value
  if (!m) return
  downloadMatchCsvPack(m, { operator: operatorName.value }, matchCsvColumnSet.value)
}
</script>

<template>
  <div
    class="flex h-full min-h-0 flex-col overflow-hidden bg-transparent"
    :class="{ 'pointer-events-none': compactDock && detail.serverHalf !== 'pk' }"
  >
    <div
      v-if="settings.settings.showHero && showFullEditor"
      class="relative shrink-0 border-b border-slate-700/80 bg-gradient-to-b from-slate-900/92 via-slate-900/88 to-slate-950/90 px-6 py-10 text-center backdrop-blur-sm"
    >
      <div class="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(59,130,246,0.15),transparent_55%)]" />
      <div class="relative mx-auto flex max-w-xl flex-col items-center gap-3">
        <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/20 text-4xl shadow-lg">⚽</div>
        <div class="text-2xl font-bold tracking-tight text-slate-50">サッカー試合管理ツール</div>
        <div class="text-sm text-slate-400">RefBoard — スタジアムモード</div>
        <div class="text-xs tracking-wide text-slate-500">by eiho</div>
      </div>
    </div>

    <div
      v-if="showFullEditor"
      ref="fullEditorAnchorRef"
      tabindex="-1"
      class="min-h-0 flex-1 overflow-y-auto px-4 py-4 outline-none focus:outline-none"
    >
      <PenaltyShootoutPanel
        v-if="detail.serverHalf === 'pk'"
        :model="detail"
        :readonly="readonly"
        @pk-shot="onPkShot"
        @finish-match="onPkPanelFinishMatch"
      />
      <div v-if="detail.serverHalf !== 'pk'">
        <header class="mb-4 flex flex-wrap items-center gap-3 border-b border-slate-700/80 pb-3">
          <div class="flex flex-1 flex-wrap items-center gap-x-3 gap-y-2 text-sm text-slate-200">
            <div class="flex min-w-0 flex-wrap items-center gap-2">
              <span class="font-semibold">試合詳細の編集</span>
              <span v-if="localEditor" class="rounded bg-emerald-500/20 px-2 py-0.5 text-xs font-medium text-emerald-300">[編集中]</span>
            </div>
            <div
              v-if="!matchCompactDock.transparentChrome"
              class="flex min-w-0 flex-shrink-0 items-center gap-1 text-xs text-slate-300/80"
            >
              <span>{{ t('match.operator_label') }}:</span>
              <span v-if="operatorIsSet" class="font-medium text-emerald-300">{{ operatorName }}</span>
              <RouterLink
                v-else
                :to="{ name: 'settings' }"
                class="text-slate-400 underline-offset-2 hover:text-emerald-300 hover:underline"
                :title="t('match.operator_set_in_settings')"
              >
                {{ t('match.operator_unset') }}
              </RouterLink>
            </div>
          </div>
          <div class="flex flex-1 flex-wrap items-center justify-end gap-2">
            <button
              type="button"
              class="rounded-lg border border-amber-400/50 bg-amber-500/15 px-3 py-1.5 text-xs font-semibold text-amber-200 hover:bg-amber-500/25"
              @click="enterCompactDock"
            >
              {{ t('match_detail.compact_mode') }}
            </button>
            <button
              type="button"
              class="rounded-lg border border-amber-500/40 bg-amber-500/10 px-3 py-1.5 text-xs font-semibold text-amber-300 hover:bg-amber-500/20"
              @click="toViewMode"
            >
              [閲覧モード]
            </button>
            <button type="button" class="rounded-lg border border-slate-600 bg-slate-800 px-3 py-1.5 text-xs text-slate-200" @click="onCancel">
              [キャンセル]
            </button>
            <button
              v-if="localEditor && detail.dbStatus === 'draft'"
              type="button"
              class="rounded-lg border border-red-500/50 bg-red-500/10 px-3 py-1.5 text-xs font-semibold text-red-300 hover:bg-red-500/20"
              @click="showFinish = true"
            >
              {{ t('match_detail.finish') }}
            </button>
            <button type="button" class="rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-white hover:brightness-110" @click="onSave">
              [保存する]
            </button>
            <button
              type="button"
              class="rounded-lg border border-slate-600 px-2 py-1.5 text-xs text-slate-200"
              :title="t('match_detail.export_json')"
              @click="exportMatchJson"
            >
              JSON
            </button>
            <div class="flex flex-wrap items-center gap-1.5">
              <label class="sr-only" for="match-csv-column-set">{{ t('data.csv_column_set') }}</label>
              <select
                id="match-csv-column-set"
                v-model="matchCsvColumnSet"
                class="max-w-[11rem] rounded border border-slate-600 bg-slate-900 px-2 py-1 text-xs text-slate-200"
              >
                <option value="standard">{{ t('data.csv_standard') }}</option>
                <option value="detailed">{{ t('data.csv_detailed') }}</option>
              </select>
              <button
                type="button"
                class="rounded-lg border border-slate-600 px-2 py-1.5 text-xs text-slate-200"
                :title="t('match_detail.export_events_csv')"
                @click="exportMatchEventsCsv"
              >
                CSV
              </button>
            </div>
            <HelpTriggerButton context-id="match_detail" />
          </div>
        </header>

        <div class="mb-4 grid min-w-0 grid-cols-1 gap-4 lg:grid-cols-[30%_40%_30%]">
          <div class="min-w-0" :style="cardDimStyle" @pointerenter="setFocus('basic_info')" @pointerleave="setFocus(null)">
            <BasicInfoCard :model="detail" :readonly="readonly" :editor-here="editorHereBasic" />
          </div>
          <div class="min-w-0" @pointerenter="setFocus('score')" @pointerleave="setFocus(null)">
            <ScoreBoardCard
              :model="detail"
              :readonly="readonly"
              :editor-here="editorHereScore"
              :clock-mm-ss-override="clockLiveDisplay"
              :clock-phase-label="clockPhaseLabel"
              @goal="showGoal = true"
              @manual-score="showScoreEdit = true"
              @clock-start="onClockStart"
              @clock-stop="onClockStop"
              @clock-clear="onClockClear"
              @clock-adjust="onClockAdjust"
            />
          </div>
          <div class="min-w-0" :style="cardDimStyle" @pointerenter="setFocus('status')" @pointerleave="setFocus(null)">
            <MatchStatusCard :model="detail" :readonly="readonly" :editor-here="editorHereStatus" @set-half="onSetHalf" />
          </div>
        </div>

        <div class="grid min-w-0 grid-cols-1 gap-4 lg:grid-cols-[65%_35%]" :style="cardDimStyle">
          <div class="grid grid-cols-1 gap-4 xl:grid-cols-2">
            <div @pointerenter="setFocus('team1_players')" @pointerleave="setFocus(null)">
              <PlayerListCard
                :title="`${detail.home.name} — ${t('match_detail.section_roster_suffix')}`"
                :players="detail.homePlayers"
                :team-id="detail.team1Id"
                :readonly="readonly"
                :can-remove-players="canRemoveMatchPlayers"
                :editor-here="editorHereT1"
                @history="showHistory = true"
                @add="openAdd"
                @remove="(p) => openRemovePlayerModal(detail.team1Id, p)"
              />
            </div>
            <div @pointerenter="setFocus('team2_players')" @pointerleave="setFocus(null)">
              <PlayerListCard
                :title="`${detail.away.name} — ${t('match_detail.section_roster_suffix')}`"
                :players="detail.awayPlayers"
                :team-id="detail.team2Id"
                :readonly="readonly"
                :can-remove-players="canRemoveMatchPlayers"
                :editor-here="editorHereT2"
                @history="showHistory = true"
                @add="openAdd"
                @remove="(p) => openRemovePlayerModal(detail.team2Id, p)"
              />
            </div>
          </div>
          <div @pointerenter="setFocus('events')" @pointerleave="setFocus(null)">
            <EventTimelineCard
              :events="detail.events"
              :readonly="readonly"
              :editor-here="editorHereEvents"
              @substitute="showSub = true"
              @issue-card="openCard"
            />
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="compactDock && detail.serverHalf !== 'pk'"
      class="pointer-events-auto fixed bottom-4 left-0 right-0 z-[100] flex flex-col items-center gap-1.5 bg-transparent px-2 pb-[max(0.75rem,env(safe-area-inset-bottom,0px))] pt-0 sm:bottom-5"
    >
      <div
        class="relative w-full max-h-[min(52vh,28rem)] max-w-6xl overflow-y-auto rounded-t-xl border border-slate-600/70 bg-slate-900/95 p-2 pt-7 shadow-[0_-8px_32px_rgba(0,0,0,0.45)] shadow-inner backdrop-blur-md md:max-h-[min(46vh,26rem)]"
      >
        <div
          class="pointer-events-none absolute right-3 top-2 z-10 text-xs tracking-wide text-slate-500"
          aria-hidden="true"
        >
          by eiho
        </div>
        <div class="flex flex-col gap-2 md:flex-row md:items-stretch md:gap-3">
          <div class="min-h-0 min-w-0 flex-1 md:max-w-[58%]" @pointerenter="setFocus('score')" @pointerleave="setFocus(null)">
            <ScoreBoardCard
              embed
              :model="detail"
              :readonly="readonly"
              :editor-here="editorHereScore"
              :clock-mm-ss-override="clockLiveDisplay"
              :clock-phase-label="clockPhaseLabel"
              @goal="showGoal = true"
              @manual-score="showScoreEdit = true"
              @clock-start="onClockStart"
              @clock-stop="onClockStop"
              @clock-clear="onClockClear"
              @clock-adjust="onClockAdjust"
            />
          </div>
          <div
            class="flex min-h-0 min-w-0 flex-1 flex-col gap-2"
            :style="cardDimStyle"
            @pointerenter="setFocus('status')"
            @pointerleave="setFocus(null)"
          >
            <MatchStatusCard :model="detail" :readonly="readonly" :editor-here="editorHereStatus" embed @set-half="onSetHalf" />
            <div class="flex flex-wrap items-baseline gap-x-1 gap-y-0.5 px-0.5 text-xs text-slate-500">
              <span>{{ t('match.operator_label') }}:</span>
              <span v-if="operatorIsSet" class="font-medium text-slate-300">{{ operatorName }}</span>
              <span v-else>{{ t('match.operator_unset') }}</span>
            </div>
            <div class="px-0.5 text-xs font-medium text-slate-400">{{ t('compact.recent_events') }}</div>
            <CompactEventList class="min-h-0 shrink" :events="detail.events" max-height="6rem" />
          </div>
          <div
            class="flex shrink-0 flex-col items-stretch justify-end gap-2 border-t border-slate-600/40 pt-2 md:min-w-[min(22rem,40vw)] md:border-l md:border-t-0 md:pl-3 md:pt-0"
          >
            <p class="text-xl font-medium leading-snug text-slate-300 md:text-right">
              {{ compactFocusHint }}
            </p>
            <button
              type="button"
              class="cursor-pointer rounded border border-amber-400/90 bg-amber-300 px-3 py-2 text-left text-[1.375rem] font-bold leading-snug text-amber-950 shadow-md ring-1 ring-amber-500/30 md:text-right"
              :title="`${t('match_detail.restore_ui_hint')} / ${t('match_detail.restore_full_click')}`"
              @click="exitCompactDock"
            >
              {{ t('match_detail.compact_restore_full') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="pointer-events-auto">
      <GoalRecordWizard
        v-model:open="showGoal"
        :model="detail"
        :suggested-event-time="suggestedEventTime"
        @record-goal="onRecordGoal"
        @recorded="reloadMatch"
      />
      <SubstitutionDialog
        v-model:open="showSub"
        :model="detail"
        :suggested-event-time="suggestedEventTime"
        :match-time-mm-ss="elapsedMmSsLive"
        @substitute="onSubstitute"
        @done="reloadMatch"
      />
      <CardIssueDialog
        v-model:open="showCard"
        :model="detail"
        :suggested-event-time="suggestedEventTime"
        :preset-kind="cardPreset"
        @issue-card="onIssueCard"
        @done="reloadMatch"
      />
      <AddPlayerDialog
        v-model:open="showAdd"
        :match-id="detail.id"
        :team-id="addTeamId"
        :roster-rows="addDialogRosterRows"
        @add-from-roster="onAddFromRoster"
        @add-manual="onAddManual"
        @added="reloadMatch"
      />
      <ScoreEditDialog v-model:open="showScoreEdit" :model="detail" @manual-score="onManualScore" @saved="reloadMatch" />
      <ScoreHistoryDialog v-model:open="showHistory" :rows="historyRows" />

      <div v-if="showRemovePlayerModal && pendingRemovePlayer" :class="matchDetailRemovePlayerOverlayClass">
        <div class="max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
          <h2 class="mb-2 text-lg font-semibold text-slate-50">{{ t('player.remove_modal_title') }}</h2>
          <p class="mb-4 text-sm text-slate-300">
            {{ t('player.remove_confirm', { name: pendingRemovePlayer.player.name }) }}
          </p>
          <div class="flex justify-end gap-2">
            <button
              type="button"
              class="rounded-lg border border-slate-600 px-3 py-2 text-sm"
              :disabled="removePlayerBusy"
              @click="closeRemovePlayerModal"
            >
              {{ t('dialog.no') }}
            </button>
            <button
              type="button"
              class="rounded-lg bg-red-600 px-3 py-2 text-sm font-semibold text-white disabled:opacity-50"
              :disabled="removePlayerBusy"
              @click="confirmRemovePlayer"
            >
              {{ t('dialog.yes') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="showFinish" :class="matchDetailFinishOverlayClass">
        <div class="max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
          <h2 class="mb-2 text-lg font-semibold text-slate-50">{{ t('match_finish.title') }}</h2>
          <p class="mb-1 text-sm text-slate-300">
            {{ t('match_finish.score_line', { home: detail.home.name, away: detail.away.name, s1: detail.score.home, s2: detail.score.away }) }}
          </p>
          <p class="mb-1 text-sm text-slate-400">{{ t('match_finish.time', { time: elapsedMmSsLive }) }}</p>
          <p class="mb-4 text-xs text-slate-500">{{ t('match_finish.note') }}</p>
          <div class="flex justify-end gap-2">
            <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="showFinish = false">
              {{ t('dialog.no') }}
            </button>
            <button type="button" class="rounded-lg bg-red-600 px-3 py-2 text-sm font-semibold text-white" @click="onFinishConfirm">
              {{ t('match_finish.confirm') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
