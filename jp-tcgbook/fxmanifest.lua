fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'TCG BOOK（コレクション・デッキ・対戦／パック入手想定）'
version '0.1.0'

dependency 'oxmysql'

shared_scripts {
    'config.lua',
    'shared/battle_rule.lua',
    'shared/battle_wire_log.lua',
    'shared/identity.lua',
    'shared/cards.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/collection.lua',
    'server/deck.lua',
    'server/debug.lua',
    'server/admin.lua',
    'server/battle_lobby.lua',
    'server/battle_debug.lua',
    'server/battle_pvp.lua',
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
    'html/admin/index.html',
    'html/admin/css/*.css',
    'html/admin/js/*.js',
    'html/assets/cards/**/*.png',
    'html/assets/cards/asset_manifest.json',
    'html/assets/duel_back.png',
}
