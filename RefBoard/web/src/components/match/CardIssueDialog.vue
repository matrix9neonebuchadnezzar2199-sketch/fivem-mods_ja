<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from '../../composables/useToast'
import type { MatchDetailModel, MatchPlayer } from '../../types/match'
import { resolveMatchPlayerRowId } from '../../utils/matchPlayerRowId'
import type { ParsedMinute } from '../../utils/matchTime'
import MinuteInput from './MinuteInput.vue'
import { useDialogOverlay } from '../../composables/useDialogOverlay'

const { overlayRootClass } = useDialogOverlay()
const cardIssueOverlayClass = overlayRootClass('z-[155]', 'bg-black/60 backdrop-blur-sm')

const props = defineProps<{
  open: boolean
  model: MatchDetailModel
  suggestedEventTime: ParsedMinute
  /** 親からプリセット（メニューから黄/赤を選んだ場合） */
  presetKind?: 'yellow' | 'red' | null
}>()

const emit = defineEmits<{
  'update:open': [boolean]
  done: []
  'issue-card': [
    {
      teamId: number
      playerId: number
      cardType: 'yellow_card' | 'red_card'
      ejectionReason?: 'second_yellow' | 'red_card'
      eventTime: ParsedMinute | null
    },
  ]
}>()

const { t } = useI18n()
const { push: toast } = useToast()

const step = ref(1)
const teamId = ref<number | null>(null)
const playerId = ref<string | null>(null)
const cardKind = ref<'yellow' | 'red' | null>(null)
const showSecondYellow = ref(false)
/** 2枚目黄から赤に切り替えた場合のみ true（ejectionReason 用） */
const redFromSecondYellow = ref(false)
const eventTime = ref<ParsedMinute | null>(null)

const isPkPhase = computed(() => props.model.serverHalf === 'pk')

const teamPlayers = computed(() => {
  if (!teamId.value) return [] as MatchPlayer[]
  return teamId.value === props.model.team1Id ? props.model.homePlayers : props.model.awayPlayers
})

/** 交代で出た選手は ui_status が bench のままになり得るが is_active=1 のためサーバでは登録可 */
const fieldPlayers = computed(() =>
  teamPlayers.value.filter((p) => p.status !== 'sent_off' && p.status !== 'subbed_out'),
)

const sel = computed(() => teamPlayers.value.find((p) => p.id === playerId.value))

watch(
  () => props.open,
  (v) => {
    if (v) {
      step.value = 1
      teamId.value = null
      playerId.value = null
      cardKind.value = null
      showSecondYellow.value = false
      redFromSecondYellow.value = false
      eventTime.value = null
    }
  },
)

function selectTeamForCard(tid: number) {
  teamId.value = tid
  step.value = 2
}

function selectPlayer(id: string) {
  playerId.value = id
}

function goStep1() {
  step.value = 1
}

function goStep2() {
  step.value = 2
}

function afterPlayerSelected() {
  const pk = props.presetKind
  if (pk === 'red') {
    cardKind.value = 'red'
    redFromSecondYellow.value = false
    step.value = 4
    return
  }
  if (pk === 'yellow') {
    if ((sel.value?.yellowCards ?? 0) >= 1) {
      showSecondYellow.value = true
      return
    }
    cardKind.value = 'yellow'
    step.value = 4
    return
  }
  step.value = 3
}

function close() {
  emit('update:open', false)
}

function pickYellow() {
  if (!sel.value) return
  if ((sel.value.yellowCards ?? 0) >= 1) {
    showSecondYellow.value = true
    return
  }
  redFromSecondYellow.value = false
  cardKind.value = 'yellow'
  step.value = 4
}

function pickRedDirect() {
  redFromSecondYellow.value = false
  cardKind.value = 'red'
  step.value = 4
}

function confirmSecondYellowAsRed() {
  showSecondYellow.value = false
  redFromSecondYellow.value = true
  cardKind.value = 'red'
  step.value = 4
}

function goBackFromConfirm() {
  cardKind.value = null
  step.value = props.presetKind ? 2 : 3
}

