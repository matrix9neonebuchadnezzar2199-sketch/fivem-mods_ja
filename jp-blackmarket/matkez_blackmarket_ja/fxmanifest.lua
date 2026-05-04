fx_version 'cerulean'
game 'gta5'
author 'MatkezZz'
description 'Black market'
lua54 'yes'
version '1.0.0'

client_scripts {
    'client/main.lua',
    'bridge/client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'server/main.lua',
    'config/server.lua',
    'bridge/server/*.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua',
    'bridge/shared.lua'
}

ui_page 'ui/a.html'

files {
    'ui/**/*',
    'locales/*.json'
}