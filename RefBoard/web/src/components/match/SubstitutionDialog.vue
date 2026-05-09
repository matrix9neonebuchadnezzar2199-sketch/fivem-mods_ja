<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../../composables/useNui'
import type { MatchDetailModel, MatchPlayer } from '../../types/match'

const props = defineProps<{
  open: boolean
  model: MatchDetailModel
  /** 未指定なら model.clockMmSs（進行中は親から経過のライブ文字列を渡す） */
  matchTimeMmSs?: string
}>()

const emit = defineEmits<{ 'update:open': [boolean]; done: [] }>()

const { t } = useI18n()
const { send, on } = useNui()

const step = ref(1)
const teamId = ref<number | null>(null)
const outId = ref<string | null>(null)
const inId = ref<string | null>(null)

const teamPlayers = computed(() => {
  if (!teamId.value) return [] as MatchPlayer[]
  return teamId.value === props.model.team1Id ? props.model.homePlayers : props.model.awayPlayers
})

const outPlayers = computed(() => teamPlayers.value.filter((p) => p.status === 'playing'))
const inPlayers = computed(() => teamPlayers.value.filter((p) => p.status === 'bench'))

const outP = computed(() => teamPlayers.value.find((p) => p.id === outId.value))
const inP = computed(() => teamPlayers.value.find((p) => p.id === inId.value))

const teamName = computed(() => {
  if (teamId.value === props.model.team1Id) return props.model.home.name
  if (teamId.value === props.model.team2Id) return props.model.away.name
  return ''
})

const summary = computed(() => {
  if (!outP.value || !inP.value || !teamName.value) return ''
  return t('substitution.summary', {
    time: `${props.matchTimeMmSs ?? props.model.clockMmSs}`,
    team: teamName.value,
    outNo: outP.value.number,
    outName: outP.value.name,
    inNo: inP.value.number,
    inName: inP.value.name,
  })
})

function reset() {
  step.value = 1
  teamId.value = null
  outId.value = null
  inId.value = null
}

watch(
  () => props.open,
  (v) => {
    if (v) reset()
  },
)

function close() {
  emit('update:open', false)
}

async function submit() {
  if (!teamId.value || !outId.value || !inId.value) return
  const un = on('refboard:event:substitute:ack', (r: { ok?: boolean }) => {
    un()
    if (r?.ok) {
      emit('done')
      close()
    }
  })
  await send('event_substitute', {
    matchId: props.model.id,
    teamId: teamId.value,
    outPlayerId: Number(outId.value),
    inPlayerId: Number(inId.value),
  })
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[155] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
  >
    <div class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">{{ t('substitution.title') }}</h2>

      <div v-if="step === 1" class="space-y-2">
        <p class="text-sm text-slate-400">{{ t('substitution.pick_team') }}</p>
        <button
          type="button"
          class="w-full rounded-lg border border-slate-600 py-3 text-slate-100"
          @click="
            teamId = model.team1Id;
            step = 2
          "
        >
          {{ model.home.name }}
        </button>
        <button
          type="button"
          class="w-full rounded-lg border border-slate-600 py-3 text-slate-100"
          @click="
            teamId = model.team2Id;
            step = 2
          "
        >
          {{ model.away.name }}
        </button>
      </div>

      <div v-else-if="step === 2" class="space-y-2">
        <p class="text-sm text-amber-400">{{ t('substitution.pick_out') }}</p>
        <div class="grid max-h-48 grid-cols-2 gap-2 overflow-y-auto">
          <button
            v-for="p in outPlayers"
            :key="p.id"
            type="button"
            class="rounded-lg border-2 border-red-500/60 bg-red-950/40 px-2 py-2 text-left text-sm"
            :class="outId === p.id ? 'ring-2 ring-red-400' : ''"
            @click="outId = p.id"
          >
            <span class="font-mono text-red-300">{{ p.number }}</span> {{ p.name }}
          </button>
        </div>
        <div class="flex justify-between">
          <button type="button" class="text-sm text-slate-400" @click="step = 1">{{ t('match.back') }}</button>
          <button type="button" class="text-primary disabled:opacity-40" :disabled="!outId" @click="step = 3">
            {{ t('match.next') }}
          </button>
        </div>
      </div>

      <div v-else-if="step === 3" class="space-y-2">
        <p class="text-sm text-emerald-400">{{ t('substitution.pick_in') }}</p>
        <div class="grid max-h-48 grid-cols-2 gap-2 overflow-y-auto">
          <button
            v-for="p in inPlayers"
            :key="p.id"
            type="button"
            class="rounded-lg border-2 border-emerald-500/60 bg-emerald-950/30 px-2 py-2 text-left text-sm"
            :class="inId === p.id ? 'ring-2 ring-emerald-400' : ''"
            @click="inId = p.id"
          >
            <span class="font-mono text-emerald-300">{{ p.number }}</span> {{ p.name }}
          </button>
        </div>
        <div class="flex justify-between">
          <button type="button" class="text-sm text-slate-400" @click="step = 2">{{ t('match.back') }}</button>
          <button type="button" class="text-primary disabled:opacity-40" :disabled="!inId" @click="step = 4">
            {{ t('match.next') }}
          </button>
        </div>
      </div>

      <div v-else class="space-y-3">
        <p class="rounded border border-slate-600 bg-slate-950/80 p-3 text-sm text-slate-200">{{ summary }}</p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded border border-slate-600 px-3 py-2 text-sm" @click="step = 3">
            {{ t('match.back') }}
          </button>
          <button type="button" class="rounded bg-primary px-3 py-2 text-sm font-semibold text-white" @click="submit">
            {{ t('substitution.submit') }}
          </button>
        </div>
      </div>

      <button type="button" class="mt-4 text-xs text-slate-500" @click="close">{{ t('dialog.no') }}</button>
    </div>
  </div>
</template>
