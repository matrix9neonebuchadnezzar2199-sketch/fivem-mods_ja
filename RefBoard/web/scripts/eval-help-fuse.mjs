/**
 * One-off: mirror helpSearch.ts Fuse inputs to validate query rankings (run from RefBoard/web).
 * Usage: node scripts/eval-help-fuse.mjs
 */
import Fuse from 'fuse.js'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(__dirname, '..')

function markdownToPlain(raw) {
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

const FUSE_OPTIONS = {
  keys: [
    { name: 'title', weight: 0.5 },
    { name: 'tags', weight: 0.3 },
    { name: 'slug', weight: 0.1 },
    { name: 'body', weight: 0.1 },
  ],
  threshold: 0.35,
  ignoreLocation: true,
  includeMatches: false,
  includeScore: true,
  minMatchCharLength: 2,
}

function buildEntries(loc) {
  const indexPath = path.join(root, 'src/help', loc, 'reverse_index.json')
  const articleDir = path.join(root, 'src/help', loc, 'articles')
  const reverseIndexJson = JSON.parse(fs.readFileSync(indexPath, 'utf8'))
  const entries = []
  for (const cat of reverseIndexJson.categories) {
    for (const item of cat.items) {
      const slug = item.article.replace(/\.md$/, '')
      let raw = ''
      try {
        raw = fs.readFileSync(path.join(articleDir, `${slug}.md`), 'utf8')
      } catch {
        raw = ''
      }
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
  return entries
}

const jaQueries = [
  'ゴール',
  'アシスト',
  'カード',
  '警告',
  '退場',
  '交代',
  'PK',
  'ペナルティ',
  '試合作成',
  '終了',
  '再開',
  'インポート',
  '取り込み',
  'バックアップ',
  'CSV',
  '履歴',
  'チーム作成',
  'ロスター',
  '表示名',
  'はじめて',
  'ゴール取消',
  '削除できない',
  'E3006',
  'ロスタイム',
  '部分マージ',
  '選択取り込み',
  'csv 形式',
  'csv エクスポート',
  'excel 文字化け',
  'excel CSV',
  'PK 入力',
  'ペナルティ 戦',
  '小窓 モード',
  'compact dock',
  'データ 移行',
  'バックアップ 取り込み',
  'イベント 消えた',
  'event missing',
]

const enQueries = [
  'goal',
  'card',
  'import',
  'substitute',
  'operator',
  'stoppage',
  'partial',
  'selective',
  'csv format',
  'csv export',
  'excel garbled',
  'excel CSV',
  'PK input',
  'penalty shootout',
  'compact dock',
  'data migration',
  'backup import',
  'event missing',
]

for (const loc of ['ja', 'en']) {
  const fuse = new Fuse(buildEntries(loc), FUSE_OPTIONS)
  const queries = loc === 'ja' ? jaQueries : enQueries
  console.log(`\n=== ${loc} (${queries.length} queries) ===\n`)
  for (const q of queries) {
    const top = fuse.search(q.trim(), { limit: 3 }).map((r) => r.item.slug)
    console.log(`${q}\t${top.join(' > ')}`)
  }
}
