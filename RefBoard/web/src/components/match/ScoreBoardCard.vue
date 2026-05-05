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
      <h3 class="text-sm font-semibold text-slate-200">スコア</h3>
      <span class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">編集中</span>
    </div>
    <div class="flex items-stretch justify-between gap-4">
      <div class="flex flex-1 flex-col items-center gap-2 text-center">
        <div class="flex h-14 w-14 items-center justify-center rounded-full bg-primary/20 text-lg font-bold text-primary">LS</div>
        <div class="text-xs font-medium text-slate-300">{{ model.home.name }}</div>
        <span class="rounded bg-primary/30 px-2 py-0.5 text-[10px] font-bold text-primary">HOME</span>
      </div>
      <div class="flex flex-col items-center justify-center px-2">
        <div class="text-7xl font-bold leading-none tracking-tight text-slate-50">
          {{ model.score.home }} - {{ model.score.away }}
        </div>
        <div class="mt-3 flex items-center gap-2 text-sm text-slate-400">
          <button type="button" class="rounded border border-slate-600 px-2 py-0.5" :disabled="readonly">−</button>
          <span class="font-mono text-lg text-slate-200">{{ model.clockMmSs }}</span>
          <button type="button" class="rounded border border-slate-600 px-2 py-0.5" :disabled="readonly">+</button>
        </div>
        <div class="mt-1 text-xs text-emerald-400">{{ model.clockLabel }}</div>
      </div>
      <div class="flex flex-1 flex-col items-center gap-2 text-center">
        <div class="flex h-14 w-14 items-center justify-center rounded-full bg-slate-600/60 text-lg font-bold text-slate-200">VW</div>
        <div class="text-xs font-medium text-slate-300">{{ model.away.name }}</div>
        <span class="rounded bg-slate-600/50 px-2 py-0.5 text-[10px] font-bold text-slate-400">AWAY</span>
      </div>
    </div>
  </div>
</template>
