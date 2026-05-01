fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'トレーディングカードゲーム（BOOK・コレクション・デッキ編成・対戦予定）'
version '0.1.0'

dependency 'oxmysql'

shared_scripts {
    'config.lua',
    'shared/identity.lua',
    'shared/cards.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/collection.lua',
    'server/deck.lua',
    'server/debug.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/nui_callbacks.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/assets/cards/**/*.png',
}
