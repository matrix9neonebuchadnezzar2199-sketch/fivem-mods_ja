<script setup lang="ts">
import MarqueeText from '../common/MarqueeText.vue'
import { useI18n } from 'vue-i18n'
import type { MatchPlayer } from '../../types/match'

withDefaults(
  defineProps<{
    title: string
    players: MatchPlayer[]
    readonly: boolean
    teamId: number
    editorHere: boolean
    /** 下書き試合のみ true（誤追加の取り消し用） */
    canRemovePlayers?: boolean
    /** 枠なし（下部ドック等で外側に枠があるとき） */
    embed?: boolean
  }>(),
  { embed: false, canRemovePlayers: false },
)

const emit = defineEmits<{
  history: []
  add: [teamId: number]
  remove: [player: MatchPlayer]
}>()

const { t } = useI18n()

function statusClass(s: MatchPlayer['status']) {
  if (s === 'playing') return 'text-emerald-400'
  if (s === 'warning') return 'text-amber-400'
  if (s === 'warning_double') return 'text-amber-300'
  if (s === 'sent_off') return 'text-red-400'
  if (s === 'subbed_out') return 'text-slate-500 line-through decoration-slate-500'
  return 'text-slate-500'
}

function statusLabel(s: MatchPlayer['status']) {
  if (s === 'playing') return t('player_status.playing')
  if (s === 'warning') return t('player_status.warning')
  if (s === 'warning_double') return t('player_status.warning_double')
  if (s === 'sent_off') return t('player_status.sent_off')
  if (s === 'subbed_out') return t('player_status.subbed_out')
  return t('player_status.bench')
}

function rowClass(s: MatchPlayer['status']) {
  if (s === 'subbed_out') return 'opacity-60'
  return ''
}
</script>

<template>
  <div
    :class="
      embed
        ? 'min-w-0'
        : 'min-w-0 rounded-lg border border-slate-700/60 bg-slate-800/50 p-4 shadow-sm backdrop-blur-md'
    "
  >
    <div v-if="!embed" class="mb-2 flex min-w-0 flex-wrap items-center justify-between gap-2 overflow-hidden">
      <div class="min-w-0 flex-1 overflow-hidden pr-2">
        <MarqueeText :text="title" variant="default" />
      </div>
      <div class="flex shrink-0 items-center gap-2">
        <button type="button" class="text-[0.625rem] text-primary hover:underline" @click="emit('history')">
          {{ t('player.list_history_link') }}
        </button>
        <span
          v-if="editorHere"
          class="rounded bg-emerald-500/20 px-2 py-0.5 text-[0.625rem] font-semibold text-emerald-300"
        >
          {{ t('match_status.editing_here') }}
        </span>
      </div>
    </div>
    <div class="min-w-0 overflow-x-auto">
      <table class="w-full min-w-[280px] table-fixed border-collapse text-left text-xs">
        <thead>
          <tr class="border-b border-slate-600 text-slate-500">
            <th class="w-10 shrink-0 py-2 pr-2">No</th>
            <th class="min-w-0 py-2 pr-2">選手</th>
            <th class="w-12 shrink-0 py-2 pr-2">POS</th>
            <th class="w-24 shrink-0 py-2 pr-2">状態</th>
            <th v-if="canRemovePlayers" class="w-14 shrink-0 py-2 text-right">{{ t('player.list_actions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in players" :key="p.id" class="border-b border-slate-700/80" :class="rowClass(p.status)">
            <td class="w-10 shrink-0 py-2 pr-2 font-mono text-slate-300">{{ p.number }}</td>
            <td class="min-w-0 overflow-hidden py-2 pr-2 text-slate-100">
              <MarqueeText :text="p.name" variant="subtle" />
            </td>
            <td class="w-12 shrink-0 py-2 pr-2 text-slate-400">{{ p.position }}</td>
            <td class="w-24 shrink-0 py-2 font-medium" :class="statusClass(p.status)">{{ statusLabel(p.status) }}</td>
            <td v-if="canRemovePlayers" class="w-14 shrink-0 py-2 text-right">
              <button
                type="button"
                class="text-red-400 hover:underline disabled:opacity-40"
                :disabled="readonly"
                :title="t('player.list_remove_aria')"
                @click="emit('remove', p)"
              >
                {{ t('player.list_remove') }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <button
      type="button"
      class="mt-3 w-full rounded-lg border border-dashed border-slate-500 py-2 text-xs font-medium text-slate-300 hover:border-primary hover:text-primary disabled:opacity-40"
      :disabled="readonly"
      @click="emit('add', teamId)"
    >
      {{ t('player.list_add') }}
    </button>
  </div>
</template>
