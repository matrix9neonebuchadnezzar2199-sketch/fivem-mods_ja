<script setup lang="ts">
import { computed, nextTick, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useI18n } from 'vue-i18n'
import type { MatchDetailModel, MatchEvent, MatchPlayer } from '../../types/match'
import { useDialogOverlay } from '../../composables/useDialogOverlay'
import { useMatchCompactDockStore } from '../../stores/matchCompactDock'

const { overlayRootClassFlexCol, overlayRootClass } = useDialogOverlay()
const pkWinnerOverlayClass = overlayRootClassFlexCol('z-[400]', 'bg-black/80')
const pkFinishAskOverlayClass = overlayRootClass('z-[410]', 'bg-black/60')

const { transparentChrome } = storeToRefs(useMatchCompactDockStore())

const props = defineProps<{
  model: MatchDetailModel
  readonly: boolean
}>()

const emit = defineEmits<{
  finished: []
  'pk-shot': [{ teamId: number; playerId: number; success: boolean }]
  'finish-match': []
}>()

const { t } = useI18n()

const homePlayerId = ref<string | null>(null)
const awayPlayerId = ref<string | null>(null)

const showWinnerOverlay = ref(false)
const showFinishAsk = ref(false)
const winnerName = ref('')

let winTimer: number | null = null

const pkEvents = computed(() =>
  [...props.model.events]
    .filter((e) => e.kind === 'penalty')
    .sort((a, b) => Number(a.id) - Number(b.id)),
)

const pkHomeShots = computed(() =>
  pkEvents.value.filter((e) => e.pkTeamId != null && e.pkTeamId === props.model.team1Id),
)

const pkAwayShots = computed(() =>
  pkEvents.value.filter((e) => e.pkTeamId != null && e.pkTeamId === props.model.team2Id),
)

const pkGridClass = computed(() =>
  transparentChrome.value ? 'grid-cols-1' : 'grid-cols-1 sm:grid-cols-2',
)

const nextTeamId = computed(() => {
  const n = pkEvents.value.length
  const first = props.model.pkFirstTeamId ?? props.model.team1Id
  const second = first === props.model.team1Id ? props.model.team2Id : props.model.team1Id
  return n % 2 === 0 ? first : second
})

const rosterHome = computed((): MatchPlayer[] =>
  props.model.homePlayers.filter((p) => p.status !== 'sent_off' && p.status !== 'subbed_out'),
)

const rosterAway = computed((): MatchPlayer[] =>
  props.model.awayPlayers.filter((p) => p.status !== 'sent_off' && p.status !== 'subbed_out'),
)

const pkHome = computed(() => props.model.breakdown.pk.home)
const pkAway = computed(() => props.model.breakdown.pk.away)

const pkDecided = computed(() => {
  const ev = pkEvents.value
  const n = ev.length
  if (n === 0) return false
  let tFirst = 0
  let tSecond = 0
  for (let i = 0; i < n; i++) {
    if (ev[i].penaltySuccess !== true) continue
    if (i % 2 === 0) tFirst++
    else tSecond++
  }
  const shotsFirst = Math.ceil(n / 2)
  const shotsSecond = Math.floor(n / 2)
  if (n < 10) {
    const remFirst = 5 - shotsFirst
    const remSecond = 5 - shotsSecond
    return tFirst > tSecond + remSecond || tSecond > tFirst + remFirst
  }
  return n % 2 === 0 && tFirst !== tSecond
})

function winnerLabelForTeam(teamId: number) {
  if (teamId === props.model.team1Id) return props.model.home.name
  if (teamId === props.model.team2Id) return props.model.away.name
  return ''
}

function maybeShowWinnerOverlay() {
  if (!pkDecided.value) return
  const ev = pkEvents.value
  let tFirst = 0
  let tSecond = 0
  for (let i = 0; i < ev.length; i++) {
    if (ev[i].penaltySuccess !== true) continue
    if (i % 2 === 0) tFirst++
    else tSecond++
  }
  const first = props.model.pkFirstTeamId ?? props.model.team1Id
  const second = first === props.model.team1Id ? props.model.team2Id : props.model.team1Id
  const wid = tFirst > tSecond ? first : second
  winnerName.value = winnerLabelForTeam(wid)
  showWinnerOverlay.value = true
  if (winTimer) window.clearTimeout(winTimer)
  winTimer = window.setTimeout(() => {
    showWinnerOverlay.value = false
    showFinishAsk.value = true
    winTimer = null
  }, 3000)
}

