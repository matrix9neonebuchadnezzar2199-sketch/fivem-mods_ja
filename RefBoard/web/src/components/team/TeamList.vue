<script setup lang="ts">
import { useI18n } from 'vue-i18n'

export type ManageTeamRow = {
  id: number
  name: string
  short_name?: string | null
  color?: string | null
  emblem_emoji?: string | null
  roster_count?: number
  last_match_date?: string | null
}

defineProps<{
  teams: ManageTeamRow[]
  selectedId: number | null
  search: string
}>()

defineEmits<{
  'update:search': [string]
  select: [id: number]
  create: []
}>()

const { t } = useI18n()
</script>

<template>
  <div class="flex h-full min-h-0 flex-col rounded-lg border border-slate-700 bg-slate-900/80 p-3">
    <div class="mb-2 flex items-center justify-between gap-2">
      <h2 class="text-sm font-semibold text-slate-200">{{ t('team_manage.list_title') }}</h2>
      <button type="button" class="rounded bg-primary px-2 py-1 text-xs font-semibold text-white" @click="$emit('create')">
        {{ t('team_manage.new_team') }}
      </button>
    </div>
    <input
      :value="search"
      class="mb-2 w-full rounded border border-slate-600 bg-slate-950 px-2 py-1.5 text-xs text-slate-100"
      :placeholder="t('team_manage.search_ph')"
      @input="$emit('update:search', ($event.target as HTMLInputElement).value)"
    />
    <div class="min-h-0 flex-1 overflow-auto">
      <table class="w-full border-collapse text-left text-xs">
        <thead class="sticky top-0 bg-slate-900 text-slate-400">
          <tr>
            <th class="p-1">{{ t('team_manage.col_logo') }}</th>
            <th class="p-1">{{ t('team.short_name') }}</th>
            <th class="p-1">{{ t('team.name') }}</th>
            <th class="p-1">{{ t('team_manage.col_roster') }}</th>
            <th class="p-1">{{ t('team_manage.col_last') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="x in teams"
            :key="x.id"
            class="cursor-pointer border-t border-slate-800 hover:bg-slate-800/80"
            :class="selectedId === x.id ? 'bg-slate-800' : ''"
            @click="$emit('select', x.id)"
          >
            <td class="p-1 text-lg">{{ x.emblem_emoji || '⚽' }}</td>
            <td class="p-1 text-slate-300">{{ x.short_name || '—' }}</td>
            <td class="p-1 font-medium text-slate-100">{{ x.name }}</td>
            <td class="p-1 text-slate-400">{{ x.roster_count ?? 0 }}</td>
            <td class="p-1 text-slate-500">{{ x.last_match_date || '—' }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
