<script setup lang="ts">
import { nextTick, onMounted, ref, watch } from 'vue'
import { onClickOutside } from '@vueuse/core'
import { useI18n } from 'vue-i18n'
import MarqueeText from '../common/MarqueeText.vue'
import type { MatchDetailModel } from '../../types/match'

const props = withDefaults(
  defineProps<{
    model: MatchDetailModel
    readonly: boolean
    editorHere: boolean
    embed?: boolean
  }>(),
  { embed: false },
)

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

/** 初回 props 反映後のみ増分ゴールでフラッシュ（0→読込は nextTick で同期し、減算は対象外） */
const scoreFlashReady = ref(false)
const lastHomeScore = ref(0)
const lastAwayScore = ref(0)

function syncScoreFlashBaseline() {
  lastHomeScore.value = props.model.score.home
  lastAwayScore.value = props.model.score.away
}

onMounted(() => {
  void nextTick(() => {
    syncScoreFlashBaseline()
    scoreFlashReady.value = true
  })
})

watch(
  () => props.model.id,
  () => {
    syncScoreFlashBaseline()
  },
)

const flashHomeScore = ref(false)
const flashAwayScore = ref(false)

watch(
  () => props.model.score.home,
  (nv) => {
    if (!scoreFlashReady.value) return
    const ov = lastHomeScore.value
    if (nv !== ov) {
      if (nv > ov) flashHomeScore.value = true
      lastHomeScore.value = nv
    }
  },
)

watch(
  () => props.model.score.away,
  (nv) => {
    if (!scoreFlashReady.value) return
    const ov = lastAwayScore.value
    if (nv !== ov) {
      if (nv > ov) flashAwayScore.value = true
      lastAwayScore.value = nv
    }
  },
)

function onScoreFlashAnimEnd(side: 'home' | 'away', ev: AnimationEvent) {
  if (ev.animationName !== 'rb-score-flash') return
  if (side === 'home') flashHomeScore.value = false
  else flashAwayScore.value = false
}
</script>

<template>
  <div
    :class="
      embed
        ? ''
        : 'rounded-lg border border-slate-700/60 bg-slate-800/50 p-4 shadow-sm backdrop-blur-md'
    "
  >
    <div v-if="!embed" class="mb-2 flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-slate-200">{{ t('score_board.title') }}</h3>
      <span
        v-if="editorHere"
        class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300"
      >
        {{ t('match_status.editing_here') }}
      </span>
    </div>
    <!-- flex 子の既定 min-width:auto を潰すため列ラッパーに min-w-0。中央は shrink-0 でスコア列を守る。
         overflow-hidden は左右マーキー列のみ（中央に付けると ⋯ ドロップダウンがクリップされ無反応に見える） -->
    <div class="flex min-w-0 items-stretch justify-between gap-4">
      <div class="flex min-w-0 flex-1 flex-col items-center gap-2 overflow-hidden text-center">
        <div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-primary/20 text-lg font-bold text-primary">
          {{ model.home.short }}
        </div>
        <div class="w-full min-w-0 max-w-full text-center text-xs font-medium text-slate-300">
          <MarqueeText :text="model.home.name ?? ''" variant="scoreboard" />
        </div>
        <span class="rounded bg-primary/30 px-2 py-0.5 text-[10px] font-bold text-primary">HOME</span>
      </div>
      <div class="relative flex shrink-0 flex-col items-center justify-center px-2">
        <div
          class="flex items-baseline justify-center gap-1 text-7xl font-bold tabular-nums leading-none tracking-tight text-slate-50"
        >
          <span
            class="inline-block min-w-[0.6ch] transform-gpu motion-reduce:transform-none"
            :class="{ 'rb-score-flash': flashHomeScore }"
            @animationend="onScoreFlashAnimEnd('home', $event)"
          >{{ model.score.home }}</span>
          <span class="shrink-0">-</span>
          <span
            class="inline-block min-w-[0.6ch] transform-gpu motion-reduce:transform-none"
            :class="{ 'rb-score-flash': flashAwayScore }"
            @animationend="onScoreFlashAnimEnd('away', $event)"
          >{{ model.score.away }}</span>
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
              class="absolute right-0 w-48 rounded-lg border border-slate-600 bg-slate-900 py-1 shadow-xl"
              :class="embed ? 'bottom-full z-[85] mb-1' : 'top-full z-20 mt-1'"
            >
              <button type="button" class="block w-full px-3 py-2 text-left text-xs hover:bg-slate-800" @click="openManual">
                {{ t('score_board.manual_edit') }}
              </button>
            </div>
          </div>
        </div>
      </div>
      <div class="flex min-w-0 flex-1 flex-col items-center gap-2 overflow-hidden text-center">
        <div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-slate-600/60 text-lg font-bold text-slate-200">
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
