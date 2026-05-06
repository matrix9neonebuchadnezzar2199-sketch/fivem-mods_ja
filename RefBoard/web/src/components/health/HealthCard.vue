<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { HealthRow } from '../../types/health'

defineProps<{
  title: string
  rows: HealthRow[]
}>()

const { t } = useI18n()

function statusDot(s: HealthRow['status']) {
  if (s === 'ok') return 'bg-emerald-500'
  if (s === 'warning') return 'bg-amber-400'
  if (s === 'error') return 'bg-red-500'
  return 'bg-slate-500'
}

function rowLabel(row: HealthRow) {
  const key = `health.rows.${row.category}.${row.name}`
  const tr = t(key)
  return tr === key ? `${row.category}.${row.name}` : tr
}
</script>

<template>
  <section class="rounded-lg border border-slate-700 bg-slate-900/70 p-4">
    <h2 class="mb-3 text-sm font-semibold text-primary">{{ title }}</h2>
    <ul class="space-y-2 text-xs text-slate-300">
      <li v-for="(row, i) in rows" :key="i" class="flex gap-2">
        <span class="mt-1 h-2 w-2 shrink-0 rounded-full" :class="statusDot(row.status)" />
        <div>
          <div class="font-medium text-slate-200">{{ rowLabel(row) }}</div>
          <div class="text-slate-400">{{ row.detail }}</div>
        </div>
      </li>
    </ul>
  </section>
</template>
