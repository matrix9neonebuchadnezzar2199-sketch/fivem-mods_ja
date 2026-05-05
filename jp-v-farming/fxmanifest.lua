fx_version 'cerulean'
game 'gta5'

author 'Virgil (原作) / 日本語化: matrix9neonebuchadnezzar2199-sketch'
description 'シンプル農業スクリプト 日本語化版 (jp-v-farming)'
version '1.0.0-ja.1'
repository 'https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua',
    'locales/ja.lua',
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}