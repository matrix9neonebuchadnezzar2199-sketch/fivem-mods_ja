<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../composables/useNui'
import { useToast } from '../composables/useToast'
import TeamList, { type ManageTeamRow } from '../components/team/TeamList.vue'
import TeamDetail from '../components/team/TeamDetail.vue'
import RosterList, { type RosterRow } from '../components/team/RosterList.vue'
import CreateTeamDialog from '../components/team/CreateTeamDialog.vue'
import AddRosterMemberDialog, { type RosterInitial } from '../components/team/AddRosterMemberDialog.vue'
import HelpTriggerButton from '../components/help/HelpTriggerButton.vue'

const { t } = useI18n()
const { send, on } = useNui()
const { push: toast } = useToast()

const teams = ref<ManageTeamRow[]>([])
const search = ref('')
const selectedId = ref<number | null>(null)
const team = ref<ManageTeamRow | null>(null)
const stats = ref<Record<string, number> | null>(null)
const roster = ref<RosterRow[]>([])

/** 古い team:detail:ack でフォームが上書きされるのを防ぐ */
let teamDetailSeq = 0

const showCreate = ref(false)
const showRoster = ref(false)
const rosterEditId = ref<number | null>(null)
const rosterInitial = ref<RosterInitial | null>(null)

const showDeleteTeamConfirm = ref(false)
const rosterRemoveTarget = ref<RosterRow | null>(null)

async function refreshList() {
  const un = on('refboard:team:manage_list:ack', (p: { teams?: ManageTeamRow[] }) => {
    un()
    teams.value = p.teams ?? []
  })
  await send('team_manage_list', { q: search.value.trim() })
}

async function loadDetail(id: number) {
  const seq = ++teamDetailSeq
  const un = on('refboard:team:detail:ack', (p: { team?: ManageTeamRow | null; stats?: Record<string, unknown> | null }) => {
    un()
    if (seq !== teamDetailSeq) return
    team.value = p.team ?? null
    stats.value = (p.stats as Record<string, number> | null) ?? null
  })
  await send('team_detail', { teamId: id })
}

async function loadRoster(id: number) {
  const un = on('refboard:team:roster:list:ack', (p: { rows?: RosterRow[] }) => {
    un()
    roster.value = p.rows ?? []
  })
  await send('team_roster_list', { teamId: id })
}

function selectTeam(id: number) {
  selectedId.value = id
  void loadDetail(id)
  void loadRoster(id)
}

onMounted(() => {
  void refreshList()
})

async function onUpdate(payload: {
  teamId: number
  name: string
  shortName: string | null
  color: string | null
  emblemEmoji: string | null
}) {
  const un = on('refboard:team:update:ack', (p: { ok?: boolean }) => {
    un()
    if (p?.ok) {
      if (team.value?.id === payload.teamId) {
        team.value = {
          ...team.value,
          name: payload.name,
          short_name: payload.shortName,
          color: payload.color,
          emblem_emoji: payload.emblemEmoji,
        }
      }
      void refreshList()
      void loadDetail(payload.teamId)
    }
  })
  await send('team_update', {
    teamId: payload.teamId,
    name: payload.name,
    shortName: payload.shortName,
    color: payload.color,
    emblemEmoji: payload.emblemEmoji,
  })
}

function requestDeleteTeam() {
  if (!selectedId.value) return
  showDeleteTeamConfirm.value = true
}

function closeDeleteTeamConfirm() {
  showDeleteTeamConfirm.value = false
}

async function confirmDeleteTeam() {
  if (!selectedId.value) return
  showDeleteTeamConfirm.value = false
  const id = selectedId.value
  let settled = false
  let timeoutId: ReturnType<typeof window.setTimeout> | null = null
  const un = on('refboard:team:delete:ack', (p: { ok?: boolean }) => {
    if (settled) return
    settled = true
    if (timeoutId != null) window.clearTimeout(timeoutId)
    un()
    if (p?.ok) {
      selectedId.value = null
      team.value = null
      stats.value = null
      roster.value = []
      void refreshList()
    }
  })
  timeoutId = window.setTimeout(() => {
    if (settled) return
    settled = true
    un()
    toast(t('toast.player_remove_timeout'), 'error', { ms: 8000 })
  }, 8000)
  try {
    await send('team_delete', { teamId: id })
  } catch {
    if (!settled) {
      settled = true
      if (timeoutId != null) window.clearTimeout(timeoutId)
      un()
      toast(t('toast.player_remove_timeout'), 'error', { ms: 8000 })
    }
  }
}

