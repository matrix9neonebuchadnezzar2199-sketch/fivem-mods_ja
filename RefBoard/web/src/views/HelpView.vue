<script setup lang="ts">
import MarqueeText from '../components/common/MarqueeText.vue'
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { marked } from 'marked'
import DOMPurify from 'dompurify'
import reverseIndex from '../help/ja/reverse_index.json'
import { helpSlugForErrorCode } from '../utils/errorCodeMapper'
import { buildHelpIndex, searchHelp, type HelpSearchHit } from '../utils/helpSearch'

const modules = import.meta.glob<string>('../help/ja/articles/*.md', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>

const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const activeSlug = ref<string | null>(null)

// ───────── 検索状態 ─────────
const searchQuery = ref('')
const searchHits = ref<HelpSearchHit[]>([])
const searching = ref(false)
const isComposing = ref(false)

function pathForSlug(slug: string): string | undefined {
  const suffix = `/articles/${slug}.md`
  for (const k of Object.keys(modules)) {
    if (k.endsWith(suffix)) return k
  }
  return undefined
}

function stripFrontMatter(raw: string): string {
  if (!raw.startsWith('---')) return raw
  const end = raw.indexOf('\n---', 3)
  if (end === -1) return raw
  return raw.slice(end + 4).trimStart()
}

watch(
  () => ({ name: route.name, code: route.params.code, slug: route.params.slug }),
  (r) => {
    if (r.name === 'help-error' && r.code) {
      const slug = helpSlugForErrorCode(String(r.code))
      activeSlug.value = slug ?? null
      return
    }
    if (r.name === 'help-article' && r.slug) {
      activeSlug.value = String(r.slug)
      return
    }
    activeSlug.value = null
  },
  { immediate: true },
)

const articleHtml = computed(() => {
  const slug = activeSlug.value
  if (!slug) return ''
  const p = pathForSlug(slug)
  const raw = p ? modules[p] : ''
  if (!raw) return `<p class="text-slate-400">${t('help.article_missing')}</p>`
  const md = stripFrontMatter(raw)
  const parsed = marked.parse(md, { async: false }) as string
  return DOMPurify.sanitize(parsed)
})

type RevItem = { id: string; title: string; article: string; tags?: string[] }
type RevCat = { id: string; icon: string; title: string; items: RevItem[] }

const categories = computed(() => (reverseIndex as { categories: RevCat[] }).categories)

function slugFromArticleFile(file: string): string {
  return file.replace(/\.md$/, '')
}

function openArticleFile(file: string) {
  void router.push({ name: 'help-article', params: { slug: slugFromArticleFile(file) } })
}

function openSlug(slug: string) {
  void router.push({ name: 'help-article', params: { slug } })
}

// ───────── 検索ロジック ─────────
const isSearchMode = computed(() => searchQuery.value.trim().length > 0)

async function runSearch(q: string) {
  if (isComposing.value) return
  if (!q.trim()) {
    searchHits.value = []
    return
  }
  searching.value = true
  try {
    searchHits.value = await searchHelp(q)
  } finally {
    searching.value = false
  }
}

watch(searchQuery, (q) => {
  if (isComposing.value) return
  void runSearch(q)
})

function onCompositionEnd(event: CompositionEvent) {
  isComposing.value = false
  void runSearch((event.target as HTMLInputElement).value)
}

function onSearchEnter() {
  // Enter で先頭ヒットを開く
  if (searchHits.value.length > 0) {
    openSlug(searchHits.value[0].slug)
  }
}

function onClearSearch() {
  searchQuery.value = ''
  searchHits.value = []
}

// 初回マウントでインデックスを温めておく（検索 1 回目を高速化）
onMounted(() => {
  void buildHelpIndex()
})

function badgeLabel(source: 'reverse' | 'tree'): string {
  return source === 'tree' ? t('help.search.badge_tree') : t('help.search.badge_reverse')
}
</script>

<template>
  <div class="flex h-full min-h-0 flex-col text-sm text-slate-200">
    <header class="shrink-0 border-b border-slate-700 px-4 py-3">
      <h1 class="text-lg font-bold text-slate-50">{{ t('help.title') }}</h1>
      <p class="mt-1 text-xs text-slate-400">{{ t('help.subtitle') }}</p>
      <div class="mt-3 flex items-center gap-2">
        <div class="relative flex-1">
          <input
            v-model="searchQuery"
            type="search"
            role="searchbox"
            :aria-label="t('help.search.placeholder')"
            :placeholder="t('help.search.placeholder')"
            class="w-full rounded border border-slate-600 bg-slate-900 px-3 py-1.5 pr-8 text-sm text-slate-100 placeholder:text-slate-500 focus:border-primary focus:outline-none"
            @compositionstart="isComposing = true"
            @compositionend="onCompositionEnd"
            @keydown.enter.prevent="onSearchEnter"
          />
          <button
            v-if="searchQuery"
            type="button"
            class="absolute right-2 top-1/2 -translate-y-1/2 rounded p-0.5 text-slate-400 hover:bg-slate-700 hover:text-slate-100"
            :aria-label="t('help.search.clear')"
            @click="onClearSearch"
          >
            ✕
          </button>
        </div>
        <span v-if="searching" class="text-xs text-slate-400">{{ t('help.search.searching') }}</span>
      </div>
    </header>
    <div class="grid min-h-0 min-w-0 flex-1 grid-cols-1 gap-0 md:grid-cols-[minmax(200px,30%)_1fr]">
      <aside class="min-w-0 overflow-y-auto overflow-x-hidden border-b border-slate-700 p-3 md:border-b-0 md:border-r">
        <!-- 検索モード -->
        <template v-if="isSearchMode">
          <h2 class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">
            {{ t('help.search.results_for', { q: searchQuery }) }}
          </h2>
          <p v-if="!searching && searchHits.length === 0" class="px-2 py-3 text-xs text-slate-400">
            {{ t('help.search.no_results') }}
          </p>
          <ul v-else class="space-y-1">
            <li v-for="hit in searchHits" :key="hit.slug" class="min-w-0">
              <button
                type="button"
                class="flex w-full min-w-0 items-center gap-2 rounded px-2 py-1.5 text-left text-xs text-slate-300 hover:bg-slate-800"
                :class="activeSlug === hit.slug ? 'bg-slate-800 text-white' : ''"
                @click="openSlug(hit.slug)"
              >
                <span
                  class="shrink-0 rounded bg-slate-700 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-slate-200"
                >
                  {{ badgeLabel(hit.source) }}
                </span>
                <span class="min-w-0 flex-1 overflow-hidden">
                  <MarqueeText :text="hit.title" variant="subtle" />
                </span>
              </button>
            </li>
          </ul>
        </template>

        <!-- 通常モード（reverse_index ベース） -->
        <template v-else>
          <h2 class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">{{ t('help.reverse_tab') }}</h2>
          <div v-for="cat in categories" :key="cat.id" class="mb-4">
            <div class="mb-1 flex items-center gap-1 text-xs font-semibold text-primary">
              <span>{{ cat.icon }}</span>
              <span>{{ cat.title }}</span>
            </div>
            <ul class="space-y-1">
              <li v-for="item in cat.items" :key="item.id" class="min-w-0">
                <button
                  type="button"
                  class="flex w-full min-w-0 items-center rounded px-2 py-1.5 text-left text-xs text-slate-300 hover:bg-slate-800"
                  :class="activeSlug === slugFromArticleFile(item.article) ? 'bg-slate-800 text-white' : ''"
                  @click="openArticleFile(item.article)"
                >
                  <span class="min-w-0 flex-1 overflow-hidden">
                    <MarqueeText :text="item.title" variant="subtle" />
                  </span>
                </button>
              </li>
            </ul>
          </div>
        </template>
      </aside>
      <main class="min-h-0 min-w-0 overflow-y-auto overflow-x-hidden p-4">
        <div v-if="!activeSlug" class="rounded-lg border border-slate-700 bg-slate-900/50 p-6 text-slate-400">
          {{
            route.name === 'help-error' && route.params.code
              ? t('help.error_article_missing', { code: String(route.params.code) })
              : t('help.pick_article')
          }}
        </div>
        <article v-else class="help-md max-w-none" v-html="articleHtml" />
      </main>
    </div>
  </div>
</template>

<style scoped>
.help-md :deep(h1) {
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 0.75rem;
  color: rgb(248 250 252);
}
.help-md :deep(h2) {
  font-size: 1rem;
  font-weight: 600;
  margin: 1rem 0 0.5rem;
  color: rgb(226 232 240);
}
.help-md :deep(p) {
  margin: 0.5rem 0;
  color: rgb(203 213 225);
  line-height: 1.6;
}
.help-md :deep(ul) {
  margin: 0.5rem 0;
  padding-left: 1.25rem;
  color: rgb(203 213 225);
}
.help-md :deep(a) {
  color: rgb(96 165 250);
  text-decoration: underline;
}
.help-md :deep(pre) {
  overflow-x: auto;
  border-radius: 0.5rem;
  background: rgb(15 23 42 / 0.9);
  padding: 0.75rem 1rem;
}
.help-md :deep(code) {
  font-size: 0.85em;
}
</style>
