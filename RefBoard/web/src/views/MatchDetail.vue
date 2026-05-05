<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { useAutosaveStore } from '../stores/autosave'
import { useNui } from '../composables/useNui'
import { useHeartbeat } from '../composables/useHeartbeat'
import { mockMatchDetail } from '../mocks/matchDetail'
import type { MatchDetailModel } from '../types/match'
import type { ScoreHistoryRow } from '../types/match'
import {
  mapEventsFromServer,
  mapHistoryRows,
  mapMatchGetAckToDetail,
  mapPlayersForTeam,
  type MatchGetAck,
  type ServerEventRow,
  type ServerHistoryRow,
  type ServerPlayerRow,
} from '../utils/mapMatchFromServer'
import BasicInfoCard from '../components/match/BasicInfoCard.vue'
import ScoreBoardCard from '../components/match/ScoreBoardCard.vue'
import MatchStatusCard from '../components/match/MatchStatusCard.vue'
import PlayerListCard from '../components/match/PlayerListCard.vue'
import EventTimelineCard from '../components/match/EventTimelineCard.vue'
import AutosaveIndicator from '../components/AutosaveIndicator.vue'
import GoalRecordWizard from '../components/match/GoalRecordWizard.vue'
import AddPlayerDialog from '../components/match/AddPlayerDialog.vue'
import ScoreEditDialog from '../components/match/ScoreEditDialog.vue'
import ScoreHistoryDialog from '../components/match/ScoreHistoryDialog.vue'
import { useI18n } from 'vue-i18n'

defineProps<{
  id?: string
}>()

const route = useRoute()
const router = useRouter()
const session = useSessionStore()
const autosave = useAutosaveStore()
const { send, on } = useNui()
const { t } = useI18n()

const readonly = computed(() => !session.isEditor)

const detail = reactive<MatchDetailModel>(JSON.parse(JSON.stringify(mockMatchDetail)) as MatchDetailModel)
const historyRows = ref<ScoreHistoryRow[]>([])

const showGoal = ref(false)
const showAdd = ref(false)
const addTeamId = ref(0)
const showScoreEdit = ref(false)
const showHistory = ref(false)
const showFinish = ref(false)

let offState: (() => void) | null = null
let offFinished: (() => void) | null = null

function applyState(p: {
  matchId: number
  team1_score: number
  team2_score: number
  status?: string
  events?: ServerEventRow[]
  players?: ServerPlayerRow[] | null
  history?: ServerHistoryRow[]
}) {
  if (p.matchId !== detail.id) return
  detail.score.home = p.team1_score
  detail.score.away = p.team2_score
  if (p.status === 'finished' || p.status === 'draft' || p.status === 'cancelled') {
    detail.dbStatus = p.status
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
}

async function loadMatch() {
  const id = Number(route.params.id)
  if (!id) return
  detail.id = id
  const un = on('refboard:match:get:ack', (ack: MatchGetAck) => {
    un()
    const mapped = mapMatchGetAckToDetail(ack)
    if (mapped) {
      Object.assign(detail, mapped)
    }
    historyRows.value = mapHistoryRows(ack.history)
  })
  await send('match_get', { matchId: id })
}

useHeartbeat()

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

watch(
  () => route.params.id,
  () => {
    void loadMatch()
  },
  { immediate: true },
)

onMounted(() => {
  if (session.isEditor) {
    void send('lock_acquire', { matchId: detail.id })
  }
  offState = on('refboard:match:state', (p) => applyState(p as never))
  offFinished = on('refboard:match:finished', (p: { matchId?: number }) => {
    if (p?.matchId === detail.id) {
      detail.dbStatus = 'finished'
    }
  })
})

onUnmounted(() => {
  offState?.()
  offFinished?.()
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
    }
  })
  await send('match_finish', { matchId: detail.id })
}

function reloadMatch() {
  void loadMatch()
}
</script>

<template>
  <div class="flex h-full min-h-0 flex-col overflow-hidden bg-bg">
    <div
      class="relative shrink-0 border-b border-slate-700 bg-gradient-to-b from-slate-900 via-slate-900/95 to-slate-950 px-6 py-10 text-center"
    >
      <div class="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(59,130,246,0.15),transparent_55%)]" />
      <div class="relative mx-auto flex max-w-xl flex-col items-center gap-3">
        <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/20 text-4xl shadow-lg">⚽</div>
        <div class="text-2xl font-bold tracking-tight text-slate-50">サッカー試合管理ツール</div>
        <div class="text-sm text-slate-400">RefBoard — スタジアムモード</div>
      </div>
    </div>

    <div class="min-h-0 flex-1 overflow-y-auto px-4 py-4">
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
        </div>
      </header>

      <div class="mb-4 grid grid-cols-1 gap-4 lg:grid-cols-[30%_40%_30%]">
        <BasicInfoCard :model="detail" :readonly="readonly" />
        <ScoreBoardCard :model="detail" :readonly="readonly" @goal="showGoal = true" @manual-score="showScoreEdit = true" />
        <MatchStatusCard :model="detail" :readonly="readonly" />
      </div>

      <div class="grid grid-cols-1 gap-4 lg:grid-cols-[65%_35%]">
        <div class="grid grid-cols-1 gap-4 xl:grid-cols-2">
          <PlayerListCard
            :title="`${detail.home.name} — 選手`"
            :players="detail.homePlayers"
            :team-id="detail.team1Id"
            :readonly="readonly"
            @history="showHistory = true"
            @add="openAdd"
          />
          <PlayerListCard
            :title="`${detail.away.name} — 選手`"
            :players="detail.awayPlayers"
            :team-id="detail.team2Id"
            :readonly="readonly"
            @history="showHistory = true"
            @add="openAdd"
          />
        </div>
        <EventTimelineCard :events="detail.events" :readonly="readonly" />
      </div>
    </div>

    <GoalRecordWizard v-model:open="showGoal" :model="detail" @recorded="reloadMatch" />
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
        <p class="mb-1 text-sm text-slate-400">{{ t('match_finish.time', { time: detail.clockMmSs }) }}</p>
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
</template>
