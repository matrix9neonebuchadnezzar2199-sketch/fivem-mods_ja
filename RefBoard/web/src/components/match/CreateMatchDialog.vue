<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { storeToRefs } from 'pinia'
import { blockDateTimeFieldKeydown, openNativeDateTimePicker } from '../../composables/openNativeDateTimePicker'
import { useToast } from '../../composables/useToast'
import { useSettingsStore } from '../../stores/settings'
import { useMatchesStore } from '../../stores/matches'
import type { TeamRow } from '../../types/match'

const props = defineProps<{
  open: boolean
  teams: TeamRow[]
}>()

const emit = defineEmits<{ 'update:open': [boolean]; created: [number] }>()

const { t } = useI18n()
const { push: toast } = useToast()
const settingsStore = useSettingsStore()
const { settings } = storeToRefs(settingsStore)
const matchesStore = useMatchesStore()

const form = reactive({
  team1Id: '' as string | number,
  team2Id: '' as string | number,
  matchName: '',
  venue: '',
  matchDate: new Date().toISOString().slice(0, 10),
  kickoffTime: '',
  halfMinutes: settings.value.defaultHalfMinutes,
})

watch(
  () => props.open,
  (v) => {
    if (v) {
      form.team1Id = ''
      form.team2Id = ''
      form.matchName = ''
      form.venue = ''
      form.matchDate = new Date().toISOString().slice(0, 10)
      form.kickoffTime = ''
      form.halfMinutes = settings.value.defaultHalfMinutes
    }
  },
)

const team2Options = computed(() => {
  const a = Number(form.team1Id)
  return props.teams.filter((x) => x.id !== a)
})

function close() {
  emit('update:open', false)
}

function submit() {
  const t1 = Number(form.team1Id)
  const t2 = Number(form.team2Id)
  if (!t1 || !t2 || t1 === t2) {
    toast(t('create_match.validation_teams'), 'error', { ms: 5000 })
    return
  }
  const home = props.teams.find((x) => x.id === t1)
  const away = props.teams.find((x) => x.id === t2)
  const title =
    (form.matchName && form.matchName.trim()) ||
    (home && away ? `${home.name} vs ${away.name}` : t('create_match.default_title'))
  const scheduled =
    form.matchDate && form.kickoffTime
      ? `${form.matchDate}T${form.kickoffTime.length === 5 ? form.kickoffTime : form.kickoffTime.slice(0, 5)}:00`
      : form.matchDate
        ? `${form.matchDate}T12:00:00`
        : null
  try {
    const m = matchesStore.createMatch({
      title,
      homeTeamId: t1,
      awayTeamId: t2,
      halfMinutes: Number(form.halfMinutes) || settings.value.defaultHalfMinutes,
      scheduledAt: scheduled ?? undefined,
      venue: form.venue?.trim() || undefined,
    })
    emit('created', m.id)
    close()
  } catch (e) {
    toast(t('create_match.create_failed'), 'error', { ms: 6000 })
    void e
  }
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
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
          {{ t('create_match.half_minutes') }}
          <input
            v-model.number="form.halfMinutes"
            type="number"
            min="1"
            max="120"
            class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100"
          />
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
