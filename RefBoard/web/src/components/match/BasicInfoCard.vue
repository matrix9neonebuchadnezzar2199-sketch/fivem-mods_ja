<script setup lang="ts">
import type { MatchDetailModel } from '../../types/match'

defineProps<{
  model: MatchDetailModel
  readonly: boolean
}>()
</script>

<template>
  <div class="rounded-lg border border-slate-700 bg-slate-800/80 p-4 shadow-sm backdrop-blur">
    <div class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">基本情報</h3>
      <span class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">編集中</span>
    </div>
    <div class="space-y-3">
      <label class="block text-xs text-slate-400">
        試合名
        <input
          v-model="model.matchName"
          type="text"
          class="mt-1 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-1.5 text-sm text-slate-100"
          :disabled="readonly"
        />
      </label>
      <label class="block text-xs text-slate-400">
        会場
        <input
          v-model="model.venue"
          type="text"
          class="mt-1 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-1.5 text-sm text-slate-100"
          :disabled="readonly"
        />
      </label>
      <div class="grid grid-cols-2 gap-2">
        <label class="block text-xs text-slate-400">
          日付
          <input
            v-model="model.matchDate"
            type="date"
            class="mt-1 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-1.5 text-sm text-slate-100"
            :disabled="readonly"
          />
        </label>
        <label class="block text-xs text-slate-400">
          開始
          <input
            v-model="model.kickoffTime"
            type="time"
            class="mt-1 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-1.5 text-sm text-slate-100"
            :disabled="readonly"
          />
        </label>
      </div>
    </div>
  </div>
</template>
