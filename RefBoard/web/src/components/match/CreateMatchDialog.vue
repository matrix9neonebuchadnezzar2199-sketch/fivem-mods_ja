<script setup lang="ts">
import { computed, reactive } from 'vue'
import { useI18n } from 'vue-i18n'
import { blockDateTimeFieldKeydown, openNativeDateTimePicker } from '../../composables/openNativeDateTimePicker'
import { useNui } from '../../composables/useNui'
import type { TeamRow } from '../../types/match'

const props = defineProps<{
  open: boolean
  teams: TeamRow[]
}>()

const emit = defineEmits<{ 'update:open': [boolean]; created: [number] }>()

const { t } = useI18n()
const { send, on } = useNui()

const form = reactive({
  team1Id: '' as string | number,
  team2Id: '' as string | number,
  matchName: '',
  venue: '',
  matchDate: new Date().toISOString().slice(0, 10),
  kickoffTime: '',
})

const team2Options = computed(() => {
  const a = Number(form.team1Id)
  return props.teams.filter((x) => x.id !== a)
})

function close() {
  emit('update:open', false)
}

async function submit() {
  const t1 = Number(form.team1Id)
  const t2 = Number(form.team2Id)
  if (!t1 || !t2 || t1 === t2) {
    return
  }
  const un = on('refboard:match:create:ack', (p: { ok?: boolean; matchId?: number }) => {
    un()
    if (p?.ok && p.matchId) {
      emit('created', p.matchId)
      close()
    }
  })
  await send('match_create', {
    team1Id: t1,
    team2Id: t2,
    matchName: form.matchName || null,
    venue: form.venue || null,
    matchDate: form.matchDate,
    kickoffTime: form.kickoffTime || null,
  })
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
    @click.self="close"
  >
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-4 text-lg font-bold text-slate-50">{{ t('create_match.title') }}</h2>
      <div class="space-y-3 text-sm">
        <label class="block text-slate-400">
          {{ t('create_match.team1') }}
          <select v-model="form.team1Id" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100">
            <option disabled value="">{{ t('create_match.select') }}</option>
            <option v-for="x in teams" :key="x.id" :value="x.id">{{ x.name }}</option>
          </select>
        </label>
        <label class="block text-slate-400">
          {{ t('create_match.team2') }}
          <select v-model="form.team2Id" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100">
            <option disabled value="">{{ t('create_match.select') }}</option>
            <option v-for="x in team2Options" :key="x.id" :value="x.id">{{ x.name }}</option>
          </select>
        </label>
        <label class="block text-slate-400">
          {{ t('create_match.match_name') }}
          <input v-model="form.matchName" type="text" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
        <label class="block text-slate-400">
          {{ t('create_match.venue') }}
          <input v-model="form.venue" type="text" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
        <div class="grid grid-cols-2 gap-2">
          <label class="block text-slate-400">
            {{ t('create_match.date') }}
            <input
              v-model="form.matchDate"
              type="date"
              class="refboard-input-pickers mt-1 w-full cursor-pointer rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100"
              @click="openNativeDateTimePicker"
              @keydown="blockDateTimeFieldKeydown"
              @keydown.enter.prevent="openNativeDateTimePicker"
              @paste.prevent
              @drop.prevent
            />
          </label>
          <label class="block text-slate-400">
            {{ t('create_match.kickoff') }}
            <input
              v-model="form.kickoffTime"
              type="time"
              class="refboard-input-pickers mt-1 w-full cursor-pointer rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100"
              @click="openNativeDateTimePicker"
              @keydown="blockDateTimeFieldKeydown"
              @keydown.enter.prevent="openNativeDateTimePicker"
              @paste.prevent
              @drop.prevent
            />
          </label>
        </div>
      </div>
      <div class="mt-5 flex justify-end gap-2">
        <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-300" @click="close">
          {{ t('dialog.no') }}
        </button>
        <button type="button" class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white" @click="submit">
          {{ t('create_match.submit') }}
        </button>
      </div>
    </div>
  </div>
</template>
