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
    'server/main.lua',
}

-- フェーズ1-5以降: client_scripts、ui_page、files { 'html/**' } を追加
