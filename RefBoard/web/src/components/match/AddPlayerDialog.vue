<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

export type AddPlayerRosterRow = {
  id: number
  name: string
  number?: number | null
  position?: string | null
}

const props = defineProps<{
  open: boolean
  matchId: number
  teamId: number
  rosterRows: AddPlayerRosterRow[]
}>()

const emit = defineEmits<{
  'update:open': [boolean]
  added: []
  'add-from-roster': [{ rosterMemberId: number }]
  'add-manual': [{ name: string; number: number | null }]
}>()

const { t } = useI18n()

const mode = ref<'roster' | 'manual'>('roster')
const rosterPickId = ref<number | null>(null)
const manualName = ref('')
const manualNumber = ref<number | null>(null)
const error = ref('')

function close() {
  emit('update:open', false)
}

function reset() {
  mode.value = 'roster'
  rosterPickId.value = null
  manualName.value = ''
  manualNumber.value = null
  error.value = ''
}

watch(
  () => props.open,
  (v) => {
    if (v) reset()
  },
)

function submit() {
  error.value = ''
  if (mode.value === 'roster') {
    if (!rosterPickId.value) {
      error.value = t('player.add_need_resolve')
      return
    }
    emit('add-from-roster', { rosterMemberId: rosterPickId.value })
  } else {
    const n = manualName.value.trim()
    if (!n) {
      error.value = t('player.add_need_resolve')
      return
    }
    emit('add-manual', { name: n, number: manualNumber.value })
  }
  emit('added')
  close()
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[150] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
  >
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">{{ t('player.add_title') }}</h2>

      <div class="mb-3 flex gap-1 rounded-lg border border-slate-700 p-1 text-xs">
        <button
          type="button"
          class="flex-1 rounded-md px-2 py-2 font-semibold"
          :class="mode === 'roster' ? 'bg-primary text-white' : 'text-slate-400'"
          @click="mode = 'roster'"
        >
          {{ t('player.add_mode_roster') }}
        </button>
        <button
          type="button"
          class="flex-1 rounded-md px-2 py-2 font-semibold"
          :class="mode === 'manual' ? 'bg-primary text-white' : 'text-slate-400'"
          @click="mode = 'manual'"
        >
          {{ t('player.add_mode_manual') }}
        </button>
      </div>

      <div v-if="mode === 'roster'" class="max-h-48 space-y-2 overflow-y-auto text-sm">
        <p class="text-xs text-slate-500">{{ t('player.add_from_roster') }}</p>
        <button
          v-for="row in rosterRows"
          :key="row.id"
          type="button"
          class="block w-full rounded border px-2 py-2 text-left"
          :class="rosterPickId === row.id ? 'border-primary bg-primary/10 text-slate-50' : 'border-slate-600 bg-slate-950 text-slate-200'"
          @click="rosterPickId = row.id"
        >
          <span class="font-mono text-primary">{{ row.number ?? '—' }}</span>
          {{ row.name }}
          <span class="text-xs text-slate-500">{{ row.position || '' }}</span>
        </button>
        <p v-if="!rosterRows.length" class="text-xs text-slate-500">{{ t('player.roster_empty_hint') }}</p>
      </div>

      <div v-else class="space-y-2 text-sm">
        <label class="block text-slate-400">
          {{ t('team_manage.roster_name') }}*
          <input v-model="manualName" type="text" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
        <label class="block text-slate-400">
          {{ t('player.jersey_optional') }}
          <input v-model.number="manualNumber" type="number" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
      </div>

      <p v-if="error" class="mt-2 text-sm text-red-400">{{ error }}</p>

      <div class="mt-5 flex justify-end gap-2">
        <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="close">{{ t('dialog.no') }}</button>
        <button type="button" class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white" @click="submit">
          {{ t('player.add_submit') }}
        </button>
      </div>
    </div>
  </div>
</template>
