<script setup lang="ts">
import MarqueeText from '../components/common/MarqueeText.vue'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { marked } from 'marked'
import DOMPurify from 'dompurify'
import reverseIndex from '../help/ja/reverse_index.json'
import { helpSlugForErrorCode } from '../utils/errorCodeMapper'

const modules = import.meta.glob<string>('../help/ja/articles/*.md', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>

const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const activeSlug = ref<string | null>(null)

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
</script>

<template>
  <div class="flex h-full min-h-0 flex-col text-sm text-slate-200">
    <header class="shrink-0 border-b border-slate-700 px-4 py-3">
      <h1 class="text-lg font-bold text-slate-50">{{ t('help.title') }}</h1>
      <p class="mt-1 text-xs text-slate-400">{{ t('help.subtitle') }}</p>
    </header>
    <div class="grid min-h-0 min-w-0 flex-1 grid-cols-1 gap-0 md:grid-cols-[minmax(200px,30%)_1fr]">
      <aside class="min-w-0 overflow-y-auto overflow-x-hidden border-b border-slate-700 p-3 md:border-b-0 md:border-r">
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
