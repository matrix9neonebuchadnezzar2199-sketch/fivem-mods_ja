<script setup lang="ts">
import type { MatchEvent } from '../../types/match'

const props = withDefaults(
  defineProps<{
    row: MatchEvent
    /** 小窓一覧は true（文字を一段小さく） */
    compact?: boolean
  }>(),
  { compact: false },
)

function isPkLabel() {
  return props.row.kind === 'penalty' && props.row.minute === 'PK'
}

function hasStoppage() {
  const s = props.row.eventStoppage
  return props.row.eventMinute != null && s != null && s > 0
}

const sizeClass = () => (props.compact ? 'text-xs' : 'text-sm')
</script>

<template>
  <span :class="['shrink-0 font-mono tabular-nums leading-tight', sizeClass()]">
    <template v-if="isPkLabel()">
      <span class="text-violet-300">{{ row.minute }}</span>
    </template>
    <template v-else-if="hasStoppage()">
      <span class="text-primary">{{ row.eventMinute }}</span><span class="font-semibold text-amber-400/95">+{{ row.eventStoppage }}'</span>
    </template>
    <template v-else>
      <span class="text-primary">{{ row.minute }}</span>
    </template>
  </span>
</template>
