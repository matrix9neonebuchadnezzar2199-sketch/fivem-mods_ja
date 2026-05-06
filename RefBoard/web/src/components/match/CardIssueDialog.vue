<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../../composables/useNui'
import type { MatchDetailModel, MatchPlayer } from '../../types/match'

const props = defineProps<{
  open: boolean
  model: MatchDetailModel
  /** 親からプリセット（メニューから黄/赤を選んだ場合） */
  presetKind?: 'yellow' | 'red' | null
}>()

const emit = defineEmits<{ 'update:open': [boolean]; done: [] }>()

const { t } = useI18n()
const { send, on } = useNui()

const step = ref(1)
const teamId = ref<number | null>(null)
const playerId = ref<string | null>(null)
const cardKind = ref<'yellow' | 'red' | null>(null)
const showSecondYellow = ref(false)
/** 2枚目黄から赤に切り替えた場合のみ true（ejectionReason 用） */
const redFromSecondYellow = ref(false)

const teamPlayers = computed(() => {
  if (!teamId.value) return [] as MatchPlayer[]
  return teamId.value === props.model.team1Id ? props.model.homePlayers : props.model.awayPlayers
})

const fieldPlayers = computed(() => teamPlayers.value.filter((p) => p.status === 'playing'))

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
    }
  },
)

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

function confirmSecondYellowAsRed() {
  showSecondYellow.value = false
  redFromSecondYellow.value = true
  cardKind.value = 'red'
  step.value = 4
}

async function record() {
  if (!teamId.value || !playerId.value || !cardKind.value) return
  const un = on('refboard:event:issue_card:ack', (r: { ok?: boolean; error?: string }) => {
    un()
    if (r?.ok) {
      emit('done')
      close()
      return
    }
    if (r?.error === 'second_yellow_confirm') {
      showSecondYellow.value = true
    }
  })
  await send('event_issue_card', {
    matchId: props.model.id,
    teamId: teamId.value,
    playerId: Number(playerId.value),
    cardType: cardKind.value === 'yellow' ? 'yellow_card' : 'red_card',
    ejectionReason:
      cardKind.value === 'red' ? (redFromSecondYellow.value ? 'second_yellow' : 'red_card') : undefined,
  })
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[155] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
    @click.self="close"
  >
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">{{ t('card.title') }}</h2>

      <div v-if="step === 1" class="space-y-2">
        <p class="text-sm text-slate-400">{{ t('card.pick_team') }}</p>
        <button
          type="button"
          class="w-full rounded-lg border border-slate-600 py-2 text-slate-100"
          @click="
            teamId = model.team1Id;
            step = 2
          "
        >
          {{ model.home.name }}
        </button>
        <button
          type="button"
          class="w-full rounded-lg border border-slate-600 py-2 text-slate-100"
          @click="
            teamId = model.team2Id;
            step = 2
          "
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
            @click="playerId = p.id"
          >
            {{ p.number }} {{ p.name }}
          </button>
        </div>
        <div class="flex justify-between">
          <button type="button" class="text-sm text-slate-400" @click="step = 1">
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
        <button
          type="button"
          class="w-full rounded-lg bg-red-700 py-3 font-semibold text-white"
          @click="
            redFromSecondYellow = false;
            cardKind = 'red';
            step = 4
          "
        >
          {{ t('card.red') }}
        </button>
        <button type="button" class="text-sm text-slate-400" @click="step = 2">{{ t('match.back') }}</button>
      </div>

      <div v-else class="space-y-2">
        <p class="text-sm text-slate-200">
          {{
            cardKind === 'yellow'
              ? t('card.confirm_yellow', { name: sel?.name ?? '' })
              : t('card.confirm_red', { name: sel?.name ?? '' })
          }}
        </p>
        <div class="flex justify-end gap-2">
          <button
            type="button"
            class="rounded border border-slate-600 px-3 py-2 text-sm"
            @click="
              cardKind = null;
              step = presetKind ? 2 : 3
            "
          >
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
