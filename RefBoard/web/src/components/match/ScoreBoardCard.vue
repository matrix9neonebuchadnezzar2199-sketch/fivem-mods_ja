<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import MarqueeText from '../common/MarqueeText.vue'
import type { MatchDetailModel } from '../../types/match'

const props = withDefaults(
  defineProps<{
    model: MatchDetailModel
    readonly: boolean
    editorHere: boolean
    embed?: boolean
    /** 親が残り時間など毎ティック更新する表示用（未指定なら model.clockMmSs） */
    clockMmSsOverride?: string | null
    /** 時計の進行状態（試合時計の下に表示） */
    clockPhaseLabel?: string
  }>(),
  { embed: false, clockMmSsOverride: undefined, clockPhaseLabel: '' },
)

const displayClockMmSs = computed(() =>
  props.clockMmSsOverride != null && props.clockMmSsOverride !== '' ? props.clockMmSsOverride : props.model.clockMmSs,
)

const emit = defineEmits<{
  goal: []
  manualScore: []
  /** 時計 UI（サーバー連携は親・NUI 側で後付け可） */
  clockStart: []
  clockStop: []
  clockClear: []
  /** 残り時間の手動補正（ms。±60*1000） */
  clockAdjust: [deltaMs: number]
}>()

const { t } = useI18n()
const goalMenuOpen = ref(false)
/** ラッパー（ボタン）。インライン／Teleport どちらでも外側クリック判定に使う */
const goalMenuRef = ref<HTMLElement | null>(null)
const goalButtonRef = ref<HTMLButtonElement | null>(null)
/** embed 時のみ body へ Teleport したパネル */
const goalMenuPanelRef = ref<HTMLElement | null>(null)
const goalMenuPanelStyle = ref<Record<string, string>>({})

function onGlobalPointerDown(ev: PointerEvent) {
  if (!goalMenuOpen.value) return
  const t = ev.target as Node | null
  if (!t) return
  if (goalMenuRef.value?.contains(t)) return
  if (goalMenuPanelRef.value?.contains(t)) return
  goalMenuOpen.value = false
}

function onWindowResizeForGoalMenu() {
  if (goalMenuOpen.value && props.embed) {
    void updateGoalMenuPanelPosition()
  }
}

watch(goalMenuOpen, async (open) => {
  if (open) {
    await nextTick()
    if (props.embed) {
      await nextTick()
      await updateGoalMenuPanelPosition()
      requestAnimationFrame(() => {
        void updateGoalMenuPanelPosition()
      })
      window.addEventListener('resize', onWindowResizeForGoalMenu)
    }
    requestAnimationFrame(() => {
      document.addEventListener('pointerdown', onGlobalPointerDown, true)
    })
  } else {
    document.removeEventListener('pointerdown', onGlobalPointerDown, true)
    window.removeEventListener('resize', onWindowResizeForGoalMenu)
  }
})

async function updateGoalMenuPanelPosition() {
  const btn = goalButtonRef.value
  if (!btn) return
  const r = btn.getBoundingClientRect()
  const panel = goalMenuPanelRef.value
  const menuH = panel?.offsetHeight ?? 96
  const gap = 8
  let top = r.top - menuH - gap
  if (top < gap) {
    top = r.bottom + gap
  }
  const w = Math.max(224, Math.min(280, r.width + 160))
  let left = r.left + r.width / 2 - w / 2
  left = Math.max(gap, Math.min(left, window.innerWidth - w - gap))
  goalMenuPanelStyle.value = {
    top: `${top}px`,
    left: `${left}px`,
    width: `${w}px`,
  }
}

function toggleGoalMenu() {
  goalMenuOpen.value = !goalMenuOpen.value
}

function openGoalWizard() {
  goalMenuOpen.value = false
  emit('goal')
}

function openManualFromGoalMenu() {
  goalMenuOpen.value = false
  emit('manualScore')
}

const showClearConfirm = ref(false)

function confirmClockClear() {
  showClearConfirm.value = false
  emit('clockClear')
}

