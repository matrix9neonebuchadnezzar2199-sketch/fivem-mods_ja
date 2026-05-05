<script setup lang="ts">
import { useI18n } from 'vue-i18n'
export type RosterRow = {
  id: number
  jersey_number: number | null
  player_name: string
  position: string | null
  license: string | null
  matches_played?: number
  goals?: number
  yellows?: number
  reds?: number
}

defineProps<{
  rows: RosterRow[]
  teamId: number | null
}>()

defineEmits<{
  add: []
  edit: [row: RosterRow]
  remove: [row: RosterRow]
}>()

const { t } = useI18n()
</script>

<template>
  <div class="flex h-full min-h-0 flex-col rounded-lg border border-slate-700 bg-slate-900/80 p-3">
    <div class="mb-2 flex items-center justify-between gap-2">
      <h2 class="text-sm font-semibold text-slate-200">{{ t('team_manage.roster_title') }}</h2>
      <button
        type="button"
        class="rounded border border-slate-600 px-2 py-1 text-xs text-slate-200 disabled:opacity-40"
        :disabled="!teamId"
        @click="$emit('add')"
      >
        {{ t('team_manage.roster_add') }}
      </button>
    </div>
    <div class="min-h-0 flex-1 overflow-auto">
      <table class="w-full border-collapse text-left text-xs">
        <thead class="sticky top-0 bg-slate-900 text-slate-400">
          <tr>
            <th class="p-1">#</th>
            <th class="p-1">{{ t('team_manage.roster_name') }}</th>
            <th class="p-1">POS</th>
            <th class="p-1">{{ t('team_manage.col_matches') }}</th>
            <th class="p-1">G</th>
            <th class="p-1">🟨</th>
            <th class="p-1">🟥</th>
            <th class="p-1">{{ t('team_manage.col_actions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in rows" :key="r.id" class="border-t border-slate-800 text-slate-200">
            <td class="p-1 font-mono">{{ r.jersey_number ?? '—' }}</td>
            <td class="p-1">{{ r.player_name }}</td>
            <td class="p-1 text-slate-400">{{ r.position || '—' }}</td>
            <td class="p-1 text-slate-400">{{ r.matches_played ?? 0 }}</td>
            <td class="p-1 text-slate-400">{{ r.goals ?? 0 }}</td>
            <td class="p-1 text-slate-400">{{ r.yellows ?? 0 }}</td>
            <td class="p-1 text-slate-400">{{ r.reds ?? 0 }}</td>
            <td class="p-1">
              <button type="button" class="mr-1 text-primary hover:underline" @click="$emit('edit', r)">{{ t('match_list.edit') }}</button>
              <button type="button" class="text-red-400 hover:underline" @click="$emit('remove', r)">{{ t('team_manage.roster_remove') }}</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
