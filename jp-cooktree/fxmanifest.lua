fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'CookTree'
description 'Cooking skill tree - POE-style'
version '0.4.0'

-- P3a: server/* + shared/tree.lua + config_recipes.lua 稼働（ox_inventory 必須）
dependency 'ox_inventory'

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
    'server/ext_xp.lua',
    'server/inventory.lua',
    'server/main.lua',
}

client_script 'client/main.lua'

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/skilltree_back.jpg',
}
