<script setup lang="ts">
import { computed, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import contextMap from '../../help/context_map.json'
import reverseIndexJa from '../../help/ja/reverse_index.json'
import reverseIndexEn from '../../help/en/reverse_index.json'
import MarqueeText from '../common/MarqueeText.vue'
import { resolveHelpLocale } from '../../utils/helpLocale'
import { useDialogOverlay } from '../../composables/useDialogOverlay'

interface RevItem {
  id: string
  title: string
  article: string
  tags?: string[]
}
interface RevCat {
  id: string
  icon: string
  title: string
  items: RevItem[]
}

const props = defineProps<{
  contextId: string
  open: boolean
}>()

const emit = defineEmits<{ close: [] }>()

const { overlayRootClass } = useDialogOverlay()
const dialogOverlayClass = overlayRootClass('z-[185]', 'bg-black/50')

const router = useRouter()
const { t, locale } = useI18n()

const reverseIndex = computed(() =>
  resolveHelpLocale(locale.value as string) === 'en' ? reverseIndexEn : reverseIndexJa,
)

const slugMeta = computed<Record<string, { title: string; icon: string }>>(() => {
  const map: Record<string, { title: string; icon: string }> = {}
  for (const cat of (reverseIndex.value as { categories: RevCat[] }).categories) {
    for (const item of cat.items) {
      const slug = item.article.replace(/\.md$/, '')
      map[slug] = { title: item.title, icon: cat.icon }
    }
  }
  return map
})

const slugs = computed<string[]>(() => {
  const list = (contextMap as Record<string, string[]>)[props.contextId]
  return list ?? []
})

const items = computed(() =>
  slugs.value.map((slug) => {
    const meta = slugMeta.value[slug]
    return {
      slug,
      title: meta?.title ?? slug,
      icon: meta?.icon ?? '📄',
    }
  }),
)

function openArticle(slug: string) {
  emit('close')
  void router.push({ name: 'help-article', params: { slug } })
}

function openHelpRoot() {
  emit('close')
  void router.push({ name: 'help' })
}

function onEsc(ev: KeyboardEvent) {
  if (ev.key === 'Escape' && props.open) {
    ev.preventDefault()
    emit('close')
  }
}

watch(
  () => props.open,
  (v) => {
    if (v) {
      window.addEventListener('keydown', onEsc, true)
    } else {
      window.removeEventListener('keydown', onEsc, true)
    }
  },
)

watch(
  () => router.currentRoute.value.fullPath,
  () => {
    if (props.open) emit('close')
  },
)

onUnmounted(() => {
  window.removeEventListener('keydown', onEsc, true)
})
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      :class="dialogOverlayClass"
      role="dialog"
      aria-modal="true"
      :aria-label="t('help.context.panel_aria')"
      tabindex="-1"
      @click.self="emit('close')"
    >
      <div
        class="relative flex max-h-[min(80vh,32rem)] w-full max-w-2xl flex-col overflow-hidden rounded-xl border border-slate-600 bg-slate-900 shadow-2xl"
        @click.stop
      >
        <header class="flex shrink-0 items-center justify-between gap-2 border-b border-slate-700 px-4 py-3">
          <h2 class="text-sm font-semibold text-slate-100">
            {{ t('help.context.title') }}
          </h2>
          <button
            type="button"
            class="rounded p-1 text-slate-400 hover:bg-slate-800 hover:text-slate-100"
            :aria-label="t('help.context.close_aria')"
            @click="emit('close')"
          >
            ✕
          </button>
        </header>
        <p class="shrink-0 border-b border-slate-700/80 px-4 py-2 text-xs text-slate-400">
          {{ t('help.context.subtitle') }}
        </p>

        <div class="min-h-0 flex-1 overflow-y-auto p-3">
          <p v-if="items.length === 0" class="rounded border border-slate-700 bg-slate-950/40 p-3 text-xs text-slate-400">
            {{ t('help.context.empty') }}
          </p>
          <ul v-else class="space-y-1">
            <li v-for="it in items" :key="it.slug" class="min-w-0">
              <button
                type="button"
                class="flex w-full min-w-0 items-center gap-2 rounded px-2 py-2 text-left text-xs text-slate-200 hover:bg-slate-800"
                @click="openArticle(it.slug)"
              >
                <span class="shrink-0 text-base">{{ it.icon }}</span>
                <span class="min-w-0 flex-1 overflow-hidden">
                  <MarqueeText :text="it.title" variant="subtle" />
                </span>
                <span class="shrink-0 text-slate-500">›</span>
              </button>
            </li>
          </ul>
        </div>

        <footer class="shrink-0 border-t border-slate-700 px-3 py-2">
          <button
            type="button"
            class="w-full rounded bg-slate-800 px-3 py-2 text-xs text-slate-200 hover:bg-slate-700"
            @click="openHelpRoot"
          >
            {{ t('help.context.open_all') }}
          </button>
        </footer>
      </div>
    </div>
  </Teleport>
</template>
