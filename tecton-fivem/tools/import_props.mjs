// SPDX-License-Identifier: LGPL-3.0-or-later
/**
 * Fetch ShiftyWreckzz/prop-list (Lua), map categories, emit TECTON config/props.lua.
 *
 * Usage:
 *   node tools/import_props.mjs [--source <url|file>] [--map <path>] [--out <path>]
 *
 * Defaults:
 *   --source https://raw.githubusercontent.com/ShiftyWreckzz/prop-list/main/prop_list.lua
 *   --map    tools/category_map.json
 *   --out    config/props.lua
 */
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const ROOT = path.resolve(__dirname, '..')

const DEFAULT_SOURCE =
  'https://raw.githubusercontent.com/ShiftyWreckzz/prop-list/main/prop_list.lua'

/** @type {Record<string, string>} token → 日本語（簡易） */
const LABEL_DICT = {
  chair: 'チェア',
  table: 'テーブル',
  bed: 'ベッド',
  sofa: 'ソファ',
  desk: 'デスク',
  lamp: 'ランプ',
  fence: 'フェンス',
  gate: 'ゲート',
  barrier: 'バリア',
  sign: '看板',
  light: 'ライト',
  tree: '木',
  plant: '植物',
  flag: '旗',
  box: 'ボックス',
  crate: '木箱',
  barrel: 'ドラム缶',
  machine: '機械',
  vent: '換気',
  dock: '桟橋',
  prop: '',
  hash: '',
  office: 'オフィス',
  residential: '住居',
  toilet: 'トイレ',
  bath: 'バス',
  towel: 'タオル',
  shelf: '棚',
  door: 'ドア',
  window: '窓',
  wall: '壁',
  floor: '床',
  stair: '階段',
  rail: 'レール',
  bench: 'ベンチ',
  bin: 'ゴミ箱',
  cart: 'カート',
  cash: 'レジ',
  atm: 'ATM',
  beer: 'ビール',
  wine: 'ワイン',
  food: '食品',
  fridge: '冷蔵庫',
  stove: 'コンロ',
  sink: 'シンク',
  tv: 'テレビ',
  radio: 'ラジオ',
  phone: '電話',
  computer: 'PC',
  monitor: 'モニター',
  keyboard: 'キーボード',
  printer: 'プリンター',
  paper: '紙',
  book: '本',
  clock: '時計',
  mirror: '鏡',
  plant: '植物',
  pot: '鉢',
  vase: '花瓶',
  statue: '像',
  art: 'アート',
  gym: 'ジム',
  pool: 'プール',
  dart: 'ダーツ',
  arcade: 'アーケード',
  weapon: '武器',
  gun: '銃',
  ammo: '弾薬',
  sec: '警備',
  cam: 'カメラ',
  tire: 'タイヤ',
  wheel: 'ホイール',
  engine: 'エンジン',
  car: '車',
  bike: 'バイク',
  heli: 'ヘリ',
  plane: '飛行機',
  boat: 'ボート',
  ship: '船',
  crane: 'クレーン',
  fork: 'フォークリフト',
  pallet: 'パレット',
  skip: 'スキップ',
  tank: 'タンク',
  wire: '配線',
  cable: 'ケーブル',
  pipe: 'パイプ',
  scaffold: '足場',
  beam: '梁',
  brick: 'レンガ',
  concrete: 'コンクリート',
  wood: '木材',
  metal: '金属',
  glass: 'ガラス',
  plastic: 'プラスチック',
  fabric: '布',
  rug: 'ラグ',
  curtain: 'カーテン',
  pillow: '枕',
  blanket: '毛布',
  lamp: 'ランプ',
  neon: 'ネオン',
  billboard: 'ビルボード',
  poster: 'ポスター',
  menu: 'メニュー',
  cashreg: 'レジ',
  shop: '店',
  store: '店',
  retail: '小売',
  jew: '宝飾',
  cloth: '衣類',
  shirt: 'シャツ',
  shoe: '靴',
  hat: '帽子',
  bag: 'バッグ',
  bong: 'パイプ',
  drug: 'ドラッグ',
  money: '金品',
  coin: 'コイン',
  gold: '金',
  biker: 'バイカー',
  gang: 'ギャング',
  sec: 'セキュリティ',
  airport: '空港',
  metro: '地下鉄',
  train: '列車',
  bus: 'バス',
  traffic: '交通',
  road: '道路',
  street: '街路',
  park: '公園',
  beach: 'ビーチ',
  farm: '農場',
  barn: '納屋',
  hay: '干草',
  fence: 'フェンス',
  farm: '農場',
  rural: '田園',
  nature: '自然',
  rock: '岩',
  bush: '茂み',
  flower: '花',
  palm: 'ヤシ',
  pine: '松',
  oak: 'オーク',
  weed: '雑草',
  log: '丸太',
  paint: '塗装',
  tool: '工具',
  drill: 'ドリル',
  saw: 'のこぎり',
  hammer: 'ハンマー',
  wrench: 'レンチ',
  ladder: 'はしご',
  cone: 'コーン',
  barrier: 'バリア',
  work: '工事',
  water: '水',
  fire: '火',
  hydrant: '消火栓',
  pole: 'ポール',
  aerial: 'アンテナ',
  satellite: '衛星',
  solar: 'ソーラー',
  wind: '風力',
  gen: '発電機',
  ac: '空調',
  fan: 'ファン',
  duct: 'ダクト',
  roof: '屋根',
  chimney: '煙突',
  gutter: '樋',
  vent: '換気口',
  elec: '電気',
  panel: '盤',
  switch: 'スイッチ',
  outlet: 'コンセント',
  fuse: 'ヒューズ',
  meter: 'メーター',
  junk: 'ジャンク',
  trash: 'ゴミ',
  waste: '廃棄物',
  skip: 'スキップ',
  barrel: 'ドラム',
  drum: 'ドラム',
  tank: 'タンク',
  ibc: 'IBC',
  pallet: 'パレット',
  crate: 'クレート',
  box: '箱',
  cardboard: '段ボール',
  package: '荷物',
  cargo: '貨物',
  ship: '船',
  dock: 'ドック',
  pier: '桟橋',
  buoy: 'ブイ',
  anchor: '錨',
  rope: 'ロープ',
  chain: 'チェーン',
  net: '網',
  fish: '魚',
  lobster: 'ロブスター',
  crab: 'カニ',
  shell: '貝',
  coral: 'サンゴ',
  wave: '波',
  sand: '砂',
  stone: '石',
  gravel: '砂利',
  asphalt: 'アスファルト',
  curb: '縁石',
  line: 'ライン',
  stripe: 'ストライプ',
  zebra: '横断歩道',
  crossing: '横断',
  stop: '停止',
  yield: '譲渡',
  speed: '速度',
  limit: '制限',
  parking: '駐車',
  no: '禁止',
  entry: '入口',
  exit: '出口',
  one: '一方通行',
  way: '通行',
  dead: '行き止まり',
  end: '終端',
  merge: '合流',
  curve: 'カーブ',
  hill: '坂',
  bump: '隆起',
  dip: '凹み',
  bridge: '橋',
  tunnel: 'トンネル',
  toll: '料金所',
  booth: 'ブース',
  ticket: 'チケット',
  machine: '機械',
  vending: '自販機',
  snack: 'スナック',
  drink: '飲料',
  coffee: 'コーヒー',
  soda: 'ソーダ',
  water: '水',
  cooler: 'クーラー',
  ice: '氷',
  freezer: '冷凍庫',
  oven: 'オーブン',
  micro: '電子レンジ',
  dish: '皿',
  cup: 'カップ',
  mug: 'マグ',
  plate: 'プレート',
  fork: 'フォーク',
  knife: 'ナイフ',
  spoon: 'スプーン',
  bottle: 'ボトル',
  can: '缶',
  jar: '瓶',
  bowl: 'ボウル',
  pan: 'フライパン',
  pot: '鍋',
  kettle: 'やかん',
  mixer: 'ミキサー',
  blender: 'ブレンダー',
  toaster: 'トースター',
  juicer: 'ジューサー',
  scale: 'はかり',
  timer: 'タイマー',
  alarm: 'アラーム',
  smoke: '煙',
  det: '探知器',
  co2: 'CO2',
  fire: '火災',
  ext: '消火器',
  hose: 'ホース',
  reel: 'リール',
  nozzle: 'ノズル',
  pump: 'ポンプ',
  valve: 'バルブ',
  gauge: 'ゲージ',
  meter: 'メーター',
  leak: '漏れ',
  drip: '滴下',
  flood: '浸水',
  drain: '排水',
  sewer: '下水',
  manhole: 'マンホール',
  grate: 'グレーチング',
  cover: '蓋',
  lid: 'ふた',
  cap: 'キャップ',
  seal: 'シール',
  lock: '錠',
  key: '鍵',
  padlock: '南京錠',
  chain: 'チェーン',
  bar: 'バー',
  grill: 'グリル',
  mesh: 'メッシュ',
  wire: 'ワイヤー',
  net: 'ネット',
  cage: 'ケージ',
  fence: 'フェンス',
  wall: '壁',
  post: '柱',
  pole: 'ポール',
  beam: '梁',
  joist: '桁',
  stud: 'スタッド',
  drywall: '石膏ボード',
  plywood: '合板',
  osb: 'OSB',
  insulation: '断熱材',
  vapor: '防湿',
  wrap: 'ラップ',
  tape: 'テープ',
  glue: '接着剤',
  nail: '釘',
  screw: 'ねじ',
  bolt: 'ボルト',
  nut: 'ナット',
  washer: 'ワッシャー',
  rivet: 'リベット',
  weld: '溶接',
  cut: '切断',
  grind: '研削',
  sand: '研磨',
  polish: '研磨',
  paint: '塗装',
  stain: '着色',
  varnish: 'ニス',
  lacquer: 'ラッカー',
  primer: '下塗り',
  coat: 'コート',
  layer: '層',
  film: 'フィルム',
  sheet: 'シート',
  roll: 'ロール',
  tile: 'タイル',
  grout: '目地',
  caulk: 'コーキング',
  sealant: 'シーラント',
  foam: 'フォーム',
  spray: 'スプレー',
  brush: 'ブラシ',
  roller: 'ローラー',
  tray: 'トレイ',
  bucket: 'バケツ',
  mop: 'モップ',
  broom: 'ほうき',
  dust: 'ほこり',
  pan: 'ちりとり',
  vacuum: '掃除機',
  cleaner: '洗剤',
  soap: '石鹸',
  sponge: 'スポンジ',
  rag: '雑巾',
  towel: 'タオル',
  tissue: 'ティッシュ',
  paper: '紙',
  roll: 'ロール',
  dispenser: 'ディスペンサー',
  holder: 'ホルダー',
  hook: 'フック',
  rack: 'ラック',
  hanger: 'ハンガー',
  rod: 'ロッド',
  pole: 'ポール',
  rail: 'レール',
  track: 'トラック',
  slide: 'スライド',
  hinge: '蝶番',
  handle: '取っ手',
  knob: 'ノブ',
  pull: '引き手',
  push: '押し手',
  latch: 'ラッチ',
  bolt: 'ボルト',
  strike: '受け口',
  jamb: '枠',
  sill: '敷居',
  header: 'ヘッダー',
  footer: 'フッター',
  trim: '廻り縁',
  molding: 'モールディング',
  crown: '廻り縁',
  base: '巾木',
  corner: 'コーナー',
  edge: 'エッジ',
  corner: '角',
  round: '丸',
  square: '四角',
  arch: 'アーチ',
  curve: '曲線',
  straight: '直線',
  angle: '角度',
  degree: '度',
  rad: 'ラジアン',
  slope: '傾斜',
  pitch: '勾配',
  rise: '上昇',
  run: '水平',
  span: 'スパン',
  width: '幅',
  height: '高さ',
  depth: '奥行き',
  thick: '厚さ',
  thin: '薄い',
  long: '長い',
  short: '短い',
  wide: '広い',
  narrow: '狭い',
  large: '大',
  small: '小',
  big: '大',
  tiny: '極小',
  mini: 'ミニ',
  micro: 'マイクロ',
  mega: 'メガ',
  super: 'スーパー',
  ultra: 'ウルトラ',
  max: '最大',
  min: '最小',
  std: '標準',
  alt: '代替',
  var: 'バリエーション',
  v1: '',
  v2: '',
  a: '',
  b: '',
  c: '',
  d: '',
  e: '',
  l: '',
  r: '',
  s: '',
  m: '',
  xl: '',
  xs: '',
  sm: '',
  md: '',
  lg: '',
  xxl: '',
}