function openRosterAdd() {
  rosterEditId.value = null
  rosterInitial.value = null
  showRoster.value = true
}

function openRosterEdit(r: RosterRow) {
  rosterEditId.value = r.id
  rosterInitial.value = {
    player_name: r.player_name,
    jersey_number: r.jersey_number,
    position: r.position,
    license: r.license,
  }
  showRoster.value = true
}

function requestRemoveRoster(r: RosterRow) {
  rosterRemoveTarget.value = r
}

function closeRosterRemoveConfirm() {
  rosterRemoveTarget.value = null
}

async function confirmRemoveRoster() {
  const r = rosterRemoveTarget.value
  if (!r || !selectedId.value) return
  rosterRemoveTarget.value = null
  const teamId = selectedId.value
  let settled = false
  let timeoutId: ReturnType<typeof window.setTimeout> | null = null
  const un = on('refboard:team:roster:remove:ack', (p: { ok?: boolean }) => {
    if (settled) return
    settled = true
    if (timeoutId != null) window.clearTimeout(timeoutId)
    un()
    if (p?.ok) void loadRoster(teamId)
  })
  timeoutId = window.setTimeout(() => {
    if (settled) return
    settled = true
    un()
    toast(t('toast.player_remove_timeout'), 'error', { ms: 8000 })
  }, 8000)
  try {
    await send('team_roster_remove', { teamId, rosterId: r.id })
  } catch {
    if (!settled) {
      settled = true
      if (timeoutId != null) window.clearTimeout(timeoutId)
      un()
      toast(t('toast.player_remove_timeout'), 'error', { ms: 8000 })
    }
  }
}

async function onCreatedTeam(id: number) {
  await refreshList()
  selectTeam(id)
}
</script>

<template>
  <div class="flex h-full min-h-0 flex-col gap-2 p-3">
    <div class="flex shrink-0 items-center justify-end">
      <HelpTriggerButton context-id="team_manage" />
    </div>
    <div class="grid min-h-0 min-w-0 flex-1 grid-cols-1 gap-2 lg:grid-cols-[30%_1fr]">
      <TeamList
        :search="search"
        :teams="teams"
        :selected-id="selectedId"
        @update:search="
          (v) => {
            search = v
            void refreshList()
          }
        "
        @select="selectTeam"
        @open-create="showCreate = true"
      />
      <div class="grid min-h-0 min-w-0 grid-rows-1 gap-2 lg:grid-rows-2">
        <div class="min-h-0 min-w-0 w-full justify-self-start lg:w-1/2 lg:max-w-[50%]">
          <TeamDetail :team="team" :stats="stats" @update="onUpdate" @delete="requestDeleteTeam" />
        </div>
        <div class="min-h-0 min-w-0 w-full justify-self-start lg:w-1/2 lg:max-w-[50%]">
          <RosterList
            :rows="roster"
            :team-id="selectedId"
            @add="openRosterAdd"
            @edit="openRosterEdit"
            @remove="requestRemoveRoster"
          />
        </div>
      </div>
    </div>

    <CreateTeamDialog v-model:open="showCreate" @created="onCreatedTeam" />
    <AddRosterMemberDialog
      v-model:open="showRoster"
      :team-id="selectedId || 0"
      :edit-id="rosterEditId"
      :initial="rosterInitial"
      @saved="selectedId ? loadRoster(selectedId) : undefined"
    />

    <div
      v-if="showDeleteTeamConfirm"
      class="fixed inset-0 z-[170] flex items-center justify-center bg-black/55 p-4"
    >
      <div class="max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
        <p class="mb-4 text-sm text-slate-300">{{ t('team_manage.delete_confirm') }}</p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="closeDeleteTeamConfirm">
            {{ t('dialog.no') }}
          </button>
          <button type="button" class="rounded-lg bg-red-600 px-3 py-2 text-sm font-semibold text-white" @click="confirmDeleteTeam">
            {{ t('dialog.yes') }}
          </button>
        </div>
      </div>
    </div>

    <div
      v-if="rosterRemoveTarget"
      class="fixed inset-0 z-[170] flex items-center justify-center bg-black/55 p-4"
    >
      <div class="max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
        <p class="mb-4 text-sm text-slate-300">
          {{ t('team_manage.roster_remove_confirm', { name: rosterRemoveTarget.player_name }) }}
        </p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="closeRosterRemoveConfirm">
            {{ t('dialog.no') }}
          </button>
          <button type="button" class="rounded-lg bg-red-600 px-3 py-2 text-sm font-semibold text-white" @click="confirmRemoveRoster">
            {{ t('dialog.yes') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
