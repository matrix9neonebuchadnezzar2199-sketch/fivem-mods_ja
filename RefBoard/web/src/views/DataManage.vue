<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useNui } from '../composables/useNui'
import { downloadFile, refboardFilename, toCSV } from '../utils/exporters'

const { t } = useI18n()
const router = useRouter()
const { send, on } = useNui()

type Tab = 'matches' | 'teams' | 'players' | 'log'
const tab = ref<Tab>('matches')

const teamStats = ref<Record<string, unknown>[]>([])
const playerStats = ref<Record<string, unknown>[]>([])
const matchHistory = ref<Record<string, unknown>[]>([])
const editLog = ref<Record<string, unknown>[]>([])

const period = ref<'this_month' | 'last_month' | 'last_3m' | 'all' | 'custom'>('this_month')
const customFrom = ref('')
const customTo = ref('')
const filterTeamId = ref<number | ''>('')
const filterStatus = ref<'all' | 'draft' | 'finished' | 'cancelled'>('all')
const sortMatches = ref<'date' | 'spread' | 'goals'>('date')
const logFrom = ref('')
const logTo = ref('')
const logEditor = ref('')
const logMatchId = ref<number | ''>('')

const teamsPick = ref<{ id: number; name: string }[]>([])

const dateRange = computed(() => {
  const now = new Date()
  const y = now.getFullYear()
  const m = now.getMonth()
  const pad = (n: number) => String(n).padStart(2, '0')
  const fmt = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
  if (period.value === 'all') return { from: null as string | null, to: null as string | null }
  if (period.value === 'custom') {
    return { from: customFrom.value || null, to: customTo.value || null }
  }
  if (period.value === 'this_month') {
    const start = new Date(y, m, 1)
    return { from: fmt(start), to: fmt(now) }
  }
  if (period.value === 'last_month') {
    const start = new Date(y, m - 1, 1)
    const end = new Date(y, m, 0)
    return { from: fmt(start), to: fmt(end) }
  }
  const start = new Date(y, m - 2, 1)
  return { from: fmt(start), to: fmt(now) }
})

async function loadTeamsPick() {
  const un = on('refboard:team:list:ack', (p: { teams?: { id: number; name: string }[] }) => {
    un()
    teamsPick.value = (p.teams ?? []).map((x) => ({ id: x.id, name: x.name }))
  })
  await send('team_list', {})
}

async function loadTeamStats() {
  const un = on('refboard:data:team_stats:ack', (p: { rows?: Record<string, unknown>[] }) => {
    un()
    teamStats.value = p.rows ?? []
  })
  await send('data_team_stats', {})
}

async function loadPlayerStats() {
  const un = on('refboard:data:player_stats:ack', (p: { rows?: Record<string, unknown>[] }) => {
    un()
    playerStats.value = p.rows ?? []
  })
  await send('data_player_stats', {})
}

async function loadMatchHistory() {
  const dr = dateRange.value
  const un = on('refboard:data:match_history:ack', (p: { rows?: Record<string, unknown>[] }) => {
    un()
    matchHistory.value = p.rows ?? []
  })
  await send('data_match_history', {
    status: filterStatus.value,
    teamId: filterTeamId.value === '' ? null : Number(filterTeamId.value),
    from: dr.from,
    to: dr.to,
    sort: sortMatches.value,
  })
}

async function loadEditLog() {
  const un = on('refboard:data:score_edit_log:ack', (p: { rows?: Record<string, unknown>[] }) => {
    un()
    editLog.value = p.rows ?? []
  })
  await send('data_score_edit_log', {
    from: logFrom.value || null,
    to: logTo.value || null,
    editorLicense: logEditor.value.trim() || null,
    matchId: logMatchId.value === '' ? null : Number(logMatchId.value),
  })
}

onMounted(async () => {
  await loadTeamsPick()
  await loadTeamStats()
  await loadPlayerStats()
  await loadMatchHistory()
  await loadEditLog()
})

function exportTeamStatsCsv() {
  const cols = [
    'id',
    'name',
    'short_name',
    'matches_played',
    'wins',
    'draws',
    'losses',
    'goals_for',
    'goals_against',
  ]
  downloadFile(toCSV(teamStats.value, cols), refboardFilename('refboard_team_stats', 'csv'), 'text/csv;charset=utf-8')
}

function exportPlayerStatsCsv() {
  const cols = ['grp_key', 'player_name', 'has_license', 'matches_played', 'goals', 'assists', 'yellows', 'reds']
  downloadFile(toCSV(playerStats.value, cols), refboardFilename('refboard_player_stats', 'csv'), 'text/csv;charset=utf-8')
}

function exportMatchHistoryCsv() {
  const cols = [
    'id',
    'match_date',
    'team1_name',
    'team2_name',
    'team1_score',
    'team2_score',
    'status',
    'venue',
  ]
  downloadFile(toCSV(matchHistory.value, cols), refboardFilename('refboard_match_history', 'csv'), 'text/csv;charset=utf-8')
}