function cancelClockClear() {
  showClearConfirm.value = false
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

onUnmounted(() => {
  document.removeEventListener('pointerdown', onGlobalPointerDown, true)
  window.removeEventListener('resize', onWindowResizeForGoalMenu)
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
        ? 'relative'
        : 'relative rounded-lg border border-slate-700/60 bg-slate-800/92 p-4 shadow-sm'
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
         overflow-hidden は左右マーキー列のみ（中央に付けると [ゴール] メニューがクリップされ無反応に見える） -->
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
        <div ref="goalMenuRef" class="relative mb-2 flex flex-wrap items-center justify-center">
          <button
            ref="goalButtonRef"
            type="button"
            class="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-40"
            :disabled="readonly"
            :aria-expanded="goalMenuOpen"
            aria-haspopup="menu"
            :aria-label="t('score_board.goal_menu_aria')"
            @click.stop="toggleGoalMenu"
          >
            {{ t('score_board.goal') }}
          </button>
          <div
            v-if="goalMenuOpen && !embed"
            role="menu"
            class="absolute left-1/2 z-20 mt-1 min-w-[14rem] -translate-x-1/2 rounded-lg border border-slate-600 bg-slate-900 py-1 shadow-xl"
          >
            <button
              type="button"
              role="menuitem"
              class="block w-full px-3 py-2 text-left hover:bg-slate-800"
              @click="openGoalWizard"
            >
              <span class="block text-xs font-medium text-slate-200">{{ t('score_board.goal_menu_record') }}</span>
              <span class="mt-0.5 block text-[10px] leading-snug text-slate-500">{{ t('score_board.goal_menu_record_hint') }}</span>
            </button>
            <button
              type="button"
              role="menuitem"
              class="block w-full px-3 py-2 text-left text-xs text-slate-200 hover:bg-slate-800"
              @click="openManualFromGoalMenu"
            >
              {{ t('score_board.goal_menu_manual') }}
            </button>
          </div>
        </div>
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
          <button
            type="button"
            class="rounded border border-slate-600 px-2 py-0.5 hover:bg-slate-700 disabled:opacity-40"
            :disabled="readonly"
            title="−1分（残り時間を減らす）"
            @click="emit('clockAdjust', -60 * 1000)"
          >
            −
          </button>
          <span class="font-mono text-lg text-slate-200">{{ displayClockMmSs }}</span>
          <button
            type="button"
            class="rounded border border-slate-600 px-2 py-0.5 hover:bg-slate-700 disabled:opacity-40"
            :disabled="readonly"
            title="+1分（残り時間を増やす）"
            @click="emit('clockAdjust', 60 * 1000)"
          >
            +
          </button>
        </div>
        <div v-if="clockPhaseLabel" class="mt-0.5 text-center text-[11px] font-medium text-slate-400">
          {{ clockPhaseLabel }}
        </div>
        <div v-if="model.dbStatus !== 'draft'" class="mt-1 text-xs text-emerald-400">{{ model.clockLabel }}</div>
        <div class="mt-3 flex flex-wrap items-center justify-center gap-2">
          <button
            type="button"
            class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full border-2 border-blue-400 bg-slate-900 text-blue-400 shadow-sm hover:bg-slate-800 disabled:opacity-40"
            :disabled="readonly"
            :aria-label="t('score_board.clock_start_aria')"
            :title="t('score_board.clock_start_aria')"
            @click="emit('clockStart')"
          >
            <svg class="ml-0.5 h-4 w-4" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M8 5v14l11-7z" />
            </svg>
          </button>
          <button
            type="button"
            class="rounded border border-red-500/70 bg-red-500/10 px-2.5 py-1.5 text-xs font-semibold text-red-200 hover:bg-red-500/20 disabled:opacity-40"
            :disabled="readonly"
            :aria-label="t('score_board.clock_stop_aria')"
            :title="t('score_board.clock_stop_aria')"
            @click="emit('clockStop')"
          >
            {{ t('score_board.clock_pause') }}
          </button>
          <button
            type="button"
            class="rounded border border-amber-500/70 bg-amber-500/10 px-2.5 py-1.5 text-xs font-semibold text-amber-200 hover:bg-amber-500/20 disabled:opacity-40"
            :disabled="readonly"
            :aria-label="t('score_board.clock_clear_aria')"
            :title="t('score_board.clock_clear_aria')"
            @click="showClearConfirm = true"
          >
            {{ t('score_board.clock_clear') }}
          </button>
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

    <Teleport to="body">
      <div
        v-if="goalMenuOpen && embed"
        ref="goalMenuPanelRef"
        role="menu"
        class="fixed z-[200] rounded-lg border border-slate-600 bg-slate-900 py-1 shadow-xl"
        :style="goalMenuPanelStyle"
      >
        <button
          type="button"
          role="menuitem"
          class="block w-full px-3 py-2 text-left hover:bg-slate-800"
          @click="openGoalWizard"
        >
          <span class="block text-xs font-medium text-slate-200">{{ t('score_board.goal_menu_record') }}</span>
          <span class="mt-0.5 block text-[10px] leading-snug text-slate-500">{{ t('score_board.goal_menu_record_hint') }}</span>
        </button>
        <button
          type="button"
          role="menuitem"
          class="block w-full px-3 py-2 text-left text-xs text-slate-200 hover:bg-slate-800"
          @click="openManualFromGoalMenu"
        >
          {{ t('score_board.goal_menu_manual') }}
        </button>
      </div>
    </Teleport>

    <Teleport to="body">
      <div
        v-if="showClearConfirm"
        class="fixed inset-0 z-[210] flex items-center justify-center bg-black/55 p-4"
        role="dialog"
        aria-modal="true"
        aria-labelledby="score-clock-clear-title"
        @click.self="cancelClockClear"
      >
        <div class="max-w-sm rounded-xl border border-amber-600/50 bg-slate-900 p-5 shadow-2xl">
          <h2 id="score-clock-clear-title" class="mb-2 text-base font-semibold text-amber-100">
            {{ t('score_board.clock_clear_confirm_title') }}
          </h2>
          <p class="mb-4 text-sm text-slate-400">{{ t('score_board.clock_clear_confirm_body') }}</p>
          <div class="flex justify-end gap-2">
            <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-200" @click="cancelClockClear">
              {{ t('dialog.no') }}
            </button>
            <button type="button" class="rounded-lg bg-amber-600 px-3 py-2 text-sm font-semibold text-white" @click="confirmClockClear">
              {{ t('dialog.yes') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
