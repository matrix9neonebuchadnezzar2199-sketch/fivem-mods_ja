<script setup lang="ts">
import { computed, nextTick, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import type { MatchDetailModel, MatchPlayer } from '../../types/match'
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

const playerId = ref<string | null>(null)

const showWinnerOverlay = ref(false)
const showFinishAsk = ref(false)
const winnerName = ref('')

let winTimer: number | null = null

const pkEvents = computed(() =>
  [...props.model.events]
    .filter((e) => e.kind === 'penalty')
    .sort((a, b) => Number(a.id) - Number(b.id)),
)

const nextTeamId = computed(() => {
  const n = pkEvents.value.length
  const first = props.model.pkFirstTeamId ?? props.model.team1Id
  const second = first === props.model.team1Id ? props.model.team2Id : props.model.team1Id
  return n % 2 === 0 ? first : second
})

const nextTeamName = computed(() => {
  if (nextTeamId.value === props.model.team1Id) return props.model.home.name
  if (nextTeamId.value === props.model.team2Id) return props.model.away.name
  return ''
})

const roster = computed((): MatchPlayer[] => {
  const tid = nextTeamId.value
  const list = tid === props.model.team1Id ? props.model.homePlayers : props.model.awayPlayers
  return list.filter((p) => p.status !== 'sent_off' && p.status !== 'subbed_out')
})

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

async function record(success: boolean) {
  const tid = nextTeamId.value
  const pid = playerId.value
  if (!tid || !pid) return
  emit('pk-shot', { teamId: tid, playerId: Number(pid), success })
  playerId.value = null
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
</script>

<template>
  <div class="mb-4 rounded-xl border border-violet-500/40 bg-violet-950/30 p-4 shadow-lg backdrop-blur">
    <h3 class="mb-2 text-sm font-semibold text-violet-200">{{ t('penalty.title') }}</h3>
    <div class="mb-3 flex flex-wrap items-center gap-4 text-lg font-bold text-slate-50">
      <span>{{ model.home.short }} {{ pkHome }}</span>
      <span class="text-slate-500">—</span>
      <span>{{ pkAway }} {{ model.away.short }}</span>
      <span v-if="pkDecided" class="rounded bg-emerald-500/20 px-2 py-0.5 text-xs font-semibold text-emerald-300">
        {{ t('penalty.decided') }}
      </span>
    </div>

    <ol class="mb-4 max-h-40 list-decimal space-y-1 overflow-y-auto pl-5 text-xs text-slate-300">
      <li v-for="e in pkEvents" :key="e.id">{{ e.text }}</li>
    </ol>

    <div v-if="!readonly" class="space-y-2 border-t border-violet-500/20 pt-3">
      <p class="text-xs text-violet-200/90">{{ t('penalty.next_kicker', { team: nextTeamName }) }}</p>
      <select
        v-model="playerId"
        class="w-full rounded border border-slate-600 bg-slate-900 px-2 py-2 text-sm text-slate-100"
      >
        <option disabled value="">{{ t('penalty.pick_player') }}</option>
        <option v-for="p in roster" :key="p.id" :value="p.id">{{ p.number }} {{ p.name }}</option>
      </select>
      <div class="flex flex-wrap gap-2">
        <button
          type="button"
          class="rounded-lg bg-emerald-600 px-3 py-2 text-sm font-semibold text-white disabled:opacity-40"
          :disabled="!playerId"
          @click="record(true)"
        >
          {{ t('penalty.success') }}
        </button>
        <button
          type="button"
          class="rounded-lg bg-slate-600 px-3 py-2 text-sm font-semibold text-white disabled:opacity-40"
          :disabled="!playerId"
          @click="record(false)"
        >
          {{ t('penalty.miss') }}
        </button>
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
