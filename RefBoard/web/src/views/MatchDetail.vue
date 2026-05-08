<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { useAutosaveStore } from '../stores/autosave'
import { usePresenceStore } from '../stores/presence'
import { refboardRecaptureNuiFocus, useNui } from '../composables/useNui'
import { useFocusTracker } from '../composables/useFocusTracker'
import { mockMatchDetail } from '../mocks/matchDetail'
import type { MatchClockAck, MatchDetailModel } from '../types/match'
import type { ScoreHistoryRow } from '../types/match'
import {
  mapBreakdown,
  mapEventsFromServer,
  mapHistoryRows,
  mapMatchGetAckToDetail,
  mapPlayersForTeam,
  mapUiStatusFromHalf,
  type MatchGetAck,
  type ServerBreakdown,
  type ServerEventRow,
  type ServerHistoryRow,
  type ServerPlayerRow,
} from '../utils/mapMatchFromServer'
import { downloadFile, exportMatchEventsToCSV, exportMatchToJSON, refboardFilename } from '../utils/exporters'
import BasicInfoCard from '../components/match/BasicInfoCard.vue'
import ScoreBoardCard from '../components/match/ScoreBoardCard.vue'
import MatchStatusCard from '../components/match/MatchStatusCard.vue'
import PlayerListCard from '../components/match/PlayerListCard.vue'
import EventTimelineCard from '../components/match/EventTimelineCard.vue'
import PenaltyShootoutPanel from '../components/match/PenaltyShootoutPanel.vue'
import SubstitutionDialog from '../components/match/SubstitutionDialog.vue'
import CardIssueDialog from '../components/match/CardIssueDialog.vue'
import AutosaveIndicator from '../components/AutosaveIndicator.vue'
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
import { nuiShellOpenRef } from '../nuiShellVisibility'

defineProps<{
  id?: string
}>()

const route = useRoute()
const router = useRouter()
const session = useSessionStore()
const autosave = useAutosaveStore()
const presence = usePresenceStore()
const { send, on } = useNui()
const { setFocus } = useFocusTracker()
const { t } = useI18n()
const settings = useSettingsStore()
const matchCompactDock = useMatchCompactDockStore()
const { push: toast } = useToast()

function closeAllModals() {
  showGoal.value = false
  showAdd.value = false
  showScoreEdit.value = false
  showHistory.value = false
  showFinish.value = false
  showSub.value = false
  showCard.value = false
}

