<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useNui } from '../composables/useNui'
import { useSessionStore } from '../stores/session'
import type { MatchListRow, TeamRow } from '../types/match'
import CreateMatchDialog from '../components/match/CreateMatchDialog.vue'

const { t } = useI18n()
const router = useRouter()
const session = useSessionStore()
const { send, on } = useNui()

const rows = ref<MatchListRow[]>([])
const teams = ref<TeamRow[]>([])
const filter = ref<'all' | 'draft' | 'finished' | 'cancelled'>('all')
const showCreate = ref(false)
const showLock = ref(false)
const lockPeer = ref('')
const pendingOpenId = ref<number | null>(null)
const showReopen = ref(false)
const reopenId = ref<number | null>(null)

let offMatch: (() => void) | null = null
let offTeam: (() => void) | null = null
let stopAfterEach: (() => void) | undefined

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
  stopAfterEach = router.afterEach((to, from) => {
    if (to.name === 'matches' && from.name === 'match-detail') {
      loadMatches()
    }
  })
})

onUnmounted(() => {
  offMatch?.()
  offTeam?.()
  stopAfterEach?.()
})

watch(filter, () => {
  loadMatches()
})

function openDetail(id: number) {
  void router.push({ name: 'match-detail', params: { id: String(id) } })
}

async function openEdit(id: number) {
  const r = await session.enterEdit(id)
  if (r.ok) {
    void router.push({ name: 'match-detail', params: { id: String(id) } })
    return
  }
  lockPeer.value = r.holder?.name || t('launcher.unknown_editor')
  pendingOpenId.value = id
  showLock.value = true
}

async function openPendingAsView() {
  showLock.value = false
  const id = pendingOpenId.value
  pendingOpenId.value = null
  if (id) {
    void router.push({ name: 'match-detail', params: { id: String(id) } })
  }
}

function askReopen(id: number) {
  reopenId.value = id
  showReopen.value = true
}

async function confirmReopen() {
  const id = reopenId.value
  if (!id) return
  const er = await session.enterEdit(id)
  if (!er.ok) {
    showReopen.value = false
    reopenId.value = null
    lockPeer.value = er.holder?.name || t('launcher.unknown_editor')
    pendingOpenId.value = id
    showLock.value = true
    return
  }
  const un = on('refboard:match:reopen:ack', (r: { ok?: boolean }) => {
    un()
    if (r?.ok) {
      showReopen.value = false
      reopenId.value = null
      loadMatches()
      void router.push({ name: 'match-detail', params: { id: String(id) } })
    }
  })
  await send('match_reopen', { matchId: id })
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
            </td>
          </tr>
          <tr v-if="!rows.length">
            <td colspan="5" class="px-3 py-8 text-center text-slate-500">{{ t('match_list.empty') }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <CreateMatchDialog v-model:open="showCreate" :teams="teams" @created="onCreated" />

    <div
      v-if="showLock"
      class="fixed inset-0 z-[200] flex items-center justify-center bg-black/55 p-4"
      @click.self="showLock = false"
    >
      <div class="max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
        <h2 class="mb-2 text-lg font-semibold text-slate-50">{{ t('launcher.lock_title') }}</h2>
        <p class="mb-4 text-sm text-slate-400">{{ t('launcher.lock_body', { name: lockPeer }) }}</p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="showLock = false">
            {{ t('launcher.lock_back') }}
          </button>
          <button type="button" class="rounded-lg bg-warning/90 px-3 py-2 text-sm font-semibold text-slate-900" @click="openPendingAsView">
            {{ t('launcher.lock_open_view') }}
          </button>
        </div>
      </div>
    </div>

    <div
      v-if="showReopen"
      class="fixed inset-0 z-[200] flex items-center justify-center bg-black/55 p-4"
      @click.self="showReopen = false"
    >
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
  </div>
</template>
