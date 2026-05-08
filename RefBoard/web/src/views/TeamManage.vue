<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../composables/useNui'
import TeamList, { type ManageTeamRow } from '../components/team/TeamList.vue'
import TeamDetail from '../components/team/TeamDetail.vue'
import RosterList, { type RosterRow } from '../components/team/RosterList.vue'
import CreateTeamDialog from '../components/team/CreateTeamDialog.vue'
import AddRosterMemberDialog, { type RosterInitial } from '../components/team/AddRosterMemberDialog.vue'
import HelpTriggerButton from '../components/help/HelpTriggerButton.vue'

const { t } = useI18n()
const { send, on } = useNui()

const teams = ref<ManageTeamRow[]>([])
const search = ref('')
const selectedId = ref<number | null>(null)
const team = ref<ManageTeamRow | null>(null)
const stats = ref<Record<string, number> | null>(null)
const roster = ref<RosterRow[]>([])

const showCreate = ref(false)
const showRoster = ref(false)
const rosterEditId = ref<number | null>(null)
const rosterInitial = ref<RosterInitial | null>(null)

async function refreshList() {
  const un = on('refboard:team:manage_list:ack', (p: { teams?: ManageTeamRow[] }) => {
    un()
    teams.value = p.teams ?? []
  })
  await send('team_manage_list', { q: search.value.trim() })
}

async function loadDetail(id: number) {
  const un = on('refboard:team:detail:ack', (p: { team?: ManageTeamRow | null; stats?: Record<string, unknown> | null }) => {
    un()
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

async function onDelete() {
  if (!selectedId.value) return
  if (!confirm(t('team_manage.delete_confirm'))) return
  const id = selectedId.value
  const un = on('refboard:team:delete:ack', (p: { ok?: boolean }) => {
    un()
    if (p?.ok) {
      selectedId.value = null
      team.value = null
      stats.value = null
      roster.value = []
      void refreshList()
    }
  })
  await send('team_delete', { teamId: id })
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

async function removeRoster(r: RosterRow) {
  if (!selectedId.value) return
  if (!confirm(t('team_manage.roster_remove_confirm', { name: r.player_name }))) return
  const un = on('refboard:team:roster:remove:ack', (p: { ok?: boolean }) => {
    un()
    if (p?.ok) void loadRoster(selectedId.value!)
  })
  await send('team_roster_remove', { teamId: selectedId.value, rosterId: r.id })
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
        <TeamDetail :team="team" :stats="stats" @update="onUpdate" @delete="onDelete" />
        <RosterList
          :rows="roster"
          :team-id="selectedId"
          @add="openRosterAdd"
          @edit="openRosterEdit"
          @remove="removeRoster"
        />
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
  </div>
</template>