useKeyboardShortcuts({
  enabled: () => session.isEditor && detail.dbStatus === 'draft',
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

const readonly = computed(() => !session.isEditor)

/** カード不透明度（設定）。スコアボードは opacity 親を持たない（CEF で blur と合成すると霞み・クリック不能になり得る） */
const cardDimStyle = computed(() => ({ opacity: settings.settings.cardOpacity / 100 }))

const detail = reactive<MatchDetailModel>(JSON.parse(JSON.stringify(mockMatchDetail)) as MatchDetailModel)
const historyRows = ref<ScoreHistoryRow[]>([])

const showGoal = ref(false)
const showAdd = ref(false)
const addTeamId = ref(0)
const showScoreEdit = ref(false)
const showHistory = ref(false)
const showFinish = ref(false)
const showSub = ref(false)
const showCard = ref(false)
const cardPreset = ref<'yellow' | 'red' | null>(null)

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
const fullMatchDurationMs = computed(
  () => Math.max(60_000, settings.settings.defaultHalfMinutes * 2 * 60 * 1000),
)

const clockUiTick = ref(0)
const clockLiveDisplay = ref('0:00')
let clockTickInterval: ReturnType<typeof setInterval> | null = null

function getElapsedMsFromDetail(): number {
  const acc =
    typeof detail.clockAccumulatedMs === 'number'
      ? detail.clockAccumulatedMs
      : parseClockMmSsToMs(detail.clockMmSs)
  if (detail.clockRunning === true && detail.clockStartedAtMs != null) {
    const st = Number(detail.clockStartedAtMs)
    if (Number.isFinite(st)) {
      return acc + Math.max(0, Date.now() - st)
    }
  }
  return acc
}

const elapsedMmSsLive = computed(() => {
  void clockUiTick.value
  return formatClockMs(getElapsedMsFromDetail())
})

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
  const full = fullMatchDurationMs.value
  const elapsed = getElapsedMsFromDetail()
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

function applyClockAck(r: MatchClockAck) {
  if (r.clock_accumulated_ms !== undefined) {
    detail.clockAccumulatedMs = Number(r.clock_accumulated_ms) || 0
  }
  if (r.clock_running !== undefined) {
    detail.clockRunning = Number(r.clock_running) === 1
  }
  if (r.clock_started_at !== undefined) {
    const v = r.clock_started_at
    detail.clockStartedAtMs = v != null && String(v) !== '' ? Number(v) : null
  }
  detail.clockMmSs = formatClockMs(getElapsedMsFromDetail())
}

function callMatchClock(
  action: 'start' | 'stop' | 'clear' | 'adjust',
  deltaRemainingMs?: number,
): Promise<boolean> {
  return new Promise((resolve) => {
    let settled = false
    const un = on('refboard:match:clock:ack', (r: MatchClockAck) => {
      const ackMid = r?.matchId != null ? Number(r.matchId) : NaN
      if (Number.isFinite(ackMid) && ackMid !== Number(detail.id)) {
        return
      }
      settled = true
      un()
      if (r?.ok) {
        applyClockAck(r)
        syncClockFromDetail()
        resolve(true)
      } else {
        const msg = r?.error
          ? t('toast.match_clock_error', { code: String(r.error) })
          : t('toast.match_clock_failed')
        toast(msg, 'error')
        resolve(false)
      }
    })
    void send('match_clock', { matchId: detail.id, action, deltaRemainingMs }).catch(() => {
      if (!settled) {
        settled = true
        un()
        toast(t('toast.match_clock_failed'), 'error')
        resolve(false)
      }
    })
    setTimeout(() => {
      if (!settled) {
        settled = true
        un()
        toast(t('toast.match_clock_timeout'), 'error')
        resolve(false)
      }
    }, 8000)
  })
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

const editorFocus = computed(() => presence.editorFocus)
const editorHereBasic = computed(() => editorFocus.value === 'basic_info')
const editorHereScore = computed(() => editorFocus.value === 'score')
const editorHereStatus = computed(() => editorFocus.value === 'status')
const editorHereT1 = computed(() => editorFocus.value === 'team1_players')
const editorHereT2 = computed(() => editorFocus.value === 'team2_players')
const editorHereEvents = computed(() => editorFocus.value === 'events')

let offState: (() => void) | null = null
let offFinished: (() => void) | null = null

function applyState(p: {
  matchId: number
  team1_score: number
  team2_score: number
  status?: string
  current_half?: string
  pk_first_team_id?: number | null
  clock_running?: number
  clock_started_at?: number | null
  clock_accumulated_ms?: number
  breakdown?: ServerBreakdown
  events?: ServerEventRow[]
  players?: ServerPlayerRow[] | null
  history?: ServerHistoryRow[]
}) {
  if (Number(p.matchId) !== Number(detail.id)) return
  detail.score.home = p.team1_score
  detail.score.away = p.team2_score
  if (p.status === 'finished' || p.status === 'draft' || p.status === 'cancelled') {
    detail.dbStatus = p.status
  }
  if (p.breakdown) {
    detail.breakdown = mapBreakdown(p.breakdown, detail.breakdown)
  }
  if (p.current_half) {
    detail.serverHalf = p.current_half
    detail.uiStatus = mapUiStatusFromHalf(detail.dbStatus, p.current_half)
  }
  if (p.pk_first_team_id !== undefined && p.pk_first_team_id !== null) {
    detail.pkFirstTeamId = Number(p.pk_first_team_id)
  }
  if (p.events) {
    detail.events = mapEventsFromServer(p.events)
  }
  if (p.players && p.players.length) {
    detail.homePlayers = mapPlayersForTeam(p.players, detail.team1Id)
    detail.awayPlayers = mapPlayersForTeam(p.players, detail.team2Id)
  }
  if (p.history) {
    historyRows.value = mapHistoryRows(p.history)
  }
  const clockPatch =
    p.clock_accumulated_ms !== undefined ||
    p.clock_running !== undefined ||
    p.clock_started_at !== undefined
  if (clockPatch) {
    if (p.clock_accumulated_ms !== undefined) {
      detail.clockAccumulatedMs = Number(p.clock_accumulated_ms) || 0
    }
    if (p.clock_running !== undefined) {
      detail.clockRunning = Number(p.clock_running) === 1
    }
    if (p.clock_started_at !== undefined) {
      const v = p.clock_started_at
      detail.clockStartedAtMs = v != null && String(v) !== '' ? Number(v) : null
    }
    detail.clockMmSs = formatClockMs(getElapsedMsFromDetail())
    syncClockFromDetail()
  }
}

function openCard(kind: 'yellow' | 'red') {
  cardPreset.value = kind
  showCard.value = true
}

watch(showCard, (v) => {
  if (!v) {
    cardPreset.value = null
  }
})

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
  await refboardRecaptureNuiFocus()
  requestAnimationFrame(() => {
    fullEditorAnchorRef.value?.focus({ preventScroll: true })
  })
})

watch(
  () => compactDock.value && detail.serverHalf !== 'pk',
  (v) => {
    matchCompactDock.setTransparentChrome(v)
  },
  { immediate: true },
)

async function loadMatch() {
  const id = Number(route.params.id)
  if (!id) return
  detail.id = id
  const un = on('refboard:match:get:ack', (ack: MatchGetAck) => {
    un()
    const mapped = mapMatchGetAckToDetail(ack)
    if (mapped) {
      Object.assign(detail, mapped)
      syncClockFromDetail()
    }
    historyRows.value = mapHistoryRows(ack.history)
  })
  await send('match_get', { matchId: id })
}

watch(
  () => route.params.id,
  () => {
    compactDock.value = false
    const id = Number(route.params.id)
    if (session.isEditor && id) {
      void send('lock_acquire', { matchId: id })
    }
    void loadMatch()
  },
  { immediate: true },
)

let deb: ReturnType<typeof setTimeout> | null = null
watch(
  () => detail,
  () => {
    if (readonly.value) {
      return
    }
    if (deb) {
      clearTimeout(deb)
    }
    deb = setTimeout(() => {
      deb = null
      autosave.markSaving()
      void send('autosave_draft', { matchId: detail.id, state: detail })
    }, 600)
  },
  { deep: true },
)

/** F6 で NUI を閉じたとき Lua がロック解放する。再オープン時は同一ルートのままなので onMounted が走らず lock が無いまま → 時計が no_lock で失敗する。ここで取り直す */
watch(nuiShellOpenRef, (open, prevOpen) => {
  if (!open || prevOpen !== false) return
  if (!session.isEditor) return
  const id = Number(detail.id)
  if (!id) return
  void send('lock_acquire', { matchId: id })
  void loadMatch()
})

onMounted(() => {
  settings.load()
  syncClockFromDetail()
  offState = on('refboard:match:state', (p) => applyState(p as never))
  offFinished = on('refboard:match:finished', (p: { matchId?: number }) => {
    if (p?.matchId != null && Number(p.matchId) === Number(detail.id)) {
      detail.dbStatus = 'finished'
    }
  })
  window.addEventListener('keydown', onDockKeydown, true)
})

onUnmounted(() => {
  matchCompactDock.setTransparentChrome(false)
  stopClockTickInterval()
  offState?.()
  offFinished?.()
  window.removeEventListener('keydown', onDockKeydown, true)
})

async function toViewMode() {
  await session.downgradeToView()
}

async function onCancel() {
  await send('lock_release', {})
  await router.push({ name: 'matches' })
}

async function onSave() {
  await send('lock_release', {})
  await router.push({ name: 'matches' })
}

function openAdd(teamId: number) {
  addTeamId.value = teamId
  showAdd.value = true
}

async function onFinishConfirm() {
  const un = on('refboard:match:finish:ack', (r: { ok?: boolean }) => {
    un()
    if (r?.ok) {
      detail.dbStatus = 'finished'
      showFinish.value = false
      toast(t('toast.match_finished'), 'success')
    }
  })
  await send('match_finish', { matchId: detail.id })
}

function onPkFinished() {
  detail.dbStatus = 'finished'
  toast(t('toast.match_finished'), 'success')
}

function reloadMatch() {
  void loadMatch()
}

function exportMatchJson() {
  downloadFile(
    exportMatchToJSON(detail, historyRows.value),
    refboardFilename('refboard_match', 'json'),
    'application/json;charset=utf-8',
  )
}

function exportMatchEventsCsv() {
  downloadFile(
    exportMatchEventsToCSV(detail.events),
    refboardFilename('refboard_match_events', 'csv'),
    'text/csv;charset=utf-8',
  )
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
        @recorded="reloadMatch"
        @finished="onPkFinished"
      />
      <div v-if="detail.serverHalf !== 'pk'">
        <header class="mb-4 flex flex-wrap items-center gap-3 border-b border-slate-700/80 pb-3">
          <div class="flex flex-1 flex-wrap items-center gap-2 text-sm text-slate-200">
            <span class="font-semibold">試合詳細の編集</span>
            <span v-if="session.isEditor" class="rounded bg-emerald-500/20 px-2 py-0.5 text-xs font-medium text-emerald-300">[編集中]</span>
            <span v-else class="rounded bg-amber-500/20 px-2 py-0.5 text-xs font-medium text-amber-300">[閲覧モード]</span>
          </div>
          <div class="flex flex-1 justify-center">
            <AutosaveIndicator />
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
              v-if="session.isEditor && detail.dbStatus === 'draft'"
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
            <button
              type="button"
              class="rounded-lg border border-slate-600 px-2 py-1.5 text-xs text-slate-200"
              :title="t('match_detail.export_events_csv')"
              @click="exportMatchEventsCsv"
            >
              CSV
            </button>
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
            <MatchStatusCard :model="detail" :readonly="readonly" :editor-here="editorHereStatus" />
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
                :editor-here="editorHereT1"
                @history="showHistory = true"
                @add="openAdd"
              />
            </div>
            <div @pointerenter="setFocus('team2_players')" @pointerleave="setFocus(null)">
              <PlayerListCard
                :title="`${detail.away.name} — ${t('match_detail.section_roster_suffix')}`"
                :players="detail.awayPlayers"
                :team-id="detail.team2Id"
                :readonly="readonly"
                :editor-here="editorHereT2"
                @history="showHistory = true"
                @add="openAdd"
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

    <button
      v-if="compactDock && detail.serverHalf !== 'pk'"
      type="button"
      class="pointer-events-auto fixed left-2 top-2 z-[120] max-w-[min(22rem,calc(100vw-1rem))] cursor-pointer rounded border border-amber-400/90 bg-amber-300 px-3 py-2 text-left text-xs font-bold leading-snug text-amber-950 shadow-lg ring-2 ring-amber-500/35"
      :title="t('match_detail.restore_full_click')"
      @click="exitCompactDock"
    >
      {{ t('match_detail.restore_ui_hint') }}
    </button>

    <div
      v-if="compactDock && detail.serverHalf !== 'pk'"
      class="pointer-events-auto fixed bottom-4 left-2 right-2 z-[100] border-t border-slate-600/80 bg-slate-950/90 px-2 pb-[max(0.75rem,env(safe-area-inset-bottom,0px))] pt-2 shadow-[0_-12px_40px_rgba(0,0,0,0.5)] backdrop-blur-md sm:bottom-5"
    >
      <div
        class="mx-auto max-h-[min(52vh,28rem)] max-w-6xl overflow-y-auto rounded-t-xl border border-slate-600/70 bg-slate-900/55 p-2 shadow-inner md:max-h-[min(46vh,26rem)]"
      >
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
            class="min-h-0 min-w-0 flex-1"
            :style="cardDimStyle"
            @pointerenter="setFocus('status')"
            @pointerleave="setFocus(null)"
          >
            <MatchStatusCard :model="detail" :readonly="readonly" :editor-here="editorHereStatus" embed />
          </div>
        </div>
      </div>
    </div>

    <div class="pointer-events-auto">
      <GoalRecordWizard v-model:open="showGoal" :model="detail" @recorded="reloadMatch" />
      <SubstitutionDialog v-model:open="showSub" :model="detail" :match-time-mm-ss="elapsedMmSsLive" @done="reloadMatch" />
      <CardIssueDialog v-model:open="showCard" :model="detail" :preset-kind="cardPreset" @done="reloadMatch" />
      <AddPlayerDialog v-model:open="showAdd" :match-id="detail.id" :team-id="addTeamId" @added="reloadMatch" />
      <ScoreEditDialog v-model:open="showScoreEdit" :model="detail" @saved="reloadMatch" />
      <ScoreHistoryDialog v-model:open="showHistory" :rows="historyRows" />

      <div
        v-if="showFinish"
        class="fixed inset-0 z-[170] flex items-center justify-center bg-black/55 p-4"
        @click.self="showFinish = false"
      >
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