function escapeLuaString(s) {
  return String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'")
}

function toJapaneseLabel(model) {
  const lower = model.toLowerCase()
  const parts = lower.split('_').filter((p) => p.length > 0)
  const mapped = parts
    .map((p) => {
      if (p === 'prop' || p === 'hash' || /^[0-9a-f]{8}$/i.test(p)) return ''
      if (/^\d+$/.test(p)) return p
      return LABEL_DICT[p] || p
    })
    .filter(Boolean)
  const joined = mapped.join(' ').trim()
  return joined || model
}

function extractTags(model) {
  const parts = model.toLowerCase().split('_').filter((p) => p.length > 1)
  const tags = []
  for (const p of parts) {
    if (p === 'prop' || p === 'hash' || /^\d+$/.test(p)) continue
    if (!tags.includes(p)) tags.push(p)
    if (tags.length >= 8) break
  }
  return tags
}

function extractPropGroups(luaText) {
  const groups = []
  let i = 0
  while (true) {
    const catMark = luaText.indexOf("category = '", i)
    if (catMark === -1) break
    const q1 = catMark + "category = '".length
    const q2 = luaText.indexOf("'", q1)
    if (q2 === -1) break
    const category = luaText.slice(q1, q2)
    const modelsMark = luaText.indexOf('models = {', q2)
    if (modelsMark === -1) break
    const openBrace = luaText.indexOf('{', modelsMark)
    if (openBrace === -1) break
    let depth = 1
    let j = openBrace + 1
    while (depth > 0 && j < luaText.length) {
      const c = luaText[j]
      if (c === '{') depth++
      else if (c === '}') depth--
      j++
    }
    const modelsBody = luaText.slice(openBrace + 1, j - 1)
    groups.push({ category, modelsBody })
    i = j
  }
  return groups
}

