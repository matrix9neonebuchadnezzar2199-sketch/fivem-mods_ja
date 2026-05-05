<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../../composables/useNui'

const props = defineProps<{
  open: boolean
  matchId: number
  teamId: number
}>()

const emit = defineEmits<{ 'update:open': [boolean]; added: [] }>()

const { t } = useI18n()
const { send, on } = useNui()

const serverId = ref('')
const previewName = ref('')
const previewLicense = ref<string | null>(null)
const jerseyNumber = ref<number | null>(null)
const position = ref<'GK' | 'DF' | 'MF' | 'FW'>('MF')
const isStarter = ref(true)
const error = ref('')
const licenseWarn = ref(false)
const showDup = ref(false)

let deb: ReturnType<typeof setTimeout> | null = null

function close() {
  emit('update:open', false)
}

function reset() {
  serverId.value = ''
  previewName.value = ''
  previewLicense.value = null
  jerseyNumber.value = null
  position.value = 'MF'
  isStarter.value = true
  error.value = ''
  licenseWarn.value = false
  showDup.value = false
}

watch(
  () => props.open,
  (v) => {
    if (v) reset()
  },
)

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

async function submit(force: boolean) {
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
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[150] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
    @click.self="close"
  >
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">{{ t('player.add_title') }}</h2>
      <div class="space-y-3 text-sm">
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
        <p v-if="error" class="text-sm text-red-400">{{ error }}</p>
        <div v-if="showDup" class="rounded border border-amber-600/50 bg-amber-500/10 p-2 text-amber-200">
          {{ t('player.duplicate_body') }}
          <div class="mt-2 flex gap-2">
            <button type="button" class="rounded border border-slate-500 px-2 py-1 text-xs" @click="showDup = false">{{ t('dialog.no') }}</button>
            <button type="button" class="rounded bg-amber-600 px-2 py-1 text-xs font-semibold text-slate-900" @click="submit(true)">
              {{ t('player.duplicate_continue') }}
            </button>
          </div>
        </div>
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
