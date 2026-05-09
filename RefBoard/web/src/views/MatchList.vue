<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from '../stores/settings'
import { useMatchesStore } from '../stores/matches'
import { useTeamsStore } from '../stores/teams'
import type { Match } from '../types/local'
import type { MatchListRow, TeamRow } from '../types/match'
import CreateMatchDialog from '../components/match/CreateMatchDialog.vue'
import HelpHoverDialog from '../components/help/HelpHoverDialog.vue'
import MatchStatusBadge from '../components/match/MatchStatusBadge.vue'
import MarqueeText from '../components/common/MarqueeText.vue'
import { formatDateJa } from '../utils/formatDate'
import { formatClockMs, parseEpochMsFromServer, remainingMsFromClock } from '../utils/matchClock'
import { useDialogOverlay } from '../composables/useDialogOverlay'

const { overlayRootClass } = useDialogOverlay()
const matchListDeleteOverlayClass = overlayRootClass('z-[200]', 'bg-black/55')
const matchListReopenOverlayClass = overlayRootClass('z-[200]', 'bg-black/55')

const { t } = useI18n()
const router = useRouter()
const settingsStore = useSettingsStore()
const { settings } = storeToRefs(settingsStore)
const matchesStore = useMatchesStore()
const teamsStore = useTeamsStore()

const listClockTick = ref(0)
let listClockInterval: ReturnType<typeof setInterval> | null = null

const filter = ref<'all' | 'draft' | 'finished' | 'cancelled'>('all')
const showCreate = ref(false)
const showReopen = ref(false)
const reopenId = ref<number | null>(null)
const showDeleteConfirm = ref(false)
const deleteId = ref<number | null>(null)
const showHelpDialog = ref(false)

let stopAfterEach: (() => void) | undefined

const teams = computed<TeamRow[]>(() =>
  teamsStore.teams.map((x) => ({
    id: x.id,
    name: x.name,
    short_name: x.shortName ?? null,
    color: x.colorHex ?? null,
    emblem_emoji: null,
  })),
)

const filteredMatches = computed(() => {
  let ms = matchesStore.matches.slice()
  if (filter.value === 'finished') ms = ms.filter((m) => m.status === 'finished')
  else if (filter.value === 'draft') ms = ms.filter((m) => m.status === 'draft' || m.status === 'live')
  else if (filter.value === 'cancelled') ms = []
  return ms
})

function toListRow(m: Match): MatchListRow {
  const dateSrc = m.scheduledAt || m.createdAt
  return {
    id: m.id,
    team1_id: m.homeTeamId,
    team2_id: m.awayTeamId,
    team1_name: m.homeName,
    team2_name: m.awayName,
    team1_score: m.homeScore,
    team2_score: m.awayScore,
    status: m.status === 'live' ? 'live' : m.status === 'finished' ? 'finished' : 'draft',
    match_date: dateSrc.slice(0, 10),
    match_name: m.title,
    venue: m.venue ?? null,
    kickoff_time: m.scheduledAt && m.scheduledAt.length >= 16 ? m.scheduledAt.slice(11, 16) : null,
    clock_running: m.clockStartedAt ? 1 : 0,
    clock_started_at: m.clockStartedAt ?? null,
    clock_accumulated_ms: m.clockAccumulatedMs,
  }
}

const rows = computed(() => filteredMatches.value.map(toListRow))

function fullMatchDurationMsFor(m: Match): number {
  return Math.max(60_000, (m.halfMinutes ?? settings.value.defaultHalfMinutes) * 2 * 60 * 1000)
}

function anyListRowClockRunning(): boolean {
  return filteredMatches.value.some((m) => m.clockStartedAt != null)
}

function syncListClockInterval() {
  if (listClockInterval != null) {
    clearInterval(listClockInterval)
    listClockInterval = null
  }
  if (anyListRowClockRunning()) {
    listClockInterval = setInterval(() => {
      listClockTick.value++
    }, 250)
  }
}

