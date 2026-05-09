<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import TeamList, { type ManageTeamRow } from '../components/team/TeamList.vue'
import TeamDetail from '../components/team/TeamDetail.vue'
import RosterList, { type RosterRow } from '../components/team/RosterList.vue'
import CreateTeamDialog from '../components/team/CreateTeamDialog.vue'
import AddRosterMemberDialog, { type RosterInitial } from '../components/team/AddRosterMemberDialog.vue'
import HelpTriggerButton from '../components/help/HelpTriggerButton.vue'
import { useTeamsStore } from '../stores/teams'
import { useMatchesStore } from '../stores/matches'
import { useDialogOverlay } from '../composables/useDialogOverlay'

const { overlayRootClass } = useDialogOverlay()
const teamDeleteOverlayClass = overlayRootClass('z-[170]', 'bg-black/55')
const rosterRemoveOverlayClass = overlayRootClass('z-[170]', 'bg-black/55')

const { t } = useI18n()
const teamsStore = useTeamsStore()
const matchesStore = useMatchesStore()

const search = ref('')
const selectedId = ref<number | null>(null)

const teams = computed((): ManageTeamRow[] => {
  const q = search.value.trim().toLowerCase()
  return teamsStore.teams
    .filter((x) => !q || x.name.toLowerCase().includes(q))
    .map((x) => ({
      id: x.id,
      name: x.name,
      short_name: x.shortName ?? null,
      color: x.colorHex ?? null,
      emblem_emoji: null,
      roster_count: teamsStore.rosterFor(x.id).length,
      last_match_date: null,
    }))
})

const team = computed(() => {
  if (!selectedId.value) return null
  const x = teamsStore.getTeam(selectedId.value)
  if (!x) return null
  return {
    id: x.id,
    name: x.name,
    short_name: x.shortName ?? null,
    color: x.colorHex ?? null,
    emblem_emoji: null as string | null,
  }
})

const stats = computed((): Record<string, number> | null => null)

const roster = computed((): RosterRow[] => {
  if (!selectedId.value) return []
  return teamsStore.rosterFor(selectedId.value).map((r) => ({
    id: r.id,
    jersey_number: r.number ?? null,
    player_name: r.name,
    position: r.position ?? null,
    license: r.note ?? null,
  }))
})

const showCreate = ref(false)
const showRoster = ref(false)
const rosterEditId = ref<number | null>(null)
const rosterInitial = ref<RosterInitial | null>(null)

const showDeleteTeamConfirm = ref(false)
const rosterRemoveTarget = ref<RosterRow | null>(null)

function selectTeam(id: number) {
  selectedId.value = id
}

function onUpdate(payload: {
  teamId: number
  name: string
  shortName: string | null
  color: string | null
  emblemEmoji: string | null
}) {
  void payload.emblemEmoji
  teamsStore.updateTeam(payload.teamId, {
    name: payload.name,
    shortName: payload.shortName,
    colorHex: payload.color,
  })
  matchesStore.refreshTeamNames(payload.teamId, payload.name.trim())
}

function requestDeleteTeam() {
  if (!selectedId.value) return
  showDeleteTeamConfirm.value = true
}

function closeDeleteTeamConfirm() {
  showDeleteTeamConfirm.value = false
}

function confirmDeleteTeam() {
  if (!selectedId.value) return
  showDeleteTeamConfirm.value = false
  teamsStore.deleteTeam(selectedId.value)
  selectedId.value = null
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

function confirmRemoveRoster() {
  const r = rosterRemoveTarget.value
  if (!r) return
  rosterRemoveTarget.value = null
  teamsStore.removeRosterMember(r.id)
}

function onCreatedTeam(id: number) {
  showCreate.value = false
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
        @update:search="(v) => (search = v)"
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
      @saved="() => {}"
    />

    <div v-if="showDeleteTeamConfirm" :class="teamDeleteOverlayClass">
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

    <div v-if="rosterRemoveTarget" :class="rosterRemoveOverlayClass">
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