function record() {
  if (!teamId.value || !playerId.value || !cardKind.value) {
    toast(t('toast.card_issue_incomplete'), 'error', 5000)
    return
  }
  const pid = resolveMatchPlayerRowId(playerId.value)
  if (pid == null || pid <= 0) {
    toast(t('toast.card_issue_incomplete'), 'error', 5000)
    return
  }
  emit('issue-card', {
    teamId: teamId.value,
    playerId: pid,
    cardType: cardKind.value === 'yellow' ? 'yellow_card' : 'red_card',
    ejectionReason:
      cardKind.value === 'red' ? (redFromSecondYellow.value ? 'second_yellow' : 'red_card') : undefined,
    eventTime: eventTime.value,
  })
  emit('done')
  close()
}
</script>

<template>
  <div v-if="open" :class="cardIssueOverlayClass">
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">{{ t('card.title') }}</h2>

      <div v-if="step === 1" class="space-y-2">
        <p class="text-sm text-slate-400">{{ t('card.pick_team') }}</p>
        <button
          type="button"
          class="w-full rounded-lg border border-slate-600 py-2 text-slate-100"
          @click="selectTeamForCard(model.team1Id)"
        >
          {{ model.home.name }}
        </button>
        <button
          type="button"
          class="w-full rounded-lg border border-slate-600 py-2 text-slate-100"
          @click="selectTeamForCard(model.team2Id)"
        >
          {{ model.away.name }}
        </button>
      </div>

      <div v-else-if="step === 2" class="space-y-2">
        <p class="text-sm text-slate-400">{{ t('card.pick_player') }}</p>
        <div class="grid max-h-48 grid-cols-2 gap-2 overflow-y-auto">
          <button
            v-for="p in fieldPlayers"
            :key="p.id"
            type="button"
            class="rounded border border-slate-600 px-2 py-2 text-left text-sm text-slate-100"
            :class="playerId === p.id ? 'border-primary ring-1 ring-primary' : ''"
            @click="selectPlayer(p.id)"
          >
            {{ p.number }} {{ p.name }}
          </button>
        </div>
        <div class="flex justify-between">
          <button type="button" class="text-sm text-slate-400" @click="goStep1">
            {{ t('match.back') }}
          </button>
          <button type="button" class="text-primary disabled:opacity-40" :disabled="!playerId" @click="afterPlayerSelected">
            {{ t('match.next') }}
          </button>
        </div>
      </div>

      <div v-else-if="step === 3" class="space-y-2">
        <p class="text-sm text-slate-300">{{ sel?.name }}</p>
        <button
          type="button"
          class="w-full rounded-lg bg-amber-600/80 py-3 font-semibold text-white drop-shadow-sm"
          @click="pickYellow"
        >
          {{ t('card.yellow') }}
        </button>
        <button type="button" class="w-full rounded-lg bg-red-700 py-3 font-semibold text-white" @click="pickRedDirect">
          {{ t('card.red') }}
        </button>
        <button type="button" class="text-sm text-slate-400" @click="goStep2">{{ t('match.back') }}</button>
      </div>

      <div v-else class="space-y-2">
        <p class="text-sm text-slate-200">
          {{
            cardKind === 'yellow'
              ? t('card.confirm_yellow', { name: sel?.name ?? '' })
              : t('card.confirm_red', { name: sel?.name ?? '' })
          }}
        </p>
        <div v-if="!isPkPhase">
          <p class="mb-1 text-xs text-slate-500">{{ t('card.event_time_label') }}</p>
          <MinuteInput v-model="eventTime" :suggested="suggestedEventTime" />
        </div>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded border border-slate-600 px-3 py-2 text-sm" @click="goBackFromConfirm">
            {{ t('match.back') }}
          </button>
          <button type="button" class="rounded bg-primary px-3 py-2 text-sm font-semibold text-white" @click="record">
            {{ t('card.submit') }}
          </button>
        </div>
      </div>

      <div
        v-if="showSecondYellow"
        class="mt-4 rounded border border-amber-500/50 bg-amber-500/10 p-3 text-sm text-amber-100"
      >
        <p class="mb-2">{{ t('card.second_yellow_body') }}</p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded border px-2 py-1 text-xs" @click="showSecondYellow = false">
            {{ t('dialog.no') }}
          </button>
          <button type="button" class="rounded bg-red-600 px-2 py-1 text-xs font-semibold" @click="confirmSecondYellowAsRed">
            {{ t('card.second_yellow_ok') }}
          </button>
        </div>
      </div>

      <button type="button" class="mt-4 text-xs text-slate-500" @click="close">{{ t('dialog.no') }}</button>
    </div>
  </div>
</template>
