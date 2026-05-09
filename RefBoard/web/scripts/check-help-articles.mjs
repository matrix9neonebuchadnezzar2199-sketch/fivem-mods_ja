/**
 * ヘルプ記事の index.json / reverse_index.json / ディスク / context_map / フロントマター整合を検証する。
 * 実行: RefBoard/web 直下で `node scripts/check-help-articles.mjs` または `npm run check:help`
 */
import fs from 'node:fs'
import path from 'node:path'

const WEB_ROOT = path.resolve(import.meta.dirname, '..')
const HELP_DIR = path.join(WEB_ROOT, 'src', 'help')
const LANGS = ['ja', 'en']

const REQUIRED_FRONTMATTER_KEYS = ['title', 'category']

let errorCount = 0

function error(msg) {
  console.error(`[NG] ${msg}`)
  errorCount++
}

function ok(msg) {
  console.log(`[OK] ${msg}`)
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'))
}

/** index.json の tree から article スラッグ（.md なし）を収集 */
function collectIndexSlugs(indexJson) {
  const set = new Set()
  function walk(nodes) {
    if (!Array.isArray(nodes)) return
    for (const n of nodes) {
      if (typeof n.article === 'string' && n.article.endsWith('.md')) {
        set.add(n.article.replace(/\.md$/i, ''))
      }
      if (n.children) walk(n.children)
    }
  }
  walk(indexJson.tree)
  return set
}

/** articles/*.md のスラッグ集合 */
function collectDiskSlugs(articlesDir) {
  if (!fs.existsSync(articlesDir)) {
    error(`articles ディレクトリが存在しません: ${articlesDir}`)
    return new Set()
  }
  const set = new Set()
  for (const name of fs.readdirSync(articlesDir)) {
    if (!name.endsWith('.md')) continue
    set.add(name.replace(/\.md$/i, ''))
  }
  return set
}

/** reverse_index の article ファイル名からスラッグを収集 */
function collectReverseArticleSlugs(reverseJson) {
  const set = new Set()
  for (const cat of reverseJson.categories ?? []) {
    for (const it of cat.items ?? []) {
      if (typeof it.article === 'string' && it.article.endsWith('.md')) {
        set.add(it.article.replace(/\.md$/i, ''))
      }
    }
  }
  return set
}

/** 先頭 YAML フロントマターからキー→値（行末までの文字列）を抽出 */
function parseFrontmatter(raw) {
  if (!raw.startsWith('---')) return null
  const nl = raw.indexOf('\n', 0)
  if (nl === -1) return null
  const end = raw.indexOf('\n---', nl)
  if (end === -1) return null
  const block = raw.slice(nl + 1, end)
  const map = Object.create(null)
  for (const line of block.split(/\r?\n/)) {
    const m = /^([a-zA-Z_][a-zA-Z0-9_]*):\s*(.*)$/.exec(line)
    if (m) map[m[1]] = m[2].trim()
  }
  return map
}

function checkFrontmatter(lang, slug, filePath) {
  const raw = fs.readFileSync(filePath, 'utf8')
  const fm = parseFrontmatter(raw)
  if (!fm) {
    error(`[${lang}] ${slug}.md: フロントマター（--- ... ---）が見つかりません`)
    return
  }
  for (const key of REQUIRED_FRONTMATTER_KEYS) {
    const v = fm[key]
    if (v == null || v === '') {
      error(`[${lang}] ${slug}.md: フロントマターに必須キー "${key}" がありません（または空です）`)
    }
  }
}

function runLangChecks(lang, indexSlugsByLang) {
  const base = path.join(HELP_DIR, lang)
  const indexPath = path.join(base, 'index.json')
  const reversePath = path.join(base, 'reverse_index.json')
  const articlesDir = path.join(base, 'articles')

  const indexJson = readJson(indexPath)
  const indexSlugs = collectIndexSlugs(indexJson)
  indexSlugsByLang[lang] = indexSlugs

  const diskSlugs = collectDiskSlugs(articlesDir)

  for (const s of indexSlugs) {
    if (!diskSlugs.has(s)) {
      error(`[${lang}] index.json が参照する ${s}.md が articles/ に存在しません`)
    }
  }
  for (const s of diskSlugs) {
    if (!indexSlugs.has(s)) {
      error(`[${lang}] articles/${s}.md が index.json から参照されていません`)
    }
  }
  ok(`[${lang}] index.json ↔ articles/（${indexSlugs.size} 本）`)

  const reverseJson = readJson(reversePath)
  const revSlugs = collectReverseArticleSlugs(reverseJson)
  for (const s of revSlugs) {
    if (!indexSlugs.has(s)) {
      error(`[${lang}] reverse_index が参照する ${s}.md が index.json にありません`)
    }
    if (!diskSlugs.has(s)) {
      error(`[${lang}] reverse_index が参照する ${s}.md がディスクにありません`)
    }
  }
  ok(`[${lang}] reverse_index.json（${revSlugs.size} 参照）`)

  for (const s of diskSlugs) {
    checkFrontmatter(lang, s, path.join(articlesDir, `${s}.md`))
  }
  ok(`[${lang}] フロントマター（title, category 必須）`)
}

// --- main ---
const contextMapPath = path.join(HELP_DIR, 'context_map.json')
const contextMap = readJson(contextMapPath)
const contextSlugs = new Set()
for (const arr of Object.values(contextMap)) {
  if (!Array.isArray(arr)) continue
  for (const id of arr) {
    if (typeof id === 'string' && id) contextSlugs.add(id)
  }
}

const indexSlugsByLang = {}

for (const lang of LANGS) {
  runLangChecks(lang, indexSlugsByLang)
}

const ja = indexSlugsByLang.ja
const en = indexSlugsByLang.en
if (ja && en) {
  const beforeSym = errorCount
  for (const s of ja) {
    if (!en.has(s)) error(`ja/en 非対称: "${s}" が ja にのみ存在します`)
  }
  for (const s of en) {
    if (!ja.has(s)) error(`ja/en 非対称: "${s}" が en にのみ存在します`)
  }
  if (errorCount === beforeSym) ok(`ja/en 記事スラッグ集合一致（${ja.size} 本）`)
}

{
  const beforeCtx = errorCount
  for (const s of contextSlugs) {
    if (!ja?.has(s)) {
      error(`context_map のスラッグ "${s}" が ja の index.json にありません`)
    }
  }
  if (errorCount === beforeCtx) ok(`context_map.json（${contextSlugs.size} スラッグ）が index にすべて含まれる`)
}

if (errorCount > 0) {
  console.error(`\nヘルプ整合性チェック失敗: ${errorCount} 件のエラー`)
  process.exit(1)
}

console.log('\nヘルプ整合性チェック: すべて OK')
process.exit(0)
