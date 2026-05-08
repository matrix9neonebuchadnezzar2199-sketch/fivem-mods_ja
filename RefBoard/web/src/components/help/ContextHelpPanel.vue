<script setup lang="ts">
import { computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { storeToRefs } from 'pinia'
import { useContextHelpStore } from '../../stores/contextHelp'
import contextMap from '../../help/context_map.json'
import reverseIndexJa from '../../help/ja/reverse_index.json'
import reverseIndexEn from '../../help/en/reverse_index.json'
import MarqueeText from '../common/MarqueeText.vue'
import { resolveHelpLocale } from '../../utils/helpLocale'

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

const store = useContextHelpStore()
const { isOpen, contextId } = storeToRefs(store)
const router = useRouter()
const { t, locale } = useI18n()

const reverseIndex = computed(() =>
  resolveHelpLocale(locale.value as string) === 'en' ? reverseIndexEn : reverseIndexJa,
)

/** slug → 表示用タイトル / カテゴリアイコン のマップ。reverse_index から組み立てる。 */
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
  const id = contextId.value
  if (!id) return []
  const list = (contextMap as Record<string, string[]>)[id]
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
  store.close()
  void router.push({ name: 'help-article', params: { slug } })
}

function openHelpRoot() {
  store.close()
  void router.push({ name: 'help' })
}

function onEsc(ev: KeyboardEvent) {
  if (ev.key === 'Escape' && isOpen.value) {
    store.close()
  }
}

onMounted(() => {
  window.addEventListener('keydown', onEsc, true)
})

onUnmounted(() => {
  window.removeEventListener('keydown', onEsc, true)
})

// ルート変更で自動的に閉じる（記事へ遷移した直後など）
watch(
  () => router.currentRoute.value.fullPath,
  () => {
    if (isOpen.value) store.close()
  },
)
</script>

<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition-opacity duration-150"
      leave-active-class="transition-opacity duration-150"
      enter-from-class="opacity-0"
      leave-to-class="opacity-0"
    >
      <div
        v-if="isOpen"
        class="fixed inset-0 z-[180] bg-black/40"
        @click="store.close()"
      />
    </Transition>
    <Transition
      enter-active-class="transition-transform duration-200 ease-out"
      leave-active-class="transition-transform duration-150 ease-in"
      enter-from-class="translate-x-full"
      leave-to-class="translate-x-full"
    >
      <aside
        v-if="isOpen"
        class="fixed inset-y-0 right-0 z-[181] flex w-full max-w-sm flex-col border-l border-slate-700 bg-slate-900 text-slate-200 shadow-2xl"
        role="dialog"
        :aria-label="t('help.context.panel_aria')"
        @click.stop
      >
        <header class="shrink-0 border-b border-slate-700 px-4 py-3">
          <div class="flex items-center justify-between gap-2">
            <h2 class="text-sm font-semibold text-slate-100">
              {{ t('help.context.title') }}
            </h2>
            <button
              type="button"
              class="rounded p-1 text-slate-400 hover:bg-slate-800 hover:text-slate-100"
              :aria-label="t('help.context.close_aria')"
              @click="store.close()"
            >
              ✕
            </button>
          </div>
          <p class="mt-1 text-xs text-slate-400">{{ t('help.context.subtitle') }}</p>
        </header>

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
      </aside>
    </Transition>
  </Teleport>
</template>
