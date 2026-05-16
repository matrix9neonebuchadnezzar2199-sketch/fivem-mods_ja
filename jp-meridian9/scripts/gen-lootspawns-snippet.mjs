import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const raw = fs.readFileSync(path.join(__dirname, '_loot_coords_block.txt'), 'utf8')
const re = /vector4\(\s*([0-9.-]+)\s*,\s*([0-9.-]+)\s*,\s*([0-9.-]+)/g
const seen = new Set()
const rows = []
let m
while ((m = re.exec(raw)) !== null) {
  const xa = m[1]
  const ya = m[2]
  const za = m[3]
  const key = `${xa},${ya},${za}`
  if (seen.has(key)) continue
  seen.add(key)
  rows.push({ x: xa, y: ya, z: za })
}

let out = ''
for (const r of rows) {
  out += `    { coords = vector3(${r.x}, ${r.y}, ${r.z}) },\n`
}
const outPath = path.join(__dirname, '_loot_spawns_body.lua.txt')
fs.writeFileSync(outPath, out, { encoding: 'utf8' })
console.error('Wrote', rows.length, 'entries to', outPath)
