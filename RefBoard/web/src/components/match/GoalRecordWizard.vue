<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../../composables/useNui'
import type { MatchDetailModel, MatchPlayer } from '../../types/match'
import PlayerSelectGrid from './PlayerSelectGrid.vue'

const props = defineProps<{
  open: boolean
  model: MatchDetailModel
}>()

const emit = defineEmits<{ 'update:open': [boolean]; recorded: [] }>()

const { t } = useI18n()
const { send, on } = useNui()

const step = ref(1)
const teamId = ref<number | null>(null)
const scorerId = ref<string | null>(null)
const assistId = ref<string | null>(null)

const teamPlayers = computed(() => {
  if (!teamId.value) return [] as MatchPlayer[]
  if (teamId.value === props.model.team1Id) return props.model.homePlayers
  return props.model.awayPlayers
})

const teamName = computed(() => {
  if (teamId.value === props.model.team1Id) return props.model.home.name
  if (teamId.value === props.model.team2Id) return props.model.away.name
  return ''
})

const scorer = computed(() => teamPlayers.value.find((p) => p.id === scorerId.value))
const assist = computed(() => teamPlayers.value.find((p) => p.id === assistId.value))

const summary = computed(() => {
  if (!teamName.value || !scorer.value) return ''
  const sn = `${scorer.value.number} ${scorer.value.name}`
  if (assist.value) {
    const an = `${assist.value.number} ${assist.value.name}`
    return t('goal_wizard.summary_with_assist', { team: teamName.value, scorer: sn, assist: an })
  }
  return t('goal_wizard.summary_goal', { team: teamName.value, scorer: sn })
})

function reset() {
  step.value = 1
  teamId.value = null
  scorerId.value = null
  assistId.value = null
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

function onKey(ev: KeyboardEvent) {
  if (!props.open) return
  if (ev.key === 'Escape') {
    if (step.value > 1 && step.value < 5) {
      if (window.confirm(t('goal_wizard.esc_confirm'))) {
        close()
      }
    } else {
      close()
    }
  }
}

onMounted(() => window.addEventListener('keydown', onKey))
onUnmounted(() => window.removeEventListener('keydown', onKey))

function nextFromTeam() {
  if (!teamId.value) return
  step.value = 2
}

function nextFromScorer() {
  if (!scorerId.value) return
  step.value = 3
}

function skipAssist() {
  assistId.value = null
  step.value = 4
}

function nextFromAssist() {
  step.value = 4
}

function back() {
  if (step.value > 1) step.value -= 1
}

async function record() {
  if (!teamId.value || !scorerId.value) return
  const assistNum = assistId.value ? Number(assistId.value) : null
  const un = on('refboard:score:goal:ack', (r: { ok?: boolean; error?: string }) => {
    un()
    if (r?.ok) {
      emit('recorded')
      close()
    }
  })
  await send('score_goal', {
    matchId: props.model.id,
    teamId: teamId.value,
    scorerPlayerId: Number(scorerId.value),
    assistPlayerId: assistNum,
  })
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[160] flex items-center justify-center bg-black/65 p-4 backdrop-blur-sm"
    @click.self="close"
  >
    <div class="max-h-[90vh] w-full max-w-lg overflow-hidden rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
      <div class="border-b border-slate-700 px-4 py-3 text-xs text-slate-500">
        {{ t('goal_wizard.breadcrumb') }}
      </div>
      <div class="max-h-[calc(90vh-8rem)] overflow-y-auto p-4">
        <Transition name="slide" mode="out-in">
          <div v-if="step === 1" key="s1" class="space-y-3">
            <h3 class="text-lg font-semibold text-slate-50">{{ t('goal_wizard.pick_team') }}</h3>
            <div class="grid gap-2">
              <button
                type="button"
                class="rounded-xl border py-4 text-center text-base font-semibold transition"
                :class="
                  teamId === model.team1Id
                    ? 'border-primary bg-primary/20 text-slate-50'
                    : 'border-slate-600 bg-slate-800 text-slate-100 hover:border-slate-500'
                "
                @click="teamId = model.team1Id"
              >
                {{ model.home.name }}
              </button>
              <button
                type="button"
                class="rounded-xl border py-4 text-center text-base font-semibold transition"
                :class="
                  teamId === model.team2Id
                    ? 'border-primary bg-primary/20 text-slate-50'
                    : 'border-slate-600 bg-slate-800 text-slate-100 hover:border-slate-500'
                "
                @click="teamId = model.team2Id"
              >
                {{ model.away.name }}
              </button>
            </div>
            <div class="flex justify-end pt-2">
              <button
                type="button"
                class="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-40"
                :disabled="!teamId"
                @click="nextFromTeam"
              >
                {{ t('match.next') }}
              </button>
            </div>
          </div>
          <div v-else-if="step === 2" key="s2" class="space-y-3">
            <h3 class="text-lg font-semibold text-slate-50">{{ t('goal_wizard.pick_scorer') }}</h3>
            <PlayerSelectGrid v-model="scorerId" :players="teamPlayers" />
            <div class="flex justify-between pt-2">
              <button type="button" class="text-sm text-slate-400 hover:text-slate-200" @click="back">{{ t('match.back') }}</button>
              <button
                type="button"
                class="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white disabled:opacity-40"
                :disabled="!scorerId"
                @click="nextFromScorer"
              >
                {{ t('match.next') }}
              </button>
            </div>
          </div>
          <div v-else-if="step === 3" key="s3" class="space-y-3">
            <h3 class="text-lg font-semibold text-slate-50">{{ t('goal_wizard.pick_assist') }}</h3>
            <PlayerSelectGrid v-model="assistId" :players="teamPlayers.filter((p) => p.id !== scorerId)" />
            <div class="flex flex-wrap justify-between gap-2 pt-2">
              <button type="button" class="text-sm text-slate-400 hover:text-slate-200" @click="back">{{ t('match.back') }}</button>
              <div class="flex gap-2">
                <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="skipAssist">
                  {{ t('goal_wizard.no_assist') }}
                </button>
                <button type="button" class="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white" @click="nextFromAssist">
                  {{ t('match.next') }}
                </button>
              </div>
            </div>
          </div>
          <div v-else-if="step === 4" key="s4" class="space-y-3">
            <h3 class="text-lg font-semibold text-slate-50">{{ t('goal_wizard.confirm') }}</h3>
            <p class="rounded-lg border border-slate-600 bg-slate-950/80 p-3 text-sm text-slate-200">{{ summary }}</p>
            <div class="flex justify-between pt-2">
              <button type="button" class="text-sm text-slate-400 hover:text-slate-200" @click="back">{{ t('match.back') }}</button>
              <button type="button" class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white" @click="record">
                {{ t('goal_wizard.submit') }}
              </button>
            </div>
          </div>
        </Transition>
      </div>
      <div class="flex justify-end border-t border-slate-700 px-4 py-2">
        <button type="button" class="text-xs text-slate-500 hover:text-slate-300" @click="close">{{ t('dialog.no') }}</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.slide-enter-active,
.slide-leave-active {
  transition:
    transform 0.18s ease,
    opacity 0.18s ease;
}
.slide-enter-from,
.slide-leave-to {
  transform: translateX(10px);
  opacity: 0;
}
</style>
