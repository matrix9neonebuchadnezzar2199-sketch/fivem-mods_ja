<script setup lang="ts">
import type { MatchPlayer } from '../../types/match'

defineProps<{
  title: string
  players: MatchPlayer[]
  readonly: boolean
}>()

function statusClass(s: MatchPlayer['status']) {
  if (s === 'playing') return 'text-emerald-400'
  if (s === 'warning') return 'text-amber-400'
  if (s === 'sent_off') return 'text-red-400'
  return 'text-slate-500'
}

function statusLabel(s: MatchPlayer['status']) {
  if (s === 'playing') return '●出場'
  if (s === 'warning') return '●警告'
  if (s === 'sent_off') return '●退場'
  return '●控え'
}
</script>

<template>
  <div class="rounded-lg border border-slate-700 bg-slate-800/80 p-4 shadow-sm backdrop-blur">
    <div class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">{{ title }}</h3>
      <span class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">編集中</span>
    </div>
    <div class="overflow-x-auto">
      <table class="w-full min-w-[280px] border-collapse text-left text-xs">
        <thead>
          <tr class="border-b border-slate-600 text-slate-500">
            <th class="py-2 pr-2">No</th>
            <th class="py-2 pr-2">選手</th>
            <th class="py-2 pr-2">POS</th>
            <th class="py-2">状態</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in players" :key="p.id" class="border-b border-slate-700/80">
            <td class="py-2 pr-2 font-mono text-slate-300">{{ p.number }}</td>
            <td class="py-2 pr-2 text-slate-100">{{ p.name }}</td>
            <td class="py-2 pr-2 text-slate-400">{{ p.position }}</td>
            <td class="py-2 font-medium" :class="statusClass(p.status)">{{ statusLabel(p.status) }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
