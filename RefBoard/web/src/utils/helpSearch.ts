/**
 * ヘルプ全文検索のインデックス構築・検索ユーティリティ。
 *
 * - 検索対象: reverse_index.json の各 item の title / tags と、紐づく Markdown 記事の本文（frontmatter / Markdown 記号除去後）。
 * - 重み付け: title 0.7 / tags 0.2 / body 0.1。
 * - インデックスはモジュールレベルで Promise キャッシュ。`resetHelpIndex()` で破棄できる。
 *
 * 将来 locale 切替で `en/` を読む際は `buildHelpIndex(locale)` に拡張する想定（Phase E）。
 */

import Fuse, { type IFuseOptions, type FuseResult } from 'fuse.js'
import reverseIndexData from '../help/ja/reverse_index.json'

/** 検索インデックスに載せる 1 レコード */
export interface HelpSearchEntry {
  /** 記事 slug（`.md` を除いたファイル名） */
  slug: string
  /** 表示タイトル（reverse_index の item.title） */
  title: string
  /** 検索用タグ */
  tags: string[]
  /** Markdown を plain text 化した本文（先頭 4000 文字に切る — 大文字・記号除去済み） */
  body: string
  /** 出典バッジ用（v0.6.6 時点では reverse のみ） */
  source: 'reverse' | 'tree'
  /** 由来カテゴリ（reverse_index の category id。デバッグ用に保持） */
  categoryId?: string
}

const FUSE_OPTIONS: IFuseOptions<HelpSearchEntry> = {
  keys: [
    { name: 'title', weight: 0.7 },
    { name: 'tags', weight: 0.2 },
    { name: 'body', weight: 0.1 },
  ],
  // Fuse.js 7 系のデフォルトに近い感覚値で出発。実機テスト後に調整可能。
  threshold: 0.4,
  ignoreLocation: true,
  includeMatches: false,
  includeScore: true,
  // 日本語対応: minMatchCharLength を 1 にすると 1 文字ヒットが多すぎるので 2 を採用。
  minMatchCharLength: 2,
}

/**
 * Markdown を素朴に plain text 化する。
 * - 先頭 frontmatter（`---\n...\n---`）を除去
 * - コードブロック / インラインコード / リンク記法 / 見出し / 強調 / リスト記号を剥がす
 * - 先頭 4000 文字に切り詰める（インデックスサイズ抑制）
 */
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

/** reverse_index.json の最低限の型（実体は web/src/help/ja/reverse_index.json） */
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

/**
 * 内部キャッシュ。`buildHelpIndex` を複数回呼んでも同じ Promise を返す。
 * Phase E で locale 切替対応するときは Map<locale, Promise<Fuse<...>>> に拡張する。
 */
let cachedFuse: Promise<Fuse<HelpSearchEntry>> | null = null
let cachedEntries: HelpSearchEntry[] = []

/**
 * ヘルプ検索インデックスを構築する（lazy・1 度だけ）。
 * @returns Fuse インスタンス（HelpSearchEntry を検索可能）
 */
export async function buildHelpIndex(): Promise<Fuse<HelpSearchEntry>> {
  if (cachedFuse) return cachedFuse

  cachedFuse = (async () => {
    // reverse_index と記事 Markdown を eager に取り込む（Phase E で locale 切替時は import 先を切り替え）
    const reverseIndexJson = reverseIndexData as ReverseIndexJson
    const articles = import.meta.glob<string>('../help/ja/articles/*.md', {
      query: '?raw',
      import: 'default',
      eager: true,
    }) as Record<string, string>

    const articleBySlug: Record<string, string> = {}
    for (const path of Object.keys(articles)) {
      const m = path.match(/\/articles\/([^/]+)\.md$/)
      if (m) articleBySlug[m[1]] = articles[path]
    }

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

    cachedEntries = entries
    return new Fuse(entries, FUSE_OPTIONS)
  })()

  return cachedFuse
}

/**
 * 構築済みインデックスを破棄する（locale 切替・テスト用）。
 */
export function resetHelpIndex(): void {
  cachedFuse = null
  cachedEntries = []
}

/**
 * 検索結果。Fuse の `FuseResult<T>` を slug 中心に薄くラップしただけ。
 */
export interface HelpSearchHit {
  slug: string
  title: string
  source: 'reverse' | 'tree'
  score: number
}

/**
 * クエリで検索する。空クエリは空配列を返す。
 * @param query ユーザー入力
 * @param limit 返す件数の上限（既定 30）
 */
export async function searchHelp(query: string, limit = 30): Promise<HelpSearchHit[]> {
  const q = query.trim()
  if (!q) return []
  const fuse = await buildHelpIndex()
  const results: FuseResult<HelpSearchEntry>[] = fuse.search(q, { limit })
  return results.map((r) => ({
    slug: r.item.slug,
    title: r.item.title,
    source: r.item.source,
    score: r.score ?? 1,
  }))
}

/** デバッグ用: 現在のインデックス件数（DevTools から確認したいとき用） */
export function getHelpIndexSize(): number {
  return cachedEntries.length
}
