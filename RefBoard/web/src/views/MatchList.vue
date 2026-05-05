<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useNui } from '../composables/useNui'
import type { MatchListRow, TeamRow } from '../types/match'
import CreateMatchDialog from '../components/match/CreateMatchDialog.vue'

const { t } = useI18n()
const router = useRouter()
const { send, on } = useNui()

const rows = ref<MatchListRow[]>([])
const teams = ref<TeamRow[]>([])
const filter = ref<'all' | 'draft' | 'finished' | 'cancelled'>('all')
const showCreate = ref(false)

let offMatch: (() => void) | null = null
let offTeam: (() => void) | null = null

function loadMatches() {
  void send('match_list', { status: filter.value })
}

onMounted(() => {
  offMatch = on('refboard:match:list:ack', (p: { matches?: MatchListRow[] }) => {
    rows.value = p.matches || []
  })
  offTeam = on('refboard:team:list:ack', (p: { teams?: TeamRow[] }) => {
    teams.value = p.teams || []
  })
  void send('team_list', {})
  loadMatches()
})

onUnmounted(() => {
  offMatch?.()
  offTeam?.()
})

watch(filter, () => {
  loadMatches()
})

function openDetail(id: number) {
  void router.push({ name: 'match-detail', params: { id: String(id) } })
}

function onCreated(id: number) {
  showCreate.value = false
  loadMatches()
  void router.push({ name: 'match-detail', params: { id: String(id) } })
}
</script>

<template>
  <div class="flex h-full min-h-0 flex-col gap-4 p-4">
    <div class="flex flex-wrap items-center justify-between gap-2">
      <h2 class="text-lg font-semibold text-slate-50">{{ t('match_list.title') }}</h2>
      <button
        type="button"
        class="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-primary/20 hover:brightness-110"
        @click="showCreate = true"
      >
        {{ t('match_list.new') }}
      </button>
    </div>

    <div class="flex flex-wrap items-center gap-2 text-sm">
      <span class="text-slate-400">{{ t('match_list.filter') }}</span>
      <select v-model="filter" class="rounded border border-slate-600 bg-slate-900 px-2 py-1 text-slate-100">
        <option value="all">{{ t('match_list.all') }}</option>
        <option value="draft">{{ t('match_list.draft') }}</option>
        <option value="finished">{{ t('match_list.finished') }}</option>
        <option value="cancelled">{{ t('match_list.cancelled') }}</option>
      </select>
    </div>

    <div class="min-h-0 flex-1 overflow-auto rounded-lg border border-slate-700 bg-slate-900/60">
      <table class="w-full min-w-[640px] border-collapse text-left text-sm">
        <thead class="sticky top-0 bg-slate-900/95 text-xs uppercase text-slate-500">
          <tr>
            <th class="border-b border-slate-700 px-3 py-2">{{ t('match_list.col_date') }}</th>
            <th class="border-b border-slate-700 px-3 py-2">{{ t('match_list.col_teams') }}</th>
            <th class="border-b border-slate-700 px-3 py-2">{{ t('match_list.col_score') }}</th>
            <th class="border-b border-slate-700 px-3 py-2">{{ t('match_list.col_status') }}</th>
            <th class="border-b border-slate-700 px-3 py-2">{{ t('match_list.col_actions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="m in rows" :key="m.id" class="border-b border-slate-800 hover:bg-slate-800/40">
            <td class="px-3 py-2 text-slate-300">{{ m.match_date }}</td>
            <td class="px-3 py-2 text-slate-100">
              {{ m.team1_name || m.team1_id }} vs {{ m.team2_name || m.team2_id }}
            </td>
            <td class="px-3 py-2 font-mono text-slate-200">{{ m.team1_score }} - {{ m.team2_score }}</td>
            <td class="px-3 py-2 text-slate-400">{{ m.status }}</td>
            <td class="px-3 py-2">
              <button type="button" class="mr-2 text-primary hover:underline" @click="openDetail(m.id)">{{ t('match_list.edit') }}</button>
              <button type="button" class="text-slate-400 hover:underline" @click="openDetail(m.id)">{{ t('match_list.detail') }}</button>
            </td>
          </tr>
          <tr v-if="!rows.length">
            <td colspan="5" class="px-3 py-8 text-center text-slate-500">{{ t('match_list.empty') }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <CreateMatchDialog v-model:open="showCreate" :teams="teams" @created="onCreated" />
  </div>
</template>