function parseModels(modelsBody) {
  const models = []
  const re = /'([a-zA-Z0-9_]+)'/g
  let m
  while ((m = re.exec(modelsBody)) !== null) {
    models.push(m[1])
  }
  return models
}

function categoriesToLua(roots) {
  const lines = []
  for (const r of roots) {
    const childLines = r.children.map(
      (c) => `                { id = '${escapeLuaString(c.id)}', label = '${escapeLuaString(c.label)}' }`,
    )
    lines.push(`            {
                id = '${escapeLuaString(r.id)}',
                label = '${escapeLuaString(r.label)}',
                children = {
${childLines.join(',\n')},
                },
            }`)
  }
  return lines.join(',\n')
}

function parseArgs(argv) {
  let source = DEFAULT_SOURCE
  let mapPath = path.join(ROOT, 'tools', 'category_map.json')
  let outPath = path.join(ROOT, 'config', 'props.lua')
  for (let a = 0; a < argv.length; a++) {
    if (argv[a] === '--source' && argv[a + 1]) {
      source = argv[++a]
    } else if (argv[a] === '--map' && argv[a + 1]) {
      mapPath = path.resolve(ROOT, argv[++a])
    } else if (argv[a] === '--out' && argv[a + 1]) {
      outPath = path.resolve(ROOT, argv[++a])
    }
  }
  return { source, mapPath, outPath }
}

