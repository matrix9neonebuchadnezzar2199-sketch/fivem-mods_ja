<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useToast, type ToastItem } from '../composables/useToast'
import { getHelpRouteForError } from '../utils/errorCodeMapper'

const { items } = useToast()
const router = useRouter()
const { t } = useI18n()

function helpRouteForToast(row: ToastItem) {
  return getHelpRouteForError({ code: row.errorCode, error: row.errorKey })
}

const showHelp = computed(() => (row: ToastItem) => helpRouteForToast(row).name === 'help-error')

function openHelp(row: ToastItem) {
  void router.push(helpRouteForToast(row))
}
</script>

<template>
  <div class="pointer-events-none fixed bottom-4 right-4 z-[500] flex flex-col gap-2">
    <div
      v-for="row in items"
      :key="row.id"
      class="pointer-events-auto max-w-sm rounded-lg border px-3 py-2 text-sm shadow-lg"
      :class="
        row.type === 'error'
          ? 'border-red-500/50 bg-red-950/90 text-red-100'
          : row.type === 'success'
            ? 'border-emerald-500/50 bg-emerald-950/90 text-emerald-100'
            : 'border-slate-600 bg-slate-900/95 text-slate-100'
      "
    >
      <p>{{ row.message }}</p>
      <p v-if="row.errorCode || row.errorKey" class="mt-1 text-[10px] opacity-80">
        {{ row.errorCode || '' }} {{ row.errorKey ? `(${row.errorKey})` : '' }}
      </p>
      <button
        v-if="showHelp(row)"
        type="button"
        class="mt-2 w-full rounded border border-red-400/40 bg-red-900/40 px-2 py-1 text-xs font-medium text-red-100 hover:bg-red-900/70"
        @click="openHelp(row)"
      >
        {{ t('help.toast_open_solution') }}
      </button>
    </div>
  </div>
</template>
