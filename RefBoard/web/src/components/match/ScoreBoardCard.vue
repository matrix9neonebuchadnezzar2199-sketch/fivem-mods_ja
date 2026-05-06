<script setup lang="ts">
import { ref } from 'vue'
import { onClickOutside } from '@vueuse/core'
import { useI18n } from 'vue-i18n'
import MarqueeText from '../common/MarqueeText.vue'
import type { MatchDetailModel } from '../../types/match'

defineProps<{
  model: MatchDetailModel
  readonly: boolean
  editorHere: boolean
}>()

const emit = defineEmits<{ goal: []; manualScore: [] }>()

const { t } = useI18n()
const menuOpen = ref(false)
const menuRef = ref<HTMLElement | null>(null)
onClickOutside(menuRef, () => {
  menuOpen.value = false
})

function toggleMenu() {
  menuOpen.value = !menuOpen.value
}

function openManual() {
  menuOpen.value = false
  emit('manualScore')
}
</script>

<template>
  <div class="rounded-lg border border-slate-700 bg-slate-800/80 p-4 shadow-sm backdrop-blur">
    <div class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">{{ t('score_board.title') }}</h3>
      <span
        v-if="editorHere"
        class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300"
      >
        {{ t('match_status.editing_here') }}
      </span>
    </div>
    <div class="flex items-stretch justify-between gap-4">
      <div class="flex flex-1 flex-col items-center gap-2 text-center">
        <div class="flex h-14 w-14 items-center justify-center rounded-full bg-primary/20 text-lg font-bold text-primary">
          {{ model.home.short }}
        </div>
        <div class="w-full min-w-0 max-w-full text-center text-xs font-medium text-slate-300">
          <MarqueeText :text="model.home.name ?? ''" variant="scoreboard" />
        </div>
        <span class="rounded bg-primary/30 px-2 py-0.5 text-[10px] font-bold text-primary">HOME</span>
      </div>
      <div class="relative flex flex-col items-center justify-center px-2">
        <div class="text-7xl font-bold leading-none tracking-tight text-slate-50">
          {{ model.score.home }} - {{ model.score.away }}
        </div>
        <div class="mt-3 flex items-center gap-2 text-sm text-slate-400">
          <button type="button" class="rounded border border-slate-600 px-2 py-0.5" disabled>−</button>
          <span class="font-mono text-lg text-slate-200">{{ model.clockMmSs }}</span>
          <button type="button" class="rounded border border-slate-600 px-2 py-0.5" disabled>+</button>
        </div>
        <div class="mt-1 text-xs text-emerald-400">{{ model.clockLabel }}</div>
        <div class="mt-3 flex flex-wrap items-center justify-center gap-2">
          <button
            type="button"
            class="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-40"
            :disabled="readonly"
            @click="emit('goal')"
          >
            {{ t('score_board.goal') }}
          </button>
          <div ref="menuRef" class="relative">
            <button
              type="button"
              class="rounded border border-slate-600 px-2 py-1.5 text-xs text-slate-300 disabled:opacity-40"
              :disabled="readonly"
              @click.stop="toggleMenu"
            >
              ⋯
            </button>
            <div
              v-if="menuOpen"
              class="absolute right-0 z-20 mt-1 w-48 rounded-lg border border-slate-600 bg-slate-900 py-1 shadow-xl"
            >
              <button type="button" class="block w-full px-3 py-2 text-left text-xs hover:bg-slate-800" @click="openManual">
                {{ t('score_board.manual_edit') }}
              </button>
            </div>
          </div>
        </div>
      </div>
      <div class="flex flex-1 flex-col items-center gap-2 text-center">
        <div class="flex h-14 w-14 items-center justify-center rounded-full bg-slate-600/60 text-lg font-bold text-slate-200">
          {{ model.away.short }}
        </div>
        <div class="w-full min-w-0 max-w-full text-center text-xs font-medium text-slate-300">
          <MarqueeText :text="model.away.name ?? ''" variant="scoreboard" />
        </div>
        <span class="rounded bg-slate-600/50 px-2 py-0.5 text-[10px] font-bold text-slate-400">AWAY</span>
      </div>
    </div>
  </div>
</template>