function exportEditLogCsv() {
  const cols = ['id', 'match_id', 'created_at', 'changed_by_name', 'team1_score', 'team2_score', 'reason', 'team1_name', 'team2_name']
  downloadFile(toCSV(editLog.value, cols), refboardFilename('refboard_score_edit_log', 'csv'), 'text/csv;charset=utf-8')
}

function resultLabel(row: Record<string, unknown>) {
  const s1 = Number(row.team1_score)
  const s2 = Number(row.team2_score)
  if (s1 === s2) return 'D'
  return s1 > s2 ? 'W1' : 'W2'
}

function openMatch(id: number) {
  void router.push({ name: 'match-detail', params: { id: String(id) } })
}
</script>

<template>
  <div class="flex h-full min-h-0 flex-col gap-2 p-3">
    <div class="flex flex-wrap gap-1 border-b border-slate-700 pb-2 text-xs">
      <button
        v-for="x in [
          ['matches', t('data.tabs.matches')],
          ['teams', t('data.tabs.teams')],
          ['players', t('data.tabs.players')],
          ['log', t('data.tabs.log')],
        ] as const"
        :key="x[0]"
        type="button"
        class="rounded-lg px-3 py-1.5 font-semibold"
        :class="tab === x[0] ? 'bg-primary text-white' : 'bg-slate-800 text-slate-300'"
        @click="tab = x[0] as Tab"
      >
        {{ x[1] }}
      </button>
    </div>

    <div v-if="tab === 'matches'" class="min-h-0 flex-1 space-y-2 overflow-auto">
      <div class="flex flex-wrap items-end gap-2 text-xs">
        <label class="text-slate-400">
          {{ t('data.period') }}
          <select v-model="period" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1 text-slate-100">
            <option value="this_month">{{ t('data.period_this_month') }}</option>
            <option value="last_month">{{ t('data.period_last_month') }}</option>
            <option value="last_3m">{{ t('data.period_3m') }}</option>
            <option value="all">{{ t('data.period_all') }}</option>
            <option value="custom">{{ t('data.period_custom') }}</option>
          </select>
        </label>
        <label v-if="period === 'custom'" class="text-slate-400">
          from
          <input v-model="customFrom" type="date" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1" />
        </label>
        <label v-if="period === 'custom'" class="text-slate-400">
          to
          <input v-model="customTo" type="date" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1" />
        </label>
        <label class="text-slate-400">
          {{ t('data.team_filter') }}
          <select v-model="filterTeamId" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1 text-slate-100">
            <option value="">{{ t('data.all_teams') }}</option>
            <option v-for="tm in teamsPick" :key="tm.id" :value="tm.id">{{ tm.name }}</option>
          </select>
        </label>
        <label class="text-slate-400">
          {{ t('match_list.filter') }}
          <select v-model="filterStatus" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1 text-slate-100">
            <option value="all">{{ t('match_list.all') }}</option>
            <option value="draft">{{ t('match_list.draft') }}</option>
            <option value="finished">{{ t('match_list.finished') }}</option>
            <option value="cancelled">{{ t('match_list.cancelled') }}</option>
          </select>
        </label>
        <label class="text-slate-400">
          {{ t('data.sort') }}
          <select v-model="sortMatches" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1 text-slate-100">
            <option value="date">{{ t('data.sort_date') }}</option>
            <option value="spread">{{ t('data.sort_spread') }}</option>
            <option value="goals">{{ t('data.sort_goals') }}</option>
          </select>
        </label>
        <button type="button" class="rounded bg-slate-800 px-2 py-1 text-xs" @click="loadMatchHistory">{{ t('data.apply') }}</button>
        <button type="button" class="rounded border border-slate-600 px-2 py-1 text-xs" @click="exportMatchHistoryCsv">
          {{ t('data.export_csv') }}
        </button>
      </div>
      <div class="overflow-auto rounded border border-slate-700">
        <table class="w-full border-collapse text-left text-xs">
          <thead class="bg-slate-900 text-slate-400">
            <tr>
              <th class="p-2">{{ t('match_list.col_date') }}</th>
              <th class="p-2">{{ t('match_list.col_teams') }}</th>
              <th class="p-2">{{ t('match_list.col_score') }}</th>
              <th class="p-2">{{ t('data.col_result') }}</th>
              <th class="p-2">{{ t('create_match.venue') }}</th>
              <th class="p-2">{{ t('match_list.col_actions') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in matchHistory" :key="String(r.id)" class="border-t border-slate-800 text-slate-200">
              <td class="p-2">{{ r.match_date }}</td>
              <td class="p-2">{{ r.team1_name }} vs {{ r.team2_name }}</td>
              <td class="p-2 font-mono">{{ r.team1_score }} - {{ r.team2_score }}</td>
              <td class="p-2 text-slate-400">{{ resultLabel(r) }}</td>
              <td class="p-2 text-slate-400">{{ r.venue || '—' }}</td>
              <td class="p-2">
                <button type="button" class="text-primary hover:underline" @click="openMatch(Number(r.id))">{{ t('match_list.detail') }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-else-if="tab === 'teams'" class="min-h-0 flex-1 space-y-2 overflow-auto">
      <div class="flex justify-end gap-2">
        <button type="button" class="rounded border border-slate-600 px-2 py-1 text-xs" @click="loadTeamStats">{{ t('data.reload') }}</button>
        <button type="button" class="rounded border border-slate-600 px-2 py-1 text-xs" @click="exportTeamStatsCsv">{{ t('data.export_csv') }}</button>
      </div>
      <div class="overflow-auto rounded border border-slate-700">
        <table class="w-full border-collapse text-left text-xs">
          <thead class="bg-slate-900 text-slate-400">
            <tr>
              <th class="p-2">{{ t('team.name') }}</th>
              <th class="p-2">MP</th>
              <th class="p-2">W</th>
              <th class="p-2">D</th>
              <th class="p-2">L</th>
              <th class="p-2">GF</th>
              <th class="p-2">GA</th>
              <th class="p-2">GD</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in teamStats" :key="String(r.id)" class="border-t border-slate-800 text-slate-200">
              <td class="p-2">{{ r.name }}</td>
              <td class="p-2">{{ r.matches_played }}</td>
              <td class="p-2">{{ r.wins }}</td>
              <td class="p-2">{{ r.draws }}</td>
              <td class="p-2">{{ r.losses }}</td>
              <td class="p-2">{{ r.goals_for }}</td>
              <td class="p-2">{{ r.goals_against }}</td>
              <td class="p-2">{{ Number(r.goals_for) - Number(r.goals_against) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-else-if="tab === 'players'" class="min-h-0 flex-1 space-y-2 overflow-auto">
      <div class="flex justify-end gap-2">
        <button type="button" class="rounded border border-slate-600 px-2 py-1 text-xs" @click="loadPlayerStats">{{ t('data.reload') }}</button>
        <button type="button" class="rounded border border-slate-600 px-2 py-1 text-xs" @click="exportPlayerStatsCsv">{{ t('data.export_csv') }}</button>
      </div>
      <div class="overflow-auto rounded border border-slate-700">
        <table class="w-full border-collapse text-left text-xs">
          <thead class="bg-slate-900 text-slate-400">
            <tr>
              <th class="p-2">{{ t('data.col_player') }}</th>
              <th class="p-2">{{ t('data.col_guest') }}</th>
              <th class="p-2">MP</th>
              <th class="p-2">G</th>
              <th class="p-2">A</th>
              <th class="p-2">🟨</th>
              <th class="p-2">🟥</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(r, idx) in playerStats" :key="String(r.grp_key ?? idx)" class="border-t border-slate-800 text-slate-200">
              <td class="p-2">{{ r.player_name }}</td>
              <td class="p-2">{{ Number(r.has_license) === 0 ? t('data.guest') : '—' }}</td>
              <td class="p-2">{{ r.matches_played }}</td>
              <td class="p-2">{{ r.goals }}</td>
              <td class="p-2">{{ r.assists }}</td>
              <td class="p-2">{{ r.yellows }}</td>
              <td class="p-2">{{ r.reds }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-else class="min-h-0 flex-1 space-y-2 overflow-auto">
      <div class="flex flex-wrap items-end gap-2 text-xs">
        <label class="text-slate-400">
          from
          <input v-model="logFrom" type="datetime-local" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1" />
        </label>
        <label class="text-slate-400">
          to
          <input v-model="logTo" type="datetime-local" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1" />
        </label>
        <label class="text-slate-400">
          {{ t('data.log_editor') }}
          <input v-model="logEditor" class="mt-1 rounded border border-slate-600 bg-slate-950 px-2 py-1 text-slate-100" />
        </label>
        <label class="text-slate-400">
          match id
          <input v-model.number="logMatchId" type="number" class="mt-1 w-24 rounded border border-slate-600 bg-slate-950 px-2 py-1" />
        </label>
        <button type="button" class="rounded bg-slate-800 px-2 py-1 text-xs" @click="loadEditLog">{{ t('data.apply') }}</button>
        <button type="button" class="rounded border border-slate-600 px-2 py-1 text-xs" @click="exportEditLogCsv">{{ t('data.export_csv') }}</button>
      </div>
      <div class="overflow-auto rounded border border-slate-700">
        <table class="w-full border-collapse text-left text-xs">
          <thead class="bg-slate-900 text-slate-400">
            <tr>
              <th class="p-2">{{ t('data.col_time') }}</th>
              <th class="p-2">{{ t('data.col_editor') }}</th>
              <th class="p-2">{{ t('data.col_match') }}</th>
              <th class="p-2">{{ t('data.col_change') }}</th>
              <th class="p-2">{{ t('score_manual.reason') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in editLog" :key="String(r.id)" class="border-t border-slate-800 text-slate-200">
              <td class="p-2 text-slate-400">{{ r.created_at }}</td>
              <td class="p-2">{{ r.changed_by_name }}</td>
              <td class="p-2">{{ r.team1_name }} vs {{ r.team2_name }} (#{{ r.match_id }})</td>
              <td class="p-2 font-mono">{{ r.team1_score }}-{{ r.team2_score }}</td>
              <td class="p-2 text-slate-400">{{ r.reason }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
