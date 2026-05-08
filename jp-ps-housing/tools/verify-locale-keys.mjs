// SPDX-License-Identifier: CC-BY-NC-SA-4.0
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..')
const extractKeys = (file) => {
  const text = fs.readFileSync(path.join(root, 'locales', file), 'utf8')
  const keys = []
  for (const line of text.split(/\r?\n/)) {
    const m = /^\s+\['([^']+)'\]\s*=/.exec(line)
    if (m) keys.push(m[1])
  }
  return keys
}

const en = new Set(extractKeys('en.lua'))
const ja = new Set(extractKeys('ja.lua'))

/** `log.*` は Discord 向け英語固定のため ja に無くてよい */
const jaMustCover = (k) => k !== '_test.fallback' && !k.startsWith('log.')

const missingJa = [...en].filter((k) => jaMustCover(k) && !ja.has(k))
const extraJa = [...ja].filter((k) => !en.has(k))
console.log('en:', en.size, 'ja:', ja.size)
console.log('missing in ja (except _test.fallback, log.*):', missingJa)
console.log('extra in ja:', extraJa)
