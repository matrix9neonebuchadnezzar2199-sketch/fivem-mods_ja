fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jp-slot'
author 'JP-Mods'
version '1.0.0'
description 'JP-Slot - VTuber Casino Slot Machine'

shared_script 'config_shared.lua'

server_scripts {
    'config_server.lua',
    'server/framework.lua',
    'server/rng.lua',
    'server/theme.lua',
    'server/ui_size.lua',
    'server/dynamic_machines.lua',
    'server/admin.lua',
    'server/main.lua',
    'server/commands.lua',
}

client_scripts {
    'client/machines.lua',
    'client/admin.lua',
    'client/commands.lua',
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/admin.html',
    'html/css/**/*.css',
    'html/js/**/*.js',
    'html/assets/**/*.png',
    'html/assets/**/*.webm',
    'html/assets/**/*.jpg',
    'html/assets/**/*.jpeg',
    -- 'html/assets/**/*.woff2',
    'locales/*.json',
}
