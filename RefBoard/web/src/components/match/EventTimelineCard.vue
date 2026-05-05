<script setup lang="ts">
import type { MatchEvent } from '../../types/match'

defineProps<{
  events: MatchEvent[]
  readonly: boolean
}>()
</script>

<template>
  <div class="rounded-lg border border-slate-700 bg-slate-800/80 p-4 shadow-sm backdrop-blur">
    <div class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">試合イベント</h3>
      <span class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">編集中</span>
    </div>
    <ul class="max-h-64 space-y-2 overflow-y-auto pr-1 text-sm">
      <li v-for="e in events" :key="e.id" class="flex gap-2 rounded bg-slate-900/50 px-2 py-1.5 font-mono text-slate-200">
        <span class="shrink-0 text-primary">{{ e.minute }}</span>
        <span>{{ e.text }}</span>
      </li>
    </ul>
    <button
      type="button"
      class="mt-3 w-full rounded-lg border border-dashed border-slate-500 py-2 text-xs font-medium text-slate-300 hover:border-primary hover:text-primary"
      :disabled="readonly"
    >
      + イベントを追加
    </button>
  </div>
</template>
