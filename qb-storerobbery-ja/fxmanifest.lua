fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot (Original) / Japanese Localization & Bug Fixes'
description 'Allows players to rob various stores on the map for money and items - 日本語化 & バグ修正版'
version '1.2.0-ja.1'
repository 'https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua'
}

client_script 'client/main.lua'

server_scripts {
    'server/bridge/inventory.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
    'html/reset.css'
}
