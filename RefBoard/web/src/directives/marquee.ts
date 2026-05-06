import type { Directive, DirectiveBinding } from 'vue'
import type { MarqueeMode } from '../stores/settings'
import type { MarqueeVariant } from '../utils/marqueeVariants'
import { resolveMarqueeTiming } from '../utils/marqueeVariants'

export interface MarqueeDirectiveValue {
  variant?: MarqueeVariant
  speed?: number
  gap?: number
  delay?: number
  /** 動的テキストは `text` で渡すことを推奨（初回のみ textContent を読む場合あり） */
  text?: string
}

type DirState = {
  container: HTMLDivElement
  track: HTMLDivElement
  spanPrimary: HTMLSpanElement
  spanClone: HTMLSpanElement | null
  ro: ResizeObserver
  variant: MarqueeVariant
  speed?: number
  gap?: number
  delay?: number
  currentText: string
}

const stateMap = new WeakMap<HTMLElement, DirState>()

function readMarqueeMode(el: Element): MarqueeMode {
  const node = el.closest('[data-marquee-mode]')
  const v = node?.getAttribute('data-marquee-mode')
  if (v === 'always' || v === 'hover-only' || v === 'off') return v
  return 'always'
}

function normalizeBinding(raw: unknown): MarqueeDirectiveValue {
  if (raw && typeof raw === 'object') return raw as MarqueeDirectiveValue
  return {}
}

function clearClone(st: DirState) {
  if (st.spanClone) {
    st.track.removeChild(st.spanClone)
    st.spanClone = null
  }
}

function clearTrackAnimation(st: DirState) {
  st.track.style.removeProperty('--marquee-distance')
  st.track.style.removeProperty('--marquee-gap')
  st.track.style.removeProperty('animation-duration')
  st.track.style.removeProperty('animation-delay')
}

function applyLayout(host: HTMLElement, st: DirState) {
  const mode = readMarqueeMode(host)
  const cw = st.container.clientWidth
  const oneW = st.spanPrimary.scrollWidth
  const overflow = oneW > cw + 1

  st.track.style.display = ''
  st.track.classList.remove('rb-marquee-track-ellipsis')

  if (!overflow) {
    st.container.classList.remove('is-overflowing', 'rb-marquee--ellipsis')
    clearClone(st)
    clearTrackAnimation(st)
    return
  }

  if (mode === 'off') {
    clearClone(st)
    clearTrackAnimation(st)
    st.container.classList.remove('is-overflowing')
    st.container.classList.add('rb-marquee--ellipsis')
    st.track.classList.add('rb-marquee-track-ellipsis')
    return
  }

  st.container.classList.remove('rb-marquee--ellipsis')
  st.container.classList.add('is-overflowing')

  if (!st.spanClone) {
    const clone = document.createElement('span')
    clone.className = 'rb-marquee-content'
    clone.setAttribute('aria-hidden', 'true')
    clone.textContent = st.currentText
    st.track.appendChild(clone)
    st.spanClone = clone
  } else {
    st.spanClone.textContent = st.currentText
  }

  const { speed, gap, delay } = resolveMarqueeTiming(st.variant, {
    speed: st.speed,
    gap: st.gap,
    delay: st.delay,
  })
  st.track.style.setProperty('--marquee-gap', `${gap}px`)
  const distance = oneW
  st.track.style.setProperty('--marquee-distance', `${distance}px`)
  const durationSec = distance > 0 ? distance / speed : 1
  st.track.style.animationDuration = `${durationSec}s`
  st.track.style.animationDelay = `${delay}ms`
}

function readText(host: HTMLElement, v: MarqueeDirectiveValue): string {
  if (typeof v.text === 'string') return v.text
  return host.textContent?.trim() ?? ''
}

function mountState(host: HTMLElement, binding: DirectiveBinding<MarqueeDirectiveValue | undefined>) {
  const v = normalizeBinding(binding.value)
  const initial = readText(host, v)
  while (host.firstChild) host.removeChild(host.firstChild)

  const container = document.createElement('div')
  container.className = 'rb-marquee'
  const track = document.createElement('div')
  track.className = 'rb-marquee-track'
  const spanPrimary = document.createElement('span')
  spanPrimary.className = 'rb-marquee-content'
  spanPrimary.textContent = initial

  track.appendChild(spanPrimary)
  container.appendChild(track)
  host.appendChild(container)

  const st: DirState = {
    container,
    track,
    spanPrimary,
    spanClone: null,
    ro: new ResizeObserver(() => applyLayout(host, st)),
    variant: v.variant ?? 'default',
    speed: v.speed,
    gap: v.gap,
    delay: v.delay,
    currentText: initial,
  }
  st.ro.observe(container)
  st.ro.observe(spanPrimary)
  stateMap.set(host, st)
  applyLayout(host, st)
}

function updateState(host: HTMLElement, binding: DirectiveBinding<MarqueeDirectiveValue | undefined>) {
  const st = stateMap.get(host)
  if (!st) return
  const v = normalizeBinding(binding.value)
  const text = readText(host, v)
  st.currentText = text
  st.spanPrimary.textContent = text
  st.variant = v.variant ?? 'default'
  st.speed = v.speed
  st.gap = v.gap
  st.delay = v.delay
  if (st.spanClone) st.spanClone.textContent = text
  applyLayout(host, st)
}

function unmountState(host: HTMLElement) {
  const st = stateMap.get(host)
  if (!st) return
  st.ro.disconnect()
  stateMap.delete(host)
  host.replaceChildren()
}

export const vMarquee: Directive<HTMLElement, MarqueeDirectiveValue | undefined> = {
  mounted(host, binding) {
    mountState(host, binding)
  },
  updated(host, binding) {
    updateState(host, binding)
  },
  unmounted(host) {
    unmountState(host)
  },
}