function listRemainingTimeLabel(m: MatchListRow): string {
  if (Number(m.clock_running) !== 1) return '-'
  void listClockTick.value
  const raw = matchesStore.find(m.id)
  if (!raw) return '-'
  const full = fullMatchDurationMsFor(raw)
  const started = parseEpochMsFromServer(m.clock_started_at)
  const rem = remainingMsFromClock(
    full,
    Number(m.clock_accumulated_ms) || 0,
    true,
    started,
    Date.now(),
  )
  return formatClockMs(rem)
}

onMounted(() => {
  settingsStore.load()
  syncListClockInterval()
  stopAfterEach = router.afterEach((to, from) => {
    if (to.name === 'matches' && from.name === 'match-detail') {
      syncListClockInterval()
    }
  })
})

onUnmounted(() => {
  stopAfterEach?.()
  if (listClockInterval != null) {
    clearInterval(listClockInterval)
    listClockInterval = null
  }
})

watch(
  () => matchesStore.matches,
  () => {
    syncListClockInterval()
  },
  { deep: true },
)

function openDetail(id: number) {
  void router.push({ name: 'match-detail', params: { id: String(id) } })
}

function openEdit(id: number) {
  void router.push({ name: 'match-detail', params: { id: String(id) } })
}

function askReopen(id: number) {
  reopenId.value = id
  showReopen.value = true
}

function askDelete(id: number) {
  deleteId.value = id
  showDeleteConfirm.value = true
}

function confirmDelete() {
  const id = deleteId.value
  showDeleteConfirm.value = false
  deleteId.value = null
  if (id) matchesStore.deleteMatch(id)
}

function confirmReopen() {
  const id = reopenId.value
  showReopen.value = false
  reopenId.value = null
  if (id) {
    matchesStore.reopenMatch(id)
    void router.push({ name: 'match-detail', params: { id: String(id) } })
  }
}

function onCreated(id: number) {
  showCreate.value = false
  void router.push({ name: 'match-detail', params: { id: String(id) } })
}
</script>

