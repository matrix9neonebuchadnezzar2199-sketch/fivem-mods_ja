<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { PresenceUser } from '../stores/presence'

const props = defineProps<{ user: PresenceUser }>()
const { t } = useI18n()

const initials = computed(() => {
  const raw = (props.user.name || '?').trim()
  if (!raw) {
    return '?'
  }
  const parts = raw.split(/\s+/).filter(Boolean)
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase()
  }
  return raw.slice(0, 2).toUpperCase()
})

const ringClass = computed(() =>
  props.user.mode === 'edit' ? 'ring-2 ring-emerald-400' : 'ring-2 ring-slate-500',
)

const tip = computed(() => {
  const role = props.user.mode === 'edit' ? t('presence.editing') : t('presence.viewing')
  return `${props.user.name} (${role})`
})
</script>

<template>
  <div
    class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-slate-700 text-[10px] font-bold text-slate-100"
    :class="ringClass"
    :title="tip"
  >
    {{ initials }}
  </div>
</template>
