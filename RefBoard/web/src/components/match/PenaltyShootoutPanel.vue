<script setup lang="ts">
import { computed, nextTick, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import type { MatchDetailModel, MatchEvent, MatchPlayer } from '../../types/match'
import { useDialogOverlay } from '../../composables/useDialogOverlay'
const { overlayRootClassFlexCol, overlayRootClass } = useDialogOverlay()
const pkWinnerOverlayClass = overlayRootClassFlexCol('z-[400]', 'bg-black/80')
const pkFinishAskOverlayClass = overlayRootClass('z-[410]', 'bg-black/60')

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

/** 先攻列・後攻列の選手選択（列は pkFirst と一致し、ホーム／アウェイとは限らない） */
const firstKickerPlayerId = ref<string | null>(null)
const secondKickerPlayerId = ref<string | null>(null)

const showWinnerOverlay = ref(false)
const showFinishAsk = ref(false)
const winnerName = ref('')

let winTimer: number | null = null

const pkEvents = computed(() =>
  [...props.model.events]
    .filter((e) => e.kind === 'penalty')
    .sort((a, b) => Number(a.id) - Number(b.id)),
)

const firstTeamId = computed(() => props.model.pkFirstTeamId ?? props.model.team1Id)

const secondTeamId = computed(() =>
  firstTeamId.value === props.model.team1Id ? props.model.team2Id : props.model.team1Id,
)

const firstTeamName = computed(() =>
  firstTeamId.value === props.model.team1Id ? props.model.home.name : props.model.away.name,
)

const secondTeamName = computed(() =>
  secondTeamId.value === props.model.team1Id ? props.model.home.name : props.model.away.name,
)

const pkColFirstShots = computed(() =>
  pkEvents.value.filter((e) => e.pkTeamId != null && e.pkTeamId === firstTeamId.value),
)

const pkColSecondShots = computed(() =>
  pkEvents.value.filter((e) => e.pkTeamId != null && e.pkTeamId === secondTeamId.value),
)

const pkFirstScore = computed(() =>
  firstTeamId.value === props.model.team1Id ? pkHome.value : pkAway.value,
)

const pkSecondScore = computed(() =>
  secondTeamId.value === props.model.team1Id ? pkHome.value : pkAway.value,
)

const displayRows = computed(() =>
  Math.max(5, pkColFirstShots.value.length, pkColSecondShots.value.length),
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

const rosterFirstKicker = computed((): MatchPlayer[] =>
  firstTeamId.value === props.model.team1Id ? rosterHome.value : rosterAway.value,
)

const rosterSecondKicker = computed((): MatchPlayer[] =>
  secondTeamId.value === props.model.team1Id ? rosterHome.value : rosterAway.value,
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
  const pid = tid === firstTeamId.value ? firstKickerPlayerId.value : secondKickerPlayerId.value
  if (!pid) return
  emit('pk-shot', { teamId: tid, playerId: Number(pid), success })
  if (tid === firstTeamId.value) firstKickerPlayerId.value = null
  else secondKickerPlayerId.value = null
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

    <div
      class="mb-4 grid max-h-[min(24rem,55vh)] grid-cols-[2.25rem_minmax(0,1fr)_minmax(0,1fr)] gap-x-2 gap-y-1 overflow-y-auto text-xs"
    >
      <div class="sticky top-0 z-[1] bg-violet-950/95 pb-1 font-semibold text-slate-400">{{ t('penalty.column_index') }}</div>
      <div class="sticky top-0 z-[1] min-w-0 bg-violet-950/95 pb-1 font-semibold text-slate-200">
        <span class="truncate">{{ firstTeamName }}</span>
        <span class="text-slate-500"> · {{ t('penalty.kicks_first') }}</span>
      </div>
      <div class="sticky top-0 z-[1] min-w-0 bg-violet-950/95 pb-1 font-semibold text-slate-200">
        <span class="truncate">{{ secondTeamName }}</span>
        <span class="text-slate-500"> · {{ t('penalty.kicks_second') }}</span>
      </div>

      <div class="tabular-nums text-slate-600"></div>
      <div class="text-lg font-bold tabular-nums text-slate-50">{{ pkFirstScore }}</div>
      <div class="text-lg font-bold tabular-nums text-slate-50">{{ pkSecondScore }}</div>

      <template v-for="ri in displayRows" :key="ri">
        <div class="border-t border-slate-700/40 pt-1 tabular-nums text-slate-500">{{ ri }}.</div>
        <div
          class="min-w-0 border-t border-slate-700/40 pt-1"
          :class="pkColFirstShots[ri - 1] ? 'text-slate-200' : 'text-slate-600'"
        >
          <template v-if="pkColFirstShots[ri - 1]">
            <div class="flex min-w-0 flex-wrap items-center gap-1.5">
              <span
                v-if="pkColFirstShots[ri - 1]!.penaltySuccess === true"
                class="shrink-0 text-emerald-400"
                aria-hidden="true"
              >{{ shotRowLabel(pkColFirstShots[ri - 1]!) }}</span>
              <span v-else class="shrink-0 font-bold text-rose-400">{{ shotRowLabel(pkColFirstShots[ri - 1]!) }}</span>
              <span
                v-if="pkColFirstShots[ri - 1]!.pkPlayerNumber != null"
                class="shrink-0 tabular-nums text-slate-500"
              >#{{ pkColFirstShots[ri - 1]!.pkPlayerNumber }}</span>
              <span class="min-w-0 truncate">{{ pkColFirstShots[ri - 1]!.pkPlayerName ?? '—' }}</span>
            </div>
          </template>
          <template v-else>—</template>
        </div>
        <div
          class="min-w-0 border-t border-slate-700/40 pt-1"
          :class="pkColSecondShots[ri - 1] ? 'text-slate-200' : 'text-slate-600'"
        >
          <template v-if="pkColSecondShots[ri - 1]">
            <div class="flex min-w-0 flex-wrap items-center gap-1.5">
              <span
                v-if="pkColSecondShots[ri - 1]!.penaltySuccess === true"
                class="shrink-0 text-emerald-400"
                aria-hidden="true"
              >{{ shotRowLabel(pkColSecondShots[ri - 1]!) }}</span>
              <span v-else class="shrink-0 font-bold text-rose-400">{{ shotRowLabel(pkColSecondShots[ri - 1]!) }}</span>
              <span
                v-if="pkColSecondShots[ri - 1]!.pkPlayerNumber != null"
                class="shrink-0 tabular-nums text-slate-500"
              >#{{ pkColSecondShots[ri - 1]!.pkPlayerNumber }}</span>
              <span class="min-w-0 truncate">{{ pkColSecondShots[ri - 1]!.pkPlayerName ?? '—' }}</span>
            </div>
          </template>
          <template v-else>—</template>
        </div>
      </template>

      <div class="border-t border-slate-700/50 pt-2 text-slate-600"></div>
      <div class="border-t border-slate-700/50 pt-2">
        <div
          v-if="!readonly && !pkDecided && nextTeamId === firstTeamId"
          class="mb-1 text-[0.625rem] font-medium text-amber-300"
        >
          {{ t('penalty.waiting_input') }}
        </div>
        <div
          v-if="!readonly"
          class="rounded-lg border p-2 transition-colors"
          :class="inputRowClass(firstTeamId)"
        >
          <select
            v-model="firstKickerPlayerId"
            :disabled="!canInputForTeam(firstTeamId)"
            class="mb-2 w-full rounded border border-slate-600 bg-slate-900 px-2 py-1.5 text-xs text-slate-100 disabled:opacity-40"
          >
            <option disabled value="">{{ t('penalty.pick_player') }}</option>
            <option v-for="p in rosterFirstKicker" :key="p.id" :value="p.id">{{ p.number }} {{ p.name }}</option>
          </select>
          <div class="flex flex-wrap gap-1.5">
            <button
              type="button"
              class="rounded-md bg-emerald-600 px-2 py-1.5 text-xs font-semibold text-white disabled:opacity-40"
              :disabled="!canInputForTeam(firstTeamId) || !firstKickerPlayerId"
              @click="record(firstTeamId, true)"
            >
              {{ t('penalty.success') }}
            </button>
            <button
              type="button"
              class="rounded-md bg-slate-600 px-2 py-1.5 text-xs font-semibold text-white disabled:opacity-40"
              :disabled="!canInputForTeam(firstTeamId) || !firstKickerPlayerId"
              @click="record(firstTeamId, false)"
            >
              {{ t('penalty.miss') }}
            </button>
          </div>
        </div>
      </div>
      <div class="border-t border-slate-700/50 pt-2">
        <div
          v-if="!readonly && !pkDecided && nextTeamId === secondTeamId"
          class="mb-1 text-[0.625rem] font-medium text-amber-300"
        >
          {{ t('penalty.waiting_input') }}
        </div>
        <div
          v-if="!readonly"
          class="rounded-lg border p-2 transition-colors"
          :class="inputRowClass(secondTeamId)"
        >
          <select
            v-model="secondKickerPlayerId"
            :disabled="!canInputForTeam(secondTeamId)"
            class="mb-2 w-full rounded border border-slate-600 bg-slate-900 px-2 py-1.5 text-xs text-slate-100 disabled:opacity-40"
          >
            <option disabled value="">{{ t('penalty.pick_player') }}</option>
            <option v-for="p in rosterSecondKicker" :key="p.id" :value="p.id">{{ p.number }} {{ p.name }}</option>
          </select>
          <div class="flex flex-wrap gap-1.5">
            <button
              type="button"
              class="rounded-md bg-emerald-600 px-2 py-1.5 text-xs font-semibold text-white disabled:opacity-40"
              :disabled="!canInputForTeam(secondTeamId) || !secondKickerPlayerId"
              @click="record(secondTeamId, true)"
            >
              {{ t('penalty.success') }}
            </button>
            <button
              type="button"
              class="rounded-md bg-slate-600 px-2 py-1.5 text-xs font-semibold text-white disabled:opacity-40"
              :disabled="!canInputForTeam(secondTeamId) || !secondKickerPlayerId"
              @click="record(secondTeamId, false)"
            >
              {{ t('penalty.miss') }}
            </button>
          </div>
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