<template>
  <div class="flex h-full min-h-0 flex-col gap-4 p-4">
    <div class="flex flex-wrap items-center justify-between gap-2">
      <h2 class="text-lg font-semibold text-slate-50">{{ t('match_list.title') }}</h2>
      <div class="flex items-center gap-2">
        <button
          type="button"
          class="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full border border-slate-600 bg-slate-800/80 text-slate-200 hover:border-primary hover:text-primary focus:outline-none focus:ring-2 focus:ring-primary"
          :aria-label="t('help.context.open_aria')"
          :title="t('help.context.open_title')"
          @click="showHelpDialog = true"
        >
          <span aria-hidden="true" class="text-sm font-bold">?</span>
        </button>
        <button
          type="button"
          class="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-primary/20 hover:brightness-110"
          @click="showCreate = true"
        >
          {{ t('match_list.new') }}
        </button>
      </div>
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
      <table class="w-full min-w-[860px] table-fixed border-collapse text-left text-sm">
        <thead class="sticky top-0 bg-slate-900/95 text-xs uppercase text-slate-500">
          <tr>
            <th class="w-28 shrink-0 border-b border-slate-700 px-3 py-2">{{ t('match_list.col_date') }}</th>
            <th class="min-w-0 border-b border-slate-700 px-3 py-2">{{ t('match_list.col_match_name') }}</th>
            <th class="min-w-0 border-b border-slate-700 px-3 py-2">{{ t('match_list.col_teams') }}</th>
            <th class="w-28 shrink-0 border-b border-slate-700 px-3 py-2">{{ t('match_list.col_score') }}</th>
            <th class="w-24 shrink-0 border-b border-slate-700 px-3 py-2">{{ t('match_list.col_remaining_time') }}</th>
            <th class="w-28 shrink-0 border-b border-slate-700 px-3 py-2">{{ t('match_list.col_status') }}</th>
            <th class="w-56 shrink-0 border-b border-slate-700 px-3 py-2">{{ t('match_list.col_actions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="m in rows" :key="m.id" class="border-b border-slate-800 hover:bg-slate-800/40">
            <td class="px-3 py-2 text-slate-300">{{ formatDateJa(m.match_date) }}</td>
            <td class="min-w-0 overflow-hidden px-3 py-2 text-slate-100">
              <MarqueeText :text="(m.match_name && String(m.match_name).trim()) || '—'" variant="default" />
            </td>
            <td class="min-w-0 overflow-hidden px-3 py-2 text-slate-100">
              <div class="flex min-w-0 items-center gap-2">
                <span class="min-w-0 flex-1 overflow-hidden">
                  <MarqueeText :text="String(m.team1_name ?? m.team1_id)" variant="subtle" />
                </span>
                <span class="shrink-0 text-slate-500">vs</span>
                <span class="min-w-0 flex-1 overflow-hidden">
                  <MarqueeText :text="String(m.team2_name ?? m.team2_id)" variant="subtle" />
                </span>
              </div>
            </td>
            <td class="px-3 py-2 font-mono text-slate-200">{{ m.team1_score }} - {{ m.team2_score }}</td>
            <td class="px-3 py-2 font-mono tabular-nums text-slate-300">{{ listRemainingTimeLabel(m) }}</td>
            <td class="px-3 py-2">
              <MatchStatusBadge :status="m.status" />
            </td>
            <td class="px-3 py-2">
              <button type="button" class="mr-2 text-primary hover:underline" @click="openEdit(m.id)">{{ t('match_list.edit') }}</button>
              <button type="button" class="text-slate-400 hover:underline" @click="openDetail(m.id)">{{ t('match_list.detail') }}</button>
              <button
                v-if="m.status === 'finished'"
                type="button"
                class="ml-2 text-amber-400 hover:underline"
                @click="askReopen(m.id)"
              >
                {{ t('match_list.reopen') }}
              </button>
              <button type="button" class="ml-2 text-rose-400 hover:underline" @click="askDelete(m.id)">
                {{ t('match_list.delete') }}
              </button>
            </td>
          </tr>
          <tr v-if="!rows.length">
            <td colspan="7" class="px-3 py-8 text-center text-slate-500">
              <p class="mb-3">{{ t('match_list.empty') }}</p>
              <button type="button" class="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white" @click="showCreate = true">
                {{ t('match_list.cta_first_match') }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <CreateMatchDialog v-model:open="showCreate" :teams="teams" @created="onCreated" />

    <div v-if="showDeleteConfirm" :class="matchListDeleteOverlayClass">
      <div class="max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
        <h2 class="mb-2 text-lg font-semibold text-slate-50">{{ t('match_list.delete_title') }}</h2>
        <p class="mb-4 text-sm text-slate-400">{{ t('match_list.delete_body') }}</p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="showDeleteConfirm = false">
            {{ t('dialog.no') }}
          </button>
          <button type="button" class="rounded-lg bg-rose-600 px-3 py-2 text-sm font-semibold text-white" @click="confirmDelete">
            {{ t('match_list.delete_confirm') }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="showReopen" :class="matchListReopenOverlayClass">
      <div class="max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
        <h2 class="mb-2 text-lg font-semibold text-slate-50">{{ t('match_list.reopen_title') }}</h2>
        <p class="mb-4 text-sm text-slate-400">{{ t('match_list.reopen_body') }}</p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="showReopen = false">
            {{ t('dialog.no') }}
          </button>
          <button type="button" class="rounded-lg bg-amber-600 px-3 py-2 text-sm font-semibold text-white" @click="confirmReopen">
            {{ t('match_list.reopen_confirm') }}
          </button>
        </div>
      </div>
    </div>

    <HelpHoverDialog context-id="match_list" :open="showHelpDialog" @close="showHelpDialog = false" />
  </div>
</template>
