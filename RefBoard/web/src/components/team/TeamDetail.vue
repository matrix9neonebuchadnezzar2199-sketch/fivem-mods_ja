<script setup lang="ts">
import { reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'

const props = defineProps<{
  team: {
    id: number
    name: string
    short_name?: string | null
    color?: string | null
    emblem_emoji?: string | null
  } | null
  stats: Record<string, unknown> | null
}>()

const emit = defineEmits<{
  update: [
    payload: {
      teamId: number
      name: string
      shortName: string | null
      color: string | null
      emblemEmoji: string | null
    },
  ]
  delete: []
}>()

const { t } = useI18n()

const form = reactive({
  name: '',
  shortName: '',
  color: '#3b82f6',
  emblemEmoji: '⚽',
})

watch(
  () => props.team,
  (x) => {
    if (!x) return
    form.name = x.name
    form.shortName = x.short_name || ''
    form.color = x.color || '#3b82f6'
    form.emblemEmoji = x.emblem_emoji || '⚽'
  },
  { immediate: true },
)

const winRate = () => {
  const mp = Number(props.stats?.matches_played ?? 0) || 0
  if (!mp) return '0%'
  const w = Number(props.stats?.wins ?? 0) || 0
  return `${Math.round((w / mp) * 1000) / 10}%`
}

function save() {
  if (!props.team) return
  emit('update', {
    teamId: props.team.id,
    name: form.name.trim(),
    shortName: form.shortName.trim() || null,
    color: form.color || null,
    emblemEmoji: form.emblemEmoji || null,
  })
}
</script>

<template>
  <div v-if="team" class="flex h-full min-h-0 flex-col rounded-lg border border-slate-700 bg-slate-900/80 p-3">
    <h2 class="mb-2 text-sm font-semibold text-slate-200">{{ t('team_manage.detail_title') }}</h2>
    <div class="space-y-2 text-xs">
      <label class="block text-slate-400">
        {{ t('team.name') }}*
        <input v-model="form.name" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-1.5 text-slate-100" />
      </label>
      <label class="block text-slate-400">
        {{ t('team.short_name') }}
        <input v-model="form.shortName" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-1.5 text-slate-100" />
      </label>
      <label class="block text-slate-400">
        {{ t('team.color') }}
        <input v-model="form.color" type="color" class="mt-1 h-9 w-full rounded border border-slate-600 bg-slate-950" />
      </label>
      <label class="block text-slate-400">
        {{ t('team_manage.emblem_emoji') }}
        <input v-model="form.emblemEmoji" maxlength="8" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-1.5 text-slate-100" />
      </label>
    </div>
    <div class="mt-3 rounded border border-slate-700 bg-slate-950/50 p-2 text-xs text-slate-300">
      <div class="font-semibold text-slate-200">{{ t('team_manage.stats_title') }}</div>
      <div v-if="stats" class="mt-1 grid grid-cols-2 gap-1 text-[11px]">
        <div>{{ t('team_manage.stat_matches') }}: {{ stats.matches_played ?? 0 }}</div>
        <div>{{ t('team_manage.stat_winrate') }}: {{ winRate() }}</div>
        <div>{{ t('team_manage.stat_wdl') }}: {{ stats.wins ?? 0 }}-{{ stats.draws ?? 0 }}-{{ stats.losses ?? 0 }}</div>
        <div>{{ t('team_manage.stat_goals') }}: {{ stats.goals_for ?? 0 }} / {{ stats.goals_against ?? 0 }}</div>
      </div>
      <div v-else class="text-slate-500">—</div>
    </div>
    <div class="mt-auto flex gap-2 pt-3">
      <button type="button" class="flex-1 rounded-lg bg-primary px-2 py-2 text-xs font-semibold text-white" @click="save">
        {{ t('team_manage.btn_update') }}
      </button>
      <button type="button" class="rounded-lg border border-red-500/50 px-2 py-2 text-xs text-red-300" @click="$emit('delete')">
        {{ t('team_manage.btn_delete') }}
      </button>
    </div>
  </div>
  <div v-else class="flex h-full items-center justify-center rounded-lg border border-dashed border-slate-700 text-sm text-slate-500">
    {{ t('team_manage.pick_team') }}
  </div>
</template>
