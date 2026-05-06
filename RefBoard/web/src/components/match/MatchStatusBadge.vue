<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { MatchDbStatus } from '../../types/match'

const props = defineProps<{ status: string }>()
const { t } = useI18n()

const STATUS_STYLES: Record<MatchDbStatus, string> = {
  draft: 'bg-amber-500/20 text-amber-300',
  finished: 'bg-emerald-500/20 text-emerald-300',
  cancelled: 'bg-rose-500/20 text-rose-300',
}

function isMatchDbStatus(s: string): s is MatchDbStatus {
  return s === 'draft' || s === 'finished' || s === 'cancelled'
}

const classes = computed(() =>
  isMatchDbStatus(props.status) ? STATUS_STYLES[props.status] : 'bg-slate-500/20 text-slate-300',
)

const label = computed(() =>
  isMatchDbStatus(props.status) ? t(`match.status.${props.status}`) : props.status,
)
</script>

<template>
  <span :class="['inline-flex items-center rounded px-2 py-0.5 text-xs font-medium', classes]">
    {{ label }}
  </span>
</template>
