<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { MatchEvent } from '../../types/match'

const props = withDefaults(
  defineProps<{
    events: MatchEvent[]
    /** 一覧の最大高さ（CSS 値）。既定 8rem ≒ 8〜10 行 */
    maxHeight?: string
  }>(),
  { maxHeight: '8rem' },
)

const { t } = useI18n()

/** 新しい順（上が最新） */
const recent = computed(() => [...props.events].reverse())
</script>

<template>
  <div
    class="compact-event-list space-y-1 overflow-y-auto pr-1 text-xs [scrollbar-color:rgba(71,85,105,0.9)_transparent] [scrollbar-width:thin]"
    :style="{ maxHeight }"
  >
    <p v-if="recent.length === 0" class="px-1 py-0.5 text-slate-500">
      {{ t('compact.no_events') }}
    </p>
    <ul v-else class="space-y-0.5">
      <li
        v-for="row in recent"
        :key="row.id"
        class="flex min-w-0 items-center gap-2 rounded bg-slate-800/40 px-2 py-1"
      >
        <span class="w-12 shrink-0 tabular-nums text-slate-400">{{ row.minute }}</span>
        <span class="min-w-0 truncate text-slate-200">{{ row.text }}</span>
      </li>
    </ul>
  </div>
</template>
