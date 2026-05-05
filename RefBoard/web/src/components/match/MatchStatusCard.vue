<script setup lang="ts">
import type { MatchDetailModel, MatchUiStatus } from '../../types/match'

defineProps<{
  model: MatchDetailModel
  readonly: boolean
}>()

const options: { value: MatchUiStatus; label: string }[] = [
  { value: 'pre_match', label: '試合前' },
  { value: 'first_half', label: '前半' },
  { value: 'halftime', label: 'ハーフタイム' },
  { value: 'second_half', label: '後半' },
  { value: 'extra_time', label: '延長' },
  { value: 'penalties', label: 'PK' },
  { value: 'full_time', label: '試合終了' },
]
</script>

<template>
  <div class="rounded-lg border border-slate-700 bg-slate-800/80 p-4 shadow-sm backdrop-blur">
    <div class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">試合ステータス</h3>
      <span class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">編集中</span>
    </div>
    <select
      v-model="model.uiStatus"
      class="mb-4 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-2 text-sm text-slate-100"
      :disabled="readonly"
    >
      <option v-for="o in options" :key="o.value" :value="o.value">{{ o.label }}</option>
    </select>
    <div class="grid grid-cols-3 gap-2 text-center text-xs">
      <div class="rounded border border-slate-600 bg-slate-900/50 p-2">
        <div class="text-slate-500">前半</div>
        <div class="text-lg font-bold text-slate-100">{{ model.breakdown.firstHalf.home }}-{{ model.breakdown.firstHalf.away }}</div>
      </div>
      <div class="rounded border border-slate-600 bg-slate-900/50 p-2">
        <div class="text-slate-500">後半</div>
        <div class="text-lg font-bold text-slate-100">{{ model.breakdown.secondHalf.home }}-{{ model.breakdown.secondHalf.away }}</div>
      </div>
      <div class="rounded border border-slate-600 bg-slate-900/50 p-2">
        <div class="text-slate-500">延長</div>
        <div class="text-lg font-bold text-slate-100">{{ model.breakdown.extra.home }}-{{ model.breakdown.extra.away }}</div>
      </div>
    </div>
  </div>
</template>
