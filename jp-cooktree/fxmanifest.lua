fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'CookTree'
description 'Cooking skill tree - POE-style'
version '0.9.1'

-- ox_inventory: アイテム付与。P3c: Glitch Minigames（jp-glitch28 / リネーム時は Config で合わせる）
dependencies {
    'jp-glitch28',
    'ox_inventory',
}

shared_scripts {
    'config/config_main.lua',
    'config/config_buffs.lua',
    'config/config_specializations/western.lua',
    'config/config_specializations/chinese.lua',
    'config/config_specializations/sweets.lua',
    'config/config_general.lua',
    'config/config_recipes.lua',
    'shared/tree.lua',
}

server_scripts {
    'server/inventory.lua',
    'server/stars.lua',
    'server/ext_xp.lua',
    'server/passive.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/skilltree_back.jpg',
}