async function readSource(source) {
  if (source.startsWith('http://') || source.startsWith('https://')) {
    const res = await fetch(source)
    if (!res.ok) throw new Error(`fetch failed ${res.status} ${source}`)
    return await res.text()
  }
  const p = path.isAbsolute(source) ? source : path.resolve(ROOT, source)
  return await fs.readFile(p, 'utf8')
}

const { source, mapPath, outPath } = parseArgs(process.argv.slice(2))
const mapRaw = await fs.readFile(mapPath, 'utf8')
const map = JSON.parse(mapRaw)
const mapping = map.mapping || {}
const roots = map.roots || []

const luaText = await readSource(source)
const groups = extractPropGroups(luaText)

const unknownCategories = []
const duplicateModels = []
const firstSeen = new Map()
const rootCounts = {}
const dictEntries = []

for (const { category, modelsBody } of groups) {
  const internal = mapping[category]
  if (!internal) {
    unknownCategories.push(category)
    continue
  }
  const root = internal.split('/')[0] || 'misc'
  const models = parseModels(modelsBody)
  for (const model of models) {
    if (firstSeen.has(model)) {
      duplicateModels.push({ model, first: firstSeen.get(model), second: category })
      continue
    }
    firstSeen.set(model, category)
    rootCounts[root] = (rootCounts[root] || 0) + 1
    const label = toJapaneseLabel(model)
    const tags = extractTags(model)
    dictEntries.push({
      model,
      label,
      category: internal,
      tags,
    })
  }
}

