/**
 * Help full-text search: build Fuse index per Help locale, lazy on first use.
 */

import Fuse, { type IFuseOptions, type FuseResult } from 'fuse.js'
import reverseIndexJa from '../help/ja/reverse_index.json'
import reverseIndexEn from '../help/en/reverse_index.json'
import type { HelpLocale } from './helpLocale'

export interface HelpSearchEntry {
  slug: string
  title: string
  tags: string[]
  body: string
  source: 'reverse' | 'tree'
  categoryId?: string
}

const FUSE_OPTIONS: IFuseOptions<HelpSearchEntry> = {
  keys: [
    { name: 'title', weight: 0.7 },
    { name: 'tags', weight: 0.2 },
    { name: 'body', weight: 0.1 },
  ],
  threshold: 0.4,
  ignoreLocation: true,
  includeMatches: false,
  includeScore: true,
  minMatchCharLength: 2,
}

function markdownToPlain(raw: string): string {
  let s = raw
  if (s.startsWith('---')) {
    const end = s.indexOf('\n---', 3)
    if (end !== -1) s = s.slice(end + 4)
  }
  s = s
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/`[^`\n]*`/g, ' ')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/^#{1,6}\s+/gm, '')
    .replace(/[*_~]+/g, '')
    .replace(/^\s*[-*+]\s+/gm, '')
    .replace(/^\s*\d+\.\s+/gm, '')
    .replace(/\|/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
  return s.slice(0, 4000)
}

interface ReverseIndexJson {
  categories: Array<{
    id: string
    icon: string
    title: string
    items: Array<{
      id: string
      title: string
      article: string
      tags?: string[]
    }>
  }>
}

const jaArticles = import.meta.glob<string>('../help/ja/articles/*.md', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>

const enArticles = import.meta.glob<string>('../help/en/articles/*.md', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>

const fuseCache = new Map<HelpLocale, Promise<Fuse<HelpSearchEntry>>>()
let lastBuiltEntries: HelpSearchEntry[] = []

function articleMapForLocale(loc: HelpLocale): Record<string, string> {
  const glob = loc === 'en' ? enArticles : jaArticles
  const articleBySlug: Record<string, string> = {}
  for (const path of Object.keys(glob)) {
    const m = path.match(/\/articles\/([^/]+)\.md$/)
    if (m) articleBySlug[m[1]] = glob[path]
  }
  return articleBySlug
}

function reverseForLocale(loc: HelpLocale): ReverseIndexJson {
  return (loc === 'en' ? reverseIndexEn : reverseIndexJa) as ReverseIndexJson
}

/**
 * Build (or return cached) Fuse index for the given help locale.
 */
export async function buildHelpIndex(loc: HelpLocale): Promise<Fuse<HelpSearchEntry>> {
  const existing = fuseCache.get(loc)
  if (existing) return existing

  const promise = (async () => {
    const reverseIndexJson = reverseForLocale(loc)
    const articleBySlug = articleMapForLocale(loc)

    const entries: HelpSearchEntry[] = []
    for (const cat of reverseIndexJson.categories) {
      for (const item of cat.items) {
        const slug = item.article.replace(/\.md$/, '')
        const raw = articleBySlug[slug] ?? ''
        entries.push({
          slug,
          title: item.title,
          tags: item.tags ?? [],
          body: markdownToPlain(raw),
          source: 'reverse',
          categoryId: cat.id,
        })
      }
    }

    lastBuiltEntries = entries
    return new Fuse(entries, FUSE_OPTIONS)
  })()

  fuseCache.set(loc, promise)
  return promise
}

export function resetHelpIndex(loc?: HelpLocale): void {
  if (loc) fuseCache.delete(loc)
  else fuseCache.clear()
  lastBuiltEntries = []
}

export interface HelpSearchHit {
  slug: string
  title: string
  source: 'reverse' | 'tree'
  score: number
}

export async function searchHelp(
  query: string,
  limit = 30,
  loc: HelpLocale = 'ja',
): Promise<HelpSearchHit[]> {
  const q = query.trim()
  if (!q) return []
  const fuse = await buildHelpIndex(loc)
  const results: FuseResult<HelpSearchEntry>[] = fuse.search(q, { limit })
  return results.map((r) => ({
    slug: r.item.slug,
    title: r.item.title,
    source: r.item.source,
    score: r.score ?? 1,
  }))
}

export function getHelpIndexSize(): number {
  return lastBuiltEntries.length
}
