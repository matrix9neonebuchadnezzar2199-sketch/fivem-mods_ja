// SPDX-License-Identifier: CC-BY-NC-SA-4.0
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const configPath = path.join(__dirname, '..', 'shared', 'config.lua')
const outTsv = path.join(__dirname, '..', 'docs', 'ja', '_furniture_labels.tsv')
const outCsv = path.join(__dirname, '..', 'docs', 'ja', 'furniture-labels-todo.csv')

const lines = fs.readFileSync(configPath, 'utf8').split(/\r?\n/)
let cat = ''
const rows = []
for (let i = 637; i < 1620 && i < lines.length; i++) {
  const L = lines[i]
  let m = L.match(/category\s*=\s*"([^"]+)"/)
  if (m) cat = m[1]
  const labelM = L.match(/\["label"\]\s*=\s*"([^"]*)"/)
  if (!labelM) continue
  const objM = L.match(/\["object"\]\s*=\s*"([^"]+)"/)
  const object = objM ? objM[1] : ''
  rows.push({ cat, object, en: labelM[1] })
}

fs.mkdirSync(path.dirname(outTsv), { recursive: true })
fs.writeFileSync(outTsv, rows.map((r) => `${r.cat}\t${r.en}`).join('\n'), 'utf8')
const header = 'category,object,label_en,label_ja'
const csvBody = rows.map((r) => {
  const esc = (s) => (s.includes(',') || s.includes('"') ? `"${s.replace(/"/g, '""')}"` : s)
  return [esc(r.cat), esc(r.object), esc(r.en), ''].join(',')
})
fs.writeFileSync(outCsv, [header, ...csvBody].join('\n'), 'utf8')
console.log('furniture rows:', rows.length, '→', path.basename(outCsv))
