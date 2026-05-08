<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../../composables/useNui'
import type { MatchDetailModel, MatchUiStatus } from '../../types/match'

const props = withDefaults(
  defineProps<{
    model: MatchDetailModel
    readonly: boolean
    /** 編集者フォーカスがこのカード上にある（閲覧者向けバッジ） */
    editorHere: boolean
    embed?: boolean
  }>(),
  { embed: false },
)

const { t } = useI18n()
const { send } = useNui()

const showPkConfirm = ref(false)
const pkFirstTeamId = ref<number>(1)

const options = computed((): { value: MatchUiStatus; labelKey: string }[] => {
  const base: { value: MatchUiStatus; labelKey: string }[] = [
    { value: 'pre_match', labelKey: 'match_status.pre_match' },
    { value: 'first_half', labelKey: 'match_status.first_half' },
    { value: 'halftime', labelKey: 'match_status.halftime' },
    { value: 'second_half', labelKey: 'match_status.second_half' },
    { value: 'extra_time', labelKey: 'match_status.extra_time' },
    { value: 'penalties', labelKey: 'match_status.penalties' },
    { value: 'full_time', labelKey: 'match_status.full_time' },
  ]
  if (props.model.dbStatus === 'finished' || props.model.dbStatus === 'cancelled') {
    return base
  }
  return base.filter((o) => o.value !== 'full_time')
})

const showExtraBreakdown = computed(() => props.model.serverHalf === 'et')
const showPkBreakdown = computed(() => props.model.serverHalf === 'pk')

function uiToHalf(u: MatchUiStatus): string | null {
  switch (u) {
    case 'pre_match':
    case 'first_half':
      return '1st'
    case 'halftime':
      return 'halftime'
    case 'second_half':
      return '2nd'
    case 'extra_time':
      return 'et'
    case 'penalties':
      return 'pk'
    default:
      return null
  }
}

function onSelectChange(ev: Event) {
  const el = ev.target as HTMLSelectElement
  const v = el.value as MatchUiStatus
  if (props.readonly) return
  if (v === 'full_time') {
    el.value = props.model.uiStatus
    return
  }
  if (v === 'penalties') {
    pkFirstTeamId.value = props.model.pkFirstTeamId ?? props.model.team1Id
    showPkConfirm.value = true
    el.value = props.model.uiStatus
    return
  }
  const half = uiToHalf(v)
  if (!half) {
    el.value = props.model.uiStatus
    return
  }
  void send('match_set_half', { matchId: props.model.id, half })
}

function cancelPk() {
  showPkConfirm.value = false
}

function confirmPk() {
  showPkConfirm.value = false
  void send('match_set_half', {
    matchId: props.model.id,
    half: 'pk',
    pkFirstTeamId: pkFirstTeamId.value,
  })
}
</script>

<template>
  <div
    :class="
      props.embed
        ? ''
        : 'rounded-lg border border-slate-700/60 bg-slate-800/50 p-4 shadow-sm backdrop-blur-md'
    "
  >
    <div v-if="!props.embed" class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">{{ t('match_status.title') }}</h3>
      <span
        v-if="editorHere"
        class="rounded bg-emerald-500/20 px-2 py-0.5 text-[0.625rem] font-semibold text-emerald-300"
      >
        {{ t('match_status.editing_here') }}
      </span>
    </div>
    <select
      class="mb-4 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-2 text-sm text-slate-100"
      :value="model.uiStatus"
      :disabled="readonly"
      @change="onSelectChange"
    >
      <option v-for="o in options" :key="o.value" :value="o.value">{{ t(o.labelKey) }}</option>
    </select>
    <div class="grid grid-cols-2 gap-2 text-center text-xs lg:grid-cols-3">
      <div class="rounded border border-slate-600 bg-slate-900/50 p-2">
        <div class="text-slate-500">{{ t('match_status.half1') }}</div>
        <div class="text-lg font-bold text-slate-100">
          {{ model.breakdown.firstHalf.home }}-{{ model.breakdown.firstHalf.away }}
        </div>
      </div>
      <div class="rounded border border-slate-600 bg-slate-900/50 p-2">
        <div class="text-slate-500">{{ t('match_status.half2') }}</div>
        <div class="text-lg font-bold text-slate-100">
          {{ model.breakdown.secondHalf.home }}-{{ model.breakdown.secondHalf.away }}
        </div>
      </div>
      <div
        v-if="showExtraBreakdown"
        class="rounded border border-slate-600 bg-slate-900/50 p-2"
      >
        <div class="text-slate-500">{{ t('match_status.et') }}</div>
        <div class="text-lg font-bold text-slate-100">{{ model.breakdown.extra.home }}-{{ model.breakdown.extra.away }}</div>
      </div>
      <div
        v-if="showPkBreakdown"
        class="rounded border border-amber-500/30 bg-amber-500/5 p-2"
      >
        <div class="text-slate-500">{{ t('match_status.pk') }}</div>
        <div class="text-lg font-bold text-amber-100">{{ model.breakdown.pk.home }}-{{ model.breakdown.pk.away }}</div>
      </div>
    </div>

    <div
      v-if="showPkConfirm"
      class="fixed inset-0 z-[160] flex items-center justify-center bg-black/55 p-4"
      @click.self="cancelPk"
    >
      <div class="max-w-md rounded-xl border border-slate-600 bg-slate-900 p-5 shadow-xl">
        <h4 class="mb-2 font-semibold text-slate-50">{{ t('match_status.pk_confirm_title') }}</h4>
        <p class="mb-2 text-sm text-slate-300">
          {{ t('match_status.pk_confirm_score', { h: model.score.home, a: model.score.away }) }}
        </p>
        <p class="mb-3 text-xs text-slate-500">{{ t('match_status.pk_confirm_note') }}</p>
        <label class="mb-3 block text-xs text-slate-400">
          {{ t('match_status.pk_first') }}
          <select v-model.number="pkFirstTeamId" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-sm">
            <option :value="model.team1Id">{{ model.home.name }}</option>
            <option :value="model.team2Id">{{ model.away.name }}</option>
          </select>
        </label>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded border border-slate-600 px-3 py-2 text-sm" @click="cancelPk">
            {{ t('dialog.no') }}
          </button>
          <button type="button" class="rounded bg-primary px-3 py-2 text-sm font-semibold text-white" @click="confirmPk">
            {{ t('match_status.pk_start') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
