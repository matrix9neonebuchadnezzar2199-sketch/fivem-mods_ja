fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'alnd（日本語化・改修: matrix9neonebuchadnezzar2199）'
description 'B2B ROLEPLAY DOCUMENTS — 日本語版（ESX / QB-Core / Qbox + 複数インベントリ）'
version '2.0.3-jp.9'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/img/logo.png',
    'ui/fonts/fonts.css',
    'ui/fonts/OFL.txt',
    'ui/fonts/*.woff2',
    'web/images/*.png',
}

exports {
    'usePaper'
}

shared_scripts {
    'config.lua',
    'locales/*.lua',
    'modules/framework_bridge.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_lib/init.lua',
    'modules/inventory_bridge.lua',
    'server.lua',
}

client_scripts {
    '@ox_lib/init.lua',
    'client.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
}

optional_dependencies {
    'ox_inventory',
    'ox_target',
    'qb-inventory',
    'qb-target',
    'es_extended',
    'qb-core',
    'qbx_core',
}

escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'modules/*.lua',
}
