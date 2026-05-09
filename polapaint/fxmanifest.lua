fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods (polapaint contributors)'
description 'polapaint v2 - Polaroid camera with NUI paint editor (local storage)'
version '2.0.0'
license 'GPL-3.0-or-later'
repository 'https://github.com/JP-Mods/polapaint'

shared_scripts {
    'config.lua',
    'locales/ja.lua',
    'locales/en.lua',
    'shared/util.lua',
}

client_scripts {
    'client/bridge.lua',
    'client/main.lua',
}

server_scripts {
    'server/bridge.lua',
    'server/storage.lua',
    'server/webhook.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/images/*.png',
}
