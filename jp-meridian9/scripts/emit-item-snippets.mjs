/**
 * 回収アイテムを一括追加するときのスニペット生成。
 * 使い方: node scripts/emit-item-snippets.mjs docs/item-bulk-seed.json
 * 入力: JSON 配列（スキーマは ITEM_I18N.md 参照）
 * 出力: stdout に config / ja / en / item-icon-map の追記用ブロックを順に出す
 */
import fs from 'fs';

const path = process.argv[2];
if (!path) {
  console.error('Usage: node scripts/emit-item-snippets.mjs <path-to-seed.json>');
  process.exit(1);
}
const raw = fs.readFileSync(path, 'utf8');
const list = JSON.parse(raw);
if (!Array.isArray(list) || list.length === 0) {
  console.error('Seed must be a non-empty JSON array');
  process.exit(1);
}

function escLua(s) {
  return String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

for (const row of list) {
  if (!row.id || !/^[a-z][a-z0-9_]*$/.test(row.id)) {
    console.error('Invalid id (ASCII snake_case required):', row.id);
    process.exit(1);
  }
  const rarity = row.rarity || 'common';
  if (!['common', 'uncommon', 'rare', 'legendary'].includes(rarity)) {
    console.error('Invalid rarity:', rarity, 'id=', row.id);
    process.exit(1);
  }
  if (typeof row.nameEn !== 'string' || typeof row.nameJa !== 'string') {
    console.error('nameEn and nameJa must be strings, id=', row.id);
    process.exit(1);
  }
  const v = Number(row.value);
  if (!Number.isFinite(v) || v < 0) {
    console.error('Invalid value, id=', row.id);
    process.exit(1);
  }
}

const nameKey = (id) => `m9_item_${id}`;

console.log('-- ========== paste into config.lua → Config.Items 配列の末尾（カンマ位置に注意） ==========\n');
for (const row of list) {
  const nk = row.nameKey || nameKey(row.id);
  const rarity = row.rarity || 'common';
  const ft = row.fictionTag ? `, fictionTag = '${escLua(row.fictionTag)}'` : '';
  console.log(
    `    { id = '${row.id}', nameKey = '${nk}', name = '${escLua(row.nameEn)}', rarity = '${rarity}', value = ${Math.floor(row.value)}${ft} },`
  );
}

console.log('\n-- ========== paste into locales/ja.lua（Locales[\'ja\'] テーブル内・末尾） ==========\n');
for (const row of list) {
  const nk = row.nameKey || nameKey(row.id);
  console.log(`    ['${nk}'] = '${escLua(row.nameJa)}',`);
}

console.log("\n-- ========== paste into locales/en.lua（Locales['en'] テーブル内・末尾） ==========\n");
for (const row of list) {
  const nk = row.nameKey || nameKey(row.id);
  console.log(`    ['${nk}'] = '${escLua(row.nameEn)}',`);
}

console.log('\n// ========== paste into html/item-icon-map.js → MRD9_ITEM_ICON_MAP 内 ==========\n');
for (const row of list) {
  console.log(`        ${row.id}: 'image/item/${row.id}.png',`);
}

console.log('\n-- ========== 画像ファイル（リポジトリ） ==========');
console.log('各 id に対し image/item/<id>.png を配置。fxmanifest は image/item/*.png 列挙済み。');
console.log('');
