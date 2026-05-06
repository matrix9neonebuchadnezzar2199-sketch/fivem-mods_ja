<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../../composables/useNui'

type RosterRow = {
  id: number
  player_name: string
  jersey_number: number | null
  position: string | null
  license: string | null
}

const props = defineProps<{
  open: boolean
  matchId: number
  teamId: number
}>()

const emit = defineEmits<{ 'update:open': [boolean]; added: [] }>()

const { t } = useI18n()
const { send, on } = useNui()

const mode = ref<'server' | 'roster'>('server')
const serverId = ref('')
const previewName = ref('')
const previewLicense = ref<string | null>(null)
const jerseyNumber = ref<number | null>(null)
const position = ref<'GK' | 'DF' | 'MF' | 'FW'>('MF')
const isStarter = ref(true)
const error = ref('')
const licenseWarn = ref(false)
const showDup = ref(false)

const rosterRows = ref<RosterRow[]>([])
const rosterPickId = ref<number | null>(null)

let deb: ReturnType<typeof setTimeout> | null = null

function close() {
  emit('update:open', false)
}

function reset() {
  mode.value = 'server'
  serverId.value = ''
  previewName.value = ''
  previewLicense.value = null
  jerseyNumber.value = null
  position.value = 'MF'
  isStarter.value = true
  error.value = ''
  licenseWarn.value = false
  showDup.value = false
  rosterRows.value = []
  rosterPickId.value = null
}

watch(
  () => props.open,
  (v) => {
    if (v) reset()
  },
)

watch(mode, (m) => {
  error.value = ''
  if (m === 'roster' && props.open && props.teamId) {
    void loadRoster()
  }
})

async function loadRoster() {
  const un = on('refboard:team:roster:list:ack', (r: { rows?: RosterRow[] }) => {
    un()
    rosterRows.value = r.rows ?? []
  })
  await send('team_roster_list', { teamId: props.teamId })
}

watch(serverId, () => {
  error.value = ''
  previewName.value = ''
  previewLicense.value = null
  licenseWarn.value = false
  if (deb) clearTimeout(deb)
  const n = Number(serverId.value)
  if (!n || n < 1) return
  deb = setTimeout(() => {
    deb = null
    const un = on('refboard:player:resolve:ack', (r: { ok?: boolean; name?: string; license?: string | null; error?: string }) => {
      un()
      if (r?.ok && r.name) {
        previewName.value = r.name
        previewLicense.value = r.license ?? null
        if (!r.license) licenseWarn.value = true
      } else {
        error.value = t('player.resolve_fail', { id: n })
      }
    })
    void send('player_resolve', { serverId: n })
  }, 500)
})

async function loadOnline() {
  const un = on('refboard:player:online_list:ack', (r: { players?: { serverId: number; name: string }[] }) => {
    un()
    const first = r.players?.[0]
    if (first) {
      serverId.value = String(first.serverId)
    }
  })
  await send('player_online_list', {})
}

async function submitServer(force: boolean) {
  const sid = Number(serverId.value)
  if (!sid || !previewName.value) {
    error.value = t('player.add_need_resolve')
    return
  }
  const un = on('refboard:player:add:ack', (r: { ok?: boolean; error?: string }) => {
    un()
    if (r?.ok) {
      emit('added')
      close()
      return
    }
    if (r?.error === 'duplicate_license' && !force) {
      showDup.value = true
      return
    }
    error.value = r?.error || 'error'
  })
  await send('player_add', {
    matchId: props.matchId,
    teamId: props.teamId,
    serverId: sid,
    playerName: previewName.value,
    license: previewLicense.value,
    jerseyNumber: jerseyNumber.value,
    position: position.value,
    isStarter: isStarter.value,
    force,
  })
}

async function submitRoster(force: boolean) {
  if (!rosterPickId.value) {
    error.value = t('player.add_need_resolve')
    return
  }
  const un = on('refboard:player:add_from_roster:ack', (r: { ok?: boolean; error?: string }) => {
    un()
    if (r?.ok) {
      emit('added')
      close()
      return
    }
    if (r?.error === 'duplicate_license' && !force) {
      showDup.value = true
      return
    }
    error.value = r?.error || 'error'
  })
  await send('player_add_from_roster', {
    matchId: props.matchId,
    teamId: props.teamId,
    rosterId: rosterPickId.value,
    isStarter: isStarter.value,
    force,
  })
}

