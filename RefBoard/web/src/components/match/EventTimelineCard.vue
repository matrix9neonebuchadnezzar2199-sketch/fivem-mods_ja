<script setup lang="ts">
import MarqueeText from '../common/MarqueeText.vue'
import { ref } from 'vue'
import { onClickOutside } from '@vueuse/core'
import { useI18n } from 'vue-i18n'
import type { MatchEvent } from '../../types/match'

withDefaults(
  defineProps<{
    events: MatchEvent[]
    readonly: boolean
    editorHere: boolean
    embed?: boolean
  }>(),
  { embed: false },
)

const emit = defineEmits<{ substitute: []; issueCard: [kind: 'yellow' | 'red'] }>()

const { t } = useI18n()
const menuOpen = ref(false)
const menuRef = ref<HTMLElement | null>(null)
onClickOutside(menuRef, () => {
  menuOpen.value = false
})

function toggleMenu() {
  menuOpen.value = !menuOpen.value
}

function pick(kind: 'sub' | 'yellow' | 'red') {
  menuOpen.value = false
  if (kind === 'sub') emit('substitute')
  else emit('issueCard', kind)
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
    <div v-if="!embed" class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">{{ t('events.title') }}</h3>
      <span
        v-if="editorHere"
        class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300"
      >
        {{ t('match_status.editing_here') }}
      </span>
    </div>
    <ul class="max-h-64 min-w-0 space-y-2 overflow-y-auto overflow-x-hidden pr-1 text-sm">
      <li
        v-for="e in events"
        :key="e.id"
        class="flex min-w-0 gap-2 overflow-hidden rounded bg-slate-900/50 px-2 py-1.5 font-mono text-slate-200"
      >
        <span class="shrink-0 text-primary">{{ e.minute }}</span>
        <div class="min-w-0 flex-1 overflow-hidden">
          <MarqueeText :text="e.text" variant="default" />
        </div>
      </li>
    </ul>
    <div ref="menuRef" class="relative mt-3">
      <button
        type="button"
        class="w-full rounded-lg border border-dashed border-slate-500 py-2 text-xs font-medium text-slate-300 hover:border-primary hover:text-primary disabled:opacity-40"
        :disabled="readonly"
        @click="toggleMenu"
      >
        {{ t('events.add') }}
      </button>
      <div
        v-if="menuOpen && !readonly"
        class="absolute bottom-full left-0 z-30 mb-1 w-full rounded-lg border border-slate-600 bg-slate-900 py-1 shadow-xl"
      >
        <button type="button" class="block w-full px-3 py-2 text-left text-xs hover:bg-slate-800" @click="pick('sub')">
          {{ t('match.substitute') }}
        </button>
        <button type="button" class="block w-full px-3 py-2 text-left text-xs hover:bg-slate-800" @click="pick('yellow')">
          {{ t('events.add_yellow') }}
        </button>
        <button type="button" class="block w-full px-3 py-2 text-left text-xs hover:bg-slate-800" @click="pick('red')">
          {{ t('events.add_red') }}
        </button>
      </div>
    </div>
  </div>
</template>