if (unknownCategories.length) {
  console.warn('WARN: categories not in category_map.json (skipped entire groups):')
  for (const c of unknownCategories) console.warn('  -', c)
}

if (duplicateModels.length) {
  console.warn(`WARN: duplicate model names (${duplicateModels.length}), kept first occurrence`)
}

const generatedAt = new Date().toISOString()
const categoriesLua = categoriesToLua(roots)

const propLines = dictEntries.map((e) => {
  const tagsLua = e.tags.map((t) => `'${escapeLuaString(t)}'`).join(', ')
  return (
    `        ['${escapeLuaString(e.model)}'] = {\n` +
    `            label = '${escapeLuaString(e.label)}',\n` +
    `            category = '${escapeLuaString(e.category)}',\n` +
    `            thumb = '${escapeLuaString(e.model)}.webp',\n` +
    `            tags = { ${tagsLua} },\n` +
    `            tintable = false,\n` +
    `            tint_palette = nil,\n` +
    `        }`
  )
})

const header = `-- SPDX-License-Identifier: LGPL-3.0-or-later
-- Auto-generated by tools/import_props.mjs — DO NOT EDIT BY HAND.
-- Regenerate: npm run build:props
--
-- Data lineage (GPL-3.0):
--   Source list: https://github.com/ShiftyWreckzz/prop-list (prop_list.lua)
--   Original prop data: Menyoo (GPL-3.0)
-- This generated catalog is GPL-3.0-sourced data reshaped for TECTON; the Lua
-- code in this repo (outside this file's factual listings) remains LGPL-3.0-or-later.
-- See README.md § Credits and CONTRIBUTING.md.

Config = Config or {}
Config.Props = {
    version = 1,
    generated_at = '${escapeLuaString(generatedAt)}',
    categories = {
${categoriesLua},
    },
    dictionary = {
`

const footer = `
    },
}
`

const out = header + propLines.join(',\n') + footer
await fs.mkdir(path.dirname(outPath), { recursive: true })
await fs.writeFile(outPath, out, 'utf8')

const buf = Buffer.from(out, 'utf8')
console.log('--- import_props summary ---')
console.log('Total props (unique):', dictEntries.length)
console.log('Root category counts:')
for (const [k, v] of Object.entries(rootCounts).sort((a, b) => b[1] - a[1])) {
  console.log(`  ${k}: ${v}`)
}
console.log('Output:', path.relative(ROOT, outPath))
console.log('Size bytes:', buf.length)
if (unknownCategories.length) console.log('Unmapped categories:', unknownCategories.length)
if (duplicateModels.length) console.log('Duplicate warnings:', duplicateModels.length)