function shotRowLabel(row: MatchEvent) {
  if (row.penaltySuccess === true) return '⚽'
  return t('penalty.miss_result')
}

async function record(tid: number, success: boolean) {
  if (pkDecided.value || tid !== nextTeamId.value) return
  const pid = tid === props.model.team1Id ? homePlayerId.value : awayPlayerId.value
  if (!pid) return
  emit('pk-shot', { teamId: tid, playerId: Number(pid), success })
  if (tid === props.model.team1Id) homePlayerId.value = null
  else awayPlayerId.value = null
  await nextTick()
  maybeShowWinnerOverlay()
}

function confirmFinishMatch() {
  emit('finish-match')
  showFinishAsk.value = false
  emit('finished')
}

function laterFinish() {
  showFinishAsk.value = false
}

function canInputForTeam(tid: number) {
  return !props.readonly && !pkDecided.value && tid === nextTeamId.value
}

function inputRowClass(tid: number) {
  const active = canInputForTeam(tid)
  return active ? 'border-amber-500/45 bg-amber-500/10' : 'border-slate-600/50 bg-slate-900/30'
}
</script>

<template>
  <div class="mb-4 rounded-xl border border-violet-500/40 bg-violet-950/30 p-4 shadow-lg backdrop-blur">
    <h3 class="mb-3 text-sm font-semibold text-violet-200">{{ t('penalty.title') }}</h3>

    <div v-if="pkDecided" class="mb-2 rounded bg-emerald-500/15 px-2 py-1 text-center text-xs font-semibold text-emerald-300">
      {{ t('penalty.decided') }}
    </div>

    <div class="mb-4 grid gap-3" :class="pkGridClass">
      <!-- ホーム列（左／通常時は sm 以上で左） -->
      <div class="min-w-0 rounded-lg border border-slate-600/40 bg-slate-900/25 p-3">
        <div class="mb-2 border-b border-slate-600/40 pb-2">
          <div class="truncate text-sm font-semibold text-slate-100">{{ model.home.name }}</div>
          <div class="text-lg font-bold tabular-nums text-slate-50">{{ pkHome }}</div>
        </div>
        <ol class="max-h-40 space-y-1.5 overflow-y-auto text-xs">
          <li
            v-for="(row, idx) in pkHomeShots"
            :key="row.id"
            class="flex min-w-0 items-center gap-2 text-slate-200"
          >
            <span class="w-5 shrink-0 tabular-nums text-slate-500">{{ idx + 1 }}.</span>
            <span
              v-if="row.penaltySuccess === true"
              class="shrink-0 text-emerald-400"
              aria-hidden="true"
            >{{ shotRowLabel(row) }}</span>
            <span v-else class="shrink-0 font-bold text-rose-400">{{ shotRowLabel(row) }}</span>
            <span v-if="row.pkPlayerNumber != null" class="w-8 shrink-0 tabular-nums text-slate-500">#{{ row.pkPlayerNumber }}</span>
            <span class="min-w-0 truncate">{{ row.pkPlayerName ?? '—' }}</span>
          </li>
        </ol>
        <div v-if="!readonly && !pkDecided" class="mt-2 border-t border-slate-700/50 pt-2 text-xs">
          <span v-if="nextTeamId === model.team1Id" class="font-medium text-amber-300">{{ t('penalty.waiting_input') }}</span>
          <span v-else class="text-slate-600">—</span>
        </div>
      </div>

      <!-- アウェイ列 -->
      <div class="min-w-0 rounded-lg border border-slate-600/40 bg-slate-900/25 p-3">
        <div class="mb-2 border-b border-slate-600/40 pb-2">
          <div class="truncate text-sm font-semibold text-slate-100">{{ model.away.name }}</div>
          <div class="text-lg font-bold tabular-nums text-slate-50">{{ pkAway }}</div>
        </div>
        <ol class="max-h-40 space-y-1.5 overflow-y-auto text-xs">
          <li
            v-for="(row, idx) in pkAwayShots"
            :key="row.id"
            class="flex min-w-0 items-center gap-2 text-slate-200"
          >
            <span class="w-5 shrink-0 tabular-nums text-slate-500">{{ idx + 1 }}.</span>
            <span
              v-if="row.penaltySuccess === true"
              class="shrink-0 text-emerald-400"
              aria-hidden="true"
            >{{ shotRowLabel(row) }}</span>
            <span v-else class="shrink-0 font-bold text-rose-400">{{ shotRowLabel(row) }}</span>
            <span v-if="row.pkPlayerNumber != null" class="w-8 shrink-0 tabular-nums text-slate-500">#{{ row.pkPlayerNumber }}</span>
            <span class="min-w-0 truncate">{{ row.pkPlayerName ?? '—' }}</span>
          </li>
        </ol>
        <div v-if="!readonly && !pkDecided" class="mt-2 border-t border-slate-700/50 pt-2 text-xs">
          <span v-if="nextTeamId === model.team2Id" class="font-medium text-amber-300">{{ t('penalty.waiting_input') }}</span>
          <span v-else class="text-slate-600">—</span>
        </div>
      </div>
    </div>

    <div v-if="!readonly" class="space-y-3 border-t border-violet-500/20 pt-3">
      <div class="rounded-lg border p-3 transition-colors" :class="inputRowClass(model.team1Id)">
        <p class="mb-2 text-xs font-medium text-slate-200">{{ model.home.name }}</p>
        <select
          v-model="homePlayerId"
          :disabled="!canInputForTeam(model.team1Id)"
          class="mb-2 w-full rounded border border-slate-600 bg-slate-900 px-2 py-2 text-sm text-slate-100 disabled:opacity-40"
        >
          <option disabled value="">{{ t('penalty.pick_player') }}</option>
          <option v-for="p in rosterHome" :key="p.id" :value="p.id">{{ p.number }} {{ p.name }}</option>
        </select>
        <div class="flex flex-wrap gap-2">
          <button
            type="button"
            class="rounded-lg bg-emerald-600 px-3 py-2 text-sm font-semibold text-white disabled:opacity-40"
            :disabled="!canInputForTeam(model.team1Id) || !homePlayerId"
            @click="record(model.team1Id, true)"
          >
            {{ t('penalty.success') }}
          </button>
          <button
            type="button"
            class="rounded-lg bg-slate-600 px-3 py-2 text-sm font-semibold text-white disabled:opacity-40"
            :disabled="!canInputForTeam(model.team1Id) || !homePlayerId"
            @click="record(model.team1Id, false)"
          >
            {{ t('penalty.miss') }}
          </button>
        </div>
      </div>

      <div class="rounded-lg border p-3 transition-colors" :class="inputRowClass(model.team2Id)">
        <p class="mb-2 text-xs font-medium text-slate-200">{{ model.away.name }}</p>
        <select
          v-model="awayPlayerId"
          :disabled="!canInputForTeam(model.team2Id)"
          class="mb-2 w-full rounded border border-slate-600 bg-slate-900 px-2 py-2 text-sm text-slate-100 disabled:opacity-40"
        >
          <option disabled value="">{{ t('penalty.pick_player') }}</option>
          <option v-for="p in rosterAway" :key="p.id" :value="p.id">{{ p.number }} {{ p.name }}</option>
        </select>
        <div class="flex flex-wrap gap-2">
          <button
            type="button"
            class="rounded-lg bg-emerald-600 px-3 py-2 text-sm font-semibold text-white disabled:opacity-40"
            :disabled="!canInputForTeam(model.team2Id) || !awayPlayerId"
            @click="record(model.team2Id, true)"
          >
            {{ t('penalty.success') }}
          </button>
          <button
            type="button"
            class="rounded-lg bg-slate-600 px-3 py-2 text-sm font-semibold text-white disabled:opacity-40"
            :disabled="!canInputForTeam(model.team2Id) || !awayPlayerId"
            @click="record(model.team2Id, false)"
          >
            {{ t('penalty.miss') }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="showWinnerOverlay" :class="pkWinnerOverlayClass">
      <div class="text-sm font-semibold text-violet-200">{{ t('penalty.winner_title') }}</div>
      <div class="mt-2 text-3xl font-black text-white">{{ t('penalty.winner_line', { team: winnerName }) }}</div>
    </div>

    <div v-if="showFinishAsk && !readonly" :class="pkFinishAskOverlayClass">
      <div class="max-w-md rounded-xl border border-slate-600 bg-slate-900 p-6 shadow-2xl">
        <h3 class="mb-2 text-lg font-semibold text-slate-50">{{ t('penalty.finish_title') }}</h3>
        <p class="mb-4 text-sm text-slate-400">{{ t('match_finish.note') }}</p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="laterFinish">
            {{ t('penalty.finish_later') }}
          </button>
          <button type="button" class="rounded-lg bg-red-600 px-3 py-2 text-sm font-semibold text-white" @click="confirmFinishMatch">
            {{ t('dialog.yes') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
