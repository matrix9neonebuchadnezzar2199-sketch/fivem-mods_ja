<script setup lang="ts">
import { computed, inject, nextTick, onMounted, onUnmounted, ref, watch, type ComputedRef } from 'vue'
import type { MarqueeMode } from '../../stores/settings'
import type { MarqueeVariant } from '../../utils/marqueeVariants'
import { resolveMarqueeTiming } from '../../utils/marqueeVariants'

const props = withDefaults(
  defineProps<{
    text: string
    variant?: MarqueeVariant
    speed?: number
    gap?: number
    delay?: number
  }>(),
  { variant: 'default' },
)

const marqueeMode = inject<ComputedRef<MarqueeMode>>(
  'marqueeMode',
  computed((): MarqueeMode => 'always'),
)

const containerRef = ref<HTMLElement | null>(null)
const trackRef = ref<HTMLElement | null>(null)
const measureRef = ref<HTMLElement | null>(null)

const textOverflows = ref(false)
const segmentWidthPx = ref(0)

const timing = computed(() =>
  resolveMarqueeTiming(props.variant, {
    speed: props.speed,
    gap: props.gap,
    delay: props.delay,
  }),
)

const useMarqueeMotion = computed(
  () => textOverflows.value && marqueeMode.value !== 'off',
)
const useEllipsis = computed(() => textOverflows.value && marqueeMode.value === 'off')

/** レイアウト確定・フォント後までずらして再計測（flex 初回幅が過大になるのを避ける） */
function scheduleMeasure() {
  requestAnimationFrame(() => {
    requestAnimationFrame(() => measure())
  })
}

function measure() {
  const c = containerRef.value
  const span = measureRef.value
  if (!c || !span) return
  const cw = c.clientWidth
  const one = span.scrollWidth
  segmentWidthPx.value = one
  textOverflows.value = one > cw + 1
}

const trackStyle = computed(() => {
  if (!useMarqueeMotion.value) return {}
  const distance = segmentWidthPx.value
  const { speed, gap, delay } = timing.value
  const durationSec = distance > 0 ? distance / speed : 1
  return {
    '--marquee-distance': `${distance}px`,
    '--marquee-gap': `${gap}px`,
    animationDuration: `${durationSec}s`,
    animationDelay: `${delay}ms`,
  }
})

let ro: ResizeObserver | undefined

function setupRo() {
  ro?.disconnect()
  // コンテナ幅だけ追えばよい。measure（トラック内 span）を observe すると max-content 周りでノイズになりやすい
  ro = new ResizeObserver(() => scheduleMeasure())
  if (containerRef.value) ro.observe(containerRef.value)
}

async function runInitialMeasures() {
  scheduleMeasure()
  try {
    await document.fonts?.ready
  } catch {
    /* document.fonts 非対応環境 */
  }
  scheduleMeasure()
}

onMounted(async () => {
  await nextTick()
  setupRo()
  await runInitialMeasures()
})

onUnmounted(() => {
  ro?.disconnect()
})

watch(
  () =>
    [props.text, props.variant, props.speed, props.gap, props.delay, marqueeMode.value] as const,
  async () => {
    await nextTick()
    scheduleMeasure()
    setupRo()
  },
)

/** plain / track の切替後に measureRef が差し替わるため再計測 */
watch(textOverflows, async () => {
  await nextTick()
  scheduleMeasure()
})
</script>

<template>
  <div
    ref="containerRef"
    class="rb-marquee"
    :class="{
      'is-overflowing': useMarqueeMotion,
      'rb-marquee--ellipsis': useEllipsis,
    }"
  >
    <template v-if="useEllipsis">
      <span ref="measureRef" class="rb-marquee-off-text">{{ text }}</span>
    </template>
    <div v-else-if="useMarqueeMotion" ref="trackRef" class="rb-marquee-track" :style="trackStyle">
      <span ref="measureRef" class="rb-marquee-content">{{ text }}</span>
      <span class="rb-marquee-content" aria-hidden="true">{{ text }}</span>
    </div>
    <span v-else ref="measureRef" class="rb-marquee-plain">{{ text }}</span>
  </div>
</template>
