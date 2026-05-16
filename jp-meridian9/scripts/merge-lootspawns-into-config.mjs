import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const root = path.join(__dirname, '..')
const configPath = path.join(root, 'config.lua')
const bodyPath = path.join(__dirname, '_loot_spawns_body.lua.txt')

let config = fs.readFileSync(configPath, 'utf8')
const body = fs.readFileSync(bodyPath, 'utf8')
const rowsOnly = body
  .split(/\r?\n/)
  .filter((l) => /^\s*\{\s*coords\s*=/.test(l))
  .join('\n')

const header = `-- ▼ アイテム出現地点 -------------------------------------------
-- Cayo Perico 陸上の足元のみ。海・崖外の XY は避ける（誤上面／海底 Z になりやすい）。
-- 取得: 陸で立ち \`/m9_cayo coords\` → 表示の vector4 から xyz を vector3 にして \`scripts/_loot_coords_block.txt\` へ貼る。
-- 一括反映: \`node scripts/gen-lootspawns-snippet.mjs\` → \`_loot_spawns_body.lua.txt\` を生成 → \`node scripts/merge-lootspawns-into-config.mjs\`（同一 xyz は除去済み）。
-- レア度は weight で調整（省略時は Config.LootRarityWeight）。`

const newBlock =
  header +
  '\nConfig.LootSpawns = {\n' +
  rowsOnly +
  '\n}\n\n'

const re =
  /-- ▼ アイテム出現地点[^\n]*\n[\s\S]*?\n\}\n+(?=-- ▼ 脱出ポイント)/

if (!re.test(config)) {
  console.error('merge-lootspawns: anchor not found in config.lua')
  process.exit(1)
}

config = config.replace(re, newBlock)
fs.writeFileSync(configPath, config, { encoding: 'utf8' })
console.error('merge-lootspawns: wrote', rowsOnly.split('\n').length, 'spawn rows to config.lua')
