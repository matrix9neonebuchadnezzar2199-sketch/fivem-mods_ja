<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAutosaveStore } from '../stores/autosave'

const { t } = useI18n()
const autosave = useAutosaveStore()

const line = computed(() => {
  if (autosave.status === 'saving') {
    return t('autosave.saving')
  }
  if (autosave.status === 'error') {
    return t('autosave.error')
  }
  if (autosave.status !== 'saved' || !autosave.lastSavedAt) {
    return ''
  }
  const sec = autosave.elapsedSeconds
  if (sec < 30) {
    return t('autosave.saved_seconds', { n: Math.max(0, sec) })
  }
  const min = Math.floor(sec / 60)
  return t('autosave.saved_minutes', { n: Math.max(1, min) })
})
</script>

<template>
  <div class="flex min-h-[1.5rem] items-center justify-center gap-2 text-sm">
    <template v-if="autosave.status === 'saving'">
      <span class="inline-block h-4 w-4 animate-spin rounded-full border-2 border-amber-400 border-t-transparent" />
      <span class="text-amber-400">{{ line }}</span>
    </template>
    <template v-else-if="autosave.status === 'error'">
      <span class="text-red-400">{{ line }}</span>
      <button type="button" class="rounded border border-red-500/50 px-2 py-0.5 text-xs text-red-300 hover:bg-red-500/10">
        {{ t('autosave.retry') }}
      </button>
    </template>
    <template v-else-if="autosave.status === 'saved' && line">
      <span class="text-emerald-400">✓</span>
      <span class="text-emerald-400">{{ line }}</span>
    </template>
    <span v-else class="text-slate-500">—</span>
  </div>
</template>
