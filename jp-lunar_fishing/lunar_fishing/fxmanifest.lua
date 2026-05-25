-- Resource Metadata
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Lunar Scripts (original) / matrix9neonebuchadnezzar2199-sketch (Japanese localization)'
description 'Advanced Fishing (Japanese Localization) - based on lunar_fishing v1.0.1, GPL-3.0'
version '1.0.1-ja1.1'

files {
    'locales/*.json'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua'
}

client_scripts {
    'framework/**/client.lua',
    'utils/cl_main.lua',
    'config/cl_edit.lua',
    'client/*.lua'
}

server_scripts {
    'framework/**/server.lua',
    '@oxmysql/lib/MySQL.lua',
    'utils/sv_main.lua',
    'config/sv_config.lua',
    'server/*.lua'
}