async function submit(force: boolean) {
  if (mode.value === 'server') {
    await submitServer(force)
  } else {
    await submitRoster(force)
  }
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[150] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
    @click.self="close"
  >
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">{{ t('player.add_title') }}</h2>

      <div class="mb-3 flex gap-1 rounded-lg border border-slate-700 p-1 text-xs">
        <button
          type="button"
          class="flex-1 rounded-md px-2 py-2 font-semibold"
          :class="mode === 'server' ? 'bg-primary text-white' : 'text-slate-400'"
          @click="mode = 'server'"
        >
          {{ t('player.add_mode_server') }}
        </button>
        <button
          type="button"
          class="flex-1 rounded-md px-2 py-2 font-semibold"
          :class="mode === 'roster' ? 'bg-primary text-white' : 'text-slate-400'"
          @click="mode = 'roster'"
        >
          {{ t('player.add_mode_roster') }}
        </button>
      </div>

      <div v-if="mode === 'server'" class="space-y-3 text-sm">
        <label class="block text-slate-400">
          {{ t('player.enter_server_id') }}
          <input
            v-model="serverId"
            type="number"
            min="1"
            class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100"
            :placeholder="t('player.server_id_ph')"
          />
        </label>
        <button type="button" class="text-xs text-primary hover:underline" @click="loadOnline">{{ t('player.pick_online') }}</button>
        <div v-if="previewName" class="rounded border border-slate-600 bg-slate-950/80 px-2 py-2 text-slate-200">
          {{ previewName }}
          <span v-if="licenseWarn" class="ml-2 text-amber-400">{{ t('player.license_warn') }}</span>
        </div>
      </div>

      <div v-else class="max-h-48 space-y-2 overflow-y-auto text-sm">
        <p class="text-xs text-slate-500">{{ t('player.add_from_roster') }}</p>
        <button
          v-for="row in rosterRows"
          :key="row.id"
          type="button"
          class="block w-full rounded border px-2 py-2 text-left"
          :class="rosterPickId === row.id ? 'border-primary bg-primary/10 text-slate-50' : 'border-slate-600 bg-slate-950 text-slate-200'"
          @click="rosterPickId = row.id"
        >
          <span class="font-mono text-primary">{{ row.jersey_number ?? '—' }}</span>
          {{ row.player_name }}
          <span class="text-xs text-slate-500">{{ row.position || '' }}</span>
        </button>
        <p v-if="!rosterRows.length" class="text-xs text-slate-500">{{ t('team_manage.pick_team') }}</p>
      </div>

      <p v-if="error" class="mt-2 text-sm text-red-400">{{ error }}</p>
      <div v-if="showDup" class="mt-2 rounded border border-amber-600/50 bg-amber-500/10 p-2 text-amber-200">
        {{ t('player.duplicate_body') }}
        <div class="mt-2 flex gap-2">
          <button type="button" class="rounded border border-slate-500 px-2 py-1 text-xs" @click="showDup = false">{{ t('dialog.no') }}</button>
          <button type="button" class="rounded bg-amber-600 px-2 py-1 text-xs font-semibold text-white drop-shadow-sm" @click="submit(true)">
            {{ t('player.duplicate_continue') }}
          </button>
        </div>
      </div>

      <div class="mt-3 space-y-2 border-t border-slate-700 pt-3 text-sm">
        <template v-if="mode === 'server'">
          <label class="block text-slate-400">
            {{ t('player.jersey_optional') }}
            <input v-model.number="jerseyNumber" type="number" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
          </label>
          <div class="text-slate-400">{{ t('player.position') }}</div>
          <div class="flex flex-wrap gap-1">
            <button
              v-for="p in ['GK', 'DF', 'MF', 'FW'] as const"
              :key="p"
              type="button"
              class="rounded px-3 py-1 text-xs font-semibold"
              :class="position === p ? 'bg-primary text-white' : 'border border-slate-600 bg-slate-800 text-slate-300'"
              @click="position = p"
            >
              {{ p }}
            </button>
          </div>
        </template>
        <label class="flex items-center gap-2 text-slate-300">
          <input v-model="isStarter" type="checkbox" class="rounded border-slate-500" />
          {{ t('player.starter') }}
        </label>
      </div>

      <div class="mt-5 flex justify-end gap-2">
        <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="close">{{ t('dialog.no') }}</button>
        <button type="button" class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white" @click="submit(false)">
          {{ t('player.add_submit') }}
        </button>
      </div>
    </div>
  </div>
</template>
