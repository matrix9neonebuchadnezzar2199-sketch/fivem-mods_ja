// SPDX-License-Identifier: LGPL-3.0-or-later
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const configPath = path.join(__dirname, '..', 'shared', 'config.lua')
const outPath = path.join(__dirname, '..', 'docs', 'ja', '_furniture_labels.tsv')

const lines = fs.readFileSync(configPath, 'utf8').split(/\r?\n/)
let cat = ''
const rows = []
for (let i = 637; i < 1620 && i < lines.length; i++) {
  const L = lines[i]
  let m = L.match(/category\s*=\s*"([^"]+)"/)
  if (m) cat = m[1]
  m = L.match(/\["label"\]\s*=\s*"([^"]*)"/)
  if (m) rows.push({ cat, en: m[1] })
}

fs.mkdirSync(path.dirname(outPath), { recursive: true })
fs.writeFileSync(outPath, rows.map((r) => `${r.cat}\t${r.en}`).join('\n'), 'utf8')
console.log('furniture label rows:', rows.length)
