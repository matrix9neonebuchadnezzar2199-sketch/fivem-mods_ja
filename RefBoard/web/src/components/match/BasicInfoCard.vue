<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { MatchDetailModel } from '../../types/match'

withDefaults(
  defineProps<{
    model: MatchDetailModel
    readonly: boolean
    editorHere: boolean
    /** 枠・見出しを外側に任せる埋め込み用 */
    embed?: boolean
  }>(),
  { embed: false },
)

const { t } = useI18n()
</script>

<template>
  <div
    :class="
      embed
        ? 'space-y-3'
        : 'rounded-lg border border-slate-700/60 bg-slate-800/50 p-4 shadow-sm backdrop-blur-md'
    "
  >
    <div v-if="!embed" class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">基本情報</h3>
      <span
        v-if="editorHere"
        class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300"
      >
        {{ t('match_status.editing_here') }}
      </span>
    </div>
    <div class="space-y-3">
      <label class="block text-xs text-slate-400">
        試合名
        <input
          v-model="model.matchName"
          type="text"
          class="mt-1 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-1.5 text-sm text-slate-100"
          :disabled="readonly"
        />
      </label>
      <label class="block text-xs text-slate-400">
        会場
        <input
          v-model="model.venue"
          type="text"
          class="mt-1 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-1.5 text-sm text-slate-100"
          :disabled="readonly"
        />
      </label>
      <div class="grid grid-cols-2 gap-2">
        <label class="block text-xs text-slate-400">
          日付
          <input
            v-model="model.matchDate"
            type="date"
            class="refboard-input-pickers mt-1 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-1.5 text-sm text-slate-100"
            :disabled="readonly"
          />
        </label>
        <label class="block text-xs text-slate-400">
          開始
          <input
            v-model="model.kickoffTime"
            type="time"
            class="refboard-input-pickers mt-1 w-full rounded border border-slate-600 bg-slate-900/80 px-2 py-1.5 text-sm text-slate-100"
            :disabled="readonly"
          />
        </label>
      </div>
    </div>
  </div>
</template>
