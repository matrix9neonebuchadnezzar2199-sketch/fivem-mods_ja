// SPDX-License-Identifier: LGPL-3.0-or-later
/**
 * Parse docs/ja/reverse-index.md (YAML front matter + Markdown sections) and emit:
 * - docs/ja/reverse-index.json
 * - web/src/data/reverse-index.json
 *
 * Usage (from repo root tecton-fivem/): node tools/build_reverse_index.mjs
 */
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const ROOT = path.resolve(__dirname, '..')
const SRC = path.join(ROOT, 'docs', 'ja', 'reverse-index.md')
const DST_DOCS = path.join(ROOT, 'docs', 'ja', 'reverse-index.json')
const DST_WEB = path.join(ROOT, 'web', 'src', 'data', 'reverse-index.json')

const md = await fs.readFile(SRC, 'utf8')

/** Split after preamble: repeated blocks of ---\nYAML\n---\nBODY */
function parseItems(text) {
  const items = []
  const re = /\r?\n---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*?)(?=\r?\n---\r?\n|$)/g
  let m
  while ((m = re.exec(text)) !== null) {
    const yamlBlock = m[1].trim()
    const bodyBlock = m[2].trim()
    if (!/^id:\s/m.test(yamlBlock)) continue
    const meta = parseYamlFrontMatter(yamlBlock)
    const sections = parseMarkdownSections(bodyBlock)
    items.push({ ...meta, ...sections })
  }
  return items
}

function parseYamlFrontMatter(text) {
  const obj = {}
  const lines = text.split(/\r?\n/)
  for (const line of lines) {
    const m = line.match(/^(\w+):\s*(.*)$/)
    if (!m) continue
    const key = m[1]
    let val = m[2].trim()
    if (val.startsWith('[')) {
      const inner = val.slice(1, val.lastIndexOf(']'))
      obj[key] = inner
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean)
    } else {
      obj[key] = val.replace(/^["']|["']$/g, '')
    }
  }
  return obj
}

function parseMarkdownSections(text) {
  const out = { situation: '', steps: [], note: '' }
  const sit = text.match(/##\s*状況\s*\n([\s\S]*?)(?=\n##\s|$)/)
  const stp = text.match(/##\s*手順\s*\n([\s\S]*?)(?=\n##\s|$)/)
  const nte = text.match(/##\s*補足\s*\n([\s\S]*?)(?=\n##\s|$)/)
  if (sit) out.situation = sit[1].trim()
  if (stp) {
    out.steps = stp[1]
      .split(/\n/)
      .map((s) => s.replace(/^\d+\.\s*/, '').trim())
      .filter(Boolean)
  }
  if (nte) out.note = nte[1].trim()
  return out
}

/** @param {Record<string, unknown>[]} items */
function validateItems(items) {
  const ids = new Set()
  for (let i = 0; i < items.length; i++) {
    const it = items[i]
    const id = typeof it.id === 'string' ? it.id : ''
    if (!id) {
      console.error(`Item #${i}: missing id`)
      process.exit(1)
    }
    if (ids.has(id)) {
      console.error(`Duplicate id: "${id}"`)
      process.exit(1)
    }
    ids.add(id)
  }
  for (const it of items) {
    const id = /** @type {string} */ (it.id)
    if (typeof it.goal !== 'string' || !it.goal.trim()) {
      console.error(`Item "${id}": missing goal`)
      process.exit(1)
    }
    const diff = it.difficulty
    if (diff !== 'easy' && diff !== 'normal' && diff !== 'advanced') {
      console.error(`Item "${id}": invalid difficulty (need easy|normal|advanced): ${diff}`)
      process.exit(1)
    }
    if (!Array.isArray(it.tags) || it.tags.length === 0) {
      console.warn(`WARN: item "${id}": tags empty or missing`)
    }
    if (!Array.isArray(it.steps) || it.steps.length === 0) {
      console.warn(`WARN: item "${id}": steps empty`)
    }
    const rel = it.related
    if (Array.isArray(rel)) {
      for (const r of rel) {
        if (typeof r !== 'string' || !r) continue
        if (!ids.has(r)) {
          console.error(`Item "${id}": related references unknown id "${r}"`)
          process.exit(1)
        }
      }
    }
  }
}

const items = parseItems(md)
validateItems(items)
const payload = { version: 1, items }
const json = JSON.stringify(payload, null, 2)

await fs.mkdir(path.dirname(DST_DOCS), { recursive: true })
await fs.mkdir(path.dirname(DST_WEB), { recursive: true })
await fs.writeFile(DST_DOCS, json, 'utf8')
await fs.writeFile(DST_WEB, json, 'utf8')

if (items.length < 30) {
  console.error(`Expected at least 30 reverse-help items, got ${items.length}`)
  process.exit(1)
}
console.log(`OK: ${items.length} items (minimum 30 satisfied)`)
console.log(`Wrote ${path.relative(ROOT, DST_DOCS)}`)
console.log(`Wrote ${path.relative(ROOT, DST_WEB)}`)
