<script setup lang="ts">
import { reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../../composables/useNui'

export type RosterInitial = {
  player_name: string
  jersey_number: number | null
  position: string | null
  license: string | null
}

const props = defineProps<{ open: boolean; teamId: number; editId: number | null; initial: RosterInitial | null }>()
const emit = defineEmits<{ 'update:open': [boolean]; saved: [] }>()

const { t } = useI18n()
const { send, on } = useNui()

const form = reactive({
  playerName: '',
  jerseyNumber: null as number | null,
  position: 'MF' as 'GK' | 'DF' | 'MF' | 'FW',
  license: '',
})

watch(
  () => props.open,
  (open) => {
    if (!open) return
    if (props.initial && props.editId) {
      form.playerName = props.initial.player_name
      form.jerseyNumber = props.initial.jersey_number
      form.position = (props.initial.position as typeof form.position) || 'MF'
      form.license = props.initial.license || ''
    } else {
      form.playerName = ''
      form.jerseyNumber = null
      form.position = 'MF'
      form.license = ''
    }
  },
)

function close() {
  emit('update:open', false)
}

async function submit() {
  if (!props.teamId || !form.playerName.trim()) return
  if (props.editId) {
    const un = on('refboard:team:roster:update:ack', (p: { ok?: boolean }) => {
      un()
      if (p?.ok) {
        emit('saved')
        close()
      }
    })
    await send('team_roster_update', {
      rosterId: props.editId,
      teamId: props.teamId,
      playerName: form.playerName.trim(),
      jerseyNumber: form.jerseyNumber,
      position: form.position,
      license: form.license.trim() || null,
    })
  } else {
    const un = on('refboard:team:roster:add:ack', (p: { ok?: boolean }) => {
      un()
      if (p?.ok) {
        emit('saved')
        close()
      }
    })
    await send('team_roster_add', {
      teamId: props.teamId,
      playerName: form.playerName.trim(),
      jerseyNumber: form.jerseyNumber,
      position: form.position,
      license: form.license.trim() || null,
    })
  }
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[200] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
    @click.self="close"
  >
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">
        {{ editId ? t('team_manage.roster_edit') : t('team_manage.roster_add') }}
      </h2>
      <div class="space-y-2 text-sm">
        <label class="block text-slate-400">
          {{ t('team_manage.roster_name') }}*
          <input v-model="form.playerName" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
        <label class="block text-slate-400">
          {{ t('player.jersey_optional') }}
          <input v-model.number="form.jerseyNumber" type="number" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
        <label class="block text-slate-400">
          {{ t('player.position') }}
        </label>
        <div class="flex flex-wrap gap-1">
          <button
            v-for="p in ['GK', 'DF', 'MF', 'FW'] as const"
            :key="p"
            type="button"
            class="rounded px-3 py-1 text-xs font-semibold"
            :class="form.position === p ? 'bg-primary text-white' : 'border border-slate-600 bg-slate-800 text-slate-300'"
            @click="form.position = p"
          >
            {{ p }}
          </button>
        </div>
        <label class="block text-slate-400">
          {{ t('team_manage.license_optional') }}
          <input v-model="form.license" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
      </div>
      <div class="mt-4 flex justify-end gap-2">
        <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="close">{{ t('dialog.no') }}</button>
        <button type="button" class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white" @click="submit">
          {{ t('dialog.yes') }}
        </button>
      </div>
    </div>
  </div>
</template>
