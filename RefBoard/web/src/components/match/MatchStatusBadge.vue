<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { MatchDbStatus } from '../../types/match'

const props = defineProps<{ status: string }>()
const { t } = useI18n()

const STATUS_STYLES: Record<MatchDbStatus | 'live', string> = {
  draft: 'bg-amber-500/20 text-amber-300',
  live: 'bg-sky-500/20 text-sky-300',
  finished: 'bg-emerald-500/20 text-emerald-300',
  cancelled: 'bg-rose-500/20 text-rose-300',
}

function isKnownStatus(s: string): s is MatchDbStatus | 'live' {
  return s === 'draft' || s === 'live' || s === 'finished' || s === 'cancelled'
}

const classes = computed(() =>
  isKnownStatus(props.status) ? STATUS_STYLES[props.status] : 'bg-slate-500/20 text-slate-300',
)

const label = computed(() =>
  isKnownStatus(props.status) ? t(`match.status.${props.status}`) : props.status,
)
</script>

<template>
  <span :class="['inline-flex items-center rounded px-2 py-0.5 text-xs font-medium', classes]">
    {{ label }}
  </span>
</template>
