fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'polapaint v3 - Polaroid camera with local storage (net-event only)'
version '3.0.0'
license 'GPL-3.0-or-later'
repository 'https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja'

shared_scripts {
    '@ox_lib/init.lua',
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

dependencies {
    'screenshot-basic',
    'ox_lib',
}
