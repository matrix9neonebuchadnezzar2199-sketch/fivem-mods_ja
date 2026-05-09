<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { ScoreHistoryRow } from '../../types/match'
import { formatDateTimeJa } from '../../utils/formatDate'

const props = defineProps<{
  open: boolean
  rows: ScoreHistoryRow[]
}>()

const emit = defineEmits<{ 'update:open': [boolean] }>()

const { t } = useI18n()

const sorted = computed(() => [...props.rows].sort((a, b) => a.id - b.id))

function icon(action: string) {
  if (action === 'goal') return '⚽'
  if (action === 'manual_edit') return '✏️'
  if (action === 'undo') return '↩️'
  if (action === 'reset') return '🔄'
  return '•'
}

function close() {
  emit('update:open', false)
}

function line(prev: ScoreHistoryRow | null, cur: ScoreHistoryRow): string {
  if (!prev) {
    return t('score_history.line_first', {
      time: formatDateTimeJa(cur.created_at),
      name: cur.changed_by_name,
      score: `${cur.team1_score}-${cur.team2_score}`,
      reason: cur.reason || '—',
    })
  }
  return t('score_history.line_change', {
    time: formatDateTimeJa(cur.created_at),
    name: cur.changed_by_name,
    from: `${prev.team1_score}-${prev.team2_score}`,
    to: `${cur.team1_score}-${cur.team2_score}`,
    reason: cur.reason || '—',
  })
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[150] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
  >
    <div class="flex max-h-[85vh] w-full max-w-lg flex-col rounded-xl border border-slate-700 bg-slate-900 shadow-2xl">
      <div class="border-b border-slate-700 px-4 py-3">
        <h2 class="text-lg font-bold text-slate-50">{{ t('score_history.title') }}</h2>
      </div>
      <ul class="min-h-0 flex-1 space-y-2 overflow-y-auto p-4 text-sm text-slate-200">
        <li v-for="(cur, idx) in sorted" :key="cur.id" class="rounded border border-slate-700/80 bg-slate-950/60 px-3 py-2">
          <span class="mr-2">{{ icon(cur.action) }}</span>
          {{ line(idx > 0 ? sorted[idx - 1] ?? null : null, cur) }}
        </li>
        <li v-if="!sorted.length" class="text-slate-500">{{ t('score_history.empty') }}</li>
      </ul>
      <div class="flex justify-end border-t border-slate-700 px-4 py-2">
        <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="close">{{ t('dialog.no') }}</button>
      </div>
    </div>
  </div>
</template>
